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

function cleanExpiredJobs() {
  const now = Date.now();
  for (const [id, job] of pendingJobs) {
    if (now > job.expire) {
      try { fs.rmSync(job.tmpDir, { recursive: true }); } catch {}
      pendingJobs.delete(id);
    }
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

function buildLoadingMsg(filename, engineLabel) {
  return {
    flags: CV2_FLAG,
    components: [{
      type: 17,
      accent_color: 0xFEE75C,
      components: [{
        type: 10,
        content: [
          `## <a:loading:1536769812187840633> Deobfuscating`,
          `Running **${engineLabel}** engine...`,
          `**File:** \`${filename}\``,
          `This may take a moment.`,
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

function buildSuccessMsg({ filename, engine, inputSize, outputSize, reduction, outputLines, strings, pastfyUrl, blocked, elapsed }) {
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
      { type: 2, style: 2, label: 'Copy', custom_id: `copy_noop_${Date.now()}` },
      ...(pastfyUrl ? [{ type: 2, style: 5, label: 'Raw Output', url: pastfyUrl }] : []),
      { type: 2, style: 3, label: 'Download', custom_id: `dl_noop_${Date.now()}` },
    ],
  });

  return {
    flags: CV2_FLAG,
    components: [{ type: 17, accent_color: 0x57F287, components: inner }],
  };
}

function buildDumpMsg({ filename, elapsed, operations, stages, detected, urlsTouched, codePreview, pastfyUrl, outFilename, outContent }) {
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
      { type: 2, style: 2, label: 'Copy', custom_id: `copy_noop_${Date.now()}` },
      ...(pastfyUrl ? [{ type: 2, style: 5, label: 'Raw Dump', url: pastfyUrl }] : []),
      { type: 2, style: 3, label: 'Download', custom_id: `dl_noop_${Date.now()}` },
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

  await interaction.editReply(buildLoadingMsg(job.filename, engine.label));

  try {
    const { ok, stderr, elapsed } = await runDeob(job.inputPath, outputPath, engineId);

    if (!ok) {
      const errText = stderr || 'No output produced';
      await interaction.editReply(buildErrorMsg(job.filename, engine.label, elapsed, errText));
      return;
    }

    const outContent  = fs.readFileSync(outputPath, 'utf8');
    const outBytes    = Buffer.byteLength(outContent, 'utf8');
    const inBytes     = fs.statSync(job.inputPath).size;
    const reduction   = Math.max(0, Math.round((1 - outBytes / inBytes) * 100));
    const outputLines = outContent.split('\n').length;
    const strings     = extractStrings(outContent);
    const blocked     = checkBlocklist(outContent);
    const pastfyUrl   = await uploadPastefy(outContent, job.filename + '.deob.lua');
    const outName     = job.filename.replace(/\.(lua|luau|txt)$/i, '.deobfuscated.lua');

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
      }),
      files: [new AttachmentBuilder(Buffer.from(outContent, 'utf8'), { name: outName })],
    });
  } finally {
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
      await executeDeob(interaction, job, engineId);
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

    // noop buttons (Copy / Download placeholders)
    if (cid.startsWith('copy_noop') || cid.startsWith('dl_noop')) {
      await interaction.reply({ content: 'Use the attached file or the Pastefy link above.', ephemeral: true });
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

        const outContent = fs.readFileSync(outPath, 'utf8');
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

        const srcDump = fs.readFileSync(inPath, 'latin1');
        const detDump = engineForDetection(srcDump);
        const plugin  = { label: detDump.label };

        await interaction.editReply({
          ...buildDumpMsg({
            filename:    att.name,
            elapsed,
            operations:  ops,
            stages:      '1',
            detected:    plugin.label,
            urlsTouched: urls,
            codePreview: preview,
            pastfyUrl,
            outFilename: outName,
            outContent,
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
});

// ─── Boot ─────────────────────────────────────────────────────────────────────

registerCommands()
  .then(() => client.login(TOKEN))
  .catch(e => { console.error('[!] Startup error:', e); process.exit(1); });
