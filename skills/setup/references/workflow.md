# Setup Workflow Reference

本 reference 只在执行 setup 扫描和生成候选时读取。维护本插件全局 skill 时不要读取。

## Claude Code 支持边界

只生成 Claude Code 原生识别的路径，按加载方式区分：

| 路径 | 加载方式 | 适用 |
|---|---|---|
| `CLAUDE.md` / `.claude/CLAUDE.md` | 启动时自动加载全文 | 项目入口说明、稳定全局指令 |
| `.claude/rules/*.md` | 启动时自动加载；带 `paths:` 则按路径触发 | 短、稳定、持续生效的规则 |
| `.claude/skills/<name>/SKILL.md` | 描述自动注入；调用时加载全文 | 任务能力、执行顺序、验证方式 |
| `.claude/skills/<name>/references/*.md` | 不自动加载；由对应 SKILL.md 主动 Read | skill 私有长样例、矩阵、证据 |

`.claude/references/` 不是原生路径，本项目不使用。所有 reference 必须归属某个 skill。项目入口说明默认写项目根 `CLAUDE.md`，仅当项目已用 `.claude/CLAUDE.md` 或用户要求时才沿用。

## 扫描流程

1. 文件索引：顶层目录、`.claude/`、docs、scripts、tests、CI、配置、主要源码。
2. 读取显式规则：CLAUDE.md / AGENTS.md / README / CONTRIBUTING / docs / `.claude/rules/`。
3. 读取项目配置：package / workspace / tsconfig / lint / format / test / build / CI。
4. 识别 UI / API / data / config / test / docs / refactor 等任务类型质量门。
5. 整理命令入口。
6. 形成初步候选清单。
7. 读取 `agents.md`，按条件派发只读 setup agents。
8. 合并结果，形成扫描账本。
9. 读取 `rules.md` / `skills.md` / `habits.md` / `coverage.md`，生成候选设计。

## 初步候选表

```markdown
| 类型 | 候选名称 | 初步依据 | 需要深扫什么 |
|---|---|---|---|
```

## 产物决策协议

| 条件 | 最终落点 | 加载方式 |
|---|---|---|
| 强规则 + 全项目 / 某技术层 + 高频踩坑或硬边界 | `.claude/rules/<name>.md` | 自动加载 |
| 强规则但只对部分路径生效 | `.claude/rules/<name>.md` + `paths:` | 触发匹配文件时加载 |
| 稳定习惯 + 明确任务触发 + 需要执行步骤 | `.claude/skills/<name>/SKILL.md` | 按需加载 |
| skill 私有长样例、矩阵、证据 | `.claude/skills/<name>/references/<file>.md` | 对应 SKILL.md 主动 Read |
| 跨 skill 共享但无 skill 归属的长内容 | 重判：rule / CLAUDE.md / 降级 | — |
| 单点观察、冲突项、低频业务、无任务触发 | internal（仅进账本） | 不写入 |

每个用户可见候选必须至少满足一条生成价值：防止模型改错、少问路、写得像项目、正确验证、降低重复扫描成本、提高任务类型质量门覆盖。

## 用户可见建议格式

```markdown
建议生成 rules：
| 路径 | 使用场景 / 作用 | 内容概要 |
|---|---|---|

建议生成 skills：
| 路径 | 使用场景 / 作用 | 内容概要 |
|---|---|---|

建议生成 references：
| 路径 | 承载内容 | 消费入口 |
|---|---|---|
```

`使用场景 / 作用` 必须写成完整句，说明该文件帮模型在什么任务中做什么判断，不写短标签。默认不输出未采纳项。

## 写入后验证

每个 skill 有 `SKILL.md` / `name` / `description`，`name` 与目录名一致；rules 简短无长示例；所有 reference 落在 `.claude/skills/<name>/references/` 且被对应 SKILL.md 显式引用；没有 `.claude/references/*.md`；setup report / domains / habits / quality gates 已落到建议位置；SKILL.md 没有大段复写 rules；没有空壳 skill。
