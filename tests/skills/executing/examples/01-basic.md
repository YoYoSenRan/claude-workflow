# 01 — 基础触发

## 触发提示词
```
按 docs/plans/2026-05-20-user-login.md 开始实现
```

## 前置条件
- `docs/plans/2026-05-20-user-login.md` 存在（由 plan 产出）
- plan 含 3+ 任务，每个任务有 Files / Steps / 代码 / 命令 / Expected
- Claude Code 已重启或 hot-reload 生效

## 预期行为清单
- [ ] 触发：Claude 自动调用 /executing skill
- [ ] 宣告：「我用 executing skill 执行任务计划」
- [ ] 步 1：Read plan 全文（一次性，不分块）
- [ ] 步 2：Critical Review 静默过一遍（顺序/路径/命令/遗漏/可读）
- [ ] 步 3：TodoWrite 立刻建项，每个任务 = 一项
- [ ] 步 4：取 Task 1，mark `in_progress`
- [ ] 步 4：按 step 顺序执行，每个 step 跑 Run 命令验证 Expected
- [ ] 步 4：Task 1 完成 → mark `completed`，继续 Task 2
- [ ] 步 6：全部 done → 提示后续（「finishing-a-development-branch 或自己 PR」）

## 反模式（不应出现）
- ✗ 跳过 critical review 直接干
- ✗ 不建 TodoWrite（直接提交 checkbox 不可见）
- ✗ 跳过失败 step 继续下一个任务
- ✗ 自己改 plan（补 step / 改文件路径 / 加任务）
- ✗ 编 expected 输出（没真跑命令，直接说「passed」）
- ✗ 测试失败猜测「环境问题」，跳过
- ✗ step 含糊时猜测意图，不报告阻塞点
- ✗ 「顺手」加范围外的修改

## 跑法
1. 先用 plan skill 产出一份 plan（或手写一份测试 plan）
2. 开一个新的 Claude 会话
3. 粘贴触发提示词
4. 对照清单打勾
5. 验证 TodoWrite 进度 + 实际产物

## 阻塞点测试用例

故意在 plan 里埋阻塞点，验证执行端会**停**而不是猜：

| Plan 故意错 | 期望 |
|---|---|
| Task 2 引用不存在的文件 `src/foo.ts` | 停，报告「Task 2 假设 src/foo.ts 存在，实际不存在」 |
| Task 3 Step 含糊（「处理边界情形」） | 停，报告「Task 3 Step 含糊，候选解读：A / B」 |
| Task 4 测试命令故意写错（`npm tset`） | 停，报告失败输出，不自己改命令 |

## 备用测试用例想法
- 反向（无 plan）：「帮我加个登录功能」 → **不应**触发（该走 plan 或 think）
- 反向（临时一行）：「把 src/x.ts 第 5 行的 x 改 y」 → **不应**触发（无需 plan）
- 边界（plan 路径错）：「按 docs/plans/nonexistent.md 实现」 → 触发但立刻报阻塞点
