// src/pmtsql.ts
// Some builds attach to `globalThis.PoorMansTSqlFormatterJS`, others export directly.
// We shim a `window` for Bridge.NET builds that expect it.
declare const global: any;
// @ts-ignore
if (!global.window) global.window = global;

const PM = require("../vendor/PoorMansTSqlFormatterJSLib.js");

// Minimal option mapping; you can expand if you find more knobs in that lib.
export type PMOptions = Partial<{
  IndentString: string; // e.g., "    "
  KeywordCase: "upper" | "lower" | "preserve";
  BreakOnSemicolon: boolean; // etc, if supported by your build
}>;

export function formatWithPoorMans(sql: string, opts: PMOptions = {}): string {
  const res = PM.Format(sql.length, opts, sql);
  if (!res || res.status !== "formatted") {
    throw new Error("Poor Man’s formatter failed.");
  }
  return res.outputSqlText; // <-- use the text, not the HTML
}
