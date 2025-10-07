#!/usr/bin/env node
'use strict';

const fs = require('fs');
const fsp = fs.promises;
const path = require('path');
const { spawn } = require('child_process');

const action = (process.argv[2] || "install").toLowerCase();

async function uninstallSelf() {
    const cwd = process.cwd();
    const pkg = JSON.parse(await fsp.readFile(path.join(cwd, "package.json"), "utf8"));
    const extensionId = `${pkg.publisher}.${pkg.name}`;
    const codeCmd = await pickCodeCli();
    console.log(`\n▶ Uninstalling ${extensionId}`);
    await run(codeCmd, ["--uninstall-extension", extensionId]);
    console.log("✅ Uninstalled.");
}

function run(cmd, args = [], opts = {}) {
    return new Promise((resolve, reject) => {
        const p = spawn(cmd, args, { stdio: 'inherit', shell: true, ...opts });
        p.on('error', reject);
        p.on('exit', (code) =>
            code === 0 ? resolve() : reject(new Error(`${cmd} ${args.join(' ')} -> exit ${code}`))
        );
    });
}

function runCapture(cmd, args = [], opts = {}) {
    return new Promise((resolve, reject) => {
        const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'inherit'], shell: true, ...opts });
        let out = '';
        p.stdout.on('data', (d) => (out += d.toString()));
        p.on('error', reject);
        p.on('exit', (code) =>
            code === 0 ? resolve(out) : reject(new Error(`${cmd} ${args.join(' ')} -> exit ${code}`))
        );
    });
}

async function pickCodeCli() {
    const candidates = [
        'code', 'code-insiders',
        // Windows direct .cmd fallbacks
        'code.cmd', 'code-insiders.cmd'
    ];
    for (const c of candidates) {
        try {
            await runCapture(c, ['--version']);
            return c;
        } catch { }
    }
    throw new Error(
        `Could not find VS Code CLI. Make sure 'code' is on PATH (Command Palette → "Shell Command: Install 'code' command in PATH").`
    );
}

async function findVsix(pkgName, pkgVersion, cwd) {
    const expected = path.join(cwd, `${pkgName}-${pkgVersion}.vsix`);
    if (fs.existsSync(expected)) return expected;

    const files = await fsp.readdir(cwd);
    const vsixes = files.filter((f) => f.toLowerCase().endsWith('.vsix'));
    if (!vsixes.length) throw new Error('No .vsix file found. Did packaging succeed?');

    const prefer = vsixes.filter((f) => f.startsWith(`${pkgName}-`));
    const candidates = prefer.length ? prefer : vsixes;

    let newest = null;
    let newestMtime = 0;
    for (const f of candidates) {
        const st = await fsp.stat(path.join(cwd, f));
        if (st.mtimeMs > newestMtime) { newestMtime = st.mtimeMs; newest = f; }
    }
    return path.join(cwd, newest);
}

async function uninstallOldOnes(codeCmd, currentId) {
    const listRaw = await runCapture(codeCmd, ['--list-extensions']);
    const installed = listRaw.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
    const currentLc = currentId.toLowerCase();

    // Anything that looks like a past SQL Stylist id but isn't the current one
    const looksLikeStylist = (id) => /(sql-stylist|better-sql-stylist)/i.test(id);
    const toRemove = installed.filter((id) => looksLikeStylist(id) && id.toLowerCase() !== currentLc);

    // Also explicitly try a couple of historic ids
    const historic = ['joeshakely.sql-stylist', 'shakely-consulting.sql-stylist', 'shakely-consulting.better-sql-stylist'];
    for (const h of historic) if (!toRemove.includes(h) && installed.includes(h)) toRemove.push(h);

    if (!toRemove.length) {
        console.log('\n(no older SQL Stylist extensions found to uninstall)');
        return;
    }

    console.log('\n↻ Uninstalling older extensions:', toRemove.join(', '));
    for (const id of toRemove) {
        try {
            await run(codeCmd, ['--uninstall-extension', id]);
        } catch (e) {
            // keep going even if one fails
            console.warn(`(warn) Failed to uninstall ${id}: ${e.message}`);
        }
    }
}

async function installVsix(codeCmd, vsixPath) {
    await run(codeCmd, ['--install-extension', vsixPath]);
}

async function publishToMarketplace() {
    console.log("\n▶ npm i");
    await run("npm", ["i"]);

    console.log("\n▶ npm run compile");
    await run("npm", ["run", "compile"]);

    console.log("\n▶ vsce publish");
    await run("vsce", ["publish"]);

    console.log("\n✅ Published to marketplace!");
}

(async () => {
    if (action === "uninstall") {
        await uninstallSelf();
        return;
    }

    if (action === "publish") {
        await publishToMarketplace();
        return;
    }

    const cwd = process.cwd();
    const pkgPath = path.join(cwd, "package.json");
    if (!fs.existsSync(pkgPath)) throw new Error(`package.json not found at ${pkgPath}`);

    const pkg = JSON.parse(await fsp.readFile(pkgPath, "utf8"));
    const name = pkg.name;
    const version = pkg.version;
    const publisher = pkg.publisher;
    if (!name || !version || !publisher) {
        throw new Error('package.json must have "name", "version", and "publisher".');
    }
    const extensionId = `${publisher}.${name}`;

    const codeCmd = await pickCodeCli();

    if (action === "reinstall") {
        // remove current first (in addition to any historic/duplicate ones)
        try {
            console.log(`\n▶ Uninstalling current ${extensionId}`);
            await run(codeCmd, ["--uninstall-extension", extensionId]);
        } catch (e) {
            console.warn(`(warn) Could not uninstall ${extensionId}: ${e.message}`);
        }
    }

    console.log("\n▶ npm i");
    await run("npm", ["i"]);

    console.log("\n▶ npm run compile");
    await run("npm", ["run", "compile"]);

    console.log("\n▶ npm run package");
    await run("npm", ["run", "package"]);

    const vsix = await findVsix(name, version, cwd);

    await uninstallOldOnes(codeCmd, extensionId);

    console.log(`\n▶ Installing ${path.basename(vsix)} (${extensionId})`);
    await installVsix(codeCmd, vsix);

    console.log("\n✅ Done.");
})().catch((e) => {
    console.error("\n❌ install.js failed:", e?.message || e);
    process.exit(1);
});