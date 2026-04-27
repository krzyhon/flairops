+++
title = "Stop tracking a file in Git"
date = "2026-04-24"
author = "Krzysztof Filar"
tags = ["git"]
categories = ["documentation"]
description = "How to stop tracking changes in a file in Git"
+++
## How I Stop Tracking a File in Git (Without Deleting It)

Every now and then, I end up committing something I didn't mean to—usually a .env file, some logs, or a random config. Deleting the file isn't the goal—I just want Git to forget about it.
Here's the quick way I handle it.

## Removing a File from Git Tracking
If I want Git to stop tracking a file but keep it on my machine, I run:

```bash
git rm --cached <file>
```
That basically tells Git: *“stop tracking this, but don't touch my local copy.”*

## Removing a Folder Instead
If it's a whole directory (which happens more often than I'd like), I go with:
```bash
git rm -r --cached <folder>
```
The `-r` just makes sure everything inside gets removed from tracking too.

## Don't Forget to Commit
After that, Git marks the file as removed, but it's not final until I commit:
```bash
git commit -m "Stop tracking file"
```
Once that's done, the file is no longer part of the repo history going forward.

## One Thing I Always Do After
If I removed something because it shouldn't be tracked (like secrets or build files), I add it to .gitignore right away. Otherwise, Git will happily try to track it again later.

## That's It

Nothing fancy—just a small command that saves me from a lot of messy commits. I probably use this more often than I'd like to admit.
