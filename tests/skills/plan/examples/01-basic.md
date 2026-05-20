# 01 — 基础触发

## Trigger Prompt
```
帮我写个用户登录功能的实现计划, 用 JWT + bcrypt, Express 后端
```

## Pre-conditions
- 当前 cwd 在一个 Node.js / Express 项目
- Claude Code 重启或 hot-reload 已生效
- docs/plans/ 不存在或为空

## Expected Behavior Checklist
- [ ] 触发: Claude 自动 invoke /plan skill
- [ ] 宣告: "我用 plan skill 写实现计划"
- [ ] 步 1-2: 范围扫 + 文件结构定 (明确改哪些文件)
- [ ] 步 3: 任务粒度 2-5 分钟/步
- [ ] 步 4: Plan 头部含 Goal / Architecture / Tech Stack
- [ ] 步 5: 每 task 含 Files + Steps(checkbox) + 完整代码块 + Run 命令 + Expected 输出
- [ ] 步 6: 占位符扫 (无 TBD / TODO / 模糊动词)
- [ ] 步 7: 自审清单过一遍
- [ ] 步 8: 文件落到 `docs/plans/YYYY-MM-DD-user-login.md`
- [ ] 步 8: 提示后续 "用 executing skill 执行?"

## Anti-Patterns (不应出现)
- ✗ 直接给"几步流程", 不写文件
- ✗ task 含 `TODO` / `TBD` / `// 类似 Task N`
- ✗ task step 不给完整代码 (只写 "实现登录")
- ✗ 不给 Run 命令 + Expected
- ✗ task 粒度 >5 分钟 (整个 Task 1 干完一个大模块)
- ✗ 文件路径含变量 (`path/to/<somewhere>`)
- ✗ 跳过自审, 直接交付
- ✗ 主动加 TDD test step 到"写文档/调样式"类不适用场景 (本例属应用代码, OK 加)

## 跑法
1. 开新 Claude 会话, cd 进任意 Node 项目
2. 粘 Trigger Prompt
3. 对照 checklist 打勾
4. 检查 docs/plans/ 下产物

## 备用测试 case 想法
- 反向 (清晰一行): "把 src/auth.ts 第 12 行 if 改成 switch" → **不应**触发
- 反向 (太早): "我想加个登录功能, 但还没想好用啥方案" → **不应**触发 (该走 think 先对齐方案)
- 边界 (已有 plan): "按 docs/plans/2026-05-20-foo.md 继续完善 Task 3" → **不应**触发 (该走 executing)
- TDD 豁免: "写个 README 介绍这个模块" → 触发但 task 不加 test step
