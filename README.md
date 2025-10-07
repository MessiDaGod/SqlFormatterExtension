# A Better SQL Stylist — VS Code Formatter for T‑SQL

An opinionated formatter that gets your `.sql` and `.txt` (Yardi) files to look clean: **UPPERCASE keywords**, clean indentation, optional **`AS` alignment**, and **block‑style comments**.

Powered by **Poor Man's T-SQL Formatter** with custom house-style post-processing for the perfect balance of readability and consistency.

## Quick Start

1. **Install from Marketplace**
   👉 [A Better SQL Stylist on Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=shakely-consulting.better-sql-stylist)

Or, if you prefer, clone and build locally:

```bash
git clone https://github.com/MessiDaGod/SqlFormatterExtension.git
cd SqlFormatterExtension
npm i
npm run compile
```

2. **Run in VS Code**

- Open this folder in VS Code.
- Press `F5` (Run → Start Debugging) to launch an Extension Development Host.
- Open any `.sql` or `.txt` file and run **Format Document** (or select text and run **Format Selection**).

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

## Features

- **Poor Man's T-SQL Formatter engine** — Battle-tested T-SQL formatting with extensive dialect support
- **UPPERCASE SQL keywords** — Makes SQL more readable
- **Optional AS alignment** — Align `AS` keywords in SELECT lists
- **Block‑style comment conversion** — Convert `--` to `/* ... */`
- **JOIN alignment and indentation** — Clean, consistent JOIN formatting
- **WHERE / HAVING first predicate inline** — Compact, readable predicates
- **Selection formatting** — Format only selected text or entire document
- **Yardi .txt file support** — Special handling for Yardi SQL files
- **Dual engine support** — Choose between Poor Man's T-SQL (default) or built-in house formatter

### Yardi File Support

When working with Yardi `.txt` files, the formatter intelligently preserves special Yardi syntax:

- **Ignores lines starting with `//`** — Lines like `//Select`, `//Detail`, `//End Select` are preserved exactly as-is
- **Ignores `//FILTER` blocks** — Everything between `//FILTER` and `//END FILTER` is preserved (case-insensitive)
- **Ignores `//FORMAT` blocks** — Everything between `//FORMAT` and `//END FORMAT` is preserved (case-insensitive)
- **Formats the SQL between special markers** — Only the actual SQL code gets formatted

Example Yardi file:

```sql
//Select
SELECT * FROM Users
//FORMAT
    badly  formatted   SQL   that   stays   this   way
//END FORMAT
SELECT
    FirstName,
    LastName
FROM Employees
//FILTER
  preserve this exactly
//END FILTER
WHERE Active = 1
//End Select
```

After formatting, the `//FORMAT` and `//FILTER` blocks remain untouched, while the rest gets formatted cleanly.

## Options

- `sqlStylist.engine` — `pmtsql | house` — choose formatter engine (default: `pmtsql`)
  - **`pmtsql`** (default) — Uses [Poor Man's T-SQL Formatter](http://architectshack.com/PoorMansTSqlFormatter.ashx) for robust T-SQL formatting
  - **`house`** — Uses sql-formatter library with custom rules
- `sqlStylist.postProcessHouse` — Apply house-style cleanup after pmtsql formatting (default: `true`)
- `sqlStylist.keywordCase` — `upper | lower | preserve` (default: `upper`)
- `sqlStylist.tabWidth` — spaces per indent (default: `4`)
- `sqlStylist.linesBetweenQueries` — blank lines between queries (default: `2`)
- `sqlStylist.convertLineCommentsToBlock` — turn `--` comment-only lines into `/* ... */` (default: `true`)
- `sqlStylist.alignAs` — pad spaces to align `AS` in SELECT lists (default: `false`)
- `sqlStylist.commaBeforeColumn` — use leading commas in SELECT lists (default: `false`)
- `sqlStylist.oneLineFunctionArgs` — collapse common function args to single line (default: `true`)

## Usage

### Format Entire Document

- Open a `.sql` or `.txt` file
- Right-click → **Format Document**
- Or use the keyboard shortcut (usually `Shift+Alt+F` on Windows/Linux, `Shift+Option+F` on Mac)

### Format Selection Only

- Select the SQL code you want to format
- Right-click → **Format Selection**
- Or use **Format Document** while text is selected

## Notes & Limitations

- Uses [Poor Man's T-SQL Formatter](http://architectshack.com/PoorMansTSqlFormatter.ashx) by default for battle-tested T-SQL formatting.
- Alternative `house` engine uses [`sql-formatter`](https://www.npmjs.com/package/sql-formatter) with the `transactsql` dialect.
- `alignAs` is a simple text pass that works best when the formatter has put one select item per line.
- Comment conversion only targets **comment-only** lines. Inline `--` after code are left as-is.
- Yardi special blocks (`//FILTER`, `//FORMAT`) are case-insensitive.

## Publishing Updates

To publish a new version to the marketplace:

```bash
# Update version in package.json, then:
npm run publish
# or
node install.js publish
```

## License

AGPL-3.0-only © Shakely Consulting

## Dev Tips

- See logs in **View → Output → Better SQL Stylist**.
- Use `npm run watch` during development for auto-compilation
- Run `npm run ext:reinstall` to test changes locally
