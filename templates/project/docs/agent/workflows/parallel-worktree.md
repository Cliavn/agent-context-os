# Workflow：多任务并行 Git worktree

## 目标

在多个 Codex 任务或会话并行开发同一仓库时，使用独立 Git worktree（工作树）隔离 working tree（工作区）和 Git index（暂存区），避免互相污染改动；同时保证临时目录在任务结束后可清理。

## 适用条件

满足以下任一条件时，应使用独立 Git worktree：

- 多个 Codex 任务或会话同时开发同一仓库。
- 变更等级为 `S2` 或 `S3`。
- 任务是大改造、跨模块改动、长期任务或实验性任务。
- 当前主工作区已有未提交改动，无法安全区分来源。
- 多个任务可能修改同一共享文件。

以下情况可以直接使用主工作区：

- `S0` / `S1` 小改动。
- 当前只有一个任务在操作仓库。
- 工作区干净，修改范围清晰。
- 不涉及共享核心文件或长期实验。

## 创建流程

1. 判断变更等级和并行风险。
2. 选择主工作区或独立 Git worktree，并在任务报告中说明原因。
3. 如果需要独立 Git worktree，在项目目录外的统一位置创建临时工作树。

```powershell
git worktree add <外部工作树根>/<项目名>/<任务名> -b codex/<任务名>
```

4. 在新工作树目录内启动任务，后续修改、验证和提交都在该目录完成。
5. 在 `docs/agent/runtime/current-task.md` 记录：

```yaml
workspace_mode: worktree
worktree_path: <外部工作树根>/<项目名>/<任务名>
worktree_branch: codex/<任务名>
worktree_cleanup: pending
```

## 提交流程

1. 在当前工作树内执行验证。
2. 检查 `git status --short`。
3. 只暂存本次任务相关文件。
4. 创建本地提交。
5. 不得在未获得用户明确授权时推送。

## 集成与清理

集成应由主工作区或专门集成工作树完成。

```powershell
git merge codex/<任务名>
```

分支已合并或任务确认废弃后，清理临时工作树：

```powershell
git worktree remove <外部工作树根>/<项目名>/<任务名>
git worktree prune
```

如果临时分支已合并，可删除分支：

```powershell
git branch -d codex/<任务名>
```

清理后更新任务状态：

```yaml
worktree_cleanup: removed
```

## 安全规则

- 不得把临时 Git worktree 散落在项目根目录内。
- 不得让多个并行任务共享同一个 working tree。
- 不得删除仍有未提交改动的 Git worktree；必须先确认提交、丢弃或保留现场。
- 不得用破坏性 Git 命令清理用户改动。
- 任务完成后必须报告工作树路径、分支、提交、合并状态和清理状态。
- 创建、使用或清理 Git worktree 后，应运行 `scripts/check-agent-worktrees.ps1` 或说明无法运行原因。
