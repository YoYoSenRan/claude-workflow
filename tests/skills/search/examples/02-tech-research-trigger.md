# 02 — 技术调研专项触发 (TR-1 至 TR-7)

## Trigger Prompt

```
调研 2026 Node.js 生态 ORM 选型, 对比 Prisma / Drizzle / Kysely / TypeORM
```

(包含"调研" + "选型" + "对比" — 应触发技术调研专项叠加)

## Pre-conditions

- 同 01
- 当前工作目录有 `package.json` (用于 TR-6 团队栈契合验证)

## Expected Behavior Checklist

### 模式叠加
- [ ] Claude 识别为技术调研 (含 ORM / 选型 / 对比 等关键词)
- [ ] 在 P0-P5 基础上叠加 TR-1 至 TR-7

### TR-1 数据源优先级
- [ ] 优先尝试 context7 MCP (官方文档), 而非 web_search 拿 Medium 二手文
- [ ] 退一步用 GitHub repo 主页

### TR-2 子代理强制采集
- [ ] 每候选 (Prisma/Drizzle/...) 都报告:
  - [ ] stars
  - [ ] last_commit 日期
  - [ ] latest_release
  - [ ] issues open/total
  - [ ] license
  - [ ] bundle/install size
  - [ ] maintainer
- [ ] last_commit > 12 月的标 ⚠️ 维护风险

### TR-3 Code Snippets
- [ ] 子代理笔记含 `## Code Snippets` 段
- [ ] 每候选 1-3 段官方代码示例 (非二手 blog)

### TR-4 决策矩阵
- [ ] 报告含"决策矩阵"表
- [ ] 必含行: 维护活跃度 / Stars / License / Bundle size / 学习曲线 / **团队栈契合** / 性能 benchmark / 主要风险

### TR-5 实测建议
- [ ] 报告末尾 (引文注册表前) 含"实测建议 (Minimum PoC)"段
- [ ] 给出 install 命令 + hello-world 调用
- [ ] 列 3 个观察点
- [ ] 预计耗时

### TR-6 本地栈感知
- [ ] Claude 读了 `package.json`
- [ ] 决策矩阵"团队栈契合"行据此填 (Node 版本 / 现有 ORM / TypeScript 等)
- [ ] 不推荐与现有栈冲突的方案 (或在风险列写明迁移成本)

## Anti-Patterns

- ✗ 用 Medium / dev.to 二手 blog 当主源
- ✗ 推荐库不报 last_commit 日期
- ✗ 决策矩阵缺"团队栈契合"行
- ✗ 推荐 React-only lib 给 Vue 项目
- ✗ 忽视 AGPL 等病毒式 license
- ✗ 报告无 PoC 命令

## 跑法

```
1. cd 进任一 Node 项目 (有 package.json)
2. 开新会话
3. 粘 Trigger Prompt
4. 对照 checklist 打勾
```
