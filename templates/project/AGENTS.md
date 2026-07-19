# <项目名> Agent 协作入口

本文件是 `<项目名>` 的最高优先级 Agent 协作入口。任何 Agent 在新增功能、修改功能、修复 Bug、重构、性能优化或评审代码前，必须先阅读本文件和 `docs/agent/00-index.md`。

## 必读顺序

1. `docs/agent/00-index.md`
2. `docs/agent/01-project-overview.md`
3. `docs/agent/style-profile.md`
4. `docs/agent/adoption.md`
5. `docs/agent/intake.md`
6. `docs/agent/plans/README.md`
7. `docs/agent/change-levels.md`
8. `docs/agent/memory-store/README.md`（如已启用检索式记忆）
9. `docs/agent/memory.md`
10. `docs/agent/02-architecture.md`
11. `docs/agent/03-tech-stack.md`
12. `docs/agent/quality.md`
13. 与任务类型对应的 workflow 和 checklist
14. 与修改范围对应的模块文档

## 硬规则

- 不允许在未理解现有实现、模块边界和验证要求前直接改代码。
- 修改必须保持范围最小，优先复用现有模式、接口和工具链。
- 涉及业务规则时，必须阅读对应业务语义文档。
- 涉及视觉、交互、文案、命名、分层风格或端侧习惯时，必须阅读 `docs/agent/style-profile.md`。
- 用户补充业务背景、验收口径、历史坑或项目偏好时，必须评估是否写回 `docs/agent/memory.md` 或对应业务文档。
- 启用 `docs/agent/memory-store/` 时，任务开始应先按任务类型、模块、文件路径、接口名或业务对象召回相关记忆，再决定是否深读 `memory.md` 或事实源。
- 检索记忆只作为召回层；与代码、测试或当前文档冲突时，以代码、测试和当前文档为准，并把记忆标记为 `stale` 或 `deprecated`。
- 老项目渐进式接入时，只能先建立旧文档索引，不得默认全量分析旧文档。
- 用户输入完整方案时，必须先理解方案初衷、业务意义和系统影响，再拆任务或写回上下文。
- 用户仅在讨论、比较或推敲方案且未明确要求定版、执行或写回时，视为 `discussion_only`，不得修改协作文档；只能在对话中整理候选方案、风险和待确认问题。
- 用户要求形成开发顺序、任务清单、记录草稿或准备落地时，必须创建或更新 `docs/agent/plans/<plan-id>.md`，初始状态为 `draft`。
- 用户要求按完整方案开发时，必须读取 `confirmed` 或 `active` 方案落实台账，并按任务顺序逐项执行；不得按零散对话直接实现。
- 修改前必须判断变更等级：`S0`、`S1`、`S2` 或 `S3`。
- `S0` 微小变更可以走轻量模式，但必须说明不涉及业务规则、记忆回写、方案摄取和旧文档迁移。
- `S0` / `S1` 单任务小改动、工作区干净且修改范围清晰时，可以直接在主工作区完成。
- 多个 Codex 任务并行、`S2` / `S3`、大改造、长期任务、实验性任务或共享文件冲突风险明显时，必须使用独立 Git worktree（工作树）和独立 branch（分支）。
- 使用独立 Git worktree 时，必须在 `docs/agent/runtime/current-task.md` 记录 `workspace_mode`、`worktree_path`、`worktree_branch` 和 `worktree_cleanup`。
- 临时 Git worktree 应放在项目目录外的统一位置；任务完成、合并或废弃后必须执行 `git worktree remove <worktree路径>` 和 `git worktree prune`，存在未提交改动时不得自动删除。
- `S2` / `S3` 必须维护或更新 `docs/agent/runtime/current-task.md`。
- 涉及字段、状态、接口、数据库、自动化流程或权限时，必须说明影响范围。
- 文档和代码冲突时，以真实代码和测试结果为准，并报告文档过期。
- 代码修改后必须执行相关验证；无法验证时必须说明原因和剩余风险。
- 启用 `docs/agent/memory-store/` 时，必须运行 `scripts/check-project-memory-store.ps1` 或说明无法运行原因。
- 代码、脚本或配置修改后，应运行 `scripts/check-agent-drift.ps1` 或说明无法运行原因。
- 创建、使用或清理 Git worktree 后，应运行 `scripts/check-agent-worktrees.ps1` 或说明无法运行原因。
- 完成代码修改并通过必要验证后，默认创建本地 Git 提交。
- 本地提交只能包含本次 Agent 改动；工作区存在用户已有未提交改动时，必须只暂存本次相关文件，无法安全区分时不得提交。
- 不得在未获得用户明确授权时推送到远端仓库。
- 最终回复结尾必须包含本地提交状态和“是否推送”；即使没有创建提交，也必须明确说明是否已推送。
- 项目风格事实变化时，必须评估是否写回 `docs/agent/style-profile.md`。
- 修复重复 Bug 时，必须建议更新历史问题库、测试或 checklist。
- 信息不完整但影响实现时，必须主动提出最小必要问题，并记录开放问题。
- 不得把账号、密钥、token、cookie、真实隐私数据写入文档、代码或测试。

## 成本控制

- 默认单 Agent。
- 默认按任务路由读取最小必要上下文。
- 默认先检索记忆摘要，再按命中结果深读文档。
- 不默认全量读取历史文档。
- 不默认为 S0/S1 小改动创建 Git worktree。
- 完整方案开发时优先以方案落实台账组织多 Agent；任务很少、强串行或用户要求单 Agent 时可不启用，但必须说明原因。
- 多 Agent 仅在复杂跨模块任务或完整方案落地中启用，并需要明确职责边界。

## 最终报告

最终回复必须包含：

- 已读文档
- 变更等级
- 工作区模式
- 修改范围
- 记忆回写
- 检索记忆更新
- 渐进式接入状态
- 方案摄取状态
- 方案落实台账
- 验证结果
- 本地 Git 提交
- 是否推送
- 风险与剩余问题
- 是否需要更新协作文档
- 是否需要更新项目风格画像
