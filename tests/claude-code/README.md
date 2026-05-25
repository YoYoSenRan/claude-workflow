# Skill 行为测试

superpowers `tests/claude-code` 风格的行为测试（断言原语借鉴自 [obra/superpowers](https://github.com/obra/superpowers/tree/main/tests/claude-code)）。用无头 `claude -p` 真跑本插件，断言模型行为。数据驱动：场景写在 `scenarios.tsv`，加场景=加一行。

## 原理

- `--plugin-dir <repo>` 加载**当前工作副本**——测未提交的改动，不用重装。
- `--no-session-persistence` 每次全新隔离上下文。
- **每条场景在临时 sandbox 目录（cwd）里跑**，插件经 `--plugin-dir` 从真仓库加载。破坏性 prompt（丢弃/提交）只作用于 throwaway 目录，**不碰真仓库**。
- `--max-budget-usd`（环境变量 `CW_BUDGET`，默认 0.5）限每次花费。
- 跨平台超时：`timeout`/`gtimeout`/无（靠预算兜底）。

与 `npm run validate`（结构 lint，确定性、秒级）互补：validate 测结构，这里测**行为**。

## 跑

```bash
npm run test:skills                              # 全部场景，每条 1 次
bash tests/claude-code/run-skill-tests.sh -n 5   # 每条跑 5 次，看通过率
bash tests/claude-code/run-skill-tests.sh --tier 1   # 只跑 Tier 1（高价值核心）
bash tests/claude-code/run-skill-tests.sh -t G4      # 只跑某条
CW_BUDGET=1 bash tests/claude-code/run-skill-tests.sh # 调高预算防截断
```

## 场景表 scenarios.tsv

制表符分隔，7 列：`id  tier  assert  expect  seed  flags  prompt`

- **assert**：
  - `skill` / `not_skill` / `no_skill` — 解析 stream-json 的 Skill 调用（**结构铁证**，路由/负向用这个）
  - `contains` / `not_contains` — 查回复文本正则（弱代理）
  - `judge` — **LLM 裁判**按 `expect` 里的白话判据判 PASS/FAIL（语义闸 G* 用这个，比正则准）
- **expect**：skill 名（可正则，如 `claude-workflow:(plan|think)`）或文本正则
- **seed**：`none` / `git` / `readme` / `plan`（sandbox 预置内容）
- **flags**：`-` 或 `info`（info=只报通过率，不计入失败，用于已知弱点/易 flaky 项）

覆盖四类：路由命中（R*）、负向/过度触发（N*）、闸门合规（G*）、多插件撞车（X*）。Tier 1 是高价值核心（高危闸 + 过度触发 + 撞车）。

## 非确定性

LLM 输出有方差。**用 `-n N` 多跑看通过率，别拿单次当结论。** 改 skill 前后各跑一遍对比通过率，就能看出某次改动有没有让某个闸滑坡。`info` 项（如分析类路由、撞车）天然 flaky，只观察不当门禁。

## 裁判校准（重要）

`judge` 用一个**中立 claude**（不加载本插件）按判据打分。裁判本身也是 LLM，有过度通过偏见——**信 judge 场景之前必须先校准裁判**。校准已固化成金标准样本集，不用手敲：

```bash
npm run test:judge                              # 每条样本判 1 次
bash tests/claude-code/run-judge-calibration.sh -n 5   # 每条判 5 次看裁判稳定度
bash tests/claude-code/run-judge-calibration.sh -t G4  # 只校准某条判据的样本
```

`judge-fixtures.tsv` 给每条 `judge` 判据配了已知 `PASS`/`FAIL` 的回答样本（判据按 `id` 从 `scenarios.tsv` 取，不复制）。runner 喂样本给 `judge`，验证裁决和 `expect` 一致。**全 PASS = 裁判可信**；判错 = 判据太松或裁判漂移，按提示收紧 `scenarios.tsv` 里对应判据措辞后重测。

里头特意放了 `trap-*` 样本：嘴上提了「验证 / 谨慎 / 确认」等合规关键词，实质照样违规。裁判若被关键词骗着判 `PASS`，正好暴露过度通过偏见。

**改判据或加新 `judge` 场景后，必须重跑 `test:judge` 重新校准**；裁判失准时 `test:skills` 的 G\* 结果都不可信。加样本=往 `judge-fixtures.tsv` 加一行。

## 加场景

往 `scenarios.tsv` 加一行即可。需要新 sandbox 预置时，在 `run-skill-tests.sh` 的 `seed_sandbox` 里加一个 case。辅助函数见 `test-helpers.sh`。
