# 约定

## SKILL.md frontmatter

必填四件:

```yaml
---
name: my-skill
description: "一句话说明做什么 + 何时触发 + 不适合什么场景"
when_to_use: "触发词1, 触发词2, trigger word, ..."
metadata:
  version: "1.0.0"
---
```

字段规则 (基于 Anthropic 官方 best-practices) —

| 字段 | 要求 |
|---|---|
| `name` | ≤64 字符, kebab-case (小写+数字+连字符), 不含 `anthropic` / `claude` |
| `description` | ≤1024 字符, 第三人称, 说"做什么 + 何时用 + 不做什么" |
| `when_to_use` | comma 分隔的触发词列表, 中英混合 OK |
| `metadata.version` | SemVer (MAJOR.MINOR.PATCH) |

## 命名

- skill 名字: 名词或动名词, kebab-case
  - 好: `search`, `processing-pdfs`, `tech-research`
  - 不好: `MySkill`, `my_skill`, `claude-research`
- 多词时连字符, 不下划线

## 字符预算 (重要!)

Claude Code 默认 SKILL.md 字符预算 **15000** (~4k tokens)。超了 silent drop, 不报错就消失。

本仓软上限设 **13000** (留 ~13% 余量, validate-skill.py 强制)。超了内容推到 `references/`。

```
SKILL.md (≤13KB)         主入口, 高频引用规则
  ↓ 链接
references/X.md          细节, 按需加载
references/Y.md
```

## 目录布局

```
skills/<name>/
├── SKILL.md                 主入口
├── references/              细节, Claude 按需读
│   ├── X.md
│   └── Y.md
├── scripts/                 可选: skill 用的 Python/Bash 脚本
├── assets/                  可选: 模板 / 资源文件
└── tests/
    ├── README.md
    └── examples/
        ├── 01-basic.md
        ├── 02-edge-case.md
        └── ...
```

## Frontmatter 之外: SKILL.md 正文结构推荐

```markdown
# Skill 名: 一句标题

简短一句话: 这个 skill 做什么。

核心承诺 — **关键不变式 / 用户最在意的保证**。

## 适用 / 不适用
表格, 两列

## 流程 (P0-PN 或类似)
每阶段一节, 含 "报告: `[Pn] ...`" 状态回执

## 反模式
- ✗ ...

## 文件清单
| 文件 | 何时加载 |

## (完成后建议下一步)
```

## 内部链接

引用同 skill 内 references 用相对路径:

```markdown
[references/X.md](references/X.md)
```

`validate-skill.py` 会扫这个 pattern, 死链报错。

## 不要做的

- ❌ name / description 里写 "anthropic" / "claude"
- ❌ SKILL.md 主体超 13KB
- ❌ frontmatter 用复杂 YAML 嵌套 (validate-skill.py 只支持 1 层 metadata)
- ❌ 跳过 tests/examples — 至少 1 个 case
- ❌ 在 SKILL.md 写绝对路径 `/Users/<name>/` (会被 PII 扫到)
- ❌ 直接 symlink 整个 `~/.claude/` 目录 (踩 4 个已知 bug)
