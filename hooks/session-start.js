#!/usr/bin/env node
/**
 * SessionStart hook
 *
 * 作用: 在会话 startup / clear / compact 时,把 using meta-skill
 * 的内容注入到 Claude 上下文。单文件 Node.js 实现,真·跨平台
 * (不需要 bash / cmd polyglot 技巧)。
 *
 * 输出格式: Claude Code 约定的 JSON 结构 —
 *   {
 *     "hookSpecificOutput": {
 *       "hookEventName": "SessionStart",
 *       "additionalContext": "<注入文本>"
 *     }
 *   }
 *
 * 失败兜底: meta-skill 文件不存在或读不到时,输出 {continue: true} —
 * 永远不阻断会话。
 */

'use strict';

const fs = require('fs');
const path = require('path');

const SCRIPT_DIR = __dirname;
const PLUGIN_ROOT = path.resolve(SCRIPT_DIR, '..');
const META_SKILL = path.join(PLUGIN_ROOT, 'skills', 'using', 'SKILL.md');

function emit(obj) {
  process.stdout.write(JSON.stringify(obj) + '\n');
}

function main() {
  if (!fs.existsSync(META_SKILL)) {
    emit({ continue: true });
    return 0;
  }

  let skillContent;
  try {
    skillContent = fs.readFileSync(META_SKILL, 'utf8');
  } catch (_err) {
    emit({ continue: true });
    return 0;
  }

  const preamble =
    '已加载 Claude Workflow skill 路由规则。\n\n' +
    "**下方是 'using' meta-skill 的全文 — " +
    "这是当前会话的工作流入口。其他 skill 一律用 'Skill' 工具调用。**\n\n";

  const sessionContext = '<EXTREMELY_IMPORTANT>\n' + preamble + skillContent + '\n</EXTREMELY_IMPORTANT>';

  emit({
    hookSpecificOutput: {
      hookEventName: 'SessionStart',
      additionalContext: sessionContext,
    },
  });
  return 0;
}

process.exit(main());
