From: Daniel Gomez <da.gomez@samsung.com>
Subject: [PATCH v2 0/2] sysbench: add postgresql tps variability
Date: Wed, 23 Oct 2024 11:26:13 +0200
Message-Id: <20241023-add-postgresql-tps-var-v2-0-ff2f3c6e1632@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADXBGGcC/4WNQQ7CIBBFr9LM2jFAkAZX3sN0gYVSEltaphJNw
 93FXsDle8l/fwdyKTiCa7NDcjlQiHMFcWqgH83sHQZbGQQTkjPeorEWl0ibT47WJ24LYTYJ2cO
 0vRislkpDHS/JDeF9hO9d5THQFtPn+Mn8Z/8mM0eGUmtl5UUKZYYbmYlesz/3cYKulPIFmgT5Y
 74AAAA=
To: kdevops@lists.linux.dev, mcgrof@kernel.org
Cc: d+samsung@kruces.com, Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729675585; l=2457;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=FgGlflK+ly9RvAR1AS3jd4m4g5+C8WmPuYjNdn6U7zM=;
 b=dO/fsqeaWhZ/pWhFfjnsOfHOiPh2yHm6EuRClLAnoLUEUWyea2FN6uqcqNJj3pc3WwZ4exHi1
 DtX1gqax5rdBam2IvAjO1gznbfXUJ/H5Gw5ljzK7xbotHXh5orXer3G
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch set adds the PostgreSQL TPS variability benchmark using
sysbench workload.

Split sysbench workloads into two separate Ansible task YAML files,
one for MySQL (docker) and one for PostgreSQL (native), to create
self-contained workload files, enabling independent control of task
workflows.

To: kdevops@lists.linux.dev
To: mcgrof@kernel.org
Cc: d+samsung@kruces.com

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
Changes in v2:
* Make sysbench PostgreSQL workload idempotence (sysbench vs
sysbench-test).
* Add/fix plots target (sysbench-plot).
* Move 'tags' keyword to the top of the task for better control flow
review.
* Add results/<host>-ab/ directory to place 'a vs b' plots.
* Add 2 different configuration templates for PostgreSQL. Default with
full_page_writes on/off based on kconfig (+ port). Extra with custom
options + full_page_writes on/off based on kconfig (+ port).
* Sysbench workflow test with 14 profiles (xfs and ext4).
* Move command to shell when plotting to fix space/arg issue.
* Merged patches:
sysbench: fix kconfig tabs -- patch contents already upstream
sysbench: fix typos -- patch contents already upstream
sysbench: fix SYSBENCH_MYSQL_INNODB_REDO_LOG_CAPACITY typo
* Add code-review trailers.

- Link to v1: https://lore.kernel.org/r/20241017-add-postgresql-tps-var-v1-0-4996d45426af@samsung.com

---
Daniel Gomez (2):
      sysbench: split mysql-docker benchmark
      sysbench: add postgresql native TPS variablity support

 playbooks/roles/sysbench/defaults/main.yml         |  15 +
 .../sysbench/tasks/install-deps/debian/main.yml    |  64 +-
 playbooks/roles/sysbench/tasks/main.yaml           | 777 +------------------
 .../roles/sysbench/tasks/mysql-docker/main.yaml    | 773 +++++++++++++++++++
 .../sysbench/tasks/postgresql-native/main.yaml     | 735 ++++++++++++++++++
 .../sysbench/templates/postgresql-conf-000.conf.j2 | 820 +++++++++++++++++++++
 .../templates/postgresql-conf-default.conf.j2      | 820 +++++++++++++++++++++
 workflows/sysbench/Kconfig                         |  47 ++
 workflows/sysbench/Kconfig.fs                      |  30 +
 workflows/sysbench/Kconfig.native                  | 138 ++++
 10 files changed, 3446 insertions(+), 773 deletions(-)
---
base-commit: 38746a0f1bced2e58d5c5d36618e111d348a7ae3
change-id: 20241017-add-postgresql-tps-var-0ba7c2fd9469

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>

