---
name: subagent
description: 将实现方案拆分给独立子代理逐个执行，每个任务做完后按确定性分级审查
---

# 分任务执行方案

<HARD-GATE>
审查级别由任务确定性决定（见 README.md 任务表）。无论哪个级别，有没解决的问题都不许进入下一个任务。

需要审查时，逐条核对 task 文件中的场景——场景说了的必须实现，没说的不该加。需求符合度先过，才能开始代码质量检查。
</HARD-GATE>

## 触发

- 已有批准的书面方案
- 任务相对独立，能按 task spec 分别完成
- 当前环境支持分配独立代理
- 需要干净上下文、分级审查或较长任务链

如果任务强依赖当前会话上下文、步骤紧耦合，或用户明确要求自己逐步做，使用 execute。

## 先做

1. 确认是否需要 worktree；已经隔离则跳过。
2. 找到方案目录；用户未指定时，从 `docs/plans/` 中找有待办任务的 README.md。
3. 读取 README.md 和下一个未完成 task。
4. 如果已有完成项，从第一个未完成任务继续。

## 审查等级

| 确定性 | 审查方式 | 适用场景 |
|---|---|---|
| **高** | 实现者自检 + 主线程快速确认 diff | Markdown、配置、单文件明确改动 |
| **中** | spec review only | 多文件代码、有逻辑判断 |
| **低** | spec review + quality review | 架构、跨系统、新设计 |

所有任务完成后做最终全局 review。

## 执行

对每个任务：

1. 读 task spec。
2. 把完整 task 文本粘进 `references/implementer-prompt.md`，派实现者 Agent。
3. 实现者提问时，补充上下文后重新派发。
4. 实现者完成后，确定本任务的 diff 命令：未提交用 `git diff`，已暂存用 `git diff --staged`，已有提交范围用 `git diff <base>..<head>`。
5. 按确定性审查：
   - 高：主线程看 diff，对照场景确认。
   - 中：派 spec reviewer。
   - 低：派 spec reviewer，通过后派 quality reviewer。
6. 审查通过后，更新 README.md 状态和 task checkbox。
7. 继续下一个任务，不在任务之间问"是否继续"。

所有任务完成后：

1. 派最终 reviewer 检查跨任务一致性。
2. 调用 verify。
3. 只有提交、PR、合并、保留、丢弃时进入 finish。

README.md 是进度源；TodoWrite 只辅助当前会话。

## 代理状态

| 状态 | 动作 |
|---|---|
| DONE | 进入审查 |
| DONE_WITH_CONCERNS | 先处理影响正确性或范围的疑虑，再审查 |
| NEEDS_CONTEXT | 补上下文后重新派发 |
| BLOCKED | 分析阻塞原因；补上下文、换模型、拆任务，或回到用户 |

## 模板

- `references/implementer-prompt.md` - 实现者
- `references/spec-reviewer-prompt.md` - 需求符合度检查
- `references/code-quality-reviewer-prompt.md` - 代码质量检查

## 停止

- 方案本身有缺口。
- 代理阻塞且无法通过补上下文、换模型、拆任务解决。
- 审查发现未满足场景。
- 验证失败。

## 输出

每个任务完成后记录：
- 任务名
- 审查方式
- 验证结果
- README.md 状态更新

## 禁止

- 不许同时分配多个执行代理。
- 不许让代理自己去读方案目录；必须粘贴完整 task spec。
- 不许跳过需求符合度检查。
- 不许需求符合度没过就查代码质量。
- 不许什么都不改就让同一模型重试。
- 不许只更新 TodoWrite 而不更新 README.md。
- 不许默认提交、push 或创建 PR。
