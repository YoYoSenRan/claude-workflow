---
name: writing-skills
description: "写新 skill 或改现有 skill 时使用。覆盖 frontmatter 规范、命名规则、字符预算、目录布局、反模式。不适用于:写代码、写文档、写 commit message — 仅指本仓 skill 文件的创作。"
when_to_use: "写 skill, 新建 skill, 加 skill, 改 skill, scaffold skill, create skill, new skill, write a skill, skill 模板, skill frontmatter"
metadata:
  version: "0.1.0"
---

# 写一个 skill

写新 skill 或改现有 skill 时按 P0-P5 顺序执行, 确保 frontmatter / 字符预算 / 测试都过关。

<HARD-GATE>
**P0 不可跳**。写新 skill 前必须先回答 3 问(痛点 / 何时激活 / 何时不激活)。

3 问任一答不上 → 暂缓写 → 跟用户对齐后再开 P1。

跳 P0 = 大概率写出来用不上(描述空泛 / 触发不准 / 边界模糊)。
</HARD-GATE>

## 反模式: "这 skill 简单, 直接写就好"

最常掉的坑。每次想"这 skill 简单不用 P0"时, 就是该走 P0 的时刻。

简单 skill 也得说清场景和边界——空泛的 description = 永远不触发的 skill。

## 清单

按顺序完成, 不可跳:

1. **P0 三问** — 痛点 / 何时激活 / 何时不激活
2. **P1 脚手架** — mkdir + symlink + 占位文件
3. **P2 frontmatter** — name / description / when_to_use / metadata.version
4. **P3 正文** — 适用 / 流程 / 反模式
5. **P4 字符预算** — `wc -c`, ≤13KB
6. **P5 测试** — 至少 `01-basic.md`

## 流程图

```
开始
  ↓
P0: 3 问能答? ── 否 ──→ 暂缓, brainstorm
  ↓ 是
P1: 起脚手架
  ↓
P2: 填 frontmatter
  ↓
P3: 写正文
  ↓
P4: wc -c ≤13KB? ── 否 ──→ 拆到 references/
  ↓ 是
P5: 写测试
  ↓
完成
```

## P0 — 想清楚干啥

回答 3 个问题:

1. 这 skill 解决什么**具体**痛点?(不是泛指)
2. Claude 在什么场景下应该**自动激活**?
3. **不应该**在什么场景下激活?(反向边界同样重要)

任一答不上 → 暂缓写, 先 brainstorm。

## P1 — 起脚手架

```bash
NAME=<kebab-name>

mkdir -p skills/$NAME/references
mkdir -p tests/skills/$NAME/examples
touch skills/$NAME/SKILL.md
touch tests/skills/$NAME/examples/01-basic.md
touch tests/skills/$NAME/README.md
(cd .claude/skills && ln -s ../../skills/$NAME $NAME)
```

校验命名:

```bash
echo $NAME | grep -E '^[a-z0-9][a-z0-9-]*$' || echo "✗ 名字非法"
[[ $NAME == *anthropic* || $NAME == *claude* ]] && echo "✗ 名字含禁用词"
```

## P2 — 填 frontmatter

**必填四件**:

```yaml
---
name: <kebab-name>
description: "做什么 + 何时用 + 不适合什么场景"
when_to_use: "触发词1, 触发词2, ..."
metadata:
  version: "0.1.0"
---
```

**字段规则**:

| 字段 | 要求 |
|---|---|
| `name` | ≤64 字符, kebab-case, 不含 `anthropic` / `claude` |
| `description` | ≤1024 字符, 第三人称, 说"做什么 + 何时用 + 不做什么" |
| `when_to_use` | comma 分隔触发词, 中英混合 OK |
| `metadata.version` | SemVer (MAJOR.MINOR.PATCH) |

**description 关键**:

❌ "一个用于 X 的工具" (太泛, 触发率低)  
✓ "X 时使用。做 A、B、C。不适用于 D、E。"

第一句包含强触发动词 + 场景对象 + 排除场景。

## P3 — 写正文

**推荐结构**(按需删减):

```markdown
# Title (skill 在干什么)

1-2 句开场。

<HARD-GATE> 或 <EXTREMELY-IMPORTANT>     ← 强制规则, 1-2 处用
## 反模式: "<最容易掉的借口>"
## 清单                              ← 编号 + 一行
## 流程图                                  ← ASCII
## (流程细节, 按阶段展开)
## 危险信号 (table)
## 核心原则                         ← 5 条原则
```

## P4 — 检查字符预算

```bash
wc -c skills/<name>/SKILL.md
```

| 字符数 | 状态 |
|---|---|
| ≤13KB | ✅ 通过 |
| 13KB–15KB | ⚠️ 警告 |
| >15KB | ❌ silent drop, Claude 看不见 |

超了 → 推到 `references/X.md`, SKILL.md 只留入口 + 链接。

## P5 — 写测试

至少 `tests/skills/<name>/examples/01-basic.md`:

```markdown
# 01 — 基础触发

## Trigger Prompt
"<典型用户输入>"

## Expected Behavior Checklist
- [ ] Claude 自动 invoke /<name>
- [ ] 阶段 ... 走到
- [ ] 产出符合预期

## Anti-Patterns (不应出现)
- ✗ ...
```

跑测: 新会话粘 Trigger Prompt → 对照打勾。

## 目录布局

```
skills/<name>/
├── SKILL.md              主入口 (≤13KB)
├── references/           细节, 按需读
└── (可选) scripts/, assets/

tests/skills/<name>/      ← 顶级 tests/, 不在 skill 包内
├── README.md
└── examples/01-basic.md
```

## 命名规则

- kebab-case (小写字母 + 数字 + 连字符)
- 意思明确, 不泛
- 好: `search`, `commit`, `standup`, `review`, `using-workflow`
- 不好: `helper`, `MySkill`, `claude-research` (含禁用词)
- 禁: `anthropic` / `claude` 字样 (Anthropic 官方禁)

## 危险信号

念头出现 → 立刻停下:

| 内心戏 | 真相 |
|---|---|
| "frontmatter 随便填" | description 决定触发率, 糊弄 = skill 永远不激活 |
| "13KB 够了, 先写超" | 超了 silent drop, Claude 看不见 |
| "测试可以后补" | 后补 = 不补。写时同步写。 |
| "这事不用专门写 skill" | 重复劳动 3 次以上 → 写 |
| "description 写'用于辅助 X'" | 太泛, 等于没写。说清边界。 |
| "我直接编辑 ~/.claude/ 那份" | 那是 sync 拷贝, 会被覆盖。改根 `skills/<name>/` |

## 核心原则

- **P0 不可跳** — 答不上 3 问就不写
- **description 决定一切** — 写不好等于 skill 不存在
- **13KB 硬上限** — 超了 silent drop
- **测试同步写** — 不后补
- **空泛 = 没写** — 不要"用于 X"这种描述
