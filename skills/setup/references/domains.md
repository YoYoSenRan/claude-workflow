# Domain Detection

本参考用于判断当前项目有哪些领域，避免把项目强行套进固定类型。领域名称必须来自当前项目，而不是来自通用模板。

## 识别顺序

1. 先看项目类型：应用、组件库、CLI、后端服务、插件、文档站、移动端、多端项目等。
2. 再看显式规则：`.claude/rules/*.md`、`CLAUDE.md`、README、docs。
3. 再看目录和文件名：这些通常反映真实领域边界。
4. 再看 package scripts 和构建流程：命令矩阵复杂时生成 `commands`。
5. 最后抽样代码，验证领域是否有稳定模式。

领域成立需要两类证据：入口证据和实现证据。入口证据包括 rules、目录、脚本或文档；实现证据来自实际读取的代表文件。只有入口证据、没有实现抽样时，不要判定为充分。

## 命名规则

- 使用项目自己的词汇：例如 `components`、`decoration`、`store`、`platform`、`brand`。
- 不要把所有前端项目都叫 `ui`。
- 不要把所有请求封装都叫 `api`。
- 不要在没有数据库层的项目里生成 `data`。
- 不要给领域 skill 加 `project-` 前缀。
- 只有领域名称过于底层或重叠时，才合并成更通用的 skill。

## 领域候选来源

| 来源 | 示例 | 可能生成 |
|---|---|---|
| rules 文件 | `components.md`、`store.md`、`platform.md` | `components`、`store`、`platform` |
| 目录结构 | `src/deco/`、`src/ui/`、`src/pages/` | 按项目命名生成 |
| 构建脚本 | `dev:*`、`build:*`、`upload:*` | `commands` |
| 平台差异 | `#ifdef`、多端 manifest | `platform` 或项目自己的平台名 |
| 品牌 / 租户 | env、brand、tenant、manifest 改写 | `brand`、`tenant` 或项目自己的品牌领域名 |
| 测试体系 | `tests/`、`*.test.*`、CI test job | 有稳定测试模式时才生成测试领域 |

## 项目类型示例

这些只是例子，不是固定清单：

- uniapp / 多端应用：可能生成 `platform`、`components`、`store`、`brand`、`decoration`。
- 组件库：可能生成 `components`、`styling`、`docs`、`release`。
- CLI / 工具库：可能生成 `cli`、`config`、`commands`。
- 后端服务：可能生成 `api`、`data`、`jobs`、`observability`。

## 合并规则

- 如果一个领域已有独立 rules 且是高频开发入口，优先生成对应领域 skill。
- 如果多个领域高度重叠，生成一个更贴近项目词汇的 skill，并在 references 中列出子领域。
- 如果领域只有一个文件或没有稳定模式，不生成独立 skill，只写入 `context` 的覆盖说明。
