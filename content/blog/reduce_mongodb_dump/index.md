+++
title = "Shrinking a MongoDB Dump"
description = "How to reduce the size of a MongoDB dump using a temporary EC2 instance, mongorestore, and mongodump"
date = "2026-05-05T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["MongoDB"]
tags = ["mongodb", "aws", "ec2", "devops", "database"]
+++

Recently there was a need to reduce the size of a MongoDB dump. The reduced dump is used in our ephemeral environment (the ephemeral environment may be described in another post). In short, the ephemeral environment is used by developers to quickly test an application that runs as an ECS service. The application uses a MongoDB database and it's useful to have some real data in it. The dump from our test database is very large — restoring it takes a long time. Reducing the size speeds up the restore process significantly.

The test dump is created every month and stored in an S3 bucket.

## Overview

The process consists of three main stages:

1. Set up a temporary EC2 instance with the necessary tools
2. Restore the full dump to a local MongoDB instance
3. Remove unnecessary data and create a new, smaller dump

## Step 1 — Set Up a Temporary EC2 Instance

A temporary EC2 instance was created with the following configuration:

- **Instance type:** `t3.xlarge` — not too large but fast enough for this task
- **OS:** Ubuntu 24.04
- **Volume size:** large enough to hold the original dump, the restored database, and the new reduced dump

On the AWS Console, an IAM role with permissions to the S3 bucket was created and assigned to the EC2 instance. This avoids the need to manage AWS credentials manually on the instance.

There is an additional complexity here — the dump is stored in an S3 bucket on the **test account**, but the ephemeral environments and the EC2 instance run on the **dev account**. Cross-account access requires configuration on both sides.

**IAM role policy on the dev account** (attached to the EC2 instance):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::source-bucket-name-in-test-account",
                "arn:aws:s3:::source-bucket-name-in-test-account/*"
            ]
        }
    ]
}
```

**S3 bucket policy on the test account** (allows the EC2 role from the dev account to read the dump):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCrossAccountRead",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::DEV_ACCOUNT_ID:role/YOUR_EC2_ROLE_NAME"
            },
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::source-bucket-name-in-test-account/*"
        },
        {
            "Sid": "AllowCrossAccountList",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::DEV_ACCOUNT_ID:role/YOUR_EC2_ROLE_NAME"
            },
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::source-bucket-name-in-test-account"
        }
    ]
}
```

Both policies need to be in place — the IAM role policy alone is not sufficient for cross-account access. The bucket policy on the test account explicitly grants the EC2 role from the dev account permission to read from it.

### Install AWS CLI

```bash
sudo snap install aws-cli --classic
```

This is used for downloading and uploading the dump to S3.

### Install MongoDB Database Tools

MongoDB Database Tools contains `mongorestore` and `mongodump`:

```bash
curl https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-x86_64-100.9.4.tgz -o ./mongodb-database-tools.tgz
tar -zxvf mongodb-database-tools.tgz
```

The archive extracts to a directory named `mongodb-database-tools-ubuntu2204-x86_64-100.9.4`. Add the `bin/` subdirectory to PATH so the tools can be run directly:

```bash
export PATH=$PATH:$(pwd)/mongodb-database-tools-ubuntu2204-x86_64-100.9.4/bin
```

### Download and Extract the Dump from S3

```bash
aws s3 cp s3://your-bucket/mongo_backup.tar.gz .
tar -xvf mongo_backup.tar.gz
```

The dump is a tar archive containing the database files.

## Step 2 — Install MongoDB Locally

At this point the tools and the dump are in place but there is no MongoDB server to restore into. MongoDB needs to be installed locally on the EC2 instance.

### Install System Dependencies

```bash
sudo apt update
sudo apt install -y gnupg curl
```

### Import the MongoDB GPG Key

```bash
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
  sudo gpg --yes --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
```

### Add the MongoDB Repository

MongoDB 7.0 was used instead of 8.0 due to a kernel compatibility issue with Ubuntu 24.04 and MongoDB 8.0. MongoDB 7.0 can be installed on Ubuntu 24.04 using the `jammy` repository:

```bash
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
  https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
```

### Install MongoDB

```bash
sudo apt update
sudo apt install -y mongodb-org
```

### Start the MongoDB Service

```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

### Verify It's Running

```bash
sudo systemctl status mongod
```

The output should show `active (running)`.

## Step 3 — Restore, Reduce, and Dump

### Restore the Database

The dump contains several databases but only one was needed, so only that specific database was restored:

```bash
mongorestore --db="db_name" ./mnt/mongo_backup/data/db_name
```

This takes quite a long time since the database is large. Once the restore finishes, connect to the MongoDB shell:

```bash
mongosh
```

Switch to the target database:

```
test> use db_name
switched to db db_name
```

### Remove Unnecessary Data

From the MongoDB shell, documents can be removed from collections that aren't needed in the ephemeral environment. This is where the actual size reduction happens — removing old records, unused collections, or data that doesn't make sense in a development context.

### Create a New Reduced Dump

Once the cleanup is done, create a new compressed dump:

```bash
mongodump --db=db_name --archive=db_name_dump.gz --gzip
```

The `--archive` flag outputs the dump as a single file and `--gzip` compresses it, keeping the size small.

### Upload the Reduced Dump to S3

```bash
aws s3 cp db_name_dump.gz s3://your-bucket/reduced/db_name_dump.gz
```

## Cleanup

Once everything is done, terminate the EC2 instance to avoid unnecessary costs. Since the IAM role was attached to the instance rather than using access keys, there are no credentials to clean up.

## Summary

Using a temporary EC2 instance with an IAM role is a clean approach for one-off data manipulation tasks like this — no long-lived credentials, easy to clean up, and the instance type can be sized appropriately for the task. The whole process takes a few hours, mostly waiting for the initial restore of the large database.