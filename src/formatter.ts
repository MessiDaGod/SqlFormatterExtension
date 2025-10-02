import { format } from "sql-formatter";

export type KeywordCase = "upper" | "lower" | "preserve";

export interface StylistOptions {
  keywordCase: KeywordCase;
  tabWidth: number;
  linesBetweenQueries: number;
  convertLineCommentsToBlock: boolean;
  alignAs: boolean;
}

export function formatSql(input: string, opts: StylistOptions): string {
  let out = format(input, {
    language: "transactsql",
    keywordCase: opts.keywordCase,
    tabWidth: opts.tabWidth,
    linesBetweenQueries: opts.linesBetweenQueries,
  });

  // House-style post passes
  out = fixSplitJoinNames(out); // e.g., "LEFT JOIN\nCONTRACT" -> "LEFT JOIN CONTRACT"
  out = uppercaseFunctions(out); // MAX/MIN/ISNULL/GETDATE/CONVERT/CAST/etc.
  out = uppercaseDataTypes(out); // DATETIME/DATE/DECIMAL/NUMERIC/etc.
  out = compactCaseWhenHeaders(out); // "CASE\nWHEN" -> "CASE WHEN" where safe
  out = compactFromFirstTable(out);

  if (opts.convertLineCommentsToBlock) {
    out = convertLineComments(out);
  }

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
