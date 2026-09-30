const express = require('express');
const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 8080;

// Increase server timeout to effectively "no timeout" (0 means no limit)
app.server = app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
app.server.timeout = 0; // no timeout for the HTTP server

// CORS
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    if (req.method === 'OPTIONS') return res.sendStatus(200);
    next();
});

app.use(express.json({ limit: '10mb' }));

app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

app.post('/obfuscate', async (req, res) => {
    const { code } = req.body;

    if (!code || typeof code !== 'string') {
        return res.status(400).json({ error: 'Missing or invalid "code" field' });
    }

    let tempFile = null;
    let outputFile = null;

    try {
        // Write input to a temporary file
        tempFile = path.join(os.tmpdir(), `input_${Date.now()}_${Math.random()}.lua`);
        await fs.writeFile(tempFile, code, 'utf8');

        const command = `lua ./cli.lua --preset Medium "${tempFile}"`;
        console.log(`Running: ${command}`);

        // Execute the obfuscator with no timeout and a large buffer
        const { stderr } = await new Promise((resolve, reject) => {
            exec(command, { timeout: 0, maxBuffer: 1024 * 1024 * 50 }, (error, stdout, stderr) => {
                if (error) {
                    reject(error);
                } else {
                    resolve({ stdout, stderr });
                }
            });
        });

        console.log('Obfuscator stderr:', stderr);

        // Extract output file path from stderr (fallback to a default name)
        const match = stderr.match(/Writing output to "([^"]+)"/);
        if (match) {
            outputFile = match[1];
        } else {
            // Fallback: assume input file name without .lua + .obfuscated.lua
            const base = tempFile.replace(/\.lua$/, '');
            outputFile = base + '.obfuscated.lua';
        }

        // Verify the output file exists and read it
        await fs.access(outputFile);
        const obfuscated = await fs.readFile(outputFile, 'utf8');
        res.json({ obfuscated });
    } catch (error) {
        console.error('Obfuscation error:', error);
        res.status(500).json({ error: 'Obfuscation failed', details: error.message });
    } finally {
        // Clean up temporary files
        if (tempFile) await fs.unlink(tempFile).catch(() => {});
        if (outputFile) await fs.unlink(outputFile).catch(() => {});
    }
});
