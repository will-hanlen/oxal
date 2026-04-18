const vscode = require('vscode');

function getIndent(line) {
  const match = line.match(/^( *)/);
  return match ? match[1].length : 0;
}

function findFoldRanges(doc) {
  const lineCount = doc.lineCount;
  const ranges = [];

  for (let i = 0; i < lineCount - 1; i++) {
    const currentLine = doc.lineAt(i);
    const nextLine = doc.lineAt(i + 1);
    const currentIndent = getIndent(currentLine.text);
    const nextIndent = getIndent(nextLine.text);
    const nextTrimmed = nextLine.text.trim();

    if (nextIndent === currentIndent + 2 && nextTrimmed === '::') {
      // Find the end of the indented block
      let end = i + 1;
      for (let j = i + 2; j < lineCount; j++) {
        const line = doc.lineAt(j);
        if (line.isEmptyOrWhitespace) {
          end = j;
          continue;
        }
        if (getIndent(line.text) >= nextIndent) {
          end = j;
        } else {
          break;
        }
      }
      ranges.push(new vscode.FoldingRange(i, end, vscode.FoldingRangeKind.Region));
    }
  }

  return ranges;
}

async function hoonCollapse(editor) {
  if (!editor) return;
  const ranges = findFoldRanges(editor.document);
  if (ranges.length === 0) return;

  // Unfold everything first, then fold our ranges
  await vscode.commands.executeCommand('editor.unfoldAll');

  // Fold each range by selecting the start line
  const startLines = ranges.map(r => r.start);
  await vscode.commands.executeCommand('editor.fold', {
    selectionLines: startLines
  });
}

function activate(context) {
  // Register our folding range provider so VS Code uses our fold regions
  const foldingProvider = vscode.languages.registerFoldingRangeProvider(
    { scheme: 'file', pattern: '**/*.hoon' },
    { provideFoldingRanges(doc) { return findFoldRanges(doc); } }
  );
  context.subscriptions.push(foldingProvider);

  const command = vscode.commands.registerCommand('hoonCollapse.collapse', () => {
    hoonCollapse(vscode.window.activeTextEditor);
  });
  context.subscriptions.push(command);

  const onOpen = vscode.workspace.onDidOpenTextDocument((doc) => {
    if (doc.languageId === 'hoon' || doc.fileName.endsWith('.hoon')) {
      setTimeout(() => {
        const editor = vscode.window.activeTextEditor;
        if (editor && editor.document === doc) {
          hoonCollapse(editor);
        }
      }, 500);
    }
  });
  context.subscriptions.push(onOpen);

  // Run on already-open hoon file at activation
  const editor = vscode.window.activeTextEditor;
  if (editor && (editor.document.languageId === 'hoon' || editor.document.fileName.endsWith('.hoon'))) {
    setTimeout(() => hoonCollapse(editor), 500);
  }
}

function deactivate() {}

module.exports = { activate, deactivate };
