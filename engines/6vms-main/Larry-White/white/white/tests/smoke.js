const fs = require("fs");
const path = require("path");

const { parseLua } = require("../lua/parse");
const { deobfuscateSourceDetailed } = require("../passes/pipeline");

const workspaceRoot = path.resolve(__dirname, "..", "..");
const fixtures = [
  {
    path: "future.lua",
  },
  {
    path: "printtest.lua",
  },
  {
    path: "tryupdateonthis.lua",
  },
  {
    path: "samples/1.lua",
    checks: [
      {
        message: "expected output to recover PlaceId mapping",
        run(output) {
          return output.includes("local placeId = game.PlaceId") && output.includes('print("hallo")');
        },
      },
      {
        message: "expected output to remain parse-clean",
        run(output) {
          return !output.includes("DEBUG PARSE ERROR");
        },
      },
    ],
  },
  {
    path: "samples/2.lua",
  },
];

let failures = 0;

for (const fixture of fixtures) {
  const fixturePath = fixture.path || fixture;
  const inputPath = path.join(workspaceRoot, fixturePath);
  if (!fs.existsSync(inputPath)) {
    process.stdout.write(`${fixturePath}: skip (missing fixture)\n`);
    continue;
  }

  const source = fs.readFileSync(inputPath, "utf8");

  try {
    const result = deobfuscateSourceDetailed(source, { inputPath });
    parseLua(result.output);

    if (Array.isArray(fixture.checks)) {
      for (const check of fixture.checks) {
        const passed = check && typeof check.run === "function" ? check.run(result.output, result) : true;
        if (!passed) {
          throw new Error(check && check.message ? check.message : "fixture check failed");
        }
      }
    }

    process.stdout.write(`${fixturePath}: ok (${result.output.split(/\r?\n/).length} lines)\n`);
  } catch (error) {
    failures += 1;
    process.stdout.write(`${fixturePath}: fail (${error.message})\n`);
  }
}

if (failures > 0) {
  process.exitCode = 1;
}
