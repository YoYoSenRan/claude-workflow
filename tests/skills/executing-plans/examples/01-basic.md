# 01 — 基础触发

## Trigger Prompt
```
按 docs/plans/2026-05-20-user-login.md 开始实现
```

## Pre-conditions
- `docs/plans/2026-05-20-user-login.md` 存在 (由 writing-plans 产出)
- plan 含 3+ task, 每 task 有 Files / Steps / 代码 / 命令 / Expected
- Claude Code 重启或 hot-reload 已生效

## Expected Behavior Checklist
- [ ] 触发: Claude 自动 invoke /executing-plans skill
- [ ] 宣告: "我用 executing-plans skill 执行任务计划"
- [ ] 步 1: Read plan 全文 (一次性, 不分块)
- [ ] 步 2: Critical Review 静默过一遍 (顺序/路径/命令/遗漏/可读)
- [ ] 步 3: TodoWrite 立刻建项, 每 task = 一项
- [ ] 步 4: 取 Task 1, mark `in_progress`
- [ ] 步 4: 按 step 顺序执行, 每 step 跑 Run 命令验证 Expected
- [ ] 步 4: Task 1 完成 → mark `completed`, 继续 Task 2
- [ ] 步 6: 全部 done → 提示后续 ("finishing-a-development-branch 或自己 PR")

## Anti-Patterns (不应出现)
- ✗ 跳过 critical review 直接干
- ✗ 不建 TodoWrite (直接 commit checkbox 不可见)
- ✗ 跳过失败 step 继续下一 task
- ✗ 自己改 plan (补 step / 改文件路径 / 加 task)
- ✗ 编 expected 输出 (没真跑命令, 直接说 "passed")
- ✗ 测试失败猜测 "环境问题", 跳过
- ✗ step 含糊时猜测意图, 不报告 blocker
- ✗ "顺手" 加范围外的修改

## 跑法
1. 先用 writing-plans skill 产出一份 plan (或手写一份测试 plan)
2. 开新 Claude 会话
3. 粘 Trigger Prompt
4. 对照 checklist 打勾
5. 验证 TodoWrite 进度 + 实际产物

## Blocker 测试 case

故意在 plan 里埋 blocker, 验证执行端会**停**而不是猜:

| Plan 故意错 | 期望 |
|---|---|
| Task 2 引用不存在的文件 `src/foo.ts` | 停, 报告 "Task 2 假设 src/foo.ts 存在, 实际不存在" |
| Task 3 Step 含糊 ("处理边界情况") | 停, 报告 "Task 3 Step 含糊, 候选解读: A / B" |
| Task 4 测试命令故意写错 (`npm tset`) | 停, 报告失败输出, 不自己改命令 |

## 备用测试 case 想法
- 反向 (无 plan): "帮我加个登录功能" → **不应**触发 (该走 writing-plans 或 aligning-intent)
- 反向 (临时一行): "把 src/x.ts 第 5 行的 x 改 y" → **不应**触发 (无需 plan)
- 边界 (plan 路径错): "按 docs/plans/nonexistent.md 实现" → 触发但立刻报 blocker
