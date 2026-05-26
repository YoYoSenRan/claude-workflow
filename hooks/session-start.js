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
    '在任何回复、澄清提问、读文件、跑命令或编辑前，先检查是否有 workflow skill 或项目 skill 可能适用。\n' +
    '只要有 1% 可能适用，必须用 `Skill` 工具加载当前版本；不得凭记忆或下方摘要执行。\n' +
    '任务简单、规则记得、先看一眼、先跑个命令，都不是跳过 Skill 的理由。\n' +
    'think 只负责对齐和判断；用户确认方向后进入 plan，不在 think 里实现。\n' +
    'plan 可用轻量内联计划，但加载 plan 后必须先给计划并等执行确认，不得直接写文件。\n' +
    '完成声明前必须用 verify；timeout、截断输出、无退出码都不是通过证据。\n' +
    '用户可见回复只说任务动作；不要提 Skill、技能名或"加载"，除非用户正在讨论 workflow 本身。\n' +
    '</EXTREMELY-IMPORTANT>\n\n' +
    "下方是 'using' 工作流入口全文，其他 skill 一律用 `Skill` 工具调用：\n\n";

  const sessionContext = '<workflow-routing>\n' + preamble + skillContent + '\n</workflow-routing>';

  emit({
    hookSpecificOutput: {
      hookEventName: 'SessionStart',
      additionalContext: sessionContext,
    },
  });
  return 0;
}

process.exit(main());
