import { format } from "sql-formatter";

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
  // 0) Base pass
  let out = format(input, {
    language: "transactsql",
    keywordCase: opts.keywordCase,
    tabWidth: opts.tabWidth,
    linesBetweenQueries: opts.linesBetweenQueries,
  });

  // 1) Structural reshaping
  out = compactFromFirstTable(out);
  out = fixSplitJoinNames(out);
  out = compactIntoTarget(out);
  out = leftAlignJoins(out); // JOIN at column 0
  out = indentJoinContinuations(out, opts.tabWidth); // AND ... under ON by one indent
  out = alignApplyIndentation(out); // CROSS/OUTER APPLY aligned with FROM
  // 1c) CTE header normalization
  if (opts.forceSemicolonBeforeWith) {
    out = normalizeCteWith(out); // <- makes  ;WITH  and removes blank line before it
  }
  // 1b) SELECT list style
  if (opts.commaBeforeColumn) {
    out = selectListLeadingCommas(out);
  }

  // 2) Clause headers
  out = compactWhereFirstPredicate(out);
  out = compactHavingFirstPredicate(out);

  // 3) Readability
  out = compactCaseWhenHeaders(out);

  // 4) Casing
  out = uppercaseFunctions(out);
  out = uppercaseDataTypes(out);

  // 5) Function args collapse
  if (opts.oneLineFunctionArgs) {
    out = collapseFunctionArgsToSingleLine(out, [
      "ISNULL",
      "CONVERT",
      "COALESCE",
      "MIN",
      "MAX",
      "SUM",
    ]);
  }

  // 5b) VALUES tuple spacing
  if (opts.tightValuesTupleSpacing) {
    out = tightenValuesTupleSpacing(out);
  }

  // 6) Comments
  if (opts.convertLineCommentsToBlock) {
    out = convertLineComments(out);
  }

  // 7) Optional alignment last
  if (opts.alignAs) {
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
