import * as vscode from "vscode";

let channel: vscode.OutputChannel | undefined;

export function initLog(context: vscode.ExtensionContext) {
  if (!channel) {
    channel = vscode.window.createOutputChannel("Better SQL Stylist");
    context.subscriptions.push(channel);
  }
  return channel;
}

export function log(msg: string) {
  channel?.appendLine(msg);
}

export function getChannel() {
  return channel;
}
