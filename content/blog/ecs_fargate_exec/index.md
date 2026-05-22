+++
title = "Logging Into a Container Running on ECS Fargate"
description = "How to open an interactive shell inside a running Fargate container using ECS Exec and the AWS CLI"
date = "2026-05-22T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["AWS"]
tags = ["aws", "ecs", "fargate", "docker", "devops"]
+++

When you run containers on ECS with the EC2 launch type, you can always SSH into the underlying instance and use `docker exec` to get inside a container. With Fargate, that escape hatch is gone — there is no instance to SSH into. The containers run on infrastructure managed entirely by AWS.

The solution is **ECS Exec**, which opens an interactive session directly into a running Fargate container using AWS Systems Manager (SSM) Session Manager under the hood. No bastion host, no open ports, no SSH keys required.

## How It Works

ECS Exec uses the SSM agent embedded in the Fargate runtime (available since platform version 1.4.0). When you run `aws ecs execute-command`, the AWS CLI establishes a secure channel through SSM to the target container and attaches your terminal to it.

## Prerequisites

**AWS CLI** — version 2 recommended:

```bash
aws --version
```

**Session Manager plugin** — required by the CLI to establish the SSM tunnel.

**macOS — Homebrew (recommended):**

```bash
brew install --cask session-manager-plugin
```

**macOS — manual install via pkg (no Homebrew required):**

```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/session-manager-plugin.pkg" \
  -o /tmp/session-manager-plugin.pkg
sudo installer -pkg /tmp/session-manager-plugin.pkg -target /
```

**Linux (Debian/Ubuntu):**

```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" \
  -o /tmp/session-manager-plugin.deb
sudo dpkg -i /tmp/session-manager-plugin.deb
```

Verify the plugin is installed:

```bash
session-manager-plugin --version
```

## IAM Permissions

The **task IAM role** (not your user role) must have permission to open SSM channels. Add the following policy to the role your ECS tasks assume:

```json
{
  "Effect": "Allow",
  "Action": [
    "ssmmessages:CreateControlChannel",
    "ssmmessages:CreateDataChannel",
    "ssmmessages:OpenControlChannel",
    "ssmmessages:OpenDataChannel"
  ],
  "Resource": "*"
}
```

Your **IAM user or role** also needs permission to call `ecs:ExecuteCommand`:

```json
{
  "Effect": "Allow",
  "Action": [
    "ecs:ExecuteCommand",
    "ecs:DescribeTasks"
  ],
  "Resource": "*"
}
```

## Enable ECS Exec on the Service

ECS Exec is disabled by default. Enable it on an existing service with:

```bash
aws ecs update-service \
  --cluster <cluster-name> \
  --service <service-name> \
  --enable-execute-command
```

> [!NOTE]
> The change only takes effect for **new tasks**. Existing tasks keep running without ECS Exec support. You need to force a new deployment to replace them:
>
> ```bash
> aws ecs update-service \
>   --cluster <cluster-name> \
>   --service <service-name> \
>   --enable-execute-command \
>   --force-new-deployment
> ```

## Connect to the Container

**Step 1 — find the task ARN:**

```bash
aws ecs list-tasks \
  --cluster <cluster-name> \
  --service-name <service-name>
```

Output:

```json
{
  "taskArns": [
    "arn:aws:ecs:eu-west-1:123456789012:task/my-cluster/abc123def456"
  ]
}
```

**Step 2 — open the shell:**

```bash
aws ecs execute-command \
  --cluster <cluster-name> \
  --task <task-arn> \
  --container <container-name> \
  --command "/bin/sh" \
  --interactive
```

If the task definition has only one container, `--container` can be omitted. For tasks with multiple containers, it is required.

Use `/bin/bash` instead of `/bin/sh` if the image includes it.

## Diagnostic Script

Before manually chasing down IAM policies and service settings, run the official AWS checker script. It inspects the full ECS Exec setup for a given task and reports exactly what is missing or misconfigured.

```bash
curl -o amazon-ecs-exec-checker \
  https://raw.githubusercontent.com/aws-containers/amazon-ecs-exec-checker/main/amazon-ecs-exec-checker
chmod +x amazon-ecs-exec-checker
./amazon-ecs-exec-checker <cluster-name> <task-id>
```

The script verifies:
- AWS CLI and Session Manager plugin versions
- ECS Exec enabled flag on the task
- Fargate platform version (must be 1.4.0+)
- Task role permissions (`ssmmessages:*`)
- SSM connectivity (VPC endpoint or internet access)

> [!TIP]
> The source is on GitHub: [aws-containers/amazon-ecs-exec-checker](https://github.com/aws-containers/amazon-ecs-exec-checker)

## Troubleshooting

**`InvalidParameterException: execute command was not enabled`**

ECS Exec is not enabled on the service, or the running task predates the change. Re-enable and force a new deployment as shown above.

**`TargetNotConnectedException`**

The SSM agent in the container is not reachable. Most commonly caused by missing IAM permissions on the task role. Check that the `ssmmessages:*` policy is attached to the task's execution role.

**Session opens but immediately closes**

The command exited — usually because `/bin/sh` or `/bin/bash` does not exist in the image. Try `/bin/ash` (Alpine) or check what shells are available in the image's Dockerfile.
