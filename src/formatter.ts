// src/formatter.ts
import { format } from "sql-formatter";
import * as vscode from "vscode";
import { log } from "./log";
export type KeywordCase = "upper" | "lower" | "preserve";

export interface StylistOptions {
  keywordCase: KeywordCase;
  tabWidth: number;
  linesBetweenQueries: number;
  convertLineCommentsToBlock: boolean;
  alignAs: boolean;
  commaBeforeColumn: boolean;
  oneLineFunctionArgs: boolean;
  tightValuesTupleSpacing?: boolean;
  forceSemicolonBeforeWith?: boolean;
}

export function formatSql(input: string, opts: StylistOptions): string {
  log("Formatting through house!");
  let out = format(input, {
    language: "transactsql",
    keywordCase: opts.keywordCase,
    tabWidth: opts.tabWidth,
    linesBetweenQueries: opts.linesBetweenQueries,
  });

  // house-style passes (order matters)
  // out = forceSemicolonBeforeWith(out);
  out = uppercaseFunctions(out);
  out = uppercaseDataTypes(out);
  out = compactCaseWhenHeaders(out);
  out = compactFromFirstTable(out);
  out = unindentJoinBlock(out);
  out = compactWhereFirstPredicate(out);
  out = leftAlignJoins(out);
  out = indentJoinContinuations(out, opts.tabWidth);
  out = compactHavingFirstPredicate(out);
  out = indentDerivedTables(out, opts.tabWidth ?? 4);

  if (opts.oneLineFunctionArgs) out = collapseCommonFunctionArgs(out);
  if (opts.commaBeforeColumn) out = applyLeadingCommasToSelect(out);
  if (opts.convertLineCommentsToBlock) out = convertLineComments(out);
  if (opts.alignAs) {
    log("Aligning AS Statements.");
    out = alignAsInSelect(out);
  }

  return out;
}

export function lightHousePostProcess(
  sql: string,
  opts: StylistOptions
): string {
  let out = sql;
  // safe, visual-only tweaks
  // out = uppercaseFunctions(out);
  // out = uppercaseDataTypes(out);
  // out = compactCaseWhenHeaders(out);
  // out = compactWhereFirstPredicate(out);
  // out = compactHavingFirstPredicate(out);
  // out = compactIntoTarget(out);
  // out = leftAlignJoins(out);
  // out = indentJoinContinuations(out, opts.tabWidth);

  // // FIX: indent “SELECT * FROM (SELECT …) x” properly (works even when the "(" is on same line)
  // out = indentDerivedTablesSmart(out, opts.tabWidth);

  // // FIX: normalize two-line IF OBJECT_ID(...) / DROP TABLE ... blocks
  // out = normalizeIfDropBlocks(out);

  // if (opts.oneLineFunctionArgs) out = collapseCommonFunctionArgs(out);
  // if (opts.commaBeforeColumn) out = applyLeadingCommasToSelect(out);
  // if (opts.convertLineCommentsToBlock) out = convertLineComments(out);

  if (opts.alignAs) {
    log("Aligning AS Statements.");
    out = alignAsInSelect(out);
  }

  return out;
}

/** Convert comment-only lines that start with `--` into block comments. */
function convertLineComments(text: string): string {
  const lines = text.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const m = /^(\s*)--(.*)$/.exec(lines[i]);
    if (m) {
      const indent = m[1] ?? "";
      const content = (m[2] ?? "").trim();
      lines[i] = `${indent}/* ${content} */`;
    }
  }
  return lines.join("\n");
}

/** Naive `AS` alignment between SELECT and the next FROM. */
function alignAsInSelect(text: string): string {
  return text.replace(/SELECT([\s\S]*?)\bFROM\b/g, (match) => {
    const header = "SELECT";
    const body = match.slice(header.length);
    const lines = body.split(/\n/);

    // compute max index of " AS " across lines
    const indices = lines
      .map((l) => l.toUpperCase().indexOf(" AS "))
      .filter((i) => i >= 0);
    if (!indices.length) return match;
    const max = Math.max(...indices);

    const adjusted = lines.map((l) => {
      const idx = l.toUpperCase().indexOf(" AS ");
      if (idx < 0) return l;
      const pad = max - idx;
      return l.slice(0, idx) + " ".repeat(pad) + l.slice(idx);
    });

    return header + adjusted.join("\n");
  });
}

/** Merge accidental line breaks after JOIN so object name stays on the same line. */
function fixSplitJoinNames(text: string): string {
  // Turn any "JOIN\n  Foo" into "JOIN Foo"
  return text.replace(/\b(JOIN|APPLY)\s*\n+\s+/gi, (s) =>
    s.replace(/\s*\n+\s+/g, " ")
  );
}

/** Uppercase common T-SQL functions so they “shout” like keywords. */
function uppercaseFunctions(text: string): string {
  const fn = [
    "isnull",
    "coalesce",
    "convert",
    "cast",
    "max",
    "min",
    "sum",
    "avg",
    "count",
    "getdate",
    "dateadd",
    "datediff",
    "datename",
    "datepart",
    "iif",
    "upper",
    "lower",
  ];
  // Match the function name only when followed by "("
  const re = new RegExp(`\\b(${fn.join("|")})\\s*\\(`, "gi");
  return text.replace(re, (m) => m.toUpperCase());
}

/** Uppercase common data types. */
function uppercaseDataTypes(text: string): string {
  const types = [
    "datetime",
    "date",
    "time",
    "decimal",
    "numeric",
    "int",
    "bigint",
    "smallint",
    "tinyint",
    "bit",
    "float",
    "real",
    "money",
    "smallmoney",
    "char",
    "varchar",
    "nvarchar",
    "nchar",
    "text",
    "ntext",
    "xml",
    "uniqueidentifier",
  ];
  const re = new RegExp(`\\b(${types.join("|")})\\b`, "gi");
  return text.replace(re, (m) => m.toUpperCase());
}

/** Prefer single-line header “CASE WHEN” over split headers when it reads cleaner. */
function compactCaseWhenHeaders(text: string): string {
  return text.replace(/CASE\s*\n\s*WHEN/gi, "CASE WHEN");
}

/** Keep first table alias on the same line as FROM. */
function compactFromFirstTable(text: string): string {
  return text.replace(
    /\bFROM\s*\n\s*([A-Za-z0-9_\[\]]+\s+\w+)/gi,
    (match, grp) => {
      return `FROM ${grp}`;
    }
  );
}

/** Unindent JOIN lines and their immediate AND-continuations. */
function unindentJoinBlock(text: string): string {
  const lines = text.split(/\r?\n/);
  const isJoin = (s: string) =>
    /^\s*(LEFT|RIGHT|FULL|INNER|CROSS)\s+JOIN\b/i.test(s) ||
    /^\s*JOIN\b/i.test(s) ||
    /^\s*(OUTER|CROSS)\s+APPLY\b/i.test(s);

  const isAnd = (s: string) => /^\s*AND\b/i.test(s);

  const prevNonEmptyIndex = (i: number) => {
    for (let k = i - 1; k >= 0; k--) {
      if (lines[k].trim() !== "") return k;
    }
    return -1;
  };

  for (let i = 0; i < lines.length; i++) {
    if (isJoin(lines[i])) {
      lines[i] = lines[i].trimStart();
      continue;
    }
    if (isAnd(lines[i])) {
      const k = prevNonEmptyIndex(i);
      if (
        k >= 0 &&
        (/\bJOIN\b/i.test(lines[k]) || /\b ON \b/i.test(lines[k]))
      ) {
        lines[i] = lines[i].trimStart();
      }
    }
  }
  return lines.join("\n");
}

/** Left-align JOIN lines (but NOT APPLY; APPLY is handled by alignApplyIndentation). */
function leftAlignJoins(text: string): string {
  const lines = text.split(/\r?\n/);
  const isJoin = (s: string) =>
    /^\s*(LEFT|RIGHT|FULL|INNER)\s+JOIN\b/i.test(s) || /^\s*JOIN\b/i.test(s);
  for (let i = 0; i < lines.length; i++) {
    if (isJoin(lines[i])) lines[i] = lines[i].trimStart();
  }
  return lines.join("\n");
}

/** Inside a block, align CROSS/OUTER APPLY to the same indent as the nearest preceding FROM line. */
function alignApplyIndentation(text: string): string {
  const lines = text.split(/\r?\n/);
  let currentFromIndent: string | null = null;
  const fromRe = /^(\s*)FROM\b/i;
  const applyRe = /^(\s*)(CROSS|OUTER)\s+APPLY\b/i;

  for (let i = 0; i < lines.length; i++) {
    const f = fromRe.exec(lines[i]);
    if (f) {
      currentFromIndent = f[1];
      continue;
    }

    const a = applyRe.exec(lines[i]);
    if (a && currentFromIndent !== null) {
      lines[i] = currentFromIndent + lines[i].trimStart();
      continue;
    }
    // reset when another clause starts (rough heuristic)
    if (
      /^\s*(WHERE|GROUP\s+BY|ORDER\s+BY|UNION\b|EXCEPT\b|INTERSECT\b)\b/i.test(
        lines[i]
      )
    ) {
      currentFromIndent = null;
    }
  }
  return lines.join("\n");
}

/** Indent AND-continuations that belong to a JOIN ... ON by exactly one indent. */
function indentJoinContinuations(text: string, tabWidth: number): string {
  const indent = " ".repeat(Math.max(0, tabWidth));
  const lines = text.split(/\r?\n/);
  const isJoin = (s: string) =>
    /^\s*(LEFT|RIGHT|FULL|INNER)\s+JOIN\b/i.test(s) || /^\s*JOIN\b/i.test(s);
  const prevNonEmpty = (i: number) => {
    for (let k = i - 1; k >= 0; k--) if (lines[k].trim() !== "") return k;
    return -1;
  };
  for (let i = 0; i < lines.length; i++) {
    if (/^\s*AND\b/i.test(lines[i])) {
      const k = prevNonEmpty(i);
      if (k >= 0 && (isJoin(lines[k]) || /\b ON \b/i.test(lines[k]))) {
        lines[i] = indent + lines[i].trim();
      }
    }
  }
  return lines.join("\n");
}

/** Keep the first predicate on the same line as WHERE (single space). */
function compactWhereFirstPredicate(text: string): string {
  return text.replace(/\bWHERE\s*\n\s*/gi, "WHERE ");
}

/** Keep the first predicate on the same line as HAVING (two spaces after HAVING). */
function compactHavingFirstPredicate(text: string): string {
  return text.replace(/\bHAVING\s*\n\s*/gi, "HAVING  ");
}

/** Convert SELECT list to leading-commas style. */
function selectListLeadingCommas(text: string): string {
  return text.replace(/\bSELECT([\s\S]*?)\bFROM\b/gi, (m, body) => {
    const lines = body.split(/\r?\n/);

    // Clean up trailing commas and any existing leading commas/spaces.
    const cleaned = lines.map(
      (l: string) =>
        l
          .replace(/,\s*$/, "") // remove trailing comma at end
          .replace(/^\s*,\s*/, "") // remove existing leading comma
          .replace(/\s+$/, "") // trim right spaces
    );

    // Rebuild with leading commas for items after the first non-empty line
    const out: string[] = [];
    let seenFirst = false;
    for (const l of cleaned) {
      if (l.trim() === "") {
        out.push(l);
        continue;
      }
      if (!seenFirst) {
        out.push(l);
        seenFirst = true;
      } else {
        out.push("," + l.trimStart());
      } // leading comma, no extra space
    }
    return "SELECT" + out.join("\n") + "\nFROM";
  });
}

/** Collapse argument lists of given functions to a single line (handles nesting). */
function collapseFunctionArgsToSingleLine(text: string, fns: string[]): string {
  const upperSet = new Set(fns.map((f) => f.toUpperCase()));
  const isIdent = (c: string) => /[A-Za-z0-9_]/.test(c);
  const src = text;
  let i = 0;
  let out = "";

  while (i < src.length) {
    if (/[A-Za-z_]/.test(src[i])) {
      let j = i;
      while (j < src.length && isIdent(src[j])) j++;
      const name = src.slice(i, j).toUpperCase();

      let k = j;
      while (k < src.length && /\s/.test(src[k])) k++;

      if (upperSet.has(name) && src[k] === "(") {
        // capture balanced parentheses
        let depth = 0,
          p = k;
        do {
          const ch = src[p++];
          if (ch === "(") depth++;
          else if (ch === ")") depth--;
        } while (p <= src.length && depth > 0);

        const inside = src
          .slice(k + 1, p - 1)
          .replace(/\s*\n\s*/g, " ")
          .replace(/\s{2,}/g, " ");

        out += src.slice(i, k) + "(" + inside + ")";
        i = p;
        continue;
      }
    }
    out += src[i++];
  }
  return out;
}

/** Keep the target on the same line as INTO (handles SELECT/INSERT/OUTPUT INTO). */
function compactIntoTarget(text: string): string {
  return text.replace(/\bINTO\s*\n\s*/gi, "INTO ");
}

/** Remove spaces after the comma inside simple VALUES tuples: ('Key', Value) -> ('Key',Value). */
function tightenValuesTupleSpacing(text: string): string {
  // Only affects tuples that begin with a string literal.
  return text.replace(/\(\s*('[^']*')\s*,\s*/g, "($1,");
}

/** Force ';WITH' at start-of-line CTEs and remove blank lines before it. */
function normalizeCteWith(text: string): string {
  // 1) Any line that *starts* with WITH (optionally with stray spaces/semicolon) -> ';WITH'
  //    Anchored to line start so we won't touch table hints like "... WITH (NOLOCK)".
  text = text.replace(/^\s*;?\s*WITH\b/gim, ";WITH");
  // 2) Nuke extra blank lines immediately before a ;WITH
  text = text.replace(/\n{2,}(?=;WITH\b)/g, "\n");
  return text;
}

// --- helpers to scan safely (ignore strings/comments/brackets) ---
function stripLineComments(s: string) {
  return s.replace(/--.*$/gm, "");
}
function stripBlockComments(s: string) {
  return s.replace(/\/\*[\s\S]*?\*\//g, "");
}
function isQuote(ch: string) {
  return ch === "'";
}
function isOpenBracket(ch: string) {
  return ch === "[";
}
function isCloseBracket(ch: string) {
  return ch === "]";
}

// Net "(" - ")" on a single line, ignoring quotes/brackets
function netParenDelta(line: string): number {
  let d = 0,
    inStr = false,
    inBr = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (inStr) {
      if (c === "'" && line[i + 1] === "'") {
        i++;
        continue;
      } // escaped ''
      if (c === "'") inStr = false;
      continue;
    }
    if (inBr) {
      if (isCloseBracket(c)) inBr = false;
      continue;
    }
    if (isQuote(c)) {
      inStr = true;
      continue;
    }
    if (isOpenBracket(c)) {
      inBr = true;
      continue;
    }
    if (c === "(") d++;
    else if (c === ")") d--;
  }
  return d;
}

// Find [start, end) of SELECT list: after SELECT ... up to top-level FROM/INTO
function findSelectListRanges(
  sql: string
): Array<{ start: number; end: number }> {
  const src = stripBlockComments(sql); // comments can fool token scans
  const ranges: Array<{ start: number; end: number }> = [];
  const reSelect = /\bSELECT\b/gi;
  let m: RegExpExecArray | null;
  while ((m = reSelect.exec(src))) {
    // start right after this SELECT
    let i = m.index + m[0].length;
    // skip TOP (...) or DISTINCT etc.
    for (;;) {
      const tail = src.slice(i);
      const head =
        tail.match(
          /^\s+(TOP\b\s*\([^)]*\)|TOP\b\s+\d+|DISTINCT\b|ALL\b)/i
        )?.[0] ?? "";
      if (!head) break;
      i += head.length;
    }
    let depth = 0,
      inStr = false,
      inBr = false;
    let end = src.length;
    for (let j = i; j < src.length; j++) {
      const c = src[j],
        n = src[j + 1];
      if (inStr) {
        if (c === "'" && n === "'") {
          j++;
          continue;
        }
        if (c === "'") inStr = false;
        continue;
      }
      if (inBr) {
        if (c === "]") inBr = false;
        continue;
      }
      if (c === "'") {
        inStr = true;
        continue;
      }
      if (c === "[") {
        inBr = true;
        continue;
      }
      if (c === "(") depth++;
      else if (c === ")") depth--;

      if (depth === 0) {
        // top-level FROM or INTO ends the select list
        if (src.slice(j).match(/^(?:\s|\r?\n)+(FROM|INTO)\b/i)) {
          end = j;
          break;
        }
        // also guard against end of statement
        if (src[j] === ";") {
          end = j;
          break;
        }
      }
    }
    ranges.push({ start: i, end });
    reSelect.lastIndex = end; // continue after this SELECT list
  }
  return ranges;
}

// Leading commas only for top-level separators inside SELECT list
export function applyLeadingCommasToSelect(sql: string): string {
  const ranges = findSelectListRanges(sql);
  if (!ranges.length) return sql;

  const lines = sql.split(/\r?\n/);
  // Map char index -> line index boundaries
  const idxToLine: number[] = [];
  let acc = 0;
  for (let li = 0; li < lines.length; li++) {
    const L = lines[li].length + 1; // +1 for \n
    for (let k = 0; k < L; k++) idxToLine.push(li);
    acc += L;
  }
  function indexToLine(i: number) {
    return Math.min(idxToLine[i] ?? lines.length - 1, lines.length - 1);
  }

  for (const { start, end } of ranges) {
    let li = indexToLine(start);
    const lastLine = indexToLine(Math.max(end - 1, 0));
    let depth = 0;
    let carryComma = false;

    for (; li <= lastLine; li++) {
      // ignore comments for depth calc
      const raw = lines[li];
      const noLineCom = stripLineComments(raw);
      const noCom = stripBlockComments(noLineCom);

      // If we’re at top level, move trailing comma → leading on next line
      if (depth === 0) {
        const trailingComma = /,(?=\s*(--.*)?$)/.test(noCom);
        if (trailingComma) {
          // remove that trailing comma
          lines[li] = raw.replace(/,(?=\s*(--.*)?$)/, "");
          carryComma = true;
        } else if (carryComma) {
          // place a leading comma on the first non-empty, non-comment line
          if (noCom.trim().length) {
            lines[li] = lines[li].replace(/^(\s*)/, "$1,");
            carryComma = false;
          }
        }
      }

      // update depth from this *original* (comment-stripped) line
      depth += netParenDelta(noCom);
    }
  }
  return lines.join("\n");
}

// Collapse args of common functions to a single line *inside their ( ... )*
export function collapseCommonFunctionArgs(sql: string): string {
  const fns = [
    "ISNULL",
    "COALESCE",
    "CONVERT",
    "TRY_CONVERT",
    "CAST",
    "DATEADD",
    "DATEDIFF",
    "DATENAME",
    "FORMAT",
    "OBJECT_ID",
    "OBJECT_NAME",
    "OBJECTPROPERTY",
    "OBJECTPROPERTYEX",
    "DB_ID",
    "DB_NAME",
  ];
  const nameRe = new RegExp(`\\b(${fns.join("|")})\\s*\\(`, "gi");

  let out = "";
  let i = 0;
  while (i < sql.length) {
    nameRe.lastIndex = i;
    const m = nameRe.exec(sql);
    if (!m) {
      out += sql.slice(i);
      break;
    }

    const fnStart = m.index;
    const openParen = nameRe.lastIndex - 1; // points at "("
    // copy text before function
    out += sql.slice(i, openParen);

    // find the matching ')'
    let j = openParen + 1,
      depth = 1,
      inStr = false,
      inBr = false;
    while (j < sql.length && depth > 0) {
      const c = sql[j],
        n = sql[j + 1];
      if (inStr) {
        if (c === "'" && n === "'") {
          j += 2;
          continue;
        }
        if (c === "'") {
          inStr = false;
          j++;
          continue;
        }
        j++;
        continue;
      }
      if (inBr) {
        if (c === "]") inBr = false;
        j++;
        continue;
      }
      if (c === "'") {
        inStr = true;
        j++;
        continue;
      }
      if (c === "[") {
        inBr = true;
        j++;
        continue;
      }
      if (c === "(") {
        depth++;
        j++;
        continue;
      }
      if (c === ")") {
        depth--;
        j++;
        if (depth === 0) break;
        continue;
      }
      j++;
    }
    const inner = sql.slice(openParen + 1, j - 0 /* j now at ')' */);

    // compact: remove newlines, trim spaces around commas, normalize spaces
    const compact = inner
      .replace(/\/\*[\s\S]*?\*\//g, " ") // keep block comments spacing sane
      .replace(/\s*--.*$/gm, " ") // drop line comments inside call
      .replace(/\s*\r?\n\s*/g, " ") // kill newlines
      .replace(/\s*,\s*/g, ", ") // commas like ", "
      .replace(/\s+/g, " ") // collapse runs of spaces
      .trim();

    out += m[0].replace(/\s+$/, "") + compact + ")"; // function name + "(" + args + ")"
    i = j + 1;
  }
  return out;
}

// Force ";WITH" (no blank line before)
export function forceSemicolonBeforeWith(sql: string): string {
  return sql
    .replace(/\r?\n\s*;\s*\r?\n\s*WITH\b/gi, "\n;WITH")
    .replace(/(^|\r?\n)\s*WITH\b/g, "\n;WITH"); // if someone forgot semicolon
}

function indentDerivedTables(sql: string, tabWidth: number): string {
  const lines = sql.split(/\r?\n/);

  const openRe = /^\s*(FROM|JOIN|CROSS\s+APPLY|OUTER\s+APPLY|APPLY)\b.*\(\s*$/i;
  const closeRe = /^\s*\)\s*(?:AS\s+)?([A-Z0-9_#\[\]\."]+)?\s*;?\s*$/i; // captures alias if present
  const aliasOnlyRe = /^\s*(?:AS\s+)?([A-Z0-9_#\[\]\."]+)\s*;?\s*$/i;

  const space = (n: number) => " ".repeat(n);
  const currentIndent = (s: string) => s.match(/^\s*/)?.[0].length ?? 0;

  type Block = { baseIndent: number };
  const stack: Block[] = [];

  const out: string[] = [];
  let i = 0;

  while (i < lines.length) {
    let raw = lines[i];
    let line = raw.replace(/\s+$/, ""); // trim end only

    // CLOSE: align ')' with the opener and optionally pull alias from next line
    if (stack.length && closeRe.test(line)) {
      const { baseIndent } = stack.pop()!;
      let aliasMatch = line.match(closeRe)?.[1];

      // If no alias on this line, see if next line is purely an alias and pull it up.
      if (!aliasMatch && i + 1 < lines.length) {
        const next = lines[i + 1];
        const m = next && next.match(aliasOnlyRe);
        if (m) {
          aliasMatch = m[1];
          i += 1; // consume alias line
        }
      }

      const rebuilt =
        space(baseIndent) + ")" + (aliasMatch ? ` AS ${aliasMatch}` : "");
      out.push(rebuilt);
      i += 1;
      continue;
    }

    // INSIDE a derived block → add one extra indent level
    if (stack.length) {
      // If the current line *opens* a new derived table, push after we re-emit
      if (openRe.test(line)) {
        const innerBase = currentIndent(line);
        out.push(space(innerBase) + line.trim());
        stack.push({ baseIndent: innerBase });
        i += 1;
        continue;
      }

      const { baseIndent } = stack[stack.length - 1];
      // one extra level inside the derived table
      const rebuilt = space(baseIndent + tabWidth) + line.trim();
      out.push(rebuilt);
      i += 1;
      continue;
    }

    // OPEN: remember base indent (indent of this line) and push
    if (openRe.test(line)) {
      const baseIndent = currentIndent(line);
      out.push(space(baseIndent) + line.trim());
      stack.push({ baseIndent });
      i += 1;
      continue;
    }

    // default: pass through
    out.push(line);
    i += 1;
  }
  return out.join("\n");
}

/** Normalize:
 * IF OBJECT_ID('X') IS NOT NULL
 * DROP TABLE [X];
 * (remove blank lines and ensure single semicolon)
 */
function normalizeIfDropBlocks(text: string): string {
  // collapse extra blanks and enforce two-line pattern + trailing semicolon
  return text.replace(
    /(IF\s+OBJECT_ID\([^\n]+?\)\s+IS\s+NOT\s+NULL)[\s;]*\r?\n+\s*(DROP\s+TABLE\s+\[[^\]\n]+\])\s*;?/gi,
    (_m, ifPart, dropPart) =>
      `${String(ifPart).trim()}\n${String(dropPart).trim()};`
  );
}

/** Derived-table indent that also handles "FROM ( SELECT ..." on the SAME line. */
function indentDerivedTablesSmart(sql: string, tabWidth: number): string {
  const lines = sql.split(/\r?\n/);
  const space = (n: number) => " ".repeat(Math.max(0, n));
  const getIndent = (s: string) => s.match(/^\s*/)?.[0].length ?? 0;

  type Block = { baseIndent: number; parenDepth: number };
  const stack: Block[] = [];
  let globalDepth = 0;

  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    const noLine = stripLineComments(raw);
    const noCom = stripBlockComments(noLine);
    const indent = getIndent(raw);

    // Does this line begin a FROM/JOIN/APPLY and increase paren depth (i.e., FROM ( ... ) ) ?
    const opensContext =
      /\b(FROM|JOIN|CROSS\s+APPLY|OUTER\s+APPLY|APPLY)\b/i.test(noCom);
    const delta = netParenDelta(noCom);
    const depthBefore = globalDepth;
    const depthAfter = depthBefore + delta;

    // Start a derived-table block if we see a FROM/JOIN/APPLY and net "(" opened on this line
    if (opensContext && delta > 0) {
      stack.push({ baseIndent: indent, parenDepth: depthBefore + 1 });
      lines[i] = raw.trimEnd(); // keep original indent / text
      globalDepth = depthAfter;
      continue;
    }

    if (stack.length) {
      const top = stack[stack.length - 1];

      // If this line is a closing ) [AS alias] — outdent to base indent
      if (
        depthAfter <= top.parenDepth - 1 &&
        /\)\s*(AS\s+\S+)?\s*;?\s*$/i.test(noCom.trim())
      ) {
        lines[i] = space(top.baseIndent) + noCom.trim();
        stack.pop();
        globalDepth = depthAfter;
        continue;
      }

      // Otherwise indent one level more than the opener
      lines[i] = space(top.baseIndent + tabWidth) + raw.trim();
      globalDepth = depthAfter;
      continue;
    }

    globalDepth = depthAfter;
  }

  return lines.join("\n");
}
