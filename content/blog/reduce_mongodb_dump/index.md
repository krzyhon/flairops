+++
title = "Shrinking a MongoDB Dump"
description = "How to reduce the size of a MongoDB dump using a temporary EC2 instance, mongorestore, and mongodump"
date = "2026-05-05T10:00:00+02:00"
author = "Krzysztof Filar"
categories = ["MongoDB"]
tags = ["mongodb", "aws", "ec2", "devops", "database"]
+++

A MongoDB dump from a production or test database can grow to tens or even hundreds of gigabytes over time. Restoring such a dump into a development or ephemeral environment is painful — it takes a long time and consumes significant disk space for data that developers don't actually need.

The solution is to shrink the dump: restore it to a temporary MongoDB instance, remove everything that isn't needed, and create a new, smaller dump. This post walks through that process step by step.

## Context

The reduced dump is used in an ephemeral environment — a short-lived environment used by developers to quickly test an application running as an ECS service. The application needs a MongoDB database with some representative data, but it doesn't need the full dataset from the test environment.

The test dump is created every month and stored in an S3 bucket on the test AWS account. The ephemeral environments run on the dev AWS account — so cross-account S3 access is also required.

## Overview

The process consists of three main stages:

1. Set up a temporary EC2 instance with the necessary tools
2. Restore the full dump to a local MongoDB instance
3. Remove unnecessary data and create a new, smaller dump

## Step 1 — Set Up a Temporary EC2 Instance

### Instance Configuration

A temporary EC2 instance was created with the following configuration:

- **Instance type:** `t3.xlarge` (4 vCPU, 16 GB RAM) — MongoDB's `mongorestore` is CPU and memory intensive. A smaller instance like `t3.medium` would work but would be significantly slower for large databases.
- **OS:** Ubuntu 24.04
- **Volume size:** at least 3× the size of the original compressed dump. For example, if the dump is 20 GB compressed, allocate at least 60 GB — space is needed for the compressed dump, the extracted files, the restored database, and the new reduced dump.

### IAM Role for Cross-Account S3 Access

Using an IAM role attached to the EC2 instance is the recommended approach — it avoids storing long-lived AWS credentials on the instance. However, since the dump lives in an S3 bucket on a different AWS account (test account), cross-account access must be configured on both sides.

**IAM role policy on the dev account** (attached to the EC2 instance):

This policy grants the EC2 instance permission to read from the S3 bucket on the test account.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowReadFromTestBucket",
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

**S3 bucket policy on the test account:**

The IAM role policy alone is not sufficient for cross-account access. The bucket on the test account must also explicitly grant the EC2 role from the dev account permission to read from it.

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

Both policies must be in place before the EC2 instance can access the dump.

### Install AWS CLI

```bash
sudo snap install aws-cli --classic
```

Used for downloading the original dump from S3 and uploading the reduced dump back.

### Install MongoDB Database Tools

MongoDB Database Tools is a separate package from the MongoDB server. It provides `mongorestore` and `mongodump` among other utilities:

```bash
curl https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-x86_64-100.9.4.tgz \
  -o ./mongodb-database-tools.tgz
tar -zxvf mongodb-database-tools.tgz
```

The archive extracts to a versioned directory. Add its `bin/` subdirectory to PATH so the tools can be run directly without specifying the full path:

```bash
export PATH=$PATH:$(pwd)/mongodb-database-tools-ubuntu2204-x86_64-100.9.4/bin
```

Note that this PATH change only persists for the current shell session. If the session is closed and reopened, the export command needs to be run again.

### Download and Extract the Dump from S3

```bash
aws s3 cp s3://your-bucket/mongo_backup.tar.gz .
tar -xvf mongo_backup.tar.gz
```

The dump is a tar archive. After extraction, note the directory structure — the path to the specific database directory will be needed in the restore step. It typically looks like `./mongo_backup/data/db_name`.

## Step 2 — Install MongoDB Locally

At this point the tools and the dump are in place but there is no MongoDB server to restore into. MongoDB 7.0 was used here instead of 8.0 due to a kernel compatibility issue between Ubuntu 24.04 and MongoDB 8.0. MongoDB 7.0 can be installed on Ubuntu 24.04 using the `jammy` repository.

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

The output should show `active (running)`. If it doesn't start, check the logs:

```bash
sudo tail -f /var/log/mongodb/mongod.log
```

## Step 3 — Restore, Reduce, and Dump

### Restore the Database

The dump contains several databases but only one is needed. The `--db` flag restores only the specified database, which saves both time and disk space compared to restoring everything:

```bash
mongorestore --db="db_name" ./mongo_backup/data/db_name
```

This takes quite a long time for a large database — the restore process is single-threaded and involves writing every document to disk. Monitor progress with:

```bash
# in a separate terminal
watch -n 5 'du -sh /var/lib/mongodb'
```

### Connect to the MongoDB Shell

Once the restore finishes, connect to the MongoDB shell to inspect and clean the data:

```bash
mongosh
```

Switch to the restored database:

```
test> use db_name
switched to db db_name
```

List collections to see what's available:

```
db_name> show collections
```

Check the size of each collection to identify which ones are the largest:

```
db_name> db.stats()
```

Or per collection:

```
db_name> db.collection_name.stats().size
```

### Remove Unnecessary Data

This is the most important step — where the actual size reduction happens. Depending on what data is needed for development, there are several approaches:

**Drop an entire collection** that isn't needed at all:

```
db_name> db.collection_name.drop()
```

**Delete old documents** based on a date field, keeping only recent data:

```
db_name> db.collection_name.deleteMany({ createdAt: { $lt: new Date("2025-01-01") } })
```

**Delete documents based on multiple conditions** — for example, removing companies that are either older than a certain date or have an inactive status:

```
db_name> db.collection_1.deleteMany({
  $or: [
    { created_on: { $lt: ISODate('2025-01-01T12:00:00.000+00:00') } },
    { status: 0 }
  ]
})
```

**Delete orphaned documents** — after removing companies, remove users that no longer have a matching company. The `$nin` operator filters out users whose `company` field references a company that no longer exists:

```
db_name> db.collection_2.deleteMany({
  company: { $nin: db.collection_1.distinct("_id") }
})
```

This is an important step when collections have references between them — removing parent documents without cleaning up child documents leaves orphaned data that wastes space and could cause application errors.

After cleanup, verify the size reduction:

```
db_name> db.stats()
```

Run `db.repairDatabase()` or compact collections to reclaim disk space before dumping:

```
db_name> db.runCommand({ compact: "collection_name" })
```

### Create a New Reduced Dump

Once the cleanup is done, create a new compressed dump:

```bash
mongodump --db=db_name --archive=db_name_dump.gz --gzip
```

The `--archive` flag outputs the entire dump as a single file instead of a directory of BSON files. Combined with `--gzip`, this produces a compact, portable file in the current working directory.

### Upload the Reduced Dump to S3

```bash
aws s3 cp db_name_dump.gz s3://your-bucket/reduced/db_name_dump.gz
```

## Cleanup

Once everything is done, terminate the EC2 instance to avoid unnecessary costs. Since the IAM role was attached to the instance rather than using access keys, there are no credentials to revoke or rotate.

## Summary

Using a temporary EC2 instance with an IAM role is a clean, secure approach for one-off data manipulation tasks. The key points:

- Size the instance appropriately — `mongorestore` is memory-intensive and a larger instance significantly speeds up the process
- Allocate at least 3× the compressed dump size for disk space
- For cross-account S3 access, both the IAM role policy and the bucket policy must be configured
- Be selective when restoring — use `--db` to restore only the database needed rather than the entire dump
- Use `compact` before dumping to reclaim disk space freed by deletions
- Terminate the instance immediately after finishing to avoid ongoing costs