# 抓取失败降级

WebFetch 失败时按以下级联顺序切换抓取方式, 不在同一节点重复重试超过 1 次。

## 代理级联

```
WebFetch (Claude 内置)
  ↓ 失败
curl -sL "https://r.jina.ai/{URL}"
  ↓ 失败
curl -sL "https://defuddle.md/{URL}"
  ↓ 失败
curl -sL "https://archive.org/wayback/available?url={URL}"  (拿快照 URL)
curl -sL "{快照 URL}"
  ↓ 全失败
笔记标 ✗ 受限, 进缺口段 (不进数据来源段)
```

## 判定失败

- HTTP 4xx / 5xx
- 返回 < 5 行
- 含 "Sign in" / "Subscribe" / "Continue reading" / "Just a moment" / "Verifying you are human"
- WebFetch 报 "402" / "Access denied"

## 专用通道

**GitHub** (走 raw 或 gh CLI, 跳过代理级联):
```bash
curl -sL "https://raw.githubusercontent.com/{user}/{repo}/{branch}/{path}"

gh api repos/{owner}/{repo}                          # 元数据
gh api repos/{owner}/{repo}/commits?per_page=1       # 最后提交
gh api repos/{owner}/{repo}/releases/latest          # 最新发布
gh api 'search/issues?q=repo:{owner}/{repo}+is:open' --jq '.total_count'
```

**PDF**:
```bash
# 远程 PDF (优先)
curl -sL "https://r.jina.ai/{pdf_url}"

# 本地 (Jina 失败)
curl -sL "{pdf_url}" -o /tmp/x.pdf
pdftotext -layout /tmp/x.pdf -
```

## 重试边界

同一 URL 同一方法最多调用 2 次 (1 次原始 + 1 次重试)。第 3 次起立即切换下一级联节点。

## 状态标记 (仅子代理笔记内部使用, 主代理报告输出禁用)

| 标 | 含义 |
|---|---|
| `✓ 畅通` | WebFetch 直拉成功 |
| `⚠ 代理 (服务名)` | Jina / Defuddle 拿到 |
| `⚠ 快照 (日期)` | archive.org 快照 |
| `✗ 受限` | 全链失败 |

**主代理起草报告时翻译成自然语言**, 报告正文禁止出现 ✓⚠✗ 符号:
- ⚠ 代理 → "二手摘录"
- ⚠ 快照 → "历史快照, 已停更"
- ✗ 受限 → 进"盲点"段

## 服务可用性

| 服务 | 风险 |
|---|---|
| r.jina.ai | 商业服务有 rate limit, 大量并发会限流 |
| defuddle.md | 小服务, 偶发宕 |
| archive.org | 部分 URL 没快照 |
| gh CLI | 需用户已登录 (`gh auth status`) |

任一服务连续 3 次空响应, 当前会话内跳过该服务, 直接切换下一级联节点。

## 跳过抓取的源

以下源直接标 ✗ 受限, 不再尝试任何级联节点:

- 私域文档 (飞书 / 微信 / 企业 wiki)
- 强反爬 (LinkedIn / Crunchbase 深页 / 知乎登录态)
- 付费数据库 (Statista / Bloomberg)
