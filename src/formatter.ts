import { format } from 'sql-formatter';

export type KeywordCase = 'upper' | 'lower' | 'preserve';

export interface StylistOptions {
  keywordCase: KeywordCase;
  tabWidth: number;
  linesBetweenQueries: number;
  convertLineCommentsToBlock: boolean;
  alignAs: boolean;
}

export function formatSql(input: string, opts: StylistOptions): string {
  let out = format(input, {
    language: 'transactsql',
    keywordCase: opts.keywordCase,
    tabWidth: opts.tabWidth,
    linesBetweenQueries: opts.linesBetweenQueries,
  });

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
      const indent = m[1] ?? '';
      const content = (m[2] ?? '').trim();
      lines[i] = `${indent}/* ${content} */`;
    }
  }
  return lines.join('\n');
}

/** Naive `AS` alignment between SELECT and the next FROM. */
function alignAsInSelect(text: string): string {
  return text.replace(/SELECT([\s\S]*?)\bFROM\b/g, (match) => {
    const header = 'SELECT';
    const body = match.slice(header.length);
    const lines = body.split(/\n/);

    // compute max index of " AS " across lines
    const indices = lines.map(l => l.toUpperCase().indexOf(' AS ')).filter(i => i >= 0);
    if (!indices.length) return match;
    const max = Math.max(...indices);

    const adjusted = lines.map(l => {
      const idx = l.toUpperCase().indexOf(' AS ');
      if (idx < 0) return l;
      const pad = max - idx;
      return l.slice(0, idx) + ' '.repeat(pad) + l.slice(idx);
    });

    return header + adjusted.join('\n');
  });
}
