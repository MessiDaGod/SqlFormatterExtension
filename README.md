# SQL Stylist — VS Code Formatter for T‑SQL

An opinionated formatter that gets your `.sql` files to look like the way I usually send them: **UPPERCASE keywords**, clean indentation, optional **`AS` alignment**, and **block‑style comments**.

## Quick Start

1. **Install from Marketplace**
   👉 [SQL Stylist on Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=joeshakely.sql-stylist&ssr=false#overview)

Or, if you prefer, clone and build locally:

```bash
mkdir sql-stylist && cd sql-stylist
npm i
npm run compile
```

1. **Create the project**

```bash
mkdir sql-stylist && cd sql-stylist
# drop the files from this repo into this folder
npm i
npm run compile
```

2. **Run in VS Code**

- Open this folder in VS Code.
- Press `F5` (Run → Start Debugging) to launch an Extension Development Host.
- Open any `.sql` file there and run **Format Document**.

3. **Make it your default SQL formatter**

- In the Extension Host window: Command Palette → `Preferences: Open Settings (JSON)` and add:

```json
{
  "[sql]": {
    "editor.defaultFormatter": "shakely-consulting.better-sql-stylist",
    "editor.formatOnSave": true
  },
  "sqlStylist.convertLineCommentsToBlock": true,
  "sqlStylist.alignAs": false
}
```

4. **Package to VSIX (optional)**

```bash
npm run package
# then install the .vsix in VS Code (Extensions → … → Install from VSIX)
```

## Options

- `sqlStylist.keywordCase` — `upper | lower | preserve` (default: `upper`)
- `sqlStylist.tabWidth` — spaces per indent (default: `4`)
- `sqlStylist.linesBetweenQueries` — blank lines between queries (default: `2`)
- `sqlStylist.convertLineCommentsToBlock` — turn `--` comment-only lines into `/* ... */` (default: `true`)
- `sqlStylist.alignAs` — pad spaces to align `AS` in SELECT lists (naive; off by default)

## Notes & Limitations

- Uses [`sql-formatter`](https://www.npmjs.com/package/sql-formatter) under the hood with the `transactsql` dialect.
- `alignAs` is a simple text pass that works best when `sql-formatter` has put one select item per line.
- Comment conversion only targets **comment-only** lines. Inline `--` after code are left as-is.

## Features

- UPPERCASE SQL keywords
- Optional AS alignment in SELECT lists
- Block‑style comment conversion
- JOIN alignment and indentation rules
- WHERE / HAVING first predicate kept inline

## License

MIT © Joe Shakely

## Dev Tips

- See logs in **View → Output → SQL Stylist**.
