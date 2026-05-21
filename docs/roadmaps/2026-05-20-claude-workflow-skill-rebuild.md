# claude-workflow 技能体系重建路线图

**目标：** 将 `claude-workflow` 调整为一个更小、更适合个人使用的 `superpowers` 风格工作流插件。保留你偏好的简短中文 skill 名称，同时恢复清晰的流程边界、完成前验证门槛和回归检查。

**参考基线：** `/Users/macos/WebProject/superpowers`

**当前问题：** 项目借鉴了 `superpowers` 的外形，但在简化过程中丢掉了关键支撑结构：架构基线文档被删除；`think` 过早禁止读取上下文，导致分析类任务受阻；`executing` 混合了 inline 执行和未完成的 subagent 流程；`review` 和 `worktree` 还是空壳；测试也只有手工 markdown checklist。

**不做什么：**
- 不把项目做成公开、多 harness 的通用插件。
- 不逐字照搬 `superpowers` 的所有 skill。
- 在缺少必要 agents 和 prompts 前，不加入完整 subagent-driven-development。
- 本轮不重命名 `executing`；先修行为，命名清理后置。

---

## Phase 1：恢复架构基线

**文件：**
- 创建：`docs/architecture.md`
- 创建：`docs/testing.md`

**调整：**
- 重新创建 `docs/architecture.md`，作为个人工作流的唯一架构基线。
- 明确稳定主流程：

```text
using -> think -> plan -> executing
              \-> debug

增强层：
worktree, review, verify, finish, future subagent flow
```

- 记录与 `superpowers` 的 skill 映射关系：

```text
using           ~= using-superpowers
think           ~= brainstorming
plan            ~= writing-plans
executing       ~= executing-plans
debug           ~= systematic-debugging
verify          ~= verification-before-completion
finish          ~= finishing-a-development-branch
worktree        ~= using-git-worktrees
review          ~= requesting-code-review / receiving-code-review
```

- 写清核心原则：个人版可以删除公开发布、多平台兼容这些包袱，但不能删除 gate、证据链和流程边界。
- 新增 `docs/testing.md`，定义最小验证策略：
  - 静态检查 frontmatter 和必需章节；
  - 自然 prompt 触发测试；
  - 显式 skill 请求测试；
  - hook 注入冒烟测试。

**验证：**
- `test -f docs/architecture.md`
- `test -f docs/testing.md`
- 人工检查：架构文档覆盖每个现有 skill，并明确标出未完成的 skill。

---

## Phase 2：修正核心路由

**文件：**
- 修改：`skills/using/SKILL.md`
- 修改：`skills/think/SKILL.md`

**`using` 调整：**
- 只保留 bootstrap 职责。
- 保留 1% skill 使用规则和指令优先级。
- 删除“使用哪个具体 skill”的路由逻辑，只保留“回复前先使用相关 skill”。
- 控制 hook 注入内容长度，避免每次会话都带入过多静态规则。

**`think` 调整：**
- 将当前 hard gate 拆成两种模式：

```text
分析模式：
  用户要求分析、审查、检查、理解、对比、解释。
  允许：先读取项目文件、文档、git 历史、参考资料，再形成判断。
  禁止：用户没有要求实现前，不编辑文件。

实现意图模式：
  用户要求构建、重构、优化、修改行为、实现功能。
  如果范围不清晰，先提问确认，再深入读取或编辑。
```

- 保留 `superpowers:brainstorming` 中有价值的行为：一次一个问题、提出 2-3 个方案并说明取舍。
- 只在复杂实现任务中写 spec。
- 不强迫简单分析任务落 spec 文档。

**验证：**
- Prompt：`先分析一下当前项目`
  - 预期：`think` 允许读取项目，并输出分析。
- Prompt：`帮我重构一下这个模块`
  - 预期：`think` 先问 what / where / why，不直接编辑。
- Prompt：`把 skills/using/SKILL.md 第 3 行描述改短`
  - 预期：不触发重型 think 流程；读取文件后可直接做小改。

---

## Phase 3：稳定计划阶段

**文件：**
- 修改：`skills/plan/SKILL.md`
- 保留：`skills/plan/plan-document-reviewer-prompt.md`

**调整：**
- 保留严格的“禁止占位符”规则。
- 保留精确文件路径、命令、预期输出。
- 修正 TDD 相关矛盾：
  - 代码行为变化推荐 TDD。
  - 文档和配置类变更不需要失败测试。
  - 如果计划省略测试，必须说明为什么可以省略。
- 将交付话术从“用 executing 执行”改为“询问用户是否现在执行”。
- 在没有真实 plan-reviewer agent 或受支持的 subagent prompt 路径前，不强制派遣评审子代理。当前阶段：
  - 必须自审；
  - subagent 评审只作为可选项，并且依赖环境能力。

**验证：**
- `rg -n "TBD|TODO|FIXME|类似任务|参考上面" skills/plan/SKILL.md`
  - 预期：除反模式说明外，不出现占位符式计划要求。
- 人工检查：plan 输出路径仍为 `docs/plans/YYYY-MM-DD-<name>.md`。

---

## Phase 4：收窄 executing 职责

**文件：**
- 修改：`skills/executing/SKILL.md`
- 后续明确处理：`skills/subagent/SKILL.md` 的删除应当是有意识的决策，而不是顺手删除。

**调整：**
- 将 `executing` 定义为“按书面计划 inline 执行”的 skill。
- 保留实现前 critical review gate。
- 保留每个任务一条 TodoWrite。
- 保留遇阻即停。
- 移除或隔离完整 subagent-driven-development 叙述，直到 `agents/` 和 reviewer prompts 真实存在。
- 保留一条小提示：

```text
如果任务过大，不适合 inline 执行，停止并建议后续启用 subagent 工作流。
没有 reviewer agent 时，不要假装存在 subagent review。
```

- 终态应为：
  - 所有任务完成 -> 调用或建议 `verify`；
  - 遇到阻塞 -> 报告阻塞点；
  - 计划本身有问题 -> 停止并回到 `plan`。

**验证：**
- 使用有效 plan 路径触发：
  - 预期：加载计划、评审、TodoWrite、按步骤执行。
- 使用不存在的 plan 路径触发：
  - 预期：报告 blocker 并停止。
- 使用含糊 plan 步骤触发：
  - 预期：停止，不猜测。

---

## Phase 5：保留 debug 严格性，并接入 verify

**文件：**
- 修改：`skills/debug/SKILL.md`

**调整：**
- 保留四阶段根因排查流程。
- 保留“没有根因前不修复”的 hard gate。
- 在 bug 修复后明确接入 `verify`：

```text
Phase 4 通过后，必须用新鲜输出验证原始症状和相关测试命令，再声明已修复。
```

- 只有当修复确实跨多文件或涉及架构时，才转入 `plan`；不要把简单 bug 修复流程过度文档化。

**验证：**
- 使用带 stack trace 的 prompt：
  - 预期：先读错误、复现、检查最近改动，再提出修复。
- 修复完成后：
  - 预期：声明“已修复”前必须有新鲜验证证据。

---

## Phase 6：补齐真实增强 skill

**文件：**
- 创建：`skills/verify/SKILL.md`
- 创建：`skills/finish/SKILL.md`
- 替换或扩展：`skills/review/SKILL.md`
- 替换或扩展：`skills/worktree/SKILL.md`

**调整：**
- `verify`：
  - 参考 `superpowers:verification-before-completion`。
  - 完成声明前必须有新鲜命令输出。
  - 禁止 “should pass” 这类无证据表述。

- `finish`：
  - 参考 `superpowers:finishing-a-development-branch`。
  - 提供简洁选项：

```text
1. 提交当前工作
2. 推送 / 创建 PR
3. 保留当前分支
4. 丢弃当前工作
```

  - 丢弃必须要求显式确认。
  - 未经用户批准，不建议或执行破坏性 git 命令。

- `review`：
  - 合并“请求代码评审”和“接收评审反馈”两个场景，做成个人版 review skill。
  - 默认采用 code-review stance：先列 bug、风险、回归、缺失测试。

- `worktree`：
  - 保持最小。
  - 有原生隔离工作区时优先用原生能力。
  - 只有用户要隔离开发时才使用 git worktree。
  - 移动工作区前必须说明位置。

**验证：**
- `wc -l skills/verify/SKILL.md skills/finish/SKILL.md`
  - 预期：两个 skill 都聚焦，不是完整复制上游长文档。
- 人工检查：没有任何破坏性命令会在未确认时被建议执行。

---

## Phase 7：增加最小自动化测试

**文件：**
- 创建：`tests/skill-triggering/run-test.sh`
- 创建：`tests/skill-triggering/prompts/think-analysis.txt`
- 创建：`tests/skill-triggering/prompts/debug.txt`
- 创建：`tests/explicit-skill-requests/run-test.sh`
- 创建：`tests/static/check-skills.sh`
- 创建：`tests/run-all.sh`

**调整：**
- 借鉴 `superpowers/tests` 的形状，但保持测试集小而稳。
- `tests/static/check-skills.sh` 检查：
  - 每个 `skills/*/SKILL.md` 都有 `name` 和 `description`；
  - 不存在空壳 placeholder skill；
  - 如果本地名称是 `verify`，就不应再引用缺失的 `verification-before-completion`；
  - 如果 `using` 设计为只走 hook 注入，就不应作为普通全局 skill 同步。

- 触发类测试只有在本机存在 `claude` CLI 时才运行：
  - 如果缺少 `claude` CLI，清晰提示并跳过。

**验证：**
- `bash tests/static/check-skills.sh`
- `bash tests/run-all.sh`

---

## Phase 8：清理同步脚本和说明文档

**文件：**
- 修改：`scripts/sync.sh`
- 修改或创建：`README.md`
- 仅在必要时修改：`.gitignore`

**调整：**
- 修正 `scripts/sync.sh` 中仍提到 `.claude/` 作为项目源目录的过时注释；当前真实源是根目录下的 `skills/ agents/ commands/`。
- 如果仍通过 SessionStart hook 注入 `using`，继续在普通同步中跳过 `using`。
- 文档说明：
  - 开发流程；
  - 如何 dry-run 同步；
  - 修改 skill 后如何测试；
  - 本项目与 `superpowers` 的差异。

**验证：**
- `DRY_RUN=1 bash scripts/sync.sh`
- 人工检查：输出跳过 `skills/using`，并列出预期同步的 skill。

---

## 风险清单

| 风险 | 缓解方式 |
|---|---|
| skill 规则过长，导致每次会话上下文膨胀 | 保持 `using` 短小；详细规则放进具体 skill 和 supporting files。 |
| `think` 过严，阻塞正常分析 | 增加明确分析模式，允许只读探索。 |
| subagent 工作流被写进文档但实际不可用 | 在 `agents/` 和 reviewer prompts 存在前，从 `executing` 中收窄或隔离。 |
| 空壳 skill 误导 agent | 扩展 `review` / `worktree`，或从同步范围移除。 |
| 文档和 skill 名称漂移 | 增加静态测试，检查缺失 skill 引用。 |
| 测试依赖本地 Claude CLI，容易不稳定 | 拆分静态测试和 Claude 行为测试；缺少 CLI 时跳过行为测试。 |

---

## 验收标准

- `docs/architecture.md` 存在，并且和实际 skill 集合一致。
- 不再存在 3 行空壳 skill。
- `think` 支持只读项目分析，并且不和自身规则冲突。
- `executing` 不再声称支持完整 subagent-driven-development，除非配套 agents 已存在。
- `verify` 存在，并成为完成声明前的唯一验证路径。
- `finish` 存在，且不会在未确认时建议破坏性操作。
- 静态测试通过。
- sync dry-run 输出符合预期的全局 skill 集合。
