---
name: dotfiles-sync
description: Use when editing /home/kintiz/dotfiles or making changes that should be preserved in the user's dotfiles repository. Ensures dotfiles changes are committed with git c "message" and pushed to the configured remote after successful validation.
metadata:
  short-description: Commit and push dotfiles changes
---

# Dotfiles Sync

When a task changes files under `/home/kintiz/dotfiles`, finish by syncing the repository.

## Workflow

1. Make the requested dotfiles change.
2. Run a relevant validation command when possible, for example `bash -n` for shell scripts.
3. Inspect `git status --short` inside `/home/kintiz/dotfiles`.
4. Commit with the user's alias:

```bash
git c "short clear message"
```

5. Push the current branch:

```bash
git push
```

## Rules

- Do not include secrets, private keys, tokens, passwords, or machine-local credentials in the repository.
- If there is no remote configured, tell the user and do not fake a push.
- If `git push` fails because GitHub authentication is missing, tell the user to run `gh auth login`.
- If unrelated user changes are present, preserve them. Only include them in the commit when they are part of the dotfiles update requested by the user.
- Use concise Portuguese commit messages unless the user asks otherwise.

