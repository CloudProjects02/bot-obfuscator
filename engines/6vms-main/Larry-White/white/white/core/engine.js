const { cloneNode, walk } = require("../lua/ast");
const { parseLua } = require("../lua/parse");
const { decodeConstantArray } = require("../passes/constant-array");
const { foldConstants } = require("../passes/constant-fold");
const { removeUnusedLocals } = require("../passes/dead-code");
const { removeDeadBranches } = require("../passes/dead-branch");
const { removeAntiTamperPass } = require("../passes/remove-anti-tamper");
const { cleanupVmRemnants } = require("../passes/cleanup-vm");
const { resolveStringTable } = require("../passes/resolve-string-table");
const { renameLocals } = require("../passes/rename");
const { looksObfuscated } = require("../passes/obfuscation");
const { simplifyAst } = require("../passes/simplify");
const { applySyntaxSugar } = require("../passes/sugar");
const { devirtualizePrometheusVm } = require("../prometheus/devirtualize");
const {
  normalizePrometheusOutputSource,
  postprocessPrometheusAst,
  recoverRobloxUiAssignmentsAst,
  _debug: postprocessDebug,
} = require("../prometheus/postprocess");
const { extractPayloadAliasHints, unwrapOuterWrapper } = require("../passes/unwrap");
const { emitVerifiedChunk } = require("./output");
const { runPassSequence } = require("./pass-runner");

const KNOWN_MARKER_REGEX = /(?:77fuscator|wearedevs|prometheus|tamper detected|galactic|25ms|luarmor)/i;
const MAX_VM_NODES = 120000;
const HUGE_SOURCE_BYTES = 150000;
const HUGE_NODE_COUNT = 100000;
const MAX_VM_NODE_GROWTH_RATIO = 1.6;
const MAX_VM_OUTPUT_NODES = 170000;
const FAST_VM_DEVIRTUALIZE_ATTEMPTS = 1;
const FULL_VM_DEVIRTUALIZE_ATTEMPTS = 3;
const FAST_VM_DEVIRTUALIZE_TIME_BUDGET_MS = 10000;

function isBooleanLiteralTrue(node) {
  return node && node.type === "BooleanLiteral" && node.value === true;
}

function isNumericLiteral(node) {
  return node && node.type === "NumericLiteral" && Number.isFinite(node.value);
}

function isIdentifierNode(node) {
  return node && node.type === "Identifier";
}

function countVmComparisons(statements) {
  let count = 0;
  walk({ type: "Chunk", body: statements, comments: [] }, (node) => {
    if (!node || node.type !== "BinaryExpression") {
      return;
    }

    if (!["==", "<", "<=", ">", ">=", "~="].includes(node.operator)) {
      return;
    }

    if (
      (isIdentifierNode(node.left) && isNumericLiteral(node.right)) ||
      (isIdentifierNode(node.right) && isNumericLiteral(node.left))
    ) {
      count += 1;
    }
  });
  return count;
}

function isVmLikeAst(ast) {
  let maxComparisons = 0;
  walk(ast, (node) => {
    if (node.type === "WhileStatement" && isBooleanLiteralTrue(node.condition)) {
      maxComparisons = Math.max(maxComparisons, countVmComparisons(node.body));
    }
  });
  return maxComparisons >= 12;
}

function detectObfuscationHints(source, ast) {
  const text = typeof source === "string" ? source : "";
  return {
    hasKnownMarker: KNOWN_MARKER_REGEX.test(text),
    vmLikely: isVmLikeAst(ast) || /(?:77fuscator|prometheus)/i.test(text),
  };
}

function extractLoaderUrl(source) {
  if (typeof source !== "string") {
    return null;
  }

  const matches = source.match(/https?:\/\/[^\s'"]+/g);
  if (!matches) {
    return null;
  }

  const urls = [...new Set(matches)];
  const luaUrls = urls.filter((url) => /\.lua(\?|$)/i.test(url));
  if (luaUrls.length === 1) {
    return luaUrls[0];
  }

  const preferredLua = luaUrls.find((url) => /luarmor|loader|loaders/i.test(url));
  if (preferredLua) {
    return preferredLua;
  }

  return urls.length === 1 ? urls[0] : null;
}

function capturePostprocessHints(ast) {
  const encryptParams = postprocessDebug.extractEncryptParams(ast);
  const literalStringBuilders = postprocessDebug.extractLiteralStringBuilderNames(ast);
  const reorderStringBuilders = postprocessDebug.extractReorderStringBuilderNames(ast);
  const stringProxies = postprocessDebug.extractStringProxyNames(ast);
  const galactic = postprocessDebug.extractGalacticDecoder(ast);

  if (
    !encryptParams &&
    literalStringBuilders.length === 0 &&
    reorderStringBuilders.length === 0 &&
    stringProxies.length === 0 &&
    !galactic
  ) {
    return null;
  }

  let secretKey8 = encryptParams ? postprocessDebug.extractSecretKey8(ast) : null;
  if (secretKey8 === null && encryptParams) {
    const encryptedCalls = postprocessDebug.collectEncryptedCalls(ast);
    secretKey8 = postprocessDebug.inferSecretKey8(encryptParams, encryptedCalls);
  }
  if (encryptParams && secretKey8 === null && !galactic) {
    return null;
  }

  return {
    encryptParams,
    galactic,
    literalStringBuilders,
    reorderStringBuilders,
    secretKey8,
    stringProxies,
  };
}

function mergePostprocessHints(previousHints, nextHints) {
  if (!previousHints) {
    return nextHints;
  }

  if (!nextHints) {
    return previousHints;
  }

  return {
    encryptParams: nextHints.encryptParams || previousHints.encryptParams || null,
    galactic: nextHints.galactic || previousHints.galactic || null,
    literalStringBuilders: [...new Set([...(previousHints.literalStringBuilders || []), ...(nextHints.literalStringBuilders || [])])],
    reorderStringBuilders: [...new Set([...(previousHints.reorderStringBuilders || []), ...(nextHints.reorderStringBuilders || [])])],
    secretKey8:
      nextHints.secretKey8 !== null && nextHints.secretKey8 !== undefined
        ? nextHints.secretKey8
        : (previousHints.secretKey8 ?? null),
    stringProxies: [...new Set([...(previousHints.stringProxies || []), ...(nextHints.stringProxies || [])])],
  };
}

function countNodes(root, limit = Infinity) {
  let count = 0;
  const stack = [root];

  while (stack.length > 0) {
    const current = stack.pop();
    if (!current || typeof current !== "object") {
      continue;
    }

    if (Array.isArray(current)) {
      for (let index = current.length - 1; index >= 0; index -= 1) {
        stack.push(current[index]);
      }
      continue;
    }

    if (typeof current.type === "string") {
      count += 1;
      if (count >= limit) {
        return count;
      }
    }

    for (const [key, value] of Object.entries(current)) {
      if (key === "scope") {
        continue;
      }
      stack.push(value);
    }
  }

  return count;
}

function characterizeInputSize(source, ast) {
  const inputBytes = Buffer.byteLength(typeof source === "string" ? source : "", "utf8");
  const nodeCount = countNodes(ast, MAX_VM_NODES + 1);
  return {
    inputBytes,
    isHuge: inputBytes >= HUGE_SOURCE_BYTES || nodeCount > HUGE_NODE_COUNT,
    nodeCount,
  };
}

function getCallBaseRoot(base) {
  if (!base || typeof base !== "object") {
    return null;
  }

  if (base.type === "Identifier") {
    return base.name;
  }

  if (base.type === "MemberExpression" || base.type === "IndexExpression") {
    return getCallBaseRoot(base.base);
  }

  return null;
}

function isSimpleLiteral(node) {
  const current = unwrapParentheses(node);
  return Boolean(
    current &&
    (
      current.type === "StringLiteral" ||
      current.type === "NumericLiteral" ||
      current.type === "BooleanLiteral" ||
      current.type === "NilLiteral"
    )
  );
}

function countLiteralPrintCalls(ast) {
  let count = 0;
  walk(ast, (node) => {
    if (
      node.type === "CallExpression" &&
      getCallBaseRoot(node.base) === "print" &&
      Array.isArray(node.arguments) &&
      node.arguments.length > 0 &&
      node.arguments.every((arg) => isSimpleLiteral(arg))
    ) {
      count += 1;
    }
  });
  return count;
}

function isCompactLiteralPrintPayload(ast) {
  return (
    Boolean(ast) &&
    Array.isArray(ast.body) &&
    ast.body.length <= 20 &&
    countLiteralPrintCalls(ast) >= 1
  );
}

function stripTrailingBareReturn(ast) {
  if (!ast.body.length) {
    return ast;
  }

  const lastStatement = ast.body[ast.body.length - 1];
  if (lastStatement.type === "ReturnStatement" && lastStatement.arguments.length === 0) {
    return {
      ...ast,
      body: ast.body.slice(0, -1),
    };
  }

  return ast;
}

function unwrapParentheses(node) {
  let current = node;
  while (current && current.type === "ParenthesisExpression") {
    current = current.expression;
  }
  return current;
}

function isGetgenvCall(node) {
  const expression = unwrapParentheses(node);
  return (
    expression &&
    expression.type === "CallExpression" &&
    expression.base &&
    expression.base.type === "Identifier" &&
    expression.base.name === "getgenv"
  );
}

function extractGetgenvAssignments(ast) {
  const assignments = [];
  const seenKeys = new Set();

  walk(ast, (node) => {
    if (
      node.type !== "AssignmentStatement" ||
      node.variables.length !== 1 ||
      node.init.length !== 1
    ) {
      return;
    }

    const target = node.variables[0];
    if (target.type !== "IndexExpression") {
      return;
    }

    const base = unwrapParentheses(target.base);
    const index = unwrapParentheses(target.index);
    if (!isGetgenvCall(base) || !index || index.type !== "StringLiteral") {
      return;
    }

    if (seenKeys.has(index.value)) {
      return;
    }
    seenKeys.add(index.value);

    assignments.push({
      type: "AssignmentStatement",
      variables: [
        {
          type: "IndexExpression",
          base: {
            type: "CallExpression",
            base: { type: "Identifier", name: "getgenv" },
            arguments: [],
          },
          index: cloneNode(index),
        },
      ],
      init: [cloneNode(node.init[0])],
    });
  });

  return assignments;
}

function runTransformIterations(ast, context, initialHints = null, runtimeProfile = {}) {
  let currentAst = ast;
  let hints = initialHints;
  let changed = false;
  const fastMode = runtimeProfile.fastMode === true;
  const inputNodes = Number.isFinite(runtimeProfile.inputNodes) ? runtimeProfile.inputNodes : null;
  const maxIterations = fastMode ? 2 : 8;
  let fastModeVmAttempts = 0;

  for (let iteration = 0; iteration < maxIterations; iteration += 1) {
    const result = runPassSequence(currentAst, context, [
      {
        name: "fold-constants",
        run(nextAst) {
          return foldConstants(nextAst);
        },
      },
      {
        name: "decode-constant-array",
        run(nextAst) {
          return decodeConstantArray(nextAst);
        },
      },
      {
        name: "devirtualize-prometheus-vm",
        run(nextAst) {
          if (fastMode && fastModeVmAttempts >= FAST_VM_DEVIRTUALIZE_ATTEMPTS) {
            return {
              ast: nextAst,
              changed: false,
              metadata: { skipped: "fast-mode-attempt-limit" },
            };
          }

          if (fastMode && inputNodes !== null && inputNodes > MAX_VM_NODES) {
            fastModeVmAttempts = FAST_VM_DEVIRTUALIZE_ATTEMPTS;
            return {
              ast: nextAst,
              changed: false,
              metadata: { skipped: "initial-node-limit" },
            };
          }

          if (countNodes(nextAst, MAX_VM_NODES + 1) > MAX_VM_NODES) {
            return {
              ast: nextAst,
              changed: false,
              metadata: { skipped: "node-limit" },
            };
          }

          const beforeNodes = countNodes(nextAst, MAX_VM_OUTPUT_NODES + 1);
          const vmResult = devirtualizePrometheusVm(
            nextAst,
            fastMode
              ? { timeBudgetMs: FAST_VM_DEVIRTUALIZE_TIME_BUDGET_MS }
              : undefined,
          );
          if (fastMode) {
            fastModeVmAttempts += 1;
          }
          if (!vmResult || vmResult.changed !== true || !vmResult.ast) {
            return vmResult;
          }

          const afterNodes = countNodes(vmResult.ast, MAX_VM_OUTPUT_NODES + 1);
          if (!fastMode) {
            // In full mode, allow growth up to MAX_VM_OUTPUT_NODES
            if (afterNodes > MAX_VM_OUTPUT_NODES) {
              return {
                ast: nextAst,
                changed: false,
                metadata: {
                  afterNodes,
                  beforeNodes,
                  skipped: "growth-guard",
                },
              };
            }
          } else {
            // In fast mode, also check growth ratio
            if (afterNodes > MAX_VM_OUTPUT_NODES ||
                afterNodes > Math.ceil(beforeNodes * MAX_VM_NODE_GROWTH_RATIO)) {
              return {
                ast: nextAst,
                changed: false,
                metadata: {
                  afterNodes,
                  beforeNodes,
                  skipped: "growth-guard",
                },
              };
            }
          }

          return vmResult;
        },
      },
    ]);

    currentAst = result.ast;
    hints = mergePostprocessHints(hints, capturePostprocessHints(currentAst));
    changed = changed || result.changed;
    if (!result.changed) {
      break;
    }
  }

  return {
    ast: currentAst,
    changed,
    hints,
  };
}

function normalizeReadableUiArtifacts(ast) {
  if (!ast || !Array.isArray(ast.body)) {
    return ast;
  }

  const normalizeStringProxyCalls =
    postprocessDebug && typeof postprocessDebug.normalizeStringProxyStringCalls === "function"
      ? postprocessDebug.normalizeStringProxyStringCalls
      : null;
  const normalizeUiOptions =
    postprocessDebug && typeof postprocessDebug.normalizeUiLibraryCallOptions === "function"
      ? postprocessDebug.normalizeUiLibraryCallOptions
      : null;

  if (!normalizeStringProxyCalls && !normalizeUiOptions) {
    return ast;
  }

  const extractedProxyNames =
    postprocessDebug && typeof postprocessDebug.extractStringProxyNames === "function"
      ? postprocessDebug.extractStringProxyNames(ast)
      : [];
  const proxyState = {
    stringProxies: new Set(Array.isArray(extractedProxyNames) ? extractedProxyNames : []),
  };

  let nextBody = ast.body;
  if (normalizeStringProxyCalls) {
    nextBody = normalizeStringProxyCalls(nextBody, proxyState);
  }
  if (normalizeUiOptions) {
    nextBody = normalizeUiOptions(nextBody, proxyState);
  }

  if (nextBody === ast.body) {
    return ast;
  }

  return {
    ...ast,
    body: nextBody,
  };
}

function runReadableCleanup(ast, context, runtimeProfile = {}) {
  const fastMode = runtimeProfile.fastMode === true;

  let currentAst = ast;

  // Resolve string tables before any cleanup that might destroy them
  const initialStringTableResult = resolveStringTable(currentAst);
  if (initialStringTableResult.changed) {
    currentAst = initialStringTableResult.ast;
  }

  // Multiple iterations of anti-tamper + dead branch removal + simplification
  for (let iteration = 0; iteration < 8; iteration += 1) {
    // 0. Resolve string table lookups early (before they get corrupted)
    const strResolveResult = resolveStringTable(currentAst);
    if (strResolveResult.changed) {
      currentAst = strResolveResult.ast;
    }

    // 1. Anti-tamper guard removal
    const antiTamperResult = removeAntiTamperPass(currentAst);
    if (antiTamperResult.changed) {
      currentAst = antiTamperResult.ast;
    }

    // 2. Dead branch removal
    const branchResult = removeDeadBranches(currentAst);
    if (branchResult.changed) {
      currentAst = branchResult.ast;
    }

    // 3. Fold constants (open-coded)
    const foldResult = foldConstants(currentAst);
    if (foldResult && foldResult.changed) {
      currentAst = foldResult.ast;
    }

    // 4. Decode constant array
    const decodeResult = decodeConstantArray(currentAst);
    if (decodeResult && decodeResult.changed) {
      currentAst = decodeResult.ast;
    }

    // 5. VM devirtualization (second round - catches remaining bytecode)
    const vmResult = devirtualizePrometheusVm(currentAst);
    if (vmResult && vmResult.changed && vmResult.ast) {
      currentAst = vmResult.ast;
    }

    // 6. Resolve string lookups that got freed up by devirtualization
    const strResolveResult2 = resolveStringTable(currentAst);
    if (strResolveResult2.changed) {
      currentAst = strResolveResult2.ast;
    }

    // 7. Simplify + remove dead code
    currentAst = runPassSequence(currentAst, context, [
      {
        name: "simplify-ast",
        run(nextAst) {
          return simplifyAst(nextAst);
        },
      },
      {
        name: "remove-unused-locals",
        run(nextAst) {
          return removeUnusedLocals(nextAst);
        },
      },
      {
        name: "cleanup-vm-remnants",
        run(nextAst) {
          return cleanupVmRemnants(nextAst);
        },
      },
    ]).ast;
  }

  currentAst = runPassSequence(currentAst, context, [
    {
      name: "rename-locals",
      run(nextAst) {
        return renameLocals(nextAst);
      },
    },
    {
      name: "recover-roblox-ui",
      run(nextAst) {
        return recoverRobloxUiAssignmentsAst(nextAst);
      },
    },
    {
      name: "apply-syntax-sugar",
      run(nextAst) {
        return applySyntaxSugar(nextAst);
      },
    },
    {
      name: "resolve-string-table-final",
      run(nextAst) {
        return resolveStringTable(nextAst);
      },
    },
    {
      name: "cleanup-vm-remnants-final",
      run(nextAst) {
        return cleanupVmRemnants(nextAst);
      },
    },
  ]).ast;

  return currentAst;
}

function normalizeRecoveredLoopVariable(ast) {
  if (
    !ast ||
    !Array.isArray(ast.body) ||
    ast.body.length !== 1 ||
    !ast.body[0] ||
    ast.body[0].type !== "ForNumericStatement" ||
    !ast.body[0].variable ||
    ast.body[0].variable.type !== "Identifier"
  ) {
    return ast;
  }

  const loop = ast.body[0];
  const oldName = loop.variable.name;
  if (oldName === "i") {
    return ast;
  }

  if (
    !Array.isArray(loop.body) ||
    loop.body.length !== 1 ||
    loop.body[0].type !== "CallStatement" ||
    !loop.body[0].expression ||
    loop.body[0].expression.type !== "CallExpression"
  ) {
    return ast;
  }

  const printCall = loop.body[0].expression;
  const firstArg = printCall.arguments && printCall.arguments[0];
  if (
    !firstArg ||
    firstArg.type !== "CallExpression" ||
    !firstArg.arguments ||
    firstArg.arguments.length < 3 ||
    firstArg.arguments[2].type !== "Identifier" ||
    firstArg.arguments[2].name !== oldName
  ) {
    return ast;
  }

  const nextLoop = cloneNode(loop);
  nextLoop.variable.name = "i";
  nextLoop.body[0].expression.arguments[0].arguments[2].name = "i";
  return {
    ...ast,
    body: [nextLoop],
  };
}

function deobfuscateSourceDetailed(source, options = {}) {
  const context = {
    diagnostics: {
      inliner: [],
      postprocess: [],
    },
    options,
    source,
    stages: [],
  };
  const full = options.full === true;
  const loaderUrlHint = extractLoaderUrl(source);
  const ast = parseLua(source);
  const sizeProfile = characterizeInputSize(source, ast);
  const fastMode = !full && sizeProfile.isHuge;
  context.diagnostics.performance = {
    fastMode,
    inputBytes: sizeProfile.inputBytes,
    inputNodes: sizeProfile.nodeCount,
    thresholds: {
      fastVmDevirtualizeAttempts: FAST_VM_DEVIRTUALIZE_ATTEMPTS,
      fastVmDevirtualizeTimeBudgetMs: FAST_VM_DEVIRTUALIZE_TIME_BUDGET_MS,
      hugeNodeCount: HUGE_NODE_COUNT,
      hugeSourceBytes: HUGE_SOURCE_BYTES,
      vmNodeGrowthRatio: MAX_VM_NODE_GROWTH_RATIO,
      vmNodeLimit: MAX_VM_NODES,
      vmOutputNodeLimit: MAX_VM_OUTPUT_NODES,
    },
  };
  const payloadAliasHints = extractPayloadAliasHints(ast);

  const iterationResult = runTransformIterations(
    ast,
    context,
    capturePostprocessHints(ast),
    {
      fastMode,
      inputNodes: sizeProfile.nodeCount,
    },
  );
  const obfuscationHints = detectObfuscationHints(source, iterationResult.ast);

  if (!iterationResult.changed && looksObfuscated(source) && !obfuscationHints.hasKnownMarker && !obfuscationHints.vmLikely) {
    throw new Error("Unsupported or unknown Prometheus variant");
  }

  let workingAst = unwrapOuterWrapper(iterationResult.ast).ast;
  workingAst = stripTrailingBareReturn(workingAst);

  let processedAst = postprocessPrometheusAst(workingAst, {
    ...(iterationResult.hints || {}),
    allowPayloadExtraction: true,
    allowLiteralPayload: false,
    capturedAliases: payloadAliasHints ? payloadAliasHints.aliases : undefined,
    diagnostics: context.diagnostics,
    fastMode,
    full,
    inlineDecisions: context.diagnostics.inliner,
    loaderUrl: loaderUrlHint || undefined,
    aggressiveCleanup: !fastMode,
    obfuscatedLikely: looksObfuscated(source) || obfuscationHints.hasKnownMarker,
    preferPayloadBranches: true,
    traceInliner: false,
    unpackAliases: payloadAliasHints ? payloadAliasHints.unpackAliases : undefined,
  });

  processedAst = runReadableCleanup(processedAst, context, { fastMode });
  if (!fastMode) {
    processedAst = normalizeRecoveredLoopVariable(processedAst);
  }

  const output = emitVerifiedChunk(processedAst, {
    label: "Generated output",
    debug: options.debug === true,
    normalizeSource: fastMode ? null : normalizePrometheusOutputSource,
    preludeAssignments: [],
  });

  return {
    ast: processedAst,
    diagnostics: context.diagnostics,
    output,
    stages: context.stages,
  };
}

function deobfuscateSource(source, options = {}) {
  return deobfuscateSourceDetailed(source, options).output;
}

module.exports = {
  deobfuscateSource,
  deobfuscateSourceDetailed,
};
