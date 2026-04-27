+++
title = 'GHA workflow  with workflow_dispatch trigger on your feature_branch'
description = 'How to run GHA workflow on your feature_branch with workflow_dispatch trigger'
date = '2026-04-27T12:46:20+02:00'
author = "Krzysztof Filar"
categories = ["Automation"]
tags = ["github", "github actions"]
+++

## Problem
If you have a workflow that starts on the `workflow_dispatch` event and you're working on your `feature branch`, it's not possible to launch such a workflow from Github.
You can only manually start such a workflow if it's on the `default` branch. This is a rather annoying limitation. However, there is a way around this.

## Solution
Here's what you need to do:

1. First, install gh (Github CLI). Here's how: https://cli.github.com/manual/installation

2. Then, add a one-time push trigger to the workflow:

```yaml
push:
  branches:
  - your_feature_branch
workflow_dispatch:
```

3. `Commit` and `push` to your repository. The workflow should start. 

This `push` trigger is so that the name of your workflow appears here (in this case it is `Build and deploy`):
![Actions List](actions_list.png)

4. Now you can remove the `push` trigger and `commit` and `push` to the repository again.

Without this one-time action, even though the workflow exists in the `.github` directory on your branch, the following commands will not work.

5. Now to trigger workflow run this command:

```bash
gh workflow run "Name of the Workflow" \
--ref your_feature_branch \
-f input_name="input_value" -f another_input_name="another_input_value"
```

After running this command, you will see a message similar to the one below:

```text
✓ Created workflow_dispatch event for workflow_name.yml at feature_branch_name
https://github.com/<your_repository>/actions/runs/24985074138

To see the created workflow run, try: gh run view 24985074138
To see runs for this workflow, try: gh run list --workflow="workflow_name.yml"
```

6. Go to your repository on Github, click on Action tab and you should see the running workflow. 