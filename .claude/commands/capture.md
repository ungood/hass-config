---
description: Captures an idea as a gh issue.
---

Help the user quickly capture a feature idea as a GitHub issue.

1. If not already provided, ask the user for:
   - Feature title
   - Brief description of what the feature should do

2. Create the issue using `gh issue create`:

   ```bash
   gh issue create --title "TITLE" --body "DESCRIPTION" --label "enhancement"
   ```

3. Return the issue URL to the user.

Notes:

- Keep it simple and fast
- Use HEREDOC format for multi-line descriptions
- Label all issues as "enhancement"
