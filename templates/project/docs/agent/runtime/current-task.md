# 当前任务状态

本文件记录当前任务的运行态上下文。任务完成后，可清空或归档到任务报告。

```yaml
task_id: <YYYYMMDD-HHMM-task-name>
task_type: <s0-micro-change / bug-fix / new-feature / refactor / plan-intake / progressive-adoption>
change_level: <S0 / S1 / S2 / S3>
status: <in_progress / blocked / done>
docs_checked:
  - AGENTS.md
  - docs/agent/00-index.md
memory_writeback: <not_required / required / done>
retrieval_memory: <not_enabled / not_required / searched / update_required / updated>
style_profile: <not_related / required / done>
plan_intake: <not_related / discussion_only / required / done>
plan_ledger: <not_related / draft / confirmed / active / done>
active_plan: <none / docs/agent/plans/plan-id.md>
plan_task_ids:
  - <none / T1>
legacy_docs: <not_related / indexed / reviewed / migrated>
verification:
  - <command or manual check>
workspace_mode: <main / worktree>
worktree_path: <none / absolute path>
worktree_branch: <none / codex/task-id>
worktree_cleanup: <not_required / pending / removed / pruned / blocked>
git_commit: <not_required / pending / committed / skipped>
pushed: <not_allowed / not_pushed / pushed / skipped>
open_questions:
  - <question or none>
```

## 使用规则

- `S0` 可不维护本文件，但最终报告必须说明不需要文档同步。
- `S1` 建议维护本文件。
- `S2` 和 `S3` 必须维护本文件。
- 方案仍处于讨论阶段时，`plan_intake` 只能记录为 `discussion_only`，不得修改协作文档。
- 完整方案开发时，`plan_ledger` 必须记录为 `confirmed` 或 `active`，并填写 `active_plan` 与本轮任务 ID。
- 任务完成后，重要事实必须写回 `memory.md`、`style-profile.md`、业务文档、模块文档、`intake.md` 或 `legacy-docs.md`。
- 启用 `memory-store/` 时，`S2` / `S3` 任务必须记录检索记忆的召回、更新或无需更新原因。
- 多个 Codex 任务并行、`S2` / `S3`、大改造、长期任务或共享文件冲突风险明显时，必须记录工作区模式和 Git worktree 生命周期。
- 使用独立 Git worktree 时，`worktree_cleanup` 初始为 `pending`；任务合并、废弃或清理后更新为 `removed`、`pruned` 或 `blocked`。
- 代码修改完成后，必须记录本地 Git 提交状态；跳过提交时必须说明原因。
- 最终回复结尾必须包含本地提交状态和“是否推送”。
