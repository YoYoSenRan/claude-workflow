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

function stripFrontmatter(text) {
  if (!text.startsWith('---')) return text;
  const closeIdx = text.indexOf('\n---', 3);
  if (closeIdx === -1) return text;
  return text.slice(closeIdx + 4).replace(/^\s*\n/, '');
}

function main() {
  if (!fs.existsSync(META_SKILL)) {
    emit({ continue: true });
    return 0;
  }

  let rawContent;
  try {
    rawContent = fs.readFileSync(META_SKILL, 'utf8');
  } catch (_err) {
    emit({ continue: true });
    return 0;
  }

  const skillContent = stripFrontmatter(rawContent);

  const preamble =
    '<EXTREMELY-IMPORTANT>\n' +
    '你有 Claude Workflow。\n' +
    '必须遵守：\n' +
    '1. 回复、澄清、读文件、跑命令或编辑前，必须先按下方 using 判断是否需要 Skill。\n' +
    '2. 任何 Skill 适用时，必须用 Skill 工具加载当前版本；不得凭记忆、摘要或经验代替。\n' +
    '3. 用户可见回复只说任务动作，不提 Skill、技能名或"加载"，除非用户正在讨论 workflow 本身。\n' +
    '4. using 是唯一入口；具体流程以被加载的 Skill 内容为准。\n' +
    '5. 如果这里和 using 冲突，以 using 为准。\n' +
    '</EXTREMELY-IMPORTANT>\n\n' +
    "下方是 'using' 工作流入口全文：\n\n";

  const sessionContext = '<workflow-routing>\n' + preamble + skillContent + '\n</workflow-routing>';

  emit({ hookSpecificOutput: { hookEventName: 'SessionStart', additionalContext: sessionContext } });
  return 0;
}

process.exit(main());
