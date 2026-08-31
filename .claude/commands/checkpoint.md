---
description: Git checkpoint — inspect status, summarize changes, commit only if explicitly requested
---

Inspect Git status (`git status`, `git diff --stat`).

If there are relevant changes:

1. Show changed files.
2. Summarize what changed.
3. Create a checkpoint commit — invoking this command is itself the explicit request to commit,
   but still verify it's safe first: review what's staged (never `git add -A`/`git add .`
   blindly — add specific files), check nothing that looks like a secret/credential is included,
   and confirm `flutter analyze` isn't newly broken by what's being committed.

Never delete user changes. Never reset the repository. Never checkout over uncommitted work.
If anything looks like in-progress work you didn't create this session, stop and ask rather than
including or discarding it.

Also ask the user whether to bump `fantatech-flutter/pubspec.yaml`'s `version:` as part of this
checkpoint — never bump it silently. If yes, increment both the semantic version and the build
number (`X.Y.Z+NNNNN`).

Commit message format:

```
checkpoint: <short description>
```

Do not push. This command creates a local checkpoint only — pushing is a separate, explicit
request.
