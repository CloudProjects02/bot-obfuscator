function walkAll(node, fn) {
  if (!node || typeof node !== "object") return false;
  if (Array.isArray(node)) {
    let changed = false;
    for (let i = 0; i < node.length; i++) {
      if (fn(node[i], node, i)) { changed = true; i--; }
    }
    for (let i = 0; i < node.length; i++) {
      if (walkAll(node[i], fn)) changed = true;
    }
    return changed;
  }
  let changed = false;
  for (const [k, v] of Object.entries(node)) {
    if (k === "scope") continue;
    if (Array.isArray(v)) {
      for (let i = 0; i < v.length; i++) {
        if (fn(v[i], v, i)) { changed = true; i--; }
      }
      for (let i = 0; i < v.length; i++) {
        if (walkAll(v[i], fn)) changed = true;
      }
    } else if (v && typeof v === "object") {
      if (walkAll(v, fn)) changed = true;
    }
  }
  return changed;
}

function fixEnumDoubleDot(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "MemberExpression" || node.indexer !== ".") return false;
    if (!node.base || node.base.type !== "MemberExpression" || node.base.indexer !== ".") return false;
    if (!node.base.base || node.base.base.type !== "Identifier" || node.base.base.name !== "Enum") return false;
    const mid = node.base.identifier && node.base.identifier.name;
    const last = node.identifier && node.identifier.name;
    if (mid && last && mid === last) {
      parent[key] = node.base;
      return true;
    }
    return false;
  })};
}

function removeTrashWrites(ast) {
  let changed = false;
  for (let iter = 0; iter < 4; iter++) {
    const c = walkAll(ast, (node, parent, key) => {
      if (!node || node.type !== "FunctionDeclaration") return false;
      if (!node.body) return false;
      let removed = false;
      for (let i = node.body.length - 1; i >= 0; i--) {
        const stmt = node.body[i];
        if (!stmt) continue;
        if (stmt.type === "AssignmentStatement" && stmt.variables.length === 1 && stmt.init.length === 1) {
          const target = stmt.variables[0];
          if (target && target.type === "IndexExpression" && target.base && target.base.type === "Identifier" &&
              /^[A-Z]$/.test(target.base.name)) {
            node.body.splice(i, 1);
            removed = true;
          }
        }
        if (stmt.type === "ReturnStatement" && (!stmt.arguments || stmt.arguments.length === 0)) {
          node.body.splice(i, 1);
          removed = true;
        }
      }
      return removed;
    });
    if (!c) break;
    changed = true;
  }
  return { ast, changed };
}

function removeEmptySameNameWrites(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "AssignmentStatement") return false;
    if (node.variables.length !== 1 || node.init.length !== 1) return false;
    const v = node.variables[0];
    const init = node.init[0];
    if (v && v.type === "Identifier" && init && init.type === "Identifier" && v.name === init.name) {
      if (parent && Array.isArray(parent)) {
        parent.splice(key, 1);
        return true;
      }
    }
    return false;
  })};
}

function removeDeadElseGuard(ast) {
  let changed = false;
  for (let iter = 0; iter < 4; iter++) {
    const c = walkAll(ast, (node, parent, key) => {
      if (!node || node.type !== "ElseClause" || !node.body) return false;
      if (node.body.length < 2) return false;
      const lastStmt = node.body[node.body.length - 1];
      if (!lastStmt || lastStmt.type !== "ReturnStatement" || !lastStmt.arguments) return false;
      const retArg = lastStmt.arguments[0];
      if (!retArg || retArg.type !== "CallExpression") return false;
      const base = retArg.base;
      if (!base || base.type !== "Identifier" || base.name !== "O") return false;
      if (parent && Array.isArray(parent)) {
        parent.splice(key, 1);
        return true;
      }
      return false;
    });
    if (!c) break;
    changed = true;
  }
  return { ast, changed };
}

function removeDeadBoolVars(ast) {
  const boolLocalNames = new Set();
  walkAll(ast, (node) => {
    if (!node || node.type !== "LocalStatement") return false;
    if (!node.init) return false;
    for (let i = 0; i < Math.min(node.variables.length, node.init.length); i++) {
      const v = node.variables[i];
      const init = node.init[i];
      if (v && v.type === "Identifier" && init && init.type === "BooleanLiteral") {
        boolLocalNames.add(v.name);
      }
    }
    return false;
  });
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "AssignmentStatement" || node.variables.length !== 1 || node.init.length !== 1) return false;
    const v = node.variables[0];
    const init = node.init[0];
    if (!v || v.type !== "Identifier" || !boolLocalNames.has(v.name)) return false;
    if (init.type !== "BooleanLiteral" && init.type !== "NilLiteral") return false;
    if (parent && Array.isArray(parent)) {
      parent.splice(key, 1);
      return true;
    }
    return false;
  })};
}

function removeVmDispatcherFunctions(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "LocalStatement" || !node.variables || !node.init) return false;
    for (let i = 0; i < Math.min(node.variables.length, node.init.length); i++) {
      const v = node.variables[i];
      const init = node.init[i];
      if (!v || v.type !== "Identifier" || !init || init.type !== "FunctionDeclaration") continue;
      if (!init.body) continue;
      let isVmDispatcher = false;
      for (const stmt of init.body) {
        if (!stmt || typeof stmt !== "object") continue;
        // VM dispatcher: uses _call4 as state variable, contains %, math operations
        if (stmt.type === "CallStatement" && stmt.expression && stmt.expression.type === "CallExpression" &&
            stmt.expression.base && stmt.expression.base.type === "Identifier" &&
            (stmt.expression.base.name === "math.floor" || stmt.expression.base.name === "math.tick" || stmt.expression.base.name === "math.sin")) {
          isVmDispatcher = true; break;
        }
        // Uses _call4 as a number accumulator
        if (stmt.type === "AssignmentStatement" && stmt.variables.length === 1 && stmt.variables[0] &&
            stmt.variables[0].type === "Identifier" && stmt.variables[0].name === "_call4") {
          isVmDispatcher = true; break;
        }
        // return O(table)
        if (stmt.type === "ReturnStatement" && stmt.arguments) {
          for (const arg of stmt.arguments) {
            if (arg && arg.type === "CallExpression" && arg.base && arg.base.type === "Identifier" && arg.base.name === "O") {
              isVmDispatcher = true; break;
            }
          }
        }
      }
      if (isVmDispatcher) {
        if (parent && Array.isArray(parent)) {
          parent.splice(key, 1);
          return true;
        }
      }
    }
    return false;
  })};
}

function removeDeadNumVars(ast) {
  let trackedStringTables = new Set();
  let callName = null;
  // Phase 1: Find which _tableN/_callN variables are used as string table
  walkAll(ast, (node) => {
    if (!node || node.type !== "LocalStatement" || !node.variables || !node.init) return false;
    for (let i = 0; i < Math.min(node.variables.length, node.init.length); i++) {
      const v = node.variables[i];
      const init = node.init[i];
      if (v && v.type === "Identifier") {
        // _callN = setmetatable({}, {__index = _tableN})
        if (/^_call\d+$/.test(v.name) && init && init.type === "CallExpression" &&
            init.base && init.base.type === "Identifier" && init.base.name === "setmetatable" &&
            init.arguments && init.arguments.length >= 2) {
          callName = v.name;
          const mt = init.arguments[1];
          if (mt && mt.type === "TableConstructorExpression" && mt.fields) {
            for (const field of mt.fields) {
              if (field && field.type === "TableKeyString" && field.key && field.key.name === "__index" &&
                  field.value && field.value.type === "Identifier") {
                trackedStringTables.add(field.value.name);
              }
            }
          }
        }
        // Also track direct _tableN = setmetatable({}, ...)
        if (/^_table\d+$/.test(v.name) && init && init.type === "CallExpression" &&
            init.base && init.base.type === "Identifier" && init.base.name === "setmetatable") {
          trackedStringTables.add(v.name);
        }
      }
    }
    return false;
  });

  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "AssignmentStatement" || node.variables.length !== 1 || node.init.length !== 1) return false;
    const v = node.variables[0];
    const init = node.init[0];
    if (!v || v.type !== "Identifier" || !init) return false;
    
    // PRESERVE string table assignments (_table3[key] = "value")
    if (v.name && trackedStringTables.has(v.name)) return false;
    // PRESERVE _tableN = someInstance (string table backing)
    if (v.name && /^_table\d+$/.test(v.name) && trackedStringTables.has(v.name)) return false;
    
    // Only remove math.Function = value
    if (init.type === "MemberExpression" && init.base && init.base.type === "Identifier" && init.base.name === "math" &&
        init.identifier && init.identifier.type === "Identifier") {
      if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
    }
    if (v.name === "_call4" && init.type === "StringLiteral" && init.value === "Instance") {
      if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
    }
    if (v.name === "_call4" && init.type === "NumericLiteral" && (init.value === 0 || init.value === 2)) {
      if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
    }
    return false;
  })};
}

function removeDeadFunctions(ast) {
  const funcNames = new Map();
  const funcUses = new Map();
  walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "LocalStatement" || !node.variables || !node.init) return false;
    for (let i = 0; i < Math.min(node.variables.length, node.init.length); i++) {
      const v = node.variables[i];
      const init = node.init[i];
      if (v && v.type === "Identifier" && init && init.type === "FunctionDeclaration") {
        funcNames.set(v.name, { parent, key, idx: i });
        funcUses.set(v.name, 0);
      }
    }
    return false;
  });
  walkAll(ast, (node) => {
    if (!node || node.type !== "Identifier") return false;
    if (funcUses.has(node.name)) funcUses.set(node.name, funcUses.get(node.name) + 1);
    return false;
  });
  let changed = false;
  for (const [name, info] of funcNames) {
    const uses = funcUses.get(name);
    if (uses <= 1) {
      const decl = info.parent[info.key];
      if (decl && decl.type === "LocalStatement") {
        const idx = decl.variables.indexOf(name);
        if (idx >= 0) {
          if (decl.variables.length === 1) { info.parent.splice(info.key, 1); }
          else { decl.variables.splice(idx, 1); if (decl.init && decl.init.length > idx) decl.init.splice(idx, 1); }
          changed = true;
        }
      }
    }
  }
  return { ast, changed };
}

function removeVmBytecodeBlock(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "LocalStatement" || !node.variables || !node.init) return false;
    for (let i = 0; i < Math.min(node.variables.length, node.init.length); i++) {
      const v = node.variables[i];
      const init = node.init[i];
      if (!v || v.type !== "Identifier" || !init) continue;
      if (!/^_call\d+$/.test(v.name)) continue;
      // VM bytecode: _callN = singleLetterFunc(...)
      if (init.type === "CallExpression" && init.base && init.base.type === "Identifier" &&
          /^[a-z]$/.test(init.base.name)) {
        if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
      }
      // VM bytecode: _callN = singleLetterVar.table
      if (init.type === "MemberExpression" && init.base && init.base.type === "Identifier" &&
          /^[a-z]$/.test(init.base.name)) {
        if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
      }
    }
    return false;
  })};
}

function removeVmStateWrites(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "AssignmentStatement" || node.variables.length !== 1) return false;
    const v = node.variables[0];
    if (!v) return false;
    // B[_callN] = frame — VM state write to single-letter global
    if (v.type === "IndexExpression" && v.base && v.base.type === "Identifier" && /^[A-Z]$/.test(v.base.name)) {
      if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
    }
    // nwN[nwUIStrokeN] = value — VM table write
    if (v.type === "IndexExpression" && v.base && v.base.type === "Identifier" && v.base.name === v.index.name &&
        v.base.name.match(/^nw(\d+)$/)) {
      // Only remove if the base was defined as a UDim within the same block
      if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
    }
    return false;
  })};
}

function fixStringGmatchCorruption(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "AssignmentStatement" || node.variables.length !== 1 || node.init.length !== 1) return false;
    const v = node.variables[0];
    const init = node.init[0];
    if (!v || !init) return false;
    // Detect ANY property assignment where the value is string.gmatch function (VM corruption)
    if (v.type === "MemberExpression" && v.identifier) {
      if (init.type === "MemberExpression" && init.base && init.base.type === "Identifier" && init.base.name === "string" &&
          init.identifier && init.identifier.type === "Identifier" && init.identifier.name === "gmatch") {
        if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
      }
    }
    return false;
  })};
}

function fixLibraryOverwrite(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    // Detect: string.gmatch = Color3Value (VM overwriting Lua library functions)
    if (!node || node.type !== "AssignmentStatement" || node.variables.length !== 1 || node.init.length !== 1) return false;
    const v = node.variables[0];
    const init = node.init[0];
    if (!v || !init) return false;
    if (v.type === "MemberExpression" && v.base && v.base.type === "Identifier" && v.base.name === "string" &&
        v.identifier && v.identifier.type === "Identifier" && init.type === "Identifier" && /^[a-z]/i.test(init.name)) {
      if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
    }
    // Also: math.Function = value (dead overwrite)
    if (v.type === "MemberExpression" && v.base && v.base.type === "Identifier" && v.base.name === "math" &&
        v.identifier && v.identifier.type === "Identifier") {
      if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
    }
    return false;
  })};
}

function removeBrokenReferences(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "AssignmentStatement" || node.variables.length !== 1 || node.init.length !== 1) return false;
    const v = node.variables[0];
    const init = node.init[0];
    if (!v || v.type !== "Identifier" || !init) return false;
    // frame = _call1(_call6 - (1)) - references removed _call6
    if (init.type === "CallExpression" && init.base && init.base.type === "Identifier" &&
        /^_call\d+$/.test(init.base.name)) {
      if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
    }
    return false;
  })};
}

function removeNwIndexWrites(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "AssignmentStatement" || node.variables.length !== 1 || node.init.length !== 1) return false;
    const v = node.variables[0];
    if (!v || v.type !== "IndexExpression") return false;
    // nwN[nwUIStrokeN] = value  (VM state write pattern)
    if (v.base && v.base.type === "Identifier" && v.index && v.index.type === "Identifier" && v.base.name === v.index.name) {
      if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
    }
    return false;
  })};
}

function removeDeadLocalVmFunctions(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "LocalStatement" || !node.variables || !node.init) return false;
    for (let i = 0; i < Math.min(node.variables.length, node.init.length); i++) {
      const v = node.variables[i];
      const init = node.init[i];
      if (!v || v.type !== "Identifier" || !init || init.type !== "FunctionDeclaration") continue;
      // VM function: contains do end (empty)
      if (init.body && init.body.length === 1 && init.body[0].type === "DoStatement" && init.body[0].body && init.body[0].body.length === 0) {
        if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
      }
    }
    return false;
  })};
}

function removeLastVmArtifacts(ast) {
  return { ast, changed: walkAll(ast, (node, parent, key) => {
    if (!node || node.type !== "LocalStatement" || !node.variables || !node.init) return false;
    for (let i = 0; i < Math.min(node.variables.length, node.init.length); i++) {
      const v = node.variables[i];
      const init = node.init[i];
      if (!v || v.type !== "Identifier" || !init) continue;
      const name = v.name;
      // _callN = {table_value} (VM bytecode array wrapping)
      if (/^_call\d+$/.test(name) && init.type === "TableConstructorExpression") {
        if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
      }
      // _callN = tonumber(O(table)) (VM string decoder)
      if (/^_call\d+$/.test(name) && init.type === "CallExpression" && init.base && init.base.type === "Identifier" && init.base.name === "tonumber") {
        if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
      }
      // _tableN = {_callN()} (VM bytecode iteration)
      if (/^_table\d+$/.test(name) && init.type === "TableConstructorExpression") {
        if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
      }
      // PRESERVE _callN = setmetatable({}, {__index = _tableN}) - This is the STRING TABLE
      // Do NOT remove it - resolveStringTable depends on it
      // if (/^_call\d+$/.test(name) && init.type === "CallExpression" && init.base && init.base.type === "Identifier" && init.base.name === "setmetatable") {
      //   if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
      // }
      // stringGmatch1 = Color3.fromRGB(...) (local alias for color)
      if (init.type === "CallExpression" && init.base && init.base.type === "MemberExpression" &&
          init.base.base && init.base.base.type === "Identifier" && init.base.base.name === "Color3") {
        if (parent && Array.isArray(parent)) { parent.splice(key, 1); return true; }
      }
    }
    return false;
  })};
}

function cleanupVmRemnants(ast) {
  let changed = false;
  for (let iter = 0; iter < 8; iter++) {
    let r = fixEnumDoubleDot(ast);
    if (r.changed) changed = true;
    r = removeTrashWrites(ast); if (r.changed) changed = true;
    r = removeEmptySameNameWrites(ast); if (r.changed) changed = true;
    r = removeDeadElseGuard(ast); if (r.changed) changed = true;
    r = removeDeadBoolVars(ast); if (r.changed) changed = true;
    r = removeVmDispatcherFunctions(ast); if (r.changed) changed = true;
    r = removeDeadNumVars(ast); if (r.changed) changed = true;
    r = removeDeadFunctions(ast); if (r.changed) changed = true;
    r = removeVmBytecodeBlock(ast); if (r.changed) changed = true;
    r = removeVmStateWrites(ast); if (r.changed) changed = true;
    r = fixStringGmatchCorruption(ast); if (r.changed) changed = true;
    r = fixLibraryOverwrite(ast); if (r.changed) changed = true;
    r = removeBrokenReferences(ast); if (r.changed) changed = true;
    r = removeNwIndexWrites(ast); if (r.changed) changed = true;
    r = removeDeadLocalVmFunctions(ast); if (r.changed) changed = true;
    r = removeLastVmArtifacts(ast); if (r.changed) changed = true;
    if (!r.changed && iter > 0) break;
  }
  return { ast, changed };
}

module.exports = { cleanupVmRemnants, fixEnumDoubleDot, removeTrashWrites, removeDeadElseGuard };