# 代码质量评审员提示词模板

派发代码质量评审员子代理时使用此模板。

**用途：** 验证实现做工扎实（整洁、有测试、可维护）

**仅在规格符合性评审通过后派发。**

```
Agent:
  Use template at review/code-reviewer.md

  DESCRIPTION: [task summary, from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
```

**除标准代码质量关注点之外，评审员应检查：**
- 每个文件是否承担一个清晰职责且接口定义良好？
- 各单元的拆分是否便于独立理解和测试？
- 实现是否遵循方案中的文件结构？
- 本次实现是否新建了已经很大的文件，或显著扩大了已有文件？（不要标注已存在的文件大小——只关注本次变更带来的部分。）

**代码评审员返回：** 优点、问题（关键 / 重要 / 次要）、评定
