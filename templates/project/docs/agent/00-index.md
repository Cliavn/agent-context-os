# Agent 文档索引

本目录是 `<项目名>` 的 Agent 协助开发操作系统。任何 Agent 都应先从这里确认阅读顺序，再进入代码修改。

## 通用阅读顺序

1. `AGENTS.md`
2. `docs/agent/00-index.md`
3. `docs/agent/01-project-overview.md`
4. `docs/agent/02-architecture.md`
5. `docs/agent/03-tech-stack.md`
6. `docs/agent/quality.md`
7. `docs/agent/review.md`
8. 按任务类型阅读 `workflows/`
9. 按修改范围阅读 `modules/`
10. 涉及架构取舍时阅读 `04-decisions.md`

## 任务路由

| 任务类型 | 必读文档 |
|---|---|
| 新增功能 | `workflows/new-feature.md`、`checklists/new-feature-checklist.md`、相关模块文档 |
| 修复 Bug | `workflows/bug-fix.md`、`checklists/bug-fix-checklist.md`、历史问题库 |
| 重构 | `workflows/refactor.md`、`checklists/refactor-checklist.md`、架构和模块文档 |
| UI 改造 | `workflows/ui-change.md`、`checklists/ui-change-checklist.md`、前端模块文档 |
| 数据库变更 | 存储模块文档、数据库 checklist、回滚方案 |
| 发布 / 提交 | `workflows/version-control.md`、`checklists/version-control-checklist.md` |

## 文档维护原则

- `AGENTS.md` 只保留入口规则和硬约束。
- 项目事实维护在 `docs/agent/` 或项目约定的业务文档目录。
- 同一主题只能有一个当前事实源。
- 历史文档只做回溯，不作为当前实现依据。
- 文档应短而可执行，优先写边界、流程、接口和验收标准。

