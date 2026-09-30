const INDENT = "    ";
const LUA_KEYWORDS = new Set([
  "and",
  "break",
  "continue",
  "do",
  "else",
  "elseif",
  "end",
  "false",
  "for",
  "function",
  "goto",
  "if",
  "in",
  "local",
  "nil",
  "not",
  "or",
  "repeat",
  "return",
  "then",
  "true",
  "until",
  "while",
]);

function isValidIdentifier(name) {
  return typeof name === "string" && /^[A-Za-z_][A-Za-z0-9_]*$/.test(name) && !LUA_KEYWORDS.has(name);
}

function escapeString(value) {
  const normalizedValue = decodeUtf8ByteEscapes(value);
  let out = "\"";
  let previousWasNumericEscape = false;
  for (let index = 0; index < normalizedValue.length; index += 1) {
    const code = normalizedValue.charCodeAt(index);
    const char = normalizedValue[index];

    if (char === "\\") {
      out += "\\\\";
      previousWasNumericEscape = false;
      continue;
    }
    if (char === "\"") {
      out += "\\\"";
      previousWasNumericEscape = false;
      continue;
    }
    if (char === "\n") {
      out += "\\n";
      previousWasNumericEscape = false;
      continue;
    }
    if (char === "\r") {
      out += "\\r";
      previousWasNumericEscape = false;
      continue;
    }
    if (char === "\t") {
      out += "\\t";
      previousWasNumericEscape = false;
      continue;
    }
    if (char === "\b") {
      out += "\\b";
      previousWasNumericEscape = false;
      continue;
    }
    if (char === "\f") {
      out += "\\f";
      previousWasNumericEscape = false;
      continue;
    }
    if (previousWasNumericEscape && /[0-9]/.test(char)) {
      out += `\\${String(code).padStart(3, "0")}`;
      previousWasNumericEscape = true;
      continue;
    }
    if (code >= 32 && code <= 126) {
      out += char;
      previousWasNumericEscape = false;
      continue;
    }
    if (code <= 255) {
      out += `\\${String(code).padStart(3, "0")}`;
      previousWasNumericEscape = true;
      continue;
    }

    out += char;
    previousWasNumericEscape = false;
  }
  out += "\"";
  return out;
}

function decodeUtf8ByteEscapes(value) {
  if (typeof value !== "string" || value.length === 0) {
    return value;
  }

  let hasHighByte = false;
  for (let index = 0; index < value.length; index += 1) {
    const code = value.charCodeAt(index);
    if (code > 255) {
      return value;
    }
    if (code >= 128) {
      hasHighByte = true;
    }
  }

  if (!hasHighByte) {
    return value;
  }

  const bytes = Buffer.from(value, "latin1");
  const decoded = bytes.toString("utf8");
  if (decoded.includes("\uFFFD")) {
    return value;
  }

  const roundTrip = Buffer.from(decoded, "utf8");
  if (roundTrip.length !== bytes.length || !roundTrip.equals(bytes)) {
    return value;
  }

  return decoded;
}

function emitIdentifier(node) {
  return node.name;
}

function emitExpression(node) {
  switch (node.type) {
    case "Identifier":
      return emitIdentifier(node);
    case "StringLiteral":
      return node.value === null ? node.raw : escapeString(node.value);
    case "NumericLiteral":
      if (!Number.isFinite(node.value)) return node.raw;
      const numStr = String(node.value);
      // Fix cases like "4e-5" -> "0.00004" and ensure leading zero for ".4" style
      // Also fix "4e+5" -> "400000" (human readable)
      if (/^[0-9.]+e/i.test(numStr)) {
        return node.value < 1e21 && node.value > 1e-10
          ? Number(node.value).toFixed(20).replace(/\.?0+$/, "")
          : numStr;
      }
      return numStr;
    case "BooleanLiteral":
      return node.value ? "true" : "false";
    case "NilLiteral":
      return "nil";
    case "VarargLiteral":
      return "...";
    case "UnaryExpression":
      if (node.operator === "not") {
        return `not ${emitWrappedExpression(node.argument)}`;
      }
      return `${node.operator}${emitWrappedExpression(node.argument)}`;
    case "BinaryExpression":
    case "LogicalExpression":
      return `${emitWrappedExpression(node.left)} ${node.operator} ${emitWrappedExpression(node.right)}`;
    case "IndexExpression":
      return `${emitWrappedExpression(node.base)}[${emitExpression(node.index)}]`;
    case "MemberExpression": {
      const ident = node.identifier ? node.identifier.name : null;
      if (ident && !isValidIdentifier(ident)) {
        return `${emitWrappedExpression(node.base)}[${escapeString(ident)}]`;
      }
      return `${emitWrappedExpression(node.base)}${node.indexer}${emitIdentifier(node.identifier)}`;
    }
    case "CallExpression":
      return `${emitWrappedExpression(node.base)}(${node.arguments.map(emitExpression).join(", ")})`;
    case "TableCallExpression":
      return `${emitWrappedExpression(node.base)} ${emitExpression(node.arguments)}`;
    case "StringCallExpression":
      return `${emitWrappedExpression(node.base)} ${emitExpression(node.argument)}`;
    case "FunctionDeclaration":
      return emitFunctionExpression(node);
    case "IfExpression":
      return `if ${emitExpression(node.condition)} then ${emitExpression(node.trueExpression)} else ${emitExpression(node.falseExpression)}`;
    case "TableConstructorExpression":
      return `{${node.fields.map(emitTableField).join(", ")}}`;
    case "ParenthesisExpression":
      return `(${emitExpression(node.expression)})`;
    default:
      throw new Error(`Unsupported expression node: ${node.type}`);
  }
}

function emitWrappedExpression(node) {
  switch (node.type) {
    case "Identifier":
    case "IndexExpression":
    case "MemberExpression":
    case "CallExpression":
    case "TableCallExpression":
    case "StringCallExpression":
    case "ParenthesisExpression":
      return emitExpression(node);
    case "StringLiteral":
    case "NumericLiteral":
    case "BooleanLiteral":
    case "NilLiteral":
    case "VarargLiteral":
    case "FunctionDeclaration":
    default:
      return `(${emitExpression(node)})`;
  }
}

function emitFunctionExpression(node) {
  const parameters = node.parameters.map((parameter) => emitExpression(parameter)).join(", ");
  const lines = [];
  lines.push(`function(${parameters})`);
  lines.push(...emitBlock(node.body, 1));
  lines.push("end");
  return lines.join("\n");
}

function isValidFunctionDeclarationTarget(node) {
  if (!node || typeof node !== "object") {
    return false;
  }

  if (node.type === "Identifier") {
    return isValidIdentifier(node.name);
  }

  if (node.type === "MemberExpression") {
    return (
      (node.indexer === "." || node.indexer === ":") &&
      isValidFunctionDeclarationTarget(node.base) &&
      node.identifier &&
      isValidIdentifier(node.identifier.name)
    );
  }

  return false;
}

function emitAnonymousFunctionStatement(statement, indentLevel) {
  const indent = INDENT.repeat(indentLevel);
  const parameters = statement.parameters.map((parameter) => emitExpression(parameter)).join(", ");
  const lines = [`${indent}do`, `${indent}${INDENT}local _ = function(${parameters})`];
  lines.push(...emitBlock(statement.body, indentLevel + 2));
  lines.push(`${indent}${INDENT}end`, `${indent}end`);
  return lines;
}

function emitDiscardedExpressionStatement(expression, indentLevel) {
  const indent = INDENT.repeat(indentLevel);

  if (expression && expression.type === "FunctionDeclaration") {
    return emitAnonymousFunctionStatement(expression, indentLevel);
  }

  return [
    `${indent}do`,
    `${indent}${INDENT}local _ = ${emitExpression(expression)}`,
    `${indent}end`,
  ];
}

function emitTableField(field) {
  switch (field.type) {
    case "TableKeyString":
      if (isValidIdentifier(field.key.name)) {
        return `${field.key.name} = ${emitExpression(field.value)}`;
      }
      return `[${escapeString(field.key.name)}] = ${emitExpression(field.value)}`;
    case "TableKey":
      return `[${emitExpression(field.key)}] = ${emitExpression(field.value)}`;
    case "TableValue":
      return emitExpression(field.value);
    default:
      throw new Error(`Unsupported table field: ${field.type}`);
  }
}

function emitAssignmentTargets(variables) {
  return variables.map((variable) => emitExpression(variable)).join(", ");
}

function emitParenSafeStatement(indent, source) {
  if (source.startsWith("(")) {
    return `${indent};${source}`;
  }
  return `${indent}${source}`;
}

function emitBlock(statements, indentLevel) {
  const lines = [];
  for (const statement of statements) {
    lines.push(...emitStatement(statement, indentLevel));
  }
  return lines;
}

function normalizeIfClauses(clauses) {
  if (!Array.isArray(clauses) || clauses.length === 0) {
    return [];
  }

  const normalized = clauses.map((clause) => ({
    ...clause,
    body: Array.isArray(clause.body) ? clause.body : [],
  }));

  if (normalized[0].type === "ElseifClause") {
    normalized[0] = {
      ...normalized[0],
      type: "IfClause",
    };
  }

  return normalized;
}

function emitIfClauses(clauses, indentLevel) {
  const indent = INDENT.repeat(indentLevel);
  const lines = [];

  clauses.forEach((clause) => {
    if (clause.type === "IfClause") {
      const condition = clause.condition ? emitExpression(clause.condition) : "true";
      lines.push(`${indent}if ${condition} then`);
      lines.push(...emitBlock(clause.body, indentLevel + 1));
      return;
    }

    if (clause.type === "ElseifClause") {
      const condition = clause.condition ? emitExpression(clause.condition) : "true";
      lines.push(`${indent}elseif ${condition} then`);
      lines.push(...emitBlock(clause.body, indentLevel + 1));
      return;
    }

    lines.push(`${indent}else`);
    lines.push(...emitBlock(clause.body, indentLevel + 1));
  });

  lines.push(`${indent}end`);
  return lines;
}

function emitStatement(statement, indentLevel = 0) {
  const indent = INDENT.repeat(indentLevel);
  switch (statement.type) {
    case "AssignmentStatement":
      return [
        emitParenSafeStatement(
          indent,
          `${emitAssignmentTargets(statement.variables)} = ${statement.init.map(emitExpression).join(", ")}`,
        ),
      ];
    case "LocalStatement":
      if (!statement.init.length) {
        return [`${indent}local ${statement.variables.map(emitIdentifier).join(", ")}`];
      }
      return [
        `${indent}local ${statement.variables.map(emitIdentifier).join(", ")} = ${statement.init.map(emitExpression).join(", ")}`,
      ];
    case "CallStatement":
      if (
        statement.expression.type !== "CallExpression" &&
        statement.expression.type !== "TableCallExpression" &&
        statement.expression.type !== "StringCallExpression"
      ) {
        return emitDiscardedExpressionStatement(statement.expression, indentLevel);
      }
      return [emitParenSafeStatement(indent, emitExpression(statement.expression))];
    case "ReturnStatement":
      return [`${indent}return ${statement.arguments.map(emitExpression).join(", ")}`.trimEnd()];
    case "IfStatement": {
      const clauses = normalizeIfClauses(statement.clauses || []);
      if (clauses.length === 0) {
        return [];
      }

      if (clauses[0].type === "ElseClause") {
        if (clauses.length === 1) {
          return emitBlock(clauses[0].body, indentLevel);
        }

        const lines = [];
        lines.push(`${indent}do`);
        lines.push(...emitBlock(clauses[0].body, indentLevel + 1));
        lines.push(`${indent}end`);

        const tail = clauses.slice(1);
        if (tail.length > 0 && tail[0].type === "ElseifClause") {
          tail[0] = {
            ...tail[0],
            type: "IfClause",
          };
        }

        if (tail.length > 0 && tail[0].type === "IfClause") {
          lines.push(...emitIfClauses(tail, indentLevel));
        }

        return lines;
      }

      return emitIfClauses(clauses, indentLevel);
    }
    case "WhileStatement": {
      const lines = [`${indent}while ${emitExpression(statement.condition)} do`];
      lines.push(...emitBlock(statement.body, indentLevel + 1));
      lines.push(`${indent}end`);
      return lines;
    }
    case "RepeatStatement": {
      const lines = [`${indent}repeat`];
      lines.push(...emitBlock(statement.body, indentLevel + 1));
      lines.push(`${indent}until ${emitExpression(statement.condition)}`);
      return lines;
    }
    case "DoStatement": {
      const lines = [`${indent}do`];
      lines.push(...emitBlock(statement.body, indentLevel + 1));
      lines.push(`${indent}end`);
      return lines;
    }
    case "ForNumericStatement": {
      const variable = emitIdentifier(statement.variable);
      const start = emitExpression(statement.start);
      const end = emitExpression(statement.end);
      const step = statement.step ? `, ${emitExpression(statement.step)}` : "";
      const lines = [`${indent}for ${variable} = ${start}, ${end}${step} do`];
      lines.push(...emitBlock(statement.body, indentLevel + 1));
      lines.push(`${indent}end`);
      return lines;
    }
    case "ForGenericStatement": {
      const names = statement.variables.map(emitIdentifier).join(", ");
      const iterators = statement.iterators.map(emitExpression).join(", ");
      const lines = [`${indent}for ${names} in ${iterators} do`];
      lines.push(...emitBlock(statement.body, indentLevel + 1));
      lines.push(`${indent}end`);
      return lines;
    }
    case "FunctionDeclaration": {
      const parameters = statement.parameters.map((parameter) => emitExpression(parameter)).join(", ");
      const lines = [];
      if (statement.isLocal) {
        if (
          !statement.identifier ||
          statement.identifier.type !== "Identifier" ||
          !isValidIdentifier(statement.identifier.name)
        ) {
          return emitAnonymousFunctionStatement(statement, indentLevel);
        }
        lines.push(`${indent}local function ${emitIdentifier(statement.identifier)}(${parameters})`);
      } else {
        if (!isValidFunctionDeclarationTarget(statement.identifier)) {
          return emitAnonymousFunctionStatement(statement, indentLevel);
        }
        lines.push(`${indent}function ${emitExpression(statement.identifier)}(${parameters})`);
      }
      lines.push(...emitBlock(statement.body, indentLevel + 1));
      lines.push(`${indent}end`);
      return lines;
    }
    case "BreakStatement":
      return [`${indent}break`];
    case "ContinueStatement":
      return [`${indent}continue`];
    default:
      throw new Error(`Unsupported statement node: ${statement.type}`);
  }
}

function emitChunk(ast) {
  return emitBlock(ast.body, 0).join("\n").replace(/\n{3,}/g, "\n\n") + "\n";
}

module.exports = {
  emitChunk,
  emitExpression,
};
