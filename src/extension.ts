// src/extension.ts
import * as vscode from "vscode";
import {
  formatSql as houseFormat,
  StylistOptions,
  lightHousePostProcess,
} from "./formatter";
import { formatWithPoorMans } from "./pmtsql";
import { initLog, log } from "./log";

export function activate(context: vscode.ExtensionContext) {
  initLog(context);

  function formatWithYardiSupport(
    text: string,
    formatFn: (sql: string) => string
  ): string {
    const lines = text.split(/\r?\n/);
    const result: string[] = [];
    let sqlBuffer: string[] = [];
    let inIgnoreBlock = false;

    function flushSqlBuffer() {
      if (sqlBuffer.length > 0) {
        const sqlBlock = sqlBuffer.join("\n");
        try {
          const formatted = formatFn(sqlBlock);
          const formattedLines = formatted.split(/\r?\n/);
          result.push(...formattedLines);
        } catch (err) {
          // If formatting fails, keep original
          result.push(...sqlBuffer);
        }
        sqlBuffer = [];
      }
    }

    for (const line of lines) {
      const trimmedUpper = line.trim().toUpperCase();

      // Check if we're entering an ignore block
      if (
        trimmedUpper.startsWith("//FILTER") ||
        trimmedUpper.startsWith("//FORMAT")
      ) {
        flushSqlBuffer();
        inIgnoreBlock = true;
        result.push(line);
        continue;
      }

      // Check if we're exiting an ignore block
      if (
        trimmedUpper.startsWith("//END FILTER") ||
        trimmedUpper.startsWith("//END FORMAT")
      ) {
        inIgnoreBlock = false;
        result.push(line);
        continue;
      }

      // If we're in an ignore block, preserve everything as-is
      if (inIgnoreBlock) {
        result.push(line);
        continue;
      }

      // Check if line starts with // (other Yardi comment lines)
      if (line.startsWith("//")) {
        flushSqlBuffer();
        result.push(line);
      } else {
        // Accumulate regular SQL lines
        sqlBuffer.push(line);
      }
    }

    // Flush any remaining SQL
    flushSqlBuffer();

    return result.join("\n");
  }

  function runFormat(text: string, cfg: vscode.WorkspaceConfiguration): string {
    const engine = cfg.get<string>("engine", "house");
    const options = {
      keywordCase: cfg.get<"upper" | "lower" | "preserve">(
        "keywordCase",
        "upper"
      ),
      tabWidth: cfg.get<number>("tabWidth", 4),
      linesBetweenQueries: cfg.get<number>("linesBetweenQueries", 2),
      convertLineCommentsToBlock: cfg.get<boolean>(
        "convertLineCommentsToBlock",
        true
      ),
      alignAs: cfg.get<boolean>("alignAs", false),
      commaBeforeColumn: cfg.get<boolean>("commaBeforeColumn", false),
      oneLineFunctionArgs: cfg.get<boolean>("oneLineFunctionArgs", true),
      forceSemicolonBeforeWith: cfg.get<boolean>(
        "forceSemicolonBeforeWith",
        true
      ),
    } as StylistOptions;

    const formatFn = (sql: string) => {
      log("Engine: Poor Man's T-SQL (pmtsql).");
      let formatted = formatWithPoorMans(sql, options.tabWidth);
      if (cfg.get<boolean>("postProcessHouse", true)) {
        formatted = lightHousePostProcess(formatted, options);
      }
      return formatted;
    };

    return formatWithYardiSupport(text, formatFn);
  }

  log("Better SQL Stylist activated.");

  const provider: vscode.DocumentFormattingEditProvider = {
    provideDocumentFormattingEdits(document) {
      const cfg = vscode.workspace.getConfiguration("sqlStylist");

      // Check if there's an active selection
      const editor = vscode.window.activeTextEditor;
      let range: vscode.Range;
      let text: string;

      if (editor && !editor.selection.isEmpty) {
        // Format selection only
        range = new vscode.Range(editor.selection.start, editor.selection.end);
        text = document.getText(range);
        log(`Formatting selection (${range.start.line}-${range.end.line})`);
      } else {
        // Format entire document
        const start = new vscode.Position(0, 0);
        const end = document.lineAt(document.lineCount - 1).range.end;
        range = new vscode.Range(start, end);
        text = document.getText();
        log("Formatting entire document");
      }

      let formatted: string;

      try {
        formatted = runFormat(text, cfg);
      } catch (err: any) {
        log(`Format error: ${err?.message ?? String(err)}`);
        vscode.window.showErrorMessage(
          "Better SQL Stylist: Failed to format document. See output."
        );
        return [];
      }

      if (formatted.trim() === text.trim()) {
        log("No changes after formatting");
        return [];
      }

      log(
        `Formatted ${document.fileName} (chars: ${text.length} -> ${formatted.length}).`
      );
      return [vscode.TextEdit.replace(range, formatted)];
    },
  };

  context.subscriptions.push(
    vscode.languages.registerDocumentFormattingEditProvider(
      { language: "sql" },
      provider
    )
  );

  // Also register for .txt files (for Yardi files)
  context.subscriptions.push(
    vscode.languages.registerDocumentFormattingEditProvider(
      { language: "plaintext", pattern: "**/*.txt" },
      provider
    )
  );
}

export function deactivate() {}
