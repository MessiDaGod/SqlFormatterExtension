#!/usr/bin/env node
'use strict';

const fs = require('fs');
const fsp = fs.promises;
const path = require('path');
const { spawn } = require('child_process');

function run(cmd, args = [], opts = {}) {
    return new Promise((resolve, reject) => {
        const p = spawn(cmd, args, { stdio: 'inherit', shell: true, ...opts });
        p.on('error', reject);
        p.on('exit', (code) => (code === 0 ? resolve() : reject(new Error(`${cmd} ${args.join(' ')} -> exit ${code}`))));
    });
}

async function findVsix(pkgName, pkgVersion, cwd) {
    const expected = path.join(cwd, `${pkgName}-${pkgVersion}.vsix`);
    if (fs.existsSync(expected)) return expected;

    const files = await fsp.readdir(cwd);
    const vsixes = files.filter(f => f.toLowerCase().endsWith('.vsix'));
    if (!vsixes.length) throw new Error('No .vsix file found. Did packaging succeed?');

    const prefer = vsixes.filter(f => f.startsWith(`${pkgName}-`));
    const candidates = prefer.length ? prefer : vsixes;

    let newest = null, newestMtime = 0;
    for (const f of candidates) {
        const st = await fsp.stat(path.join(cwd, f));
        if (st.mtimeMs > newestMtime) { newestMtime = st.mtimeMs; newest = f; }
    }
    return path.join(cwd, newest);
}

async function installVsix(vsixPath) {
    // Try common Windows/Unix CLI names in order
    const candidates = [
        { cmd: 'code', args: ['--install-extension', vsixPath] },
        { cmd: 'code.cmd', args: ['--install-extension', vsixPath] },
        { cmd: 'code-insiders', args: ['--install-extension', vsixPath] },
        { cmd: 'code-insiders.cmd', args: ['--install-extension', vsixPath] },
    ];
    let lastErr;
    for (const { cmd, args } of candidates) {
        try { await run(cmd, args); return; } catch (err) { lastErr = err; }
    }
    throw new Error(
        "Could not run VS Code CLI. Make sure 'code' is on PATH (on Windows: re-run the VS Code installer and check 'Add to PATH'). " +
        (lastErr ? `Last error: ${lastErr.message}` : '')
    );
}

(async () => {
    const cwd = process.cwd();
    const pkgPath = path.join(cwd, 'package.json');
    if (!fs.existsSync(pkgPath)) throw new Error(`package.json not found at ${pkgPath}`);

    const pkg = JSON.parse(await fsp.readFile(pkgPath, 'utf8'));
    const name = pkg.name;
    const version = pkg.version;
    if (!name || !version) throw new Error('package.json must have both "name" and "version".');

    console.log('\n▶ npm i');
    await run('npm', ['i', '--ignore-scripts']);

    console.log('\n▶ npm run compile');
    await run('npm', ['run', 'compile']);

    console.log('\n▶ npm run package');
    await run('npm', ['run', 'package']);

    const vsix = await findVsix(name, version, cwd);
    console.log(`\n✔ VSIX located: ${path.basename(vsix)}`);

    console.log('\n▶ Installing VSIX into VS Code');
    await installVsix(vsix);

    console.log('\n🎉 Done. Reload VS Code if prompted.');
})().catch(err => {
    console.error('\n✖ Error:', err.message);
    process.exit(1);
});
