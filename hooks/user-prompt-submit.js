#!/usr/bin/env node
/**
 * UserPromptSubmit hook
 *
 * 作用: 每条用户消息前注入一行短提醒,把 using 入口门留在最近上下文。
 * SessionStart 注入的完整路由会随上下文增长 / 压缩被稀释,多轮后模型
 * 漂移——跳过 using 直接答或直接动手。本 hook 只补「skill 加载前」那段
 * 空白:不重发全文(省 token),不抢「答案 vs 动手」判断。
 *
 * 短指针内容写死在此,不读 using/SKILL.md —— 它该稳定,不随全文变;
 * 全文真相源仍在 SessionStart。
 *
 * 失败兜底: 任何异常输出 {continue: true},永不阻断会话。
 */

'use strict';

const REMINDER =
  '有 Claude Workflow。回复或动手前,先按 using 路由判断是否需要 Skill;' +
  '适用就用 Skill 工具加载当前版本,不凭记忆或摘要代替。' +
  '不依赖项目代码的解释或闲聊直接答;要读项目代码判断的走只读分析。';

function emit(obj) {
  process.stdout.write(JSON.stringify(obj) + '\n');
}

let input = '';
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    emit({
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        additionalContext: REMINDER,
      },
    });
  } catch (_err) {
    emit({ continue: true });
  }
});
