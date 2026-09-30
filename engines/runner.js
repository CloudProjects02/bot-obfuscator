'use strict';

/**
 * Unified engine runner — each engine gets a standardized
 * spawn interface: run(inputPath, outputPath) → Promise<{ ok, output, elapsed }>
 *
 * Engine types:
 *   luraph        — deob.js (Node) — Luraph v14/v15 + generic trace
 *   node_script   — arbitrary .js entry that takes (input, output) as argv[2/3]
 *   moonsec_js    — moonsec -dis pipeline (JS → bytecode disasm)
 *   moonsec_cs    — MoonsecDeobfuscator.exe -dev → .luac → unluac.jar → .lua
 *   77fuscator    — deobfuscator.exe → .luac → unluac.jar → .lua
 *   prometheus_wad— Python deobfuscator.py → writes to cwd/out.lua
 *   exe_direct    — exe that takes (input -o output) directly (IronBrew2)
 */

const fs     = require('fs');
const path   = require('path');
const { spawn, execFile } = require('child_process');
const os     = require('os');

const ROOT      = path.join(__dirname, '..');
const ENG_DIR   = __dirname;
const SHARED    = path.join(ENG_DIR, 'shared');
const UNLUAC    = path.join(SHARED, 'unluac.jar');

const TIMEOUT_MS = 120_000; // 2 min per engine

// ─── Helpers ─────────────────────────────────────────────────────────────────

function spawnAsync(cmd, args, opts = {}) {
  const limitMs = opts.timeout ?? TIMEOUT_MS;
  return new Promise((resolve) => {
    let out = '', err = '', settled = false;
    const done = (val) => { if (!settled) { settled = true; clearTimeout(timer); resolve(val); } };
    const proc  = spawn(cmd, args, { ...opts, windowsHide: true });
    const timer = setTimeout(() => { try { proc.kill('SIGKILL'); } catch {} done({ code: -1, out, err: `Engine timed out after ${limitMs / 1000}s` }); }, limitMs);
    proc.stdout?.on('data', d => (out += d));
    proc.stderr?.on('data', d => (err += d));
    proc.on('close', code => done({ code, out, err }));
    proc.on('error', e    => done({ code: -1, out, err: err + e.message }));
  });
}

function execAsync(cmd, args, opts = {}) {
  return new Promise((resolve) => {
    execFile(cmd, args, { timeout: TIMEOUT_MS, maxBuffer: 50 * 1024 * 1024, ...opts }, (err, stdout, stderr) => {
      resolve({ code: err?.code ?? 0, out: stdout || '', err: stderr || (err?.message ?? '') });
    });
  });
}

// unluac: decompile .luac → .lua using Java
async function unluacDecompile(luacPath, outPath) {
  if (!fs.existsSync(UNLUAC)) return { ok: false, err: 'unluac.jar not found' };
  const res = await execAsync('java', ['-jar', UNLUAC, luacPath]);
  if (res.out && res.out.trim()) {
    fs.writeFileSync(outPath, res.out, 'utf8');
    return { ok: true };
  }
  return { ok: false, err: res.err || 'unluac produced no output' };
}

// ─── Engine definitions ───────────────────────────────────────────────────────

const REGISTRY = {

  // ── Luraph v15 / v14 / generic (original deob.js) ─────────────────────────
  luraph_v15: {
    label: 'Luraph v15',
    async run(inputPath, outputPath) {
      const deobJs = path.join(ROOT, 'deob.js');
      const t0 = Date.now();
      const res = await spawnAsync(process.execPath, [deobJs, inputPath, '-o', outputPath], { cwd: ROOT });
      return result(outputPath, t0, res.err);
    },
  },

  luraph_v14: {
    label: 'Luraph v14.x',
    async run(inputPath, outputPath) {
      const deobJs = path.join(ROOT, 'deob.js');
      const t0 = Date.now();
      const res = await spawnAsync(process.execPath, [deobJs, inputPath, '-o', outputPath], {
        cwd: ROOT,
        env: { ...process.env, DEOB_ENGINE: 'v14' },
      });
      return result(outputPath, t0, res.err);
    },
  },

  generic: {
    label: 'Generic Trace',
    async run(inputPath, outputPath) {
      const deobJs = path.join(ROOT, 'deob.js');
      const t0 = Date.now();
      const res = await spawnAsync(process.execPath, [deobJs, inputPath, '-o', outputPath, '--no-devirt'], { cwd: ROOT });
      return result(outputPath, t0, res.err);
    },
  },

  // ── MoonSec JS (Node) → dis(assembly) = readable Lua ─────────────────────
  moonsec_js: {
    label: 'MoonSec (JS)',
    async run(inputPath, outputPath) {
      const entry = path.join(ENG_DIR, 'moonsec', 'bin', 'moonsec.js');
      const t0 = Date.now();
      // -dis mode: decompile bytecode → disassembly text (closest to source)
      const res = await spawnAsync(process.execPath, [entry, '-dis', '-i', inputPath, '-o', outputPath], {
        cwd: path.join(ENG_DIR, 'moonsec'),
      });
      return result(outputPath, t0, res.err);
    },
  },

  // ── MoonSec .NET → .luac → unluac.jar → .lua ─────────────────────────────
  moonsec_cs: {
    label: 'MoonSec V3 (.NET)',
    async run(inputPath, outputPath) {
      const exe = path.join(ENG_DIR, 'moonsec-dotnet', 'MoonsecDeobfuscator', 'MoonsecDeobfuscator.exe');
      const tmpLuac = outputPath + '.tmp.luac';
      const t0 = Date.now();
      // Step 1: Deobfuscate → bytecode
      await execAsync(exe, ['-dev', '-i', inputPath, '-o', tmpLuac]);
      if (!fs.existsSync(tmpLuac)) {
        return { ok: false, output: null, elapsed: elapsed(t0), err: 'MoonsecDeobfuscator produced no bytecode' };
      }
      // Step 2: Decompile bytecode → Lua source
      const decomp = await unluacDecompile(tmpLuac, outputPath);
      try { fs.unlinkSync(tmpLuac); } catch {}
      if (!decomp.ok) return { ok: false, output: null, elapsed: elapsed(t0), err: decomp.err };
      return result(outputPath, t0, '');
    },
  },

  // ── 77fuscator .NET → .luac → unluac.jar → .lua ──────────────────────────
  '77fuscator': {
    label: '77fuscator (.NET)',
    async run(inputPath, outputPath) {
      const exe = path.join(ENG_DIR, '77fuscator', 'bin', 'deobfuscator.exe');
      const tmpLuac = outputPath + '.tmp.luac';
      const t0 = Date.now();
      // Step 1: Peel layers → bytecode
      await execAsync(exe, [inputPath, '-o', tmpLuac]);
      if (!fs.existsSync(tmpLuac)) {
        return { ok: false, output: null, elapsed: elapsed(t0), err: '77fuscator produced no bytecode' };
      }
      // Step 2: Decompile
      const decomp = await unluacDecompile(tmpLuac, outputPath);
      try { fs.unlinkSync(tmpLuac); } catch {}
      if (!decomp.ok) return { ok: false, output: null, elapsed: elapsed(t0), err: decomp.err };
      return result(outputPath, t0, '');
    },
  },

  // ── Prometheus JS ─────────────────────────────────────────────────────────
  prometheus_js: {
    label: 'Prometheus (JS)',
    async run(inputPath, outputPath) {
      const entry = path.join(ENG_DIR, 'prometheus', 'main.js');
      const t0 = Date.now();
      // main.js argv[2]=input argv[3]=output
      const res = await spawnAsync(process.execPath, ['--experimental-vm-modules', entry, inputPath, outputPath], {
        cwd: path.join(ENG_DIR, 'prometheus'),
        env: { ...process.env, NODE_PATH: path.join(ROOT, 'node_modules') },
      });
      return result(outputPath, t0, res.err);
    },
  },

  // ── Prometheus WeAre Devs (Python + Lua 5.1) ─────────────────────────────
  prometheus_wad: {
    label: 'Prometheus WeAre Devs',
    async run(inputPath, outputPath) {
      const script = path.join(ENG_DIR, 'prometheus-wad', 'deobfuscator.py');
      const cwd    = path.join(ENG_DIR, 'prometheus-wad');
      const t0 = Date.now();
      // Copy input to cwd so Lua 5.1 exe can find it with relative paths
      const tmpIn = path.join(cwd, '_bot_input.lua');
      fs.copyFileSync(inputPath, tmpIn);
      const python = process.platform === 'win32' ? 'python' : 'python3';
      const res = await spawnAsync(python, [script, tmpIn, outputPath], { cwd });
      try { fs.unlinkSync(tmpIn); } catch {}
      return result(outputPath, t0, res.err || res.out);
    },
  },

  // ── IronBrew2 (.NET exe) ──────────────────────────────────────────────────
  ironbrew2: {
    label: 'IronBrew2 (.NET)',
    async run(inputPath, outputPath) {
      const exe = path.join(ENG_DIR, 'ironbrew2', 'ib2deobf', 'LuaAnalysis.Ironbrew2.exe');
      const t0 = Date.now();
      const res = await execAsync(exe, [inputPath, '-o', outputPath]);
      return result(outputPath, t0, res.err);
    },
  },

  // ── Aspect Dumper (Lune / Luau runtime) ──────────────────────────────────
  aspect_dumper: {
    label: 'Aspect Dumper',
    async run(inputPath, outputPath) {
      const cwd      = path.join(ENG_DIR, 'aspect-dumper', 'aspect');
      const luneExe  = path.join(cwd, 'lune.exe');
      const script   = path.join(cwd, '4sp3ct.luau');
      const fixedIn  = path.join(cwd, 'core', 'io', 'obfuscated.lua');
      const fixedOut = path.join(cwd, 'core', 'io', 'dumped_output.lua');
      const t0 = Date.now();
      fs.copyFileSync(inputPath, fixedIn);
      const res = await spawnAsync(luneExe, ['run', script], { cwd });
      if (fs.existsSync(fixedOut) && fs.statSync(fixedOut).size > 0) {
        fs.copyFileSync(fixedOut, outputPath);
      }
      return result(outputPath, t0, res.err || res.out);
    },
  },

  // ── 6Vms Environment Logger (Lune) ───────────────────────────────────────
  '6vms_logger': {
    label: '6Vms Logger',
    async run(inputPath, outputPath) {
      const cwd     = path.join(ENG_DIR, '6vms-main');
      const luneExe = path.join(cwd, 'lune.exe');
      const script  = path.join(cwd, 'main.luau');
      const t0 = Date.now();
      const res = await spawnAsync(luneExe, ['run', script, `ipt=${inputPath}`, `out=${outputPath}`], { cwd });
      return result(outputPath, t0, res.err || res.out);
    },
  },

  // ── 6Vms Static Deobfuscator (Lune / AST-based) ──────────────────────────
  '6vms_static': {
    label: '6Vms Static',
    async run(inputPath, outputPath) {
      const cwd     = path.join(ENG_DIR, '6vms-main', '6vms');
      const luneExe = path.join(ENG_DIR, '6vms-main', 'lune.exe');
      const script  = path.join(cwd, 'main.luau');
      const t0 = Date.now();
      const res = await spawnAsync(luneExe, ['run', script, inputPath, `out=${outputPath}`], { cwd });
      return result(outputPath, t0, res.err || res.out);
    },
  },

  // ── Threaded / Unveilr v3 (Lune) ─────────────────────────────────────────
  threaded: {
    label: 'Threaded (Unveilr v3)',
    async run(inputPath, outputPath) {
      const cwd     = path.join(ENG_DIR, '6vms-main', 'Threaded');
      const luneExe = path.join(cwd, 'lune.exe');
      const script  = path.join(cwd, 'main.luau');
      const t0 = Date.now();
      const res = await spawnAsync(luneExe, ['run', script, `ipt=${inputPath}`, `out=${outputPath}`], { cwd });
      return result(outputPath, t0, res.err || res.out);
    },
  },

  // ── LPH Devirtualizer v8 (Python) ────────────────────────────────────────
  lph_deobf: {
    label: 'LPH Devirtualizer v8',
    async run(inputPath, outputPath) {
      const script = path.join(ENG_DIR, '6vms-main', 'deobfuscator.py');
      const python = process.platform === 'win32' ? 'python' : 'python3';
      const t0 = Date.now();
      const res = await spawnAsync(python, [script, inputPath, '-o', outputPath], {
        cwd: path.join(ENG_DIR, '6vms-main'),
      });
      return result(outputPath, t0, res.err || res.out);
    },
  },

  // ── MoonSec V3 Python Deobfuscator ───────────────────────────────────────
  moonsec_py: {
    label: 'MoonSec V3 (Python)',
    async run(inputPath, outputPath) {
      const script = path.join(ENG_DIR, '6vms-main', 'MoonDeobf', 'cli.py');
      const python = process.platform === 'win32' ? 'python' : 'python3';
      const t0 = Date.now();
      const res = await spawnAsync(python, [script, inputPath, '-o', outputPath], {
        cwd: path.join(ENG_DIR, '6vms-main', 'MoonDeobf'),
      });
      return result(outputPath, t0, res.err || res.out);
    },
  },

  // ── Prometheus v2 / PromDeobf (Node.js) ──────────────────────────────────
  prometheus_v2: {
    label: 'Prometheus v2 (PromDeobf)',
    async run(inputPath, outputPath) {
      const entry = path.join(ENG_DIR, '6vms-main', 'PromDeobf', 'main.js');
      const t0 = Date.now();
      const res = await spawnAsync(process.execPath, [entry, inputPath, outputPath], {
        cwd: path.join(ENG_DIR, '6vms-main', 'PromDeobf'),
        env: { ...process.env, NODE_PATH: path.join(ENG_DIR, '6vms-main', 'PromDeobf', 'node_modules') },
      });
      return result(outputPath, t0, res.err || res.out);
    },
  },

  // ── Cracker2 v16 Full Static Analysis Pipeline (Python) ──────────────────
  cracker2: {
    label: 'Cracker2 v16',
    async run(inputPath, outputPath) {
      const script  = path.join(ENG_DIR, 'cracker2', 'main.py');
      const outDir  = outputPath + '_cracker2_out';
      const python  = process.platform === 'win32' ? 'python' : 'python3';
      const t0 = Date.now();
      fs.mkdirSync(outDir, { recursive: true });
      const res = await spawnAsync(python, [script, inputPath, '-o', outDir, '--deobfuscate'], {
        cwd: path.join(ENG_DIR, 'cracker2'),
      });
      const deobfOut = path.join(outDir, 'deobfuscated.lua');
      if (fs.existsSync(deobfOut) && fs.statSync(deobfOut).size > 0) {
        fs.copyFileSync(deobfOut, outputPath);
        try { fs.rmSync(outDir, { recursive: true, force: true }); } catch {}
      }
      return result(outputPath, t0, res.err || res.out);
    },
  },

  // ── IronbrewDeobfuscator .NET (v2 — KeraLua/NLua) → .luac → unluac ──────
  ironbrew_new: {
    label: 'IronBrew2 (New)',
    async run(inputPath, outputPath) {
      const exe     = path.join(ENG_DIR, 'ironbrew-new', 'IronbrewDeobfuscator.exe');
      const tmpLuac = outputPath + '.tmp.luac';
      const t0 = Date.now();
      await execAsync(exe, ['-t', 'ib2', '-f', inputPath, '-o', tmpLuac]);
      if (!fs.existsSync(tmpLuac)) {
        return { ok: false, output: null, elapsed: elapsed(t0), err: 'IronbrewDeobfuscator produced no bytecode' };
      }
      const decomp = await unluacDecompile(tmpLuac, outputPath);
      try { fs.unlinkSync(tmpLuac); } catch {}
      if (!decomp.ok) return { ok: false, output: null, elapsed: elapsed(t0), err: decomp.err };
      return result(outputPath, t0, '');
    },
  },

  // ── Luraph v17 Static Decoder (Python) ───────────────────────────────────
  luraph_v17: {
    label: 'Luraph v17',
    async run(inputPath, outputPath) {
      const script = path.join(ENG_DIR, 'luraph-v17', 'deobf.py');
      const python = process.platform === 'win32' ? 'python' : 'python3';
      const t0 = Date.now();
      // deobf.py writes <stem>_decoded.lua alongside the input; stage in tmp
      const tmpIn   = outputPath + '_lrv17_input.lua';
      const tmpOut  = outputPath + '_lrv17_input_decoded.lua';
      fs.copyFileSync(inputPath, tmpIn);
      const res = await spawnAsync(python, [script, tmpIn], { cwd: path.join(ENG_DIR, 'luraph-v17') });
      if (fs.existsSync(tmpOut) && fs.statSync(tmpOut).size > 0) {
        fs.copyFileSync(tmpOut, outputPath);
      }
      try { fs.unlinkSync(tmpIn); } catch {}
      try { if (fs.existsSync(tmpOut)) fs.unlinkSync(tmpOut); } catch {}
      return result(outputPath, t0, res.err || res.out);
    },
  },

  // ── Moonveil Decompiler (Python + luau.exe) ───────────────────────────────
  moonveil: {
    label: 'Moonveil Decompiler',
    async run(inputPath, outputPath) {
      const script = path.join(ENG_DIR, 'moonveil', 'moonveil_decompile.py');
      const python = process.platform === 'win32' ? 'python' : 'python3';
      const t0 = Date.now();
      const res = await spawnAsync(python, [script, inputPath, outputPath], {
        cwd: path.join(ENG_DIR, 'moonveil'),
        env: { ...process.env, MOONVEIL_LUAU: path.join(ENG_DIR, 'moonveil', 'luau.exe') },
      });
      return result(outputPath, t0, res.err || res.out);
    },
  },

};

// ─── Shared result builder ────────────────────────────────────────────────────

function elapsed(t0) { return ((Date.now() - t0) / 1000).toFixed(1); }

function result(outputPath, t0, errText) {
  const ok = fs.existsSync(outputPath) && fs.statSync(outputPath).size > 0;
  return {
    ok,
    output: ok ? outputPath : null,
    elapsed: elapsed(t0),
    err: ok ? null : (errText || 'No output produced'),
  };
}

// ─── Public API ──────────────────────────────────────────────────────────────

/**
 * Run deobfuscation for a given engineId.
 * @param {string} engineId  key from REGISTRY
 * @param {string} inputPath  absolute path to input .lua file
 * @param {string} outputPath  absolute path where output should be written
 * @returns {Promise<{ok, output, elapsed, err}>}
 */
async function runEngine(engineId, inputPath, outputPath) {
  const eng = REGISTRY[engineId];
  if (!eng) return { ok: false, output: null, elapsed: '0', err: `Unknown engine: ${engineId}` };
  return eng.run(inputPath, outputPath);
}

function getEngine(id) { return REGISTRY[id] || null; }
function listEngines() { return Object.entries(REGISTRY).map(([id, e]) => ({ id, label: e.label })); }

module.exports = { runEngine, getEngine, listEngines, REGISTRY };
