/* eslint-disable @typescript-eslint/no-explicit-any */
// src/pmtsql.ts

// VS Code Node host has `global`, browsery libs want `window`.
declare const global: any;
(global as any).window = (global as any).window ?? global;

// Load the minified Poor Man's T-SQL JS at runtime so it executes and registers globals.
// Use require (CommonJS) so it actually runs; a bare ESM "import" can be tree-shaken.
try {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  require("../vendor/PoorMansTSqlFormatterJS.min.js");
} catch (e) {
  // Swallow here; we’ll throw a clearer error later if API isn’t present.
}

function ns() {
  const g = global as any;
  const JS = g.PoorMansTSqlFormatterJS || g.window?.PoorMansTSqlFormatterJS;
  const Lib = g.PoorMansTSqlFormatterLib || g.window?.PoorMansTSqlFormatterLib;
  const Format = g.Format || JS?.Format || JS?.format || g.window?.Format;
  return { g, JS, Lib, Format };
}

export function formatWithPoorMans(sql: string, indentSize = 4): string {
  const Format = findFormatFn();
  if (typeof Format !== "function") {
    throw new Error("Poor Man's T-SQL: global Format(...) not found.");
  }

  const options = {
    IndentString: " ".repeat(Math.max(0, indentSize)),
    SpacesPerTab: indentSize,
    MaxLineWidth: 999,
    // 👇 prevent breaking lists
    ExpandCommaLists: false,
    ExpandInLists: false,
    // keep these off too (just to be explicit)
    TrailingCommas: false,
    SpaceAfterExpandedComma: false,
  };

  const result = Format(sql.length, options, sql);
  if (!result || result.status !== "formatted") {
    throw new Error("Poor Man's T-SQL returned an unexpected result.");
  }
  return result.outputSqlText;
}

export function formatWithPoorMans(sql: string, indentSize = 4): string {
  const { JS, Lib, Format } = ns();
  const options = { IndentString: " ".repeat(Math.max(0, indentSize)) };

  // Path A: some builds expose a helper Format(len, options, sql)
  if (typeof Format === "function") {
    const r = Format(sql.length, options, sql);
    if (r?.outputSqlText) return r.outputSqlText;
    if (r?.outputSqlHtml) return r.outputSqlHtml; // fallback
  }

  // Path B: construct the pipeline manually from the Lib namespace
  // Tokenize -> Parse -> Format
  const tokCtor = Lib?.Tokenizers?.TSqlStandardTokenizer;
  const parseCtor =
    Lib?.Parsers?.TSqlStandardParser || Lib?.Parsers?.TSqlStandardParserManager;
  const fmtCtor =
    Lib?.Formatters?.TSqlStandardFormatter ||
    Lib?.Formatters?.ObfuscatingFormatter ||
    Lib?.Formatters?.SqlFormatter; // try a few likely names

  if (tokCtor && parseCtor && fmtCtor) {
    const tokenizer = new tokCtor();
    const parser = new parseCtor();
    const formatter = new fmtCtor(options);
    const tokens = tokenizer.TokenizeSQL(sql);
    const parsed = parser.ParseSQL
      ? parser.ParseSQL(tokens)
      : parser.Parse(tokens);
    const output =
      formatter.FormatSQLTree?.(parsed) ??
      formatter.Format?.(parsed) ??
      formatter.FormatSQL?.(parsed);
    if (typeof output === "string") return output;
  }

  // Last resort: dump what we see for debugging.
  const seen = {
    hasJS: !!JS,
    hasLib: !!Lib,
    libKeys: Lib ? Object.keys(Lib) : [],
    jsKeys: JS ? Object.keys(JS) : [],
  };
  throw new Error(
    "Poor Man's T-SQL: API not found after loading library. " +
      JSON.stringify(seen)
  );
}
