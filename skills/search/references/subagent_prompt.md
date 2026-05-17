# 子代理派遣模板

P2 阶段, 主代理用本模板派遣并行子代理。把占位符 `{...}` 填上后整段作为子代理的 prompt。

## 模板

```
你是深度调研流水线的子代理。

## 角色
{专家角色, 如 "TLS 指纹研究员" / "AI 浏览器自动化分析师"}

## 目标
{一句话调查目标}

## AS_OF
{YYYY-MM-DD} — 超过 18 个月的资料视为可能过时, 标 [unverified] 或降信心度

## 搜索查询 (先用这些, 不够再扩)
1. "{query 1}"
2. "{query 2}"
3. "{query 3}"

## 深度
{DEEP — 用 WebFetch 拉 2-3 篇关键全文 / SCAN — snippet 够用}

## 输出格式 (整段返回, 别加客套话)

# Task {ID}: {主题}

## Sources
[X1] {作者/机构} — {标题} | URL | type: {official/academic/secondary-industry/journalism/community/other} | date: YYYY-MM-DD | auth: 1-10
[X2] ...
(Standard 4-8 条 / Lightweight 3-5 条; 按首次出现编号, X 是任务字母如 A/B/C)

## Findings (≤15 条, 每条单句 + 源号)
- {单句事实} [X1][X3]
- ...

## Deep Reads (DEEP 任务才有, 2-3 篇)
### [X1] {标题}
- 关键数据: ...
- 核心观点: ...
- 反例/限制: ...

## Gaps
- 搜了但没找到: ...
- 反向解释候选: ...
- 时效风险: ...

## 自评信心度
整体: 高/中/低 — 一句理由

## (技术调研专项 — Tech Research Mode 开启时必填)

### GitHub / Package 元数据 (每候选一条)
{库名}:
  stars: N
  last_commit: YYYY-MM-DD       (>12 月标 ⚠️ 维护风险)
  latest_release: vX.Y.Z @ YYYY-MM-DD
  issues: {open}/{total}
  license: MIT/Apache-2.0/AGPL-3.0/...
  size: {bundle/install size}
  maintainer: {公司/个人/基金会}

数据源优先级: context7 MCP → GitHub repo → npm/pypi/crates.io → web_search 兜底。

### Code Snippets (每候选 1-3 段, 整任务 ≤5 段)
### [Xn] {库名} 基础调用
```{lang}
{≤15 行核心调用示例, 从官方文档/作者代码抠}
```
铁律: 只抠官方文档/作者 README/example 的代码, 不抓 Medium/dev.to 二手教程。

## 铁律
- ✗ 不许编 URL — 只用 WebSearch/WebFetch 实际访问过的链接
- ✗ 不许凭印象写数字 — 找不到就标 [unverified]
- ✗ 不许把整页 raw HTML 塞回来 — 蒸馏成 findings
- ✓ 每条 finding 必须带 [Xn] 源号
- ✓ 数字带日期 + 单位
- ✓ 厂商自家营销页注意打折 — 多源交叉
- ✓ 整份笔记不超过 ~2000 中文字 (~3000 英文 words)

开始。
```

## 派遣建议

- **并发 ≤3** — 子代理太多易超 API 限速
- **角色分工** — 同一主题不同切面 (如调研"反爬": 一个查检测端、一个查工具端、一个查云服务)
- **来源多样** — 不同任务尽量让搜索域不重叠
- **DEEP 慎用** — 每次 WebFetch 耗 token, 默认 SCAN, 关键源才 DEEP
