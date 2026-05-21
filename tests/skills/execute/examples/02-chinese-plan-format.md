# 02 — 中文 plan 字段格式

## 触发提示词
```
按 docs/plans/2026-05-20-chinese-plan-smoke.md 开始实现
```

## 前置条件

在任意测试项目中创建 `docs/plans/2026-05-20-chinese-plan-smoke.md`，内容如下：

```markdown
# 中文计划格式冒烟 实现计划

**状态：** 已批准
**来源：** execute 中文字段格式测试
**创建日期：** 2026-05-20

## 目标

创建一个最小文本文件，验证 execute 能读取中文 plan 字段。

## 范围

- 包含：新建 `tmp/chinese-plan-smoke.txt`。
- 不包含：修改业务代码、运行真实测试套件。

## 背景

- 这是 execute skill 的格式兼容测试。

## 涉及文件

- 新建：`tmp/chinese-plan-smoke.txt` — 保存固定文本。

## 验证方式

- `test -f tmp/chinese-plan-smoke.txt`
  预期：退出码为 0。

## 任务清单

### 任务 1：创建冒烟文件

**状态：** 待执行
**目的：** 验证 execute 能按中文字段执行一个最小任务。

**涉及文件：**
- 新建：`tmp/chinese-plan-smoke.txt`

**步骤：**
- [ ] 步骤 1.1：创建文件并写入固定文本。
  变更：创建 `tmp/chinese-plan-smoke.txt`，内容为 `execute chinese plan smoke`。
  运行：`mkdir -p tmp && printf 'execute chinese plan smoke\n' > tmp/chinese-plan-smoke.txt`
  预期：命令退出码为 0，文件存在。

**验证：**
- 运行：`grep -Fx 'execute chinese plan smoke' tmp/chinese-plan-smoke.txt`
  预期：输出 `execute chinese plan smoke`，退出码为 0。

**完成标准：**
- `tmp/chinese-plan-smoke.txt` 存在，且内容完全等于 `execute chinese plan smoke`。
```

## 预期行为清单

- [ ] 触发：Claude 自动调用 /execute skill
- [ ] critical review 识别中文字段，不要求英文 Files / Steps / Run / Expected
- [ ] TodoWrite 建立 1 项，任务标题来自 `任务 1：创建冒烟文件`
- [ ] 执行时只更新 plan 中的 `状态` 和步骤 checkbox
- [ ] 按 `运行` 命令真实创建文件
- [ ] 按 `验证` 命令读取输出并比对 `预期`
- [ ] 完成后不直接声称完成，先提示进入 verify 或执行最终验证

## 反模式（不应出现）

- ✗ 因没有 Files / Steps / Run / Expected 而阻塞
- ✗ 改写任务内容或重排计划
- ✗ 跳过 `验证`，只看文件存在
- ✗ 把 `完成标准` 当成可忽略说明
