+++
title = "Stop tracking a file"
date = "2026-04-24"
author = "Krzysztof Filar"
tags = ["git"]
categories = ["documentation"]
description = "How to stop tracking changes in a file in Git"
draft = false
+++

## How to stop tracking changes in a file in Git

To stop tracking a file, it has to be removed from the index:

```bash
git rm --cached <file>
```

To remove a folder and all files in the folder recursively:

```bash
git rm -r --cached <folder>
```

The removal of the file from the head revision will happen on the next commit.