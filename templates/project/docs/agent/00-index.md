# Agent 文档索引

本目录是 `<项目名>` 的 Agent 协助开发操作系统。任何 Agent 都应先从这里确认阅读顺序，再进入代码修改。

## 通用阅读顺序

1. `AGENTS.md`
2. `docs/agent/00-index.md`
3. `docs/agent/01-project-overview.md`
4. `docs/agent/style-profile.md`
5. `docs/agent/adoption.md`
6. `docs/agent/intake.md`
7. `docs/agent/change-levels.md`
8. `docs/agent/memory-store/README.md`（如已启用检索式记忆）
9. `docs/agent/memory.md`
10. `docs/agent/02-architecture.md`
11. `docs/agent/03-tech-stack.md`
12. `docs/agent/quality.md`
13. `docs/agent/review.md`
14. 按任务类型阅读 `workflows/`
15. 按修改范围阅读 `modules/`
16. 涉及架构取舍时阅读 `04-decisions.md`

## 任务路由

| 任务类型 | 必读文档 |
|---|---|
| 渐进式接入 | `workflows/progressive-adoption.md`、`checklists/adoption-checklist.md`、`adoption.md`、`legacy-docs.md` |
| 方案理解与摄取 | `workflows/plan-intake.md`、`checklists/plan-intake-checklist.md`、`intake.md`、`memory.md` |
| S0 微小变更 | `change-levels.md`、相关代码或样式文件、最小验证 |
| 新增功能 | `workflows/new-feature.md`、`checklists/new-feature-checklist.md`、检索相关业务和架构记忆、相关模块文档 |
| 修复 Bug | `workflows/bug-fix.md`、`checklists/bug-fix-checklist.md`、检索历史问题和实现记忆、历史问题库 |
| 重构 | `workflows/refactor.md`、`checklists/refactor-checklist.md`、架构和模块文档 |
| UI 改造 | `workflows/ui-change.md`、`checklists/ui-change-checklist.md`、`style-profile.md`、前端模块文档 |
| 端侧风格 / 工程习惯调整 | `style-profile.md`、相关模块文档、必要的业务或架构文档 |
| 数据库变更 | 存储模块文档、数据库 checklist、回滚方案 |
| 发布 / 提交 | `workflows/version-control.md`、`checklists/version-control-checklist.md` |
| 用户补充业务背景 | `memory-store/`、`memory.md`、相关业务文档、相关模块文档 |
| 用户补充风格偏好 | `style-profile.md`、相关模块文档 |

## 文档维护原则

- `AGENTS.md` 只保留入口规则和硬约束。
- 项目事实维护在 `docs/agent/` 或项目约定的业务文档目录。
- 可检索项目记忆维护在 `docs/agent/memory-store/`，当前事实仍必须回写到人类可审查的文档。
- 项目风格事实维护在 `docs/agent/style-profile.md`。
- 同一主题只能有一个当前事实源。
- 每次修改前必须先判断变更等级。
- 用户补充的可复用项目事实必须评估是否写回 `memory.md` 或对应事实源。
- 启用检索式记忆后，用户补充的可复用事实还必须评估是否同步到 `memory-store/memories.jsonl`。
- 旧文档首次接入只进入 `legacy-docs.md` 索引，不默认作为当前事实。
- 完整方案必须先进入 `intake.md`，拆分为意图、业务意义、实现逻辑、系统影响和融合更新。
- 历史文档只做回溯，不作为当前实现依据。
- 文档应短而可执行，优先写边界、流程、接口和验收标准。
