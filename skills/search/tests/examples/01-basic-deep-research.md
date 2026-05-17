# 01 — 基础深度调研流程

## Trigger Prompt

```
帮我调研一下 2026 主流向量数据库的现状, 重点对比 Pinecone / Weaviate / Qdrant / Milvus
```

## Pre-conditions

- Claude Code 已重启或 hot-reload 已生效
- `~/.claude/skills/search` symlink 指向本仓库
- web_search 工具可用

## Expected Behavior Checklist

### 触发
- [ ] Claude 自动激活 /search skill (无需 `/search` 显式调用)
- [ ] 进入 Standard 模式 (多实体对比)

### P0
- [ ] 询问深度 / 视角 / 输出语言三件事 (一次提问)
- [ ] 报告 `[P0] mode=Standard, AS_OF=YYYY-MM-DD, 子代理=yes`

### P1
- [ ] 分解 4-5 个独立任务
- [ ] 每任务有"专家角色" (如"数据库引擎研究员")
- [ ] 派遣 ≤3 并发, 多于 3 任务分批

### P2
- [ ] 并行派出子代理
- [ ] 收回的笔记符合 Sources / Findings / Gaps 三段
- [ ] 每条 Finding 带 `[Xn]` 源号

### P3 注册表 + Quality Gates
- [ ] 主代理建引文注册表, 编号 [1]-[N]
- [ ] 报告统计: Approved 数 / 域名数 / official 占比
- [ ] 阈值: ≥10 sources, ≥5 域名, ≥30% official

### P4-P5
- [ ] 报告含: 摘要 / 正文 / 反向争议 / 引文注册表
- [ ] 每事实带 `[n]`, 每节标信心度
- [ ] P5 自审 ≥3 issue
- [ ] 类型 B (实质对立) 进"核心争议", 类型 A/C silent fix

## Anti-Patterns (不应出现)

- ✗ 主代理直接读 raw search 结果作为报告素材
- ✗ 编 URL (注册表外的引文)
- ✗ Dropped 源在 P4 复活
- ✗ 凑"核心争议 ≥3 条"硬塞缺源问题
- ✗ Quality Gates 不达标却继续起草

## 跑法

```
1. 开新 Claude Code 会话
2. 粘 Trigger Prompt
3. 走完全流程
4. 对照 checklist 打勾
5. 任一项失败 → 记 issue, 回去修 SKILL.md
```
