import * as vscode from 'vscode';
import { formatSql, StylistOptions } from './formatter';

let channel: vscode.OutputChannel;

export function activate(context: vscode.ExtensionContext) {
  channel = vscode.window.createOutputChannel('SQL Stylist');
  channel.appendLine('SQL Stylist activated.');

  const provider: vscode.DocumentFormattingEditProvider = {
    provideDocumentFormattingEdits(document) {
      const start = new vscode.Position(0, 0);
      const end = document.lineAt(document.lineCount - 1).range.end;
      const fullRange = new vscode.Range(start, end);
      const text = document.getText();

      const cfg = vscode.workspace.getConfiguration('sqlStylist');
      const options: StylistOptions = {
        keywordCase: cfg.get<'upper' | 'lower' | 'preserve'>('keywordCase', 'upper'),
        tabWidth: cfg.get<number>('tabWidth', 4),
        linesBetweenQueries: cfg.get<number>('linesBetweenQueries', 2),
        convertLineCommentsToBlock: cfg.get<boolean>('convertLineCommentsToBlock', true),
        alignAs: cfg.get<boolean>('alignAs', false),
      };

      try {
        const formatted = formatSql(text, options);
        if (formatted.trim() === text.trim()) return [];
        channel.appendLine(`Formatted ${document.fileName} (chars: ${text.length} -> ${formatted.length}).`);
        return [vscode.TextEdit.replace(fullRange, formatted)];
      } catch (err: any) {
        const msg = `Format error: ${err?.message ?? String(err)}`;
        channel.appendLine(msg);
        vscode.window.showErrorMessage('SQL Stylist: Failed to format document. See "SQL Stylist" output.');
        return [];
      }
    },
  };

  context.subscriptions.push(
    vscode.languages.registerDocumentFormattingEditProvider({ language: 'sql' }, provider)
  );
}

export function deactivate() {}
