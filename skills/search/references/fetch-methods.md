# 抓取方法清单

P2 阶段子代理用本文档处理网页/PDF/GitHub/历史快照抓取。WebFetch 失败时按代理级联走, 不要重试 WebFetch。

## 代理级联 (核心)

所有非 GitHub 普通网页都按此顺序:

```
第 1 站  WebFetch (Claude 内置)
         ↓ 失败 (403 / 429 / Cloudflare / 空响应 / 登录墙)
第 2 站  curl -sL "https://r.jina.ai/{URL}"
         ↓ 失败
第 3 站  curl -sL "https://defuddle.md/{URL}"
         ↓ 失败
第 4 站  curl -sL "https://web.archive.org/web/2025*/{URL}"
         (Wayback 历史快照)
         ↓ 失败
         标 ✗ 受限, 进缺口段"访问失败"
```

**判定失败标准**:
- HTTP 4xx/5xx 状态码
- 返回内容 < 5 行
- 内容含 "Sign in" / "Subscribe" / "Continue reading" / "Just a moment" / "Verifying you are human" 等登录/Cloudflare 拦截文案
- WebFetch 报 "402" / "Access denied"

**重试边界**: 同一 URL 同一方法最多打 2 次 (第 1 次 + 1 次重试), 失败立刻走下一站。第 3 次起视为死磕, 禁止。

## GitHub 专项

GitHub 页面 HTML 渲染重, 走专用通道, 不走代理级联:

```bash
# 1. Raw 文件 (无 rate limit, 最快)
curl -sL "https://raw.githubusercontent.com/{user}/{repo}/{branch}/{path}"

# 2. gh CLI (自带认证, 高 rate limit, 适合元数据)
gh api repos/{owner}/{repo}                          # 仓库元数据 (stars/forks/license)
gh api repos/{owner}/{repo}/commits?per_page=1       # 最后提交
gh api repos/{owner}/{repo}/releases/latest          # 最新发布
gh api 'repos/{owner}/{repo}/issues?state=all&per_page=1' --jq '.[0]'  # issue 抽样
gh api 'search/issues?q=repo:{owner}/{repo}+is:open' --jq '.total_count'  # 开放 issue 数
```

GitHub issue 评论 / discussion 等非 raw 内容才回退到代理级联。

## PDF 处理

调研常遇 PDF — Thoughtworks Tech Radar / arXiv 论文 / 政府报告。三选一:

### 远程 PDF (优先)

```bash
# Jina 内置 PDF 解析, 返回 Markdown
curl -sL "https://r.jina.ai/{pdf_url}"
```

### 本地工具 (Jina 失败时)

```bash
# 下载 + 文本提取 (快, 适合纯文本 PDF)
curl -sL "{pdf_url}" -o /tmp/x.pdf
pdftotext -layout /tmp/x.pdf -
# 要求: brew install poppler

# 高质量 (适合带表格/学术论文)
marker_single /tmp/x.pdf --output_dir /tmp/
# 要求: pip install marker-pdf
```

### 长 PDF 截断规则

整文 > 500 行时:
- 头部 100 行 (摘要/引言)
- 尾部 50 行 (结论)
- 正文按关键词 grep 关键段
- 不要全文塞回主代理 — 违反笔记蒸馏铁律

## 历史快照 (Wayback Machine)

当原站已下线 / 改版 / 全链反爬时, 走 archive.org:

```bash
# 查最近可用快照
curl -sL "https://archive.org/wayback/available?url={URL}"
# 返回 JSON 含最近快照 timestamp + URL

# 拉快照内容
curl -sL "https://web.archive.org/web/{timestamp}/{URL}"
```

注: 快照可能不是最新内容, 笔记里务必标 `⚠ 快照: {YYYY-MM-DD}`。

## 失败标记规约 (写入笔记来源段)

每个源标 1 个状态字段:

| 标签 | 含义 | 入注册表? | 权威度影响 |
|---|---|---|---|
| `✓ 畅通` | WebFetch 直拉成功 | ✓ | 无 |
| `⚠ 代理` | r.jina.ai / defuddle.md 拿到 | ✓ | 自动 -1 (转手) |
| `⚠ 快照` | archive.org 历史快照 | ✓ | 自动 -1 (转手) + 标快照日期 |
| `✗ 受限` | 全链失败 | ✗ | 不计, 进缺口段 |

**示例**:
```
[X1] Mozilla — MDN React Hooks | https://... | 类型: 官方 | 日期: 2026-03 | 权威: 10 | 状态: ✓ 畅通
[X2] 掘金 — useEffect 深入 | https://... | 类型: 社区 | 日期: 2025-08 | 权威: 5 | 状态: ⚠ 代理 (r.jina.ai)
[X3] Stack Overflow Q | https://... | 类型: 社区 | 日期: 2024-02 | 权威: 4 | 状态: ⚠ 快照 (2024-08-15)
```

`✗ 受限` 的源不出现在来源段, 进缺口段:
```
## 缺口
- 访问失败: LinkedIn 公司页 (反爬), Crunchbase 融资数据 (登录墙)
```

## 反模式

- ✗ 子代理对同一 URL 同一方法打 ≥3 次 (烧 token 不解决问题, 立即走下一站)
- ✗ 代理拿到内容后主代理在 P4 起草时不标 ⚠ (掩盖转手风险)
- ✗ archive 快照不标快照日期 (读者误以为最新数据)
- ✗ 把 `Just a moment...` (Cloudflare 拦截页) 当真实内容存入笔记
- ✗ 微信公众号 / 飞书私域文档 — 调研场景几乎不涉, 真遇到了让用户提供链接以外的备份

## 不在本 skill 覆盖范围

以下场景请用户介入或换工具, search skill 不自动处理:

- 私域文档 (飞书/微信公众号原文/企业 wiki) — 让用户提供 PDF 或 markdown 备份
- 登录态内容 (LinkedIn 个人页、内部 Slack) — 让用户截图/复制粘贴
- 反爬 captcha (Crunchbase, Google Scholar 深页) — 标 ✗ 受限, 报告里明说
- 付费数据库 (Statista / Bloomberg 收费版) — 同上

## 服务可用性预警

| 服务 | 风险 |
|---|---|
| r.jina.ai | 商业服务有 rate limit, 大量并发可能限流 |
| defuddle.md | 小服务, 偶发宕机 |
| archive.org | 偶发被限速 / 部分 URL 没快照 |
| gh CLI | 需用户已登录 (`gh auth status` 检查) |

**任一服务连续 3 次空响应** → 跳过, 直接走下一站, 不在该服务上死磕。
