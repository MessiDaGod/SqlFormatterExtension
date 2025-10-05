// src/extension.ts
import * as vscode from "vscode";
import {
  formatSql as houseFormat,
  StylistOptions,
  lightHousePostProcess,
} from "./formatter";
import { formatWithPoorMans } from "./pmtsql";
import { initLog, log } from "./log";

// let channel: vscode.OutputChannel;

// function optionsFromConfig(cfg: vscode.WorkspaceConfiguration): StylistOptions {
//   return {
//     keywordCase: cfg.get<"upper" | "lower" | "preserve">(
//       "keywordCase",
//       "upper"
//     ),
//     tabWidth: cfg.get<number>("tabWidth", 4),
//     linesBetweenQueries: cfg.get<number>("linesBetweenQueries", 2),
//     convertLineCommentsToBlock: cfg.get<boolean>(
//       "convertLineCommentsToBlock",
//       true
//     ),
//     alignAs: cfg.get<boolean>("alignAs", false),
//     commaBeforeColumn: cfg.get<boolean>("commaBeforeColumn", false),
//     oneLineFunctionArgs: cfg.get<boolean>("oneLineFunctionArgs", true),
//     forceSemicolonBeforeWith: cfg.get<boolean>(
//       "forceSemicolonBeforeWith",
//       true
//     ),
//   };
// }

export function activate(context: vscode.ExtensionContext) {
  initLog(context);
  log("Better SQL Stylist activated.");

  const provider: vscode.DocumentFormattingEditProvider = {
    provideDocumentFormattingEdits(document) {
      const start = new vscode.Position(0, 0);
      const end = document.lineAt(document.lineCount - 1).range.end;
      const fullRange = new vscode.Range(start, end);
      const text = document.getText();

      const cfg = vscode.workspace.getConfiguration("sqlStylist");
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

      let formatted = text;

      try {
        if (engine === "pmtsql") {
          log("Engine: Poor Man's T-SQL (pmtsql).");
          formatted = formatWithPoorMans(text, options.tabWidth);
          if (cfg.get<boolean>("postProcessHouse", true)) {
            formatted = lightHousePostProcess(formatted, options);
          }
        } else {
          log("Engine: House formatter.");
          formatted = houseFormat(text, options);
        }
      } catch (err: any) {
        log(`Format error: ${err?.message ?? String(err)}`);
        vscode.window.showErrorMessage(
          "Better SQL Stylist: Failed to format document. See output."
        );
        return [];
      }

      if (formatted.trim() === text.trim()) return [];
      log(
        `Formatted ${document.fileName} (chars: ${text.length} -> ${formatted.length}).`
      );
      return [vscode.TextEdit.replace(fullRange, formatted)];
    },
  };

  context.subscriptions.push(
    vscode.languages.registerDocumentFormattingEditProvider(
      { language: "sql" },
      provider
    )
  );
}

export function deactivate() {}
