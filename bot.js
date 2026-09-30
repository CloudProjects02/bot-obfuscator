'use strict';

require('dotenv').config();

const {
  Client,
  GatewayIntentBits,
  REST,
  Routes,
  SlashCommandBuilder,
  AttachmentBuilder,
  PermissionFlagsBits,
} = require('discord.js');

const fs      = require('fs');
const path    = require('path');
const os      = require('os');
const https   = require('https');
const http    = require('http');
const { runEngine, listEngines } = require('./engines/runner');
const { detectObfuscator }       = require('./lib/detector');
const { detect: luraphDetect }   = require('./src/detect');

// ─── Config ──────────────────────────────────────────────────────────────────

const TOKEN     = process.env.DISCORD_TOKEN;
const CLIENT_ID = process.env.DISCORD_CLIENT_ID;
const GUILD_ID  = process.env.GUILD_ID || '1531394302956011603';

// Role ID that represents "has server tag / is verified member"
// Set MEMBER_ROLE_ID in .env — if blank, tag check is skipped for all
const MEMBER_ROLE_ID = process.env.MEMBER_ROLE_ID || '';

const ALLOWED_CHANNEL_ID = '1531399709246357594';

const LIMIT_REGULAR = 6;
const LIMIT_BOOSTER = 20;
const CV2_FLAG      = 1 << 15; // MessageFlags.IsComponentsV2

if (!TOKEN || !CLIENT_ID) {
  console.error('[!] Set DISCORD_TOKEN and DISCORD_CLIENT_ID in your .env file');
  process.exit(1);
}

// ─── Engine definitions ───────────────────────────────────────────────────────
// style 1 = Primary (blurple), 2 = Secondary (grey), 3 = Success (green)

const ALL_ENGINES = [
  // ── Luraph family ────────────────────────────────────────────────────────
  { id: 'luraph_v15',      label: 'Luraph v15',            style: 1 },
  { id: 'luraph_v14',      label: 'Luraph v14.x',          style: 2 },
  { id: 'luraph_v17',      label: 'Luraph v17',            style: 2 },
  { id: 'lph_deobf',       label: 'LPH Devirt v8',         style: 2 },
  // ── MoonSec family ───────────────────────────────────────────────────────
  { id: 'moonsec_cs',      label: 'MoonSec V3 (.NET)',     style: 2 },
  { id: 'moonsec_js',      label: 'MoonSec (JS)',          style: 2 },
  { id: 'moonsec_py',      label: 'MoonSec (Python)',      style: 2 },
  // ── Prometheus family ────────────────────────────────────────────────────
  { id: 'prometheus_js',   label: 'Prometheus',            style: 2 },
  { id: 'prometheus_v2',   label: 'Prometheus v2',         style: 2 },
  { id: 'prometheus_wad',  label: 'Prometheus WAD',        style: 2 },
  // ── IronBrew family ──────────────────────────────────────────────────────
  { id: 'ironbrew2',       label: 'IronBrew2',             style: 2 },
  { id: 'ironbrew_new',    label: 'IronBrew2 (New)',       style: 2 },
  // ── 6Vms / Lune loggers ──────────────────────────────────────────────────
  { id: '6vms_logger',     label: '6Vms Logger',           style: 2 },
  { id: '6vms_static',     label: '6Vms Static',           style: 2 },
  { id: 'threaded',        label: 'Threaded (Unveilr v3)', style: 2 },
  // ── Other engines ────────────────────────────────────────────────────────
  { id: '77fuscator',      label: '77fuscator',            style: 2 },
  { id: 'aspect_dumper',   label: 'Aspect Dumper',         style: 2 },
  { id: 'cracker2',        label: 'Cracker2 v16',          style: 2 },
  { id: 'moonveil',        label: 'Moonveil',              style: 2 },
  { id: 'generic',         label: 'Generic Trace',         style: 2 },
];

// Short description for each engine (used in /engines)
const ENGINE_DESC = {
  luraph_v15:     'Luraph v15 — current default Luraph VM',
  luraph_v14:     'Luraph v14.x — older VM, runs via env logger at runtime',
  luraph_v17:     'Luraph v17 — newer experimental variant',
  lph_deobf:      'LPH Devirt v8 — LPH obfuscator variant',
  moonsec_cs:     'MoonSec V3 — .NET devirtualizer (recommended for V3)',
  moonsec_js:     'MoonSec — JavaScript port fallback',
  moonsec_py:     'MoonSec — Python port fallback',
  prometheus_js:  'Prometheus — standard JS deobfuscator',
  prometheus_v2:  'Prometheus v2 — newer variant',
  prometheus_wad: 'Prometheus WAD — WAD payload variant',
  ironbrew2:      'IronBrew2 — classic IB2 devirt',
  ironbrew_new:   'IronBrew2 (New) — updated .NET binary',
  '6vms_logger':  '6Vms Logger — runtime environment trace',
  '6vms_static':  '6Vms Static — static analysis pass',
  threaded:       'Threaded (Unveilr v3) — multi-thread VM tracer',
  '77fuscator':   '77fuscator — 77 custom VM deobfuscator',
  aspect_dumper:  'Aspect Dumper — Aspect VM logger',
  cracker2:       'Cracker2 v16 — Python static analysis pipeline',
  moonveil:       'Moonveil — MoonVeil 2.x decompiler',
  generic:        'Generic Trace — fallback environment logger',
};

// Map detected obfuscator type → recommended engine id
const DETECT_MAP = {
  luraph:     'luraph_v15',
  moonsec:    'moonsec_cs',
  prometheus: 'prometheus_js',
  ironbrew:   'ironbrew2',
  '77fus':    '77fuscator',
  aspect:     'aspect_dumper',
  moonveil:   'moonveil',
  lph:        'lph_deobf',
  unknown:    'generic',
  generic_lua:'generic',
};

function engineForDetection(source) {
  // Combine both detectors for best coverage
  const libResult   = detectObfuscator(source);   // moonveilvro lib/detector.js
  const luraphResult = (() => {
    try { const r = luraphDetect(source); return r.plugin.name; } catch { return 'generic'; }
  })();

  // Luraph-specific detector takes priority if confident
  if (luraphResult === 'luraph_v15') return { id: 'luraph_v15', label: 'Luraph v15', confidence: 95 };
  if (luraphResult === 'luraph_v14') return { id: 'luraph_v14', label: 'Luraph v14.x', confidence: 95 };

  const mapped = DETECT_MAP[libResult.type] || 'generic';
  return { id: mapped, label: libResult.name || 'Unknown', confidence: libResult.confidence || 10 };
}

// Build the sorted engine button list for a given recommended engine
function buildEngineList(recommendedId) {
  const rec   = ALL_ENGINES.find(e => e.id === recommendedId);
  const rest  = ALL_ENGINES.filter(e => e.id !== recommendedId);
  return [
    { ...rec,  style: 1 },   // recommended = blurple
    ...rest.map(e => ({ ...e, style: 2 })),
  ].filter(Boolean);
}

// ─── In-memory pending jobs ───────────────────────────────────────────────────
// jobId -> { inputPath, tmpDir, filename, userId, expire }
const pendingJobs = new Map();

// resultId -> { content, filename, expire }  (30-min TTL)
const resultCache = new Map();

// ─── Deob queue ───────────────────────────────────────────────────────────────
// Regular users queue; boosters/admins bypass entirely (separate activeDeobs counter)
const deobQueue  = []; // { interaction, job, engineId, filename, engineLabel }
let   activeDeobs = 0;

function buildQueueMsg(filename, engineLabel, position, total) {
  const bar = '█'.repeat(Math.max(0, 10 - Math.round((position / total) * 10))) +
              '░'.repeat(Math.round((position / total) * 10));
  return {
    flags: CV2_FLAG,
    components: [{ type: 17, accent_color: 0xFEE75C, components: [{
      type: 10,
      content: [
        `## <a:loading:1536769812187840633> Queued for Deobfuscation`,
        `**File:** \`${filename}\`  |  **Engine:** ${engineLabel}`,
        `**Position: ${position}/${total}** in queue`,
        `\`${bar}\``,
        ``,
        `> Get the **Booster** role to skip the queue instantly!`,
      ].join('\n'),
    }]}],
  };
}

async function updateQueuePositions() {
  const total = deobQueue.length + activeDeobs;
  for (let i = 0; i < deobQueue.length; i++) {
    const item = deobQueue[i];
    try { await item.interaction.editReply(buildQueueMsg(item.filename, item.engineLabel, i + 1, total)); } catch {}
  }
}

async function processQueue() {
  if (deobQueue.length === 0 || activeDeobs >= 1) return;
  const next = deobQueue.shift();
  activeDeobs++;
  updateQueuePositions().catch(() => {});
  try {
    await executeDeob(next.interaction, next.job, next.engineId);
  } finally {
    activeDeobs--;
    processQueue().catch(() => {});
  }
}

async function enqueueDeob(interaction, job, engineId, member) {
  const admin = isAdmin(member);
  const boost = isBooster(member);
  const skip  = admin || boost || activeDeobs === 0;

  if (skip) {
    activeDeobs++;
    try { await executeDeob(interaction, job, engineId); }
    finally { activeDeobs--; processQueue().catch(() => {}); }
    return;
  }

  // Regular user — add to queue
  const engine = ALL_ENGINES.find(e => e.id === engineId) || ALL_ENGINES[0];
  deobQueue.push({ interaction, job, engineId, filename: job.filename, engineLabel: engine.label });
  await interaction.editReply(buildQueueMsg(job.filename, engine.label, deobQueue.length, deobQueue.length + activeDeobs));
}

function cleanExpiredJobs() {
  const now = Date.now();
  for (const [id, job] of pendingJobs) {
    if (now > job.expire) {
      try { fs.rmSync(job.tmpDir, { recursive: true }); } catch {}
      pendingJobs.delete(id);
    }
  }
  for (const [id, r] of resultCache) {
    if (now > r.expire) resultCache.delete(id);
  }
}
setInterval(cleanExpiredJobs, 60_000);

function makeJobId(userId) {
  return `${userId}_${Date.now()}`;
}

// ─── Rate limiting ────────────────────────────────────────────────────────────

const DATA_DIR   = path.join(__dirname, 'data');
const USAGE_FILE = path.join(DATA_DIR, 'usage.json');

function loadUsage() {
  try { return JSON.parse(fs.readFileSync(USAGE_FILE, 'utf8')); }
  catch { return {}; }
}

function saveUsage(data) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  fs.writeFileSync(USAGE_FILE, JSON.stringify(data, null, 2));
}

// Returns { allowed, remaining, resetIn (hours), limit }
function checkAndConsumeLimit(userId, isBooster, isAdmin, consume = false) {
  if (isAdmin) return { allowed: true, remaining: Infinity, limit: Infinity };

  const limit = isBooster ? LIMIT_BOOSTER : LIMIT_REGULAR;
  const usage = loadUsage();
  const now   = Date.now();
  const entry = usage[userId];

  let count   = 0;
  let resetAt = now + 24 * 3600 * 1000;

  if (entry && now < entry.resetAt) {
    count   = entry.count;
    resetAt = entry.resetAt;
  }

  if (count >= limit) {
    const resetIn = Math.ceil((resetAt - now) / 3600_000);
    return { allowed: false, remaining: 0, resetIn, limit };
  }

  if (consume) {
    usage[userId] = { count: count + 1, resetAt };
    saveUsage(usage);
  }

  return { allowed: true, remaining: limit - count - (consume ? 1 : 0), limit };
}

// ─── Stats ────────────────────────────────────────────────────────────────────

const STATS_FILE = path.join(DATA_DIR, 'stats.json');

function loadStats() {
  try { return JSON.parse(fs.readFileSync(STATS_FILE, 'utf8')); }
  catch { return { total_deobs: 0, total_dumps: 0, total_detects: 0, engine_counts: {} }; }
}

function recordStat(type, engineId = null) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  const s = loadStats();
  if (type === 'deob')   { s.total_deobs++;   if (engineId) s.engine_counts[engineId] = (s.engine_counts[engineId] || 0) + 1; }
  if (type === 'dump')   s.total_dumps++;
  if (type === 'detect') s.total_detects++;
  fs.writeFileSync(STATS_FILE, JSON.stringify(s, null, 2));
}

// ─── Steganographic watermark ─────────────────────────────────────────────────
// Encodes a string as zero-width Unicode characters (invisible in all renderers)
// U+200B = bit 0, U+200C = bit 1, U+200D = char boundary

const WM_TEXT = 'discord.gg/leaking';

function encodeWatermark(text) {
  return text.split('').map(ch => {
    const bits = ch.charCodeAt(0).toString(2).padStart(8, '0');
    return bits.split('').map(b => b === '0' ? '​' : '‌').join('') + '‍';
  }).join('');
}

const WATERMARK_ENCODED = encodeWatermark(WM_TEXT);

function injectWatermark(code) {
  // Inject invisibly at end of our header comment — safe inside Lua comments
  return code.replace(
    /^(-- Deobfuscated by discord\.gg\/leaking)/m,
    `$1${WATERMARK_ENCODED}`
  );
}

// ─── Permission helpers ───────────────────────────────────────────────────────

function isAdmin(member) {
  return member.permissions.has(PermissionFlagsBits.Administrator);
}

function isBooster(member) {
  return !!member.premiumSince;
}

// Returns true if user has the member role (server tag) OR is booster OR is admin
function hasServerTag(member) {
  if (isAdmin(member) || isBooster(member)) return true;
  if (!MEMBER_ROLE_ID) return true; // tag check disabled
  return member.roles.cache.has(MEMBER_ROLE_ID);
}

// ─── Blocklist ───────────────────────────────────────────────────────────────

const BLOCKED_DOMAINS = ['discord.gg', 'discord.com/invite'];
const WEB_PORTS       = new Set([80, 443, 8080, 8443, 3000, 3001, 4000, 5000]);

function checkBlocklist(content) {
  const urls    = content.match(/https?:\/\/[^\s"')\]>]+/g) || [];
  const results = [];
  const seen    = new Set();
  for (const url of urls) {
    if (seen.has(url)) continue;
    seen.add(url);
    const dom = BLOCKED_DOMAINS.find(d => url.includes(d));
    if (dom) { results.push({ url, reason: `\`${dom}\` is on the blocklist` }); continue; }
    const pm  = url.match(/:(\d+)(?:\/|$)/);
    if (pm && !WEB_PORTS.has(parseInt(pm[1], 10))) {
      results.push({ url, reason: `port ${pm[1]} is not a web port, so it is not fetched` });
    }
  }
  return results;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function formatSize(bytes) {
  if (bytes < 1024)           return `${bytes}B`;
  if (bytes < 1024 * 1024)   return `${(bytes / 1024).toFixed(1)}KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)}MB`;
}

const ROBLOX_SERVICES = [
  'Players','ReplicatedStorage','MarketplaceService','ServerStorage','DataModules',
  'DataHandler','TweenService','UserInputService','RunService','Workspace',
  'ServerScriptService','StarterGui','StarterPack','Teams','SoundService',
  'Lighting','PathfindingService','HttpService','TextService','VirtualInputManager',
];

function extractStrings(content) {
  return ROBLOX_SERVICES.filter(s =>
    content.includes(`"${s}"`) || content.includes(`'${s}'`) ||
    content.includes(`:GetService("${s}")`)
  );
}

function extractUrlsTouched(content) {
  return [...new Set(content.match(/https?:\/\/[^\s"')\]>]+/g) || [])].slice(0, 5);
}

function extractConstants(content) {
  const webhooks = [...new Set(
    (content.match(/https?:\/\/(?:canary\.)?discord(?:app)?\.com\/api\/webhooks\/\d+\/[A-Za-z0-9_-]+/g) || [])
  )];
  const urls = [...new Set(
    (content.match(/https?:\/\/[^\s"')\]>,]+/g) || []).filter(u => !webhooks.includes(u))
  )].slice(0, 20);
  const hexKeys = [...new Set(
    (content.match(/\b[0-9a-fA-F]{32,}\b/g) || [])
  )].slice(0, 10);
  const strLiterals = [...new Set(
    (content.match(/(?:"(?:[^"\\]|\\.){4,}"|'(?:[^'\\]|\\.){4,}')/g) || [])
      .map(s => s.slice(1, -1))
      .filter(s => s.length >= 4 && !/^[0-9a-fA-F]+$/.test(s))
  )].slice(0, 30);
  return { webhooks, urls, hexKeys, strLiterals };
}

// ─── Network ─────────────────────────────────────────────────────────────────

function downloadFile(url, destPath) {
  return new Promise((resolve, reject) => {
    const proto = url.startsWith('https') ? https : http;
    const file  = fs.createWriteStream(destPath);
    proto.get(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        file.close();
        return downloadFile(res.headers.location, destPath).then(resolve).catch(reject);
      }
      res.pipe(file);
      file.on('finish', () => { file.close(); resolve(res.statusCode); });
      file.on('error', reject);
    }).on('error', reject);
  });
}

function uploadPastefy(content, title) {
  return new Promise((resolve) => {
    const body = JSON.stringify({ content, title, type: 'PASTE' });
    const req  = https.request({
      hostname: 'pastefy.app',
      path: '/api/v2/paste',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    }, (res) => {
      let d = '';
      res.on('data', c => (d += c));
      res.on('end', () => {
        try {
          const j = JSON.parse(d);
          resolve(j?.paste?.id ? `https://pastefy.app/${j.paste.id}/raw` : null);
        } catch { resolve(null); }
      });
    });
    req.on('error', () => resolve(null));
    req.write(body);
    req.end();
  });
}

// ─── Deobfuscator runner (delegates to engines/runner.js) ────────────────────

async function runDeob(inputPath, outputPath, engineId = 'luraph_v15') {
  const res = await runEngine(engineId, inputPath, outputPath);
  return {
    code:    res.ok ? 0 : 1,
    stderr:  res.err || '',
    elapsed: res.elapsed,
    ok:      res.ok,
  };
}

// ─── Components V2 builders ───────────────────────────────────────────────────

// Engine selection buttons (shown after detection)
function buildEngineSelectMsg(filename, detected, recommendedId, jobId, confidence) {
  const confScore = Math.round(confidence);
  const notStrong = confidence < 60;

  // Build button rows (max 5 per row)
  const sorted = buildEngineList(recommendedId);

  const rows = [];
  for (let i = 0; i < sorted.length; i += 5) {
    rows.push({
      type: 1,
      components: sorted.slice(i, i + 5).map(e => ({
        type: 2,
        style: e.style,
        label: e.label,
        custom_id: `run_${jobId}_${e.id}`,
      })),
    });
  }

  return {
    flags: CV2_FLAG,
    components: [{
      type: 17,
      accent_color: 0x5865F2,
      components: [
        {
          type: 10,
          content: [
            `## <a:loading:1536769812187840633> Deobfuscation`,
            `**Detected:** ${detected} (score ${confScore})`,
            `**Recommended:** ${ALL_ENGINES.find(e => e.id === recommendedId)?.label || detected}`,
            notStrong ? `The match is not strong - if it fails, try another engine below.` : '',
            `**File:** \`${filename}\``,
          ].filter(Boolean).join('\n'),
        },
        { type: 14 },
        { type: 10, content: `Select a deobfuscator to run:` },
        ...rows,
      ],
    }],
  };
}

function buildLoadingMsg(filename, engineLabel, elapsedSec = null) {
  const timeStr = elapsedSec !== null ? `  ·  **${elapsedSec}s elapsed**` : '';
  return {
    flags: CV2_FLAG,
    components: [{
      type: 17,
      accent_color: 0xFEE75C,
      components: [{
        type: 10,
        content: [
          `## <a:loading:1536769812187840633> Deobfuscating`,
          `Running **${engineLabel}** engine...${timeStr}`,
          `**File:** \`${filename}\``,
          `This may take a moment. Timeout: 2 min.`,
        ].join('\n'),
      }],
    }],
  };
}

function buildRateLimitMsg(remaining, resetIn, limit, isBooster) {
  return {
    flags: CV2_FLAG,
    components: [{
      type: 17,
      accent_color: 0xED4245,
      components: [{
        type: 10,
        content: [
          `## <:error:1536769814637322271> Rate Limit Reached`,
          `You've used all **${limit}** daily deobfuscations.`,
          `Resets in **${resetIn}h**.`,
          isBooster ? '' : `Server boosters get **${LIMIT_BOOSTER}** uses/day.`,
        ].filter(Boolean).join('\n'),
      }],
    }],
    ephemeral: true,
  };
}

function buildTagRequiredMsg() {
  return {
    flags: CV2_FLAG | 64, // 64 = ephemeral
    components: [{
      type: 17,
      accent_color: 0xED4245,
      components: [{
        type: 10,
        content: [
          `## 🔒 Server Tag Required`,
          `You need the server tag to use this command.`,
          `Server boosters and admins are exempt.`,
        ].join('\n'),
      }],
    }],
  };
}

function buildErrorMsg(filename, engine, elapsed, errText) {
  const short = errText.replace(/\[!\]\s*/g, '').slice(0, 900);
  return {
    flags: CV2_FLAG,
    components: [{
      type: 17,
      accent_color: 0xED4245,
      components: [
        {
          type: 10,
          content: [
            `## <:error:1536769814637322271> Deobfuscation Failed`,
            `**Engine:** ${engine}  |  **Time:** ${elapsed}s`,
            `**File:** \`${filename}\``,
          ].join('\n'),
        },
        { type: 14 },
        { type: 10, content: `**Error:**\n\`\`\`\n${short}\n\`\`\`` },
      ],
    }],
  };
}

function buildSuccessMsg({ filename, engine, inputSize, outputSize, reduction, outputLines, strings, pastfyUrl, blocked, elapsed, resultId }) {
  const strLine = strings.length > 0
    ? `**Recovered Strings:** ${strings.slice(0, 6).map(s => `\`${s}\``).join(', ')}${strings.length > 6 ? ` +${strings.length - 6} more` : ''}\n`
    : '';

  const inner = [
    {
      type: 10,
      content: [
        `## <a:success:1536769872552403034> Deobfuscation Complete`,
        `**Engine:** ${engine}`,
        `**Input:** ${inputSize}  |  **Output:** ${outputSize}  |  **Reduction:** ${reduction}%`,
      ].join('\n'),
    },
    { type: 14 },
    {
      type: 10,
      content: [
        strLine + `**Output:** ${outputLines} lines, ${outputSize}`,
        pastfyUrl ? `**showcase: [pastefy here](${pastfyUrl})** - full raw output, no downloading needed` : '',
      ].filter(Boolean).join('\n'),
    },
  ];

  if (blocked.length > 0) {
    inner.push({ type: 14 });
    inner.push({
      type: 10,
      content: [
        `⚠️ **The recovered script contacts a blocked host:**`,
        ...blocked.map(b => `\`${b.url}\`\n> ${b.reason}`),
        ``,
        `That is what this script was for. Do not run it.`,
      ].join('\n'),
    });
  }

  inner.push({ type: 14 });
  inner.push({
    type: 1,
    components: [
      { type: 2, style: 2, label: 'Copy',     custom_id: `copy_${resultId}` },
      ...(pastfyUrl ? [{ type: 2, style: 5, label: 'Raw Output', url: pastfyUrl }] : []),
      { type: 2, style: 3, label: 'Download', custom_id: `dl_${resultId}` },
    ],
  });

  return {
    flags: CV2_FLAG,
    components: [{ type: 17, accent_color: 0x57F287, components: inner }],
  };
}

function buildDumpMsg({ filename, elapsed, operations, stages, detected, urlsTouched, codePreview, pastfyUrl, outFilename, outContent, resultId }) {
  const inner = [
    {
      type: 10,
      content: [
        `## 🔒 Environment Dump`,
        `**File:** \`${filename}\``,
        `**Ran for:** ${elapsed}s  |  **Operations:** ${operations}  |  **Recovered stages:** ${stages}  |  **Detected:** ${detected}`,
      ].join('\n'),
    },
  ];

  if (urlsTouched.length > 0) {
    inner.push({ type: 14 });
    inner.push({
      type: 10,
      content: `**URLs touched:**\n${urlsTouched.map(u => `\`${u}\``).join('\n')}`,
    });
  }

  if (codePreview) {
    inner.push({ type: 14 });
    inner.push({
      type: 10,
      content: `\`\`\`lua\n${codePreview.slice(0, 1500)}\n\`\`\``,
    });
  }

  inner.push({ type: 14 });
  inner.push({
    type: 10,
    content: pastfyUrl
      ? `**showcase brody: [pastefy here](${pastfyUrl})** - full raw dump, no downloading needed`
      : `*Raw dump attached below.*`,
  });

  inner.push({
    type: 1,
    components: [
      { type: 2, style: 2, label: 'Copy',     custom_id: `copy_${resultId}` },
      ...(pastfyUrl ? [{ type: 2, style: 5, label: 'Raw Dump', url: pastfyUrl }] : []),
      { type: 2, style: 3, label: 'Download', custom_id: `dl_${resultId}` },
    ],
  });

  return {
    flags: CV2_FLAG,
    components: [{ type: 17, accent_color: 0x57F287, components: inner }],
  };
}

function buildGetMsg({ url, size, lines, pastfyUrl, jobId }) {
  return {
    flags: CV2_FLAG,
    components: [{
      type: 17,
      accent_color: 0x5865F2,
      components: [
        {
          type: 10,
          content: [
            `## 🔒 Script Fetched`,
            `**URL:** ${url}`,
            `**Size:** ${size} | ${lines} lines`,
          ].join('\n'),
        },
        { type: 14 },
        {
          type: 1,
          components: [
            { type: 2, style: 2, label: 'Copy',     custom_id: `copy_noop_${Date.now()}` },
            ...(pastfyUrl ? [{ type: 2, style: 5, label: 'Download', url: pastfyUrl }] : []),
            { type: 2, style: 1, label: 'Deobfuscate', custom_id: `detect_${jobId}` },
          ],
        },
      ],
    }],
  };
}

function buildDetectMsg(filename, engine, confidence) {
  const pct   = (confidence * 100).toFixed(0);
  const color = confidence >= 0.8 ? 0x57F287 : confidence >= 0.5 ? 0xFEE75C : 0xED4245;
  const icon  = confidence >= 0.8 ? '<a:success:1536769872552403034>' : confidence >= 0.5 ? '⚠️' : '<:error:1536769814637322271>';
  return {
    flags: CV2_FLAG,
    components: [{
      type: 17,
      accent_color: color,
      components: [{
        type: 10,
        content: [
          `## ${icon} Detection Result`,
          `**File:** \`${filename}\``,
          `**Detected:** ${engine}`,
          `**Confidence:** ${pct}%`,
        ].join('\n'),
      }],
    }],
  };
}

// ─── Core deob flow (called from button handler too) ─────────────────────────

async function executeDeob(interaction, job, engineId) {
  const engine     = ALL_ENGINES.find(e => e.id === engineId) || ALL_ENGINES[0];
  const outputPath = path.join(job.tmpDir, `output.lua`);
  const t0         = Date.now();

  await interaction.editReply(buildLoadingMsg(job.filename, engine.label));

  // Update elapsed time every 15s so user knows it's still running
  const ticker = setInterval(async () => {
    const sec = Math.round((Date.now() - t0) / 1000);
    try { await interaction.editReply(buildLoadingMsg(job.filename, engine.label, sec)); } catch {}
  }, 15_000);

  try {
    const { ok, stderr, elapsed } = await runDeob(job.inputPath, outputPath, engineId);
    clearInterval(ticker);

    if (!ok) {
      const errText = stderr || 'No output produced';
      await interaction.editReply(buildErrorMsg(job.filename, engine.label, elapsed, errText));
      return;
    }

    const rawContent  = fs.readFileSync(outputPath, 'utf8');
    const header      = `-- Deobfuscated by discord.gg/leaking\n-- Detected obfuscation: ${engine.label}\n\n`;
    const outContent  = injectWatermark(header + rawContent);
    const outBytes    = Buffer.byteLength(outContent, 'utf8');
    const inBytes     = fs.statSync(job.inputPath).size;
    const reduction   = Math.max(0, Math.round((1 - outBytes / inBytes) * 100));
    const outputLines = outContent.split('\n').length;
    const strings     = extractStrings(outContent);
    const blocked     = checkBlocklist(outContent);
    const pastfyUrl   = await uploadPastefy(outContent, job.filename + '.deob.lua');
    const outName     = job.filename.replace(/\.(lua|luau|txt)$/i, '.deobfuscated.lua');

    recordStat('deob', engineId);
    const resultId = `r_${Date.now()}`;
    resultCache.set(resultId, { content: outContent, filename: outName, expire: Date.now() + 30 * 60_000 });

    await interaction.editReply({
      ...buildSuccessMsg({
        filename:    job.filename,
        engine:      engine.label,
        inputSize:   formatSize(inBytes),
        outputSize:  formatSize(outBytes),
        reduction,
        outputLines,
        strings,
        pastfyUrl,
        blocked,
        elapsed,
        resultId,
      }),
      files: [new AttachmentBuilder(Buffer.from(outContent, 'utf8'), { name: outName })],
    });
  } finally {
    clearInterval(ticker);
    pendingJobs.delete(job.id);
    try { fs.rmSync(job.tmpDir, { recursive: true }); } catch {}
  }
}

// ─── Discord setup ────────────────────────────────────────────────────────────

const commands = [
  new SlashCommandBuilder()
    .setName('deob')
    .setDescription('Deobfuscate a Luraph / Lua script')
    .addAttachmentOption(o =>
      o.setName('file').setDescription('.lua / .luau / .txt file to deobfuscate').setRequired(true))
    .toJSON(),

  new SlashCommandBuilder()
    .setName('dump')
    .setDescription('Run an environment trace dump on a script (behaviour trace only, no devirt)')
    .addAttachmentOption(o =>
      o.setName('file').setDescription('.lua / .luau / .txt file to dump').setRequired(true))
    .toJSON(),

  new SlashCommandBuilder()
    .setName('get')
    .setDescription('Fetch a script from a URL and inspect / deobfuscate it')
    .addStringOption(o =>
      o.setName('url').setDescription('Raw URL to the Lua script').setRequired(true))
    .toJSON(),

  new SlashCommandBuilder()
    .setName('detect')
    .setDescription('Detect the obfuscator used in a Lua file')
    .addAttachmentOption(o =>
      o.setName('file').setDescription('.lua / .luau / .txt file to analyze').setRequired(true))
    .toJSON(),

  new SlashCommandBuilder()
    .setName('usage')
    .setDescription('Check how many deobs you have left today')
    .toJSON(),

  new SlashCommandBuilder()
    .setName('engines')
    .setDescription('List all supported deobfuscation engines')
    .toJSON(),

  new SlashCommandBuilder()
    .setName('strings')
    .setDescription('Extract all string literals from a Lua script (no engine needed)')
    .addAttachmentOption(o =>
      o.setName('file').setDescription('.lua / .luau / .txt file to scan').setRequired(true))
    .toJSON(),

  new SlashCommandBuilder()
    .setName('scan')
    .setDescription('Scan a script for suspicious URLs, webhooks, and blocked domains')
    .addAttachmentOption(o =>
      o.setName('file').setDescription('.lua / .luau / .txt file to scan').setRequired(true))
    .toJSON(),

  new SlashCommandBuilder()
    .setName('condumper')
    .setDescription('Dump all constants from a script — strings, URLs, webhooks, hex keys')
    .addAttachmentOption(o =>
      o.setName('file').setDescription('.lua / .luau / .txt file').setRequired(true))
    .toJSON(),

  new SlashCommandBuilder()
    .setName('bypass')
    .setDescription('Plato key solver — fetch auth.platorelay.com key from URL')
    .addStringOption(o =>
      o.setName('url').setDescription('The Plato auth URL from the script').setRequired(true))
    .toJSON(),

  new SlashCommandBuilder()
    .setName('stats')
    .setDescription('Bot statistics — total deobs, dumps, most used engines')
    .toJSON(),

  new SlashCommandBuilder()
    .setName('help')
    .setDescription('How to use this bot')
    .toJSON(),
];

async function registerCommands() {
  const rest = new REST({ version: '10' }).setToken(TOKEN);
  // Guild commands register instantly (no propagation delay)
  await rest.put(Routes.applicationGuildCommands(CLIENT_ID, GUILD_ID), { body: commands });
  console.log(`[+] Guild commands registered for ${GUILD_ID}`);
}

const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once('ready', () => console.log(`[+] Online as ${client.user.tag}`));

// ─── Interaction handler ──────────────────────────────────────────────────────

client.on('interactionCreate', async (interaction) => {

  // ── Channel gate — commands only work in the designated channel ───────────
  if (interaction.channelId !== ALLOWED_CHANNEL_ID) {
    await interaction.reply({
      content: `<:error:1536769814637322271> Este comando só pode ser usado em <#${ALLOWED_CHANNEL_ID}>.`,
      ephemeral: true,
    });
    return;
  }

  // ── Button: engine selected after /deob detection ─────────────────────────
  if (interaction.isButton()) {
    const cid = interaction.customId;

    if (cid.startsWith('run_')) {
      const parts    = cid.split('_');
      // run_<userId>_<timestamp>_<engineId>
      const engineId = parts.slice(3).join('_'); // handles engineId with underscores
      const jobId    = parts.slice(1, 3).join('_'); // userId_timestamp
      const job      = pendingJobs.get(jobId);

      if (!job) {
        await interaction.reply({ content: '<:error:1536769814637322271> Job expired or not found. Run the command again.', ephemeral: true });
        return;
      }
      if (job.userId !== interaction.user.id) {
        await interaction.reply({ content: '<:error:1536769814637322271> This is not your job.', ephemeral: true });
        return;
      }

      await interaction.deferUpdate();
      await enqueueDeob(interaction, job, engineId, interaction.member);
      return;
    }

    // Button: Deobfuscate from /get
    if (cid.startsWith('detect_')) {
      const jobId = cid.replace('detect_', '');
      const job   = pendingJobs.get(jobId);

      if (!job) {
        await interaction.reply({ content: '<:error:1536769814637322271> Job expired. Run `/get` again.', ephemeral: true });
        return;
      }
      if (job.userId !== interaction.user.id) {
        await interaction.reply({ content: '<:error:1536769814637322271> This is not your job.', ephemeral: true });
        return;
      }

      // Check limits again when they click Deobfuscate
      const member = interaction.member;
      const admin  = isAdmin(member);
      const boost  = isBooster(member);
      const limit  = checkAndConsumeLimit(interaction.user.id, boost, admin, false);
      if (!limit.allowed) {
        await interaction.reply({ ...buildRateLimitMsg(0, limit.resetIn, limit.limit, boost), ephemeral: true });
        return;
      }

      await interaction.deferUpdate();

      const src2 = fs.readFileSync(job.inputPath, 'latin1');
      const det2 = engineForDetection(src2);

      const jobId2 = makeJobId(interaction.user.id);
      pendingJobs.set(jobId2, { ...job, id: jobId2, expire: Date.now() + 10 * 60_000 });
      pendingJobs.delete(jobId);

      checkAndConsumeLimit(interaction.user.id, boost, admin, true);

      await interaction.editReply(
        buildEngineSelectMsg(job.filename, det2.label, det2.id, jobId2, det2.confidence)
      );
      return;
    }

    // Copy button — send content inline for easy copying
    if (cid.startsWith('copy_')) {
      const rid = cid.slice(5);
      const cached = resultCache.get(rid);
      if (!cached) {
        await interaction.reply({ content: '<:error:1536769814637322271> Output expired (30 min limit). Run the command again.', ephemeral: true });
        return;
      }
      const snippet = cached.content.length > 1900
        ? cached.content.slice(0, 1900) + '\n... (truncated — use Download for full file)'
        : cached.content;
      await interaction.reply({
        content: `\`\`\`lua\n${snippet}\n\`\`\``,
        ephemeral: true,
      });
      return;
    }

    // Download button — send as file attachment
    if (cid.startsWith('dl_')) {
      const rid = cid.slice(3);
      const cached = resultCache.get(rid);
      if (!cached) {
        await interaction.reply({ content: '<:error:1536769814637322271> Output expired (30 min limit). Run the command again.', ephemeral: true });
        return;
      }
      await interaction.reply({
        files: [new AttachmentBuilder(Buffer.from(cached.content, 'utf8'), { name: cached.filename })],
        ephemeral: true,
      });
      return;
    }

    return;
  }

  if (!interaction.isChatInputCommand()) return;

  // ── Ensure we're in the right guild ───────────────────────────────────────
  if (interaction.guildId !== GUILD_ID) {
    await interaction.reply({ content: '<:error:1536769814637322271> This bot only works in its home server.', ephemeral: true });
    return;
  }

  const member = interaction.member;
  const admin  = isAdmin(member);
  const boost  = isBooster(member);

  // ── /detect ───────────────────────────────────────────────────────────────
  if (interaction.commandName === 'detect') {
    const att = interaction.options.getAttachment('file');
    await interaction.deferReply();

    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'deob_'));
    const ext    = path.extname(att.name) || '.lua';
    const inPath = path.join(tmpDir, `input${ext}`);

    try {
      await downloadFile(att.url, inPath);
      const src = fs.readFileSync(inPath, 'latin1');
      const det = engineForDetection(src);
      recordStat('detect');
      await interaction.editReply(buildDetectMsg(att.name, det.label, det.confidence / 100));
    } catch (e) {
      await interaction.editReply({ content: `<:error:1536769814637322271> Detection error: ${e.message}` });
    } finally {
      try { fs.rmSync(tmpDir, { recursive: true }); } catch {}
    }
    return;
  }

  // ── /get url ──────────────────────────────────────────────────────────────
  if (interaction.commandName === 'get') {
    const rawUrl = interaction.options.getString('url');

    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      await interaction.reply({ content: '<:error:1536769814637322271> URL must start with http:// or https://', ephemeral: true });
      return;
    }

    await interaction.deferReply();

    const tmpDir  = fs.mkdtempSync(path.join(os.tmpdir(), 'deob_'));
    const inPath  = path.join(tmpDir, 'fetched.lua');

    try {
      await downloadFile(rawUrl, inPath);
      const content = fs.readFileSync(inPath, 'utf8');
      const bytes   = Buffer.byteLength(content, 'utf8');
      const lines   = content.split('\n').length;
      const pastfyUrl = await uploadPastefy(content, 'fetched.lua');

      const jobId = makeJobId(interaction.user.id);
      pendingJobs.set(jobId, {
        id: jobId,
        inputPath: inPath,
        tmpDir,
        filename: 'fetched.lua',
        userId: interaction.user.id,
        expire: Date.now() + 10 * 60_000,
      });

      await interaction.editReply({
        ...buildGetMsg({ url: rawUrl, size: formatSize(bytes), lines, pastfyUrl, jobId }),
        files: [new AttachmentBuilder(Buffer.from(content, 'utf8'), { name: 'fetched.lua' })],
      });
    } catch (e) {
      try { fs.rmSync(tmpDir, { recursive: true }); } catch {}
      await interaction.editReply({ content: `<:error:1536769814637322271> Failed to fetch URL: ${e.message}` });
    }
    return;
  }

  // ── /dump and /deob — require server tag ─────────────────────────────────
  if (interaction.commandName === 'dump' || interaction.commandName === 'deob') {
    if (!hasServerTag(member)) {
      await interaction.reply(buildTagRequiredMsg());
      return;
    }

    const limit = checkAndConsumeLimit(interaction.user.id, boost, admin, false);
    if (!limit.allowed) {
      await interaction.reply({ ...buildRateLimitMsg(0, limit.resetIn, limit.limit, boost), ephemeral: true });
      return;
    }

    const att = interaction.options.getAttachment('file');
    const ext = path.extname(att.name).toLowerCase();
    if (!['.lua', '.luau', '.txt'].includes(ext)) {
      await interaction.reply({ content: '<:error:1536769814637322271> Only .lua, .luau, or .txt files are supported.', ephemeral: true });
      return;
    }

    await interaction.deferReply();

    const tmpDir  = fs.mkdtempSync(path.join(os.tmpdir(), 'deob_'));
    const inPath  = path.join(tmpDir, `input${ext}`);
    const outPath = path.join(tmpDir, `output.lua`);

    try {
      await downloadFile(att.url, inPath);
    } catch (e) {
      try { fs.rmSync(tmpDir, { recursive: true }); } catch {}
      await interaction.editReply({ content: `<:error:1536769814637322271> Failed to download file: ${e.message}` });
      return;
    }

    // ── /dump — generic trace only ────────────────────────────────────────
    if (interaction.commandName === 'dump') {
      checkAndConsumeLimit(interaction.user.id, boost, admin, true);
      recordStat('dump');

      await interaction.editReply({
        flags: CV2_FLAG,
        components: [{
          type: 17,
          accent_color: 0xFEE75C,
          components: [{ type: 10, content: `## <a:loading:1536769812187840633> Running Environment Dump\n**File:** \`${att.name}\`\nThis may take a moment...` }],
        }],
      });

      try {
        const { ok, stderr, elapsed } = await runDeob(inPath, outPath, 'generic');

        if (!ok) {
          await interaction.editReply(buildErrorMsg(att.name, 'Generic Trace', elapsed, stderr || 'No output'));
          return;
        }

        const rawDump    = fs.readFileSync(outPath, 'utf8');
        const srcDump    = fs.readFileSync(inPath, 'latin1');
        const detDump    = engineForDetection(srcDump);
        const dumpHeader = `-- Deobfuscated by discord.gg/leaking\n-- Detected obfuscation: ${detDump.label}\n\n`;
        const outContent = injectWatermark(dumpHeader + rawDump);
        const outBytes   = Buffer.byteLength(outContent, 'utf8');
        const urls       = extractUrlsTouched(outContent);
        const pastfyUrl  = await uploadPastefy(outContent, att.name + '.dump.lua');
        const outName    = att.name.replace(/\.(lua|luau|txt)$/i, '.dump.lua');

        const preview = outContent
          .split('\n')
          .filter(l => !l.trim().startsWith('--') && l.trim())
          .slice(0, 20)
          .join('\n');

        const opMatch = stderr.match(/(\d+) statement/);
        const ops     = opMatch ? opMatch[1] : '?';

        const dumpResultId = `r_${Date.now()}`;
        resultCache.set(dumpResultId, { content: outContent, filename: outName, expire: Date.now() + 30 * 60_000 });

        await interaction.editReply({
          ...buildDumpMsg({
            filename:    att.name,
            elapsed,
            operations:  ops,
            stages:      '1',
            detected:    detDump.label,
            urlsTouched: urls,
            codePreview: preview,
            pastfyUrl,
            outFilename: outName,
            outContent,
            resultId:    dumpResultId,
          }),
          files: [new AttachmentBuilder(Buffer.from(outContent, 'utf8'), { name: outName })],
        });
      } finally {
        try { fs.rmSync(tmpDir, { recursive: true }); } catch {}
      }
      return;
    }

    // ── /deob — detect + show engine selection ───────────────────────────
    const src      = fs.readFileSync(inPath, 'latin1');
    const det      = engineForDetection(src);
    const inputSize = formatSize(fs.statSync(inPath).size);

    const jobId = makeJobId(interaction.user.id);
    pendingJobs.set(jobId, {
      id: jobId,
      inputPath: inPath,
      tmpDir,
      filename: att.name,
      userId: interaction.user.id,
      inputSize,
      expire: Date.now() + 10 * 60_000,
    });

    checkAndConsumeLimit(interaction.user.id, boost, admin, true);

    await interaction.editReply(
      buildEngineSelectMsg(att.name, det.label, det.id, jobId, det.confidence)
    );
  }

  // ── /usage ─────────────────────────────────────────────────────────────────
  if (interaction.commandName === 'usage') {
    const info = checkAndConsumeLimit(interaction.user.id, boost, admin, false);
    const isAdm = isAdmin(member);
    let body;
    if (isAdm) {
      body = `**Usage:** Unlimited (admin)\n**Limit:** ∞`;
    } else {
      const used = info.limit - info.remaining;
      const pct  = Math.round((used / info.limit) * 100);
      const bar  = '█'.repeat(Math.round(pct / 10)) + '░'.repeat(10 - Math.round(pct / 10));
      const resetIn = info.resetIn ?? '< 24';
      body = [
        `**${used}/${info.limit}** uses today ${boost ? '(Booster)' : '(Regular)'}`,
        `\`${bar}\` ${pct}%`,
        info.remaining > 0
          ? `**${info.remaining}** remaining — resets in ~${resetIn}h`
          : `<:error:1536769814637322271> **Limit reached** — resets in ~${resetIn}h`,
      ].join('\n');
    }
    await interaction.reply({
      flags: CV2_FLAG,
      components: [{ type: 17, accent_color: 0x5865F2, components: [
        { type: 10, content: `## <a:loading:1536769812187840633> Your Usage\n${body}` },
      ]}],
      ephemeral: true,
    });
    return;
  }

  // ── /engines ───────────────────────────────────────────────────────────────
  if (interaction.commandName === 'engines') {
    const families = [
      { name: 'Luraph',    ids: ['luraph_v15','luraph_v14','luraph_v17','lph_deobf'] },
      { name: 'MoonSec',   ids: ['moonsec_cs','moonsec_js','moonsec_py'] },
      { name: 'Prometheus',ids: ['prometheus_js','prometheus_v2','prometheus_wad'] },
      { name: 'IronBrew',  ids: ['ironbrew2','ironbrew_new'] },
      { name: '6Vms / Lune',ids: ['6vms_logger','6vms_static','threaded'] },
      { name: 'Other',     ids: ['77fuscator','aspect_dumper','cracker2','moonveil','generic'] },
    ];
    const lines = families.map(f =>
      `**${f.name}**\n` + f.ids.map(id => `> \`${id}\` — ${ENGINE_DESC[id] || id}`).join('\n')
    ).join('\n\n');
    await interaction.reply({
      flags: CV2_FLAG,
      components: [{ type: 17, accent_color: 0x5865F2, components: [
        { type: 10, content: `## Supported Engines (${ALL_ENGINES.length} total)\n\n${lines}` },
      ]}],
      ephemeral: true,
    });
    return;
  }

  // ── /strings ───────────────────────────────────────────────────────────────
  if (interaction.commandName === 'strings') {
    const att = interaction.options.getAttachment('file');
    await interaction.deferReply();
    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'deob_'));
    const inPath = path.join(tmpDir, `input${path.extname(att.name) || '.lua'}`);
    try {
      await downloadFile(att.url, inPath);
      const src = fs.readFileSync(inPath, 'utf8');
      const strs = [...new Set(
        (src.match(/(?:"(?:[^"\\]|\\.){2,}"|'(?:[^'\\]|\\.){2,}')/g) || [])
          .map(s => s.slice(1, -1))
          .filter(s => s.trim().length > 1)
      )].slice(0, 60);
      const out = strs.length > 0
        ? strs.map(s => `\`${s.replace(/`/g, "'")}\``).join('\n')
        : '*No string literals found.*';
      const pasteUrl = strs.length > 20 ? await uploadPastefy(strs.join('\n'), att.name + '.strings.txt') : null;
      await interaction.editReply({
        flags: CV2_FLAG,
        components: [{ type: 17, accent_color: 0x5865F2, components: [
          { type: 10, content: `## String Extraction — \`${att.name}\`\n**${strs.length}** strings found${pasteUrl ? ` · [full list](${pasteUrl})` : ''}` },
          { type: 14 },
          { type: 10, content: strs.slice(0, 20).map(s => `\`${s.replace(/`/g, "'")}\``).join('\n') || '*none*' },
        ]}],
      });
    } catch (e) {
      await interaction.editReply({ content: `<:error:1536769814637322271> Error: ${e.message}` });
    } finally {
      try { fs.rmSync(tmpDir, { recursive: true }); } catch {}
    }
    return;
  }

  // ── /scan ──────────────────────────────────────────────────────────────────
  if (interaction.commandName === 'scan') {
    const att = interaction.options.getAttachment('file');
    await interaction.deferReply();
    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'deob_'));
    const inPath = path.join(tmpDir, `input${path.extname(att.name) || '.lua'}`);
    try {
      await downloadFile(att.url, inPath);
      const src     = fs.readFileSync(inPath, 'utf8');
      const blocked = checkBlocklist(src);
      const urls    = [...new Set((src.match(/https?:\/\/[^\s"')\]>,]+/g) || []))].slice(0, 15);
      const det     = engineForDetection(fs.readFileSync(inPath, 'latin1'));
      const parts   = [
        `## <a:success:1536769872552403034> Scan — \`${att.name}\``,
        `**Detected:** ${det.label}  |  **URLs found:** ${urls.length}  |  **Blocked:** ${blocked.length}`,
      ].join('\n');
      const urlBlock = urls.length > 0 ? urls.map(u => `\`${u}\``).join('\n') : '*none*';
      const blkBlock = blocked.length > 0
        ? blocked.map(b => `<:error:1536769814637322271> \`${b.url}\` — ${b.reason}`).join('\n')
        : '<a:success:1536769872552403034> *No blocked domains detected*';
      await interaction.editReply({
        flags: CV2_FLAG,
        components: [{ type: 17, accent_color: blocked.length > 0 ? 0xED4245 : 0x57F287, components: [
          { type: 10, content: parts },
          { type: 14 },
          { type: 10, content: `**URLs:**\n${urlBlock}` },
          { type: 14 },
          { type: 10, content: `**Blocklist hits:**\n${blkBlock}` },
        ]}],
      });
    } catch (e) {
      await interaction.editReply({ content: `<:error:1536769814637322271> Error: ${e.message}` });
    } finally {
      try { fs.rmSync(tmpDir, { recursive: true }); } catch {}
    }
    return;
  }

  // ── /condumper ─────────────────────────────────────────────────────────────
  if (interaction.commandName === 'condumper') {
    const att = interaction.options.getAttachment('file');
    await interaction.deferReply();
    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'deob_'));
    const inPath = path.join(tmpDir, `input${path.extname(att.name) || '.lua'}`);
    try {
      await downloadFile(att.url, inPath);
      const src = fs.readFileSync(inPath, 'utf8');
      const { webhooks, urls, hexKeys, strLiterals } = extractConstants(src);
      const sections = [];
      if (webhooks.length)    sections.push(`**Discord Webhooks (${webhooks.length}):**\n${webhooks.map(w => `\`${w}\``).join('\n')}`);
      if (hexKeys.length)     sections.push(`**Hex Keys/Tokens (${hexKeys.length}):**\n${hexKeys.map(k => `\`${k}\``).join('\n')}`);
      if (urls.length)        sections.push(`**URLs (${urls.length}):**\n${urls.slice(0,10).map(u => `\`${u}\``).join('\n')}`);
      if (strLiterals.length) sections.push(`**Strings (${strLiterals.length}):**\n${strLiterals.slice(0,15).map(s => `\`${s.replace(/`/g,"'")}\``).join('\n')}`);
      const fullDump = [
        `=== CONSTANTS DUMP: ${att.name} ===`,
        webhooks.length ? `\nWEBHOOKS:\n${webhooks.join('\n')}` : '',
        hexKeys.length  ? `\nHEX KEYS:\n${hexKeys.join('\n')}` : '',
        urls.length     ? `\nURLs:\n${urls.join('\n')}` : '',
        strLiterals.length ? `\nSTRINGS:\n${strLiterals.join('\n')}` : '',
      ].filter(Boolean).join('\n');
      const pasteUrl = await uploadPastefy(fullDump, att.name + '.condump.txt');
      await interaction.editReply({
        flags: CV2_FLAG,
        components: [{ type: 17, accent_color: 0xFEE75C, components: [
          { type: 10, content: `## Constant Dump — \`${att.name}\`${pasteUrl ? ` · [full dump](${pasteUrl})` : ''}` },
          { type: 14 },
          { type: 10, content: sections.length > 0 ? sections.join('\n\n') : '*No constants found.*' },
        ]}],
        files: [new AttachmentBuilder(Buffer.from(fullDump, 'utf8'), { name: att.name + '.condump.txt' })],
      });
    } catch (e) {
      await interaction.editReply({ content: `<:error:1536769814637322271> Error: ${e.message}` });
    } finally {
      try { fs.rmSync(tmpDir, { recursive: true }); } catch {}
    }
    return;
  }

  // ── /bypass ────────────────────────────────────────────────────────────────
  if (interaction.commandName === 'bypass') {
    const rawUrl = interaction.options.getString('url');
    if (!rawUrl.includes('platorelay.com') && !rawUrl.includes('plato')) {
      await interaction.reply({ content: '<:error:1536769814637322271> URL must be a Plato relay endpoint.', ephemeral: true });
      return;
    }
    await interaction.deferReply();
    try {
      const key = await new Promise((resolve, reject) => {
        const proto = rawUrl.startsWith('https') ? https : http;
        let data = '';
        proto.get(rawUrl, { headers: { 'User-Agent': 'Roblox/WinInet' } }, res => {
          res.on('data', c => (data += c));
          res.on('end', () => resolve(data.trim()));
        }).on('error', reject);
      });
      const display = key.length > 500 ? key.slice(0, 500) + '...' : key;
      await interaction.editReply({
        flags: CV2_FLAG,
        components: [{ type: 17, accent_color: 0x57F287, components: [
          { type: 10, content: `## <a:success:1536769872552403034> Plato Key Resolved` },
          { type: 14 },
          { type: 10, content: `\`\`\`\n${display}\n\`\`\`` },
        ]}],
      });
    } catch (e) {
      await interaction.editReply({ content: `<:error:1536769814637322271> Failed to fetch: ${e.message}` });
    }
    return;
  }

  // ── /stats ─────────────────────────────────────────────────────────────────
  if (interaction.commandName === 'stats') {
    const s = loadStats();
    const topEngines = Object.entries(s.engine_counts || {})
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([id, n], i) => `${i + 1}. \`${id}\` — **${n}**`)
      .join('\n') || '*no data yet*';
    await interaction.reply({
      flags: CV2_FLAG,
      components: [{ type: 17, accent_color: 0x5865F2, components: [
        { type: 10, content: [
          `## Bot Statistics`,
          `**Total deobs:** ${s.total_deobs}`,
          `**Total dumps:** ${s.total_dumps}`,
          `**Total detects:** ${s.total_detects}`,
          `**Total requests:** ${s.total_deobs + s.total_dumps + s.total_detects}`,
        ].join('\n') },
        { type: 14 },
        { type: 10, content: `**Top Engines:**\n${topEngines}` },
      ]}],
    });
    return;
  }

  // ── /help ──────────────────────────────────────────────────────────────────
  if (interaction.commandName === 'help') {
    await interaction.reply({
      flags: CV2_FLAG,
      components: [{ type: 17, accent_color: 0x5865F2, components: [
        { type: 10, content: [
          `## How to Use`,
          `\`/deob\` — throw ur obfuscated file / link / code at it, pick an engine, get clean code back`,
          `\`/get\` — fetch a script from a URL and inspect / deobfuscate it`,
          `\`/dump\` — runs the script in a sandbox and logs what it does (strings, remotes, loadstring payloads). good when deob fails on VM stuff`,
          `\`/condumper\` — peel every constant out — strings, URLs, keys, webhooks`,
          `\`/strings\` — extract all string literals from a file without running any engine`,
          `\`/scan\` — scan for suspicious URLs, webhooks, and blocked domains`,
          `\`/detect\` — tells u what obfuscator ur file is`,
          `\`/bypass\` — Plato key solver (auth.platorelay.com)`,
          `\`/usage\` — how many deobs u have left today`,
          `\`/engines\` — list all 20 supported engines`,
          `\`/stats\` — bot stats`,
        ].join('\n') },
        { type: 14 },
        { type: 10, content: [
          `## What We Support`,
          `77fuscator, IronBrew2, Prometheus, MoonSec V3, Luraph v14/v15/v17, MoonVeil, Cracker2, Aspect, 6Vms, Threaded, LPH, and more`,
        ].join('\n') },
        { type: 14 },
        { type: 10, content: [
          `## Quick Start`,
          `1. upload .lua file or paste link`,
          `2. let it detect or pick manually`,
          `3. copy / download result`,
          ``,
          `**Deob failed?** try \`/dump\` — it runs it safely and shows what it actually did`,
        ].join('\n') },
      ]}],
      ephemeral: true,
    });
    return;
  }
});

// ─── Boot ─────────────────────────────────────────────────────────────────────

registerCommands()
  .then(() => client.login(TOKEN))
  .catch(e => { console.error('[!] Startup error:', e); process.exit(1); });
