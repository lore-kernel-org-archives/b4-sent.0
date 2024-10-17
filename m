From: Daniel Gomez <da.gomez@samsung.com>
Subject: [PATCH 0/5] sysbench: add postgresql tps variability
Date: Thu, 17 Oct 2024 14:42:42 +0200
Message-Id: <20241017-add-postgresql-tps-var-v1-0-4996d45426af@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEIGEWcC/x3MMQqAMAxA0atIZgNtKYpeRRyqjRoQrYmIIN7d4
 viG/x9QEiaFtnhA6GLlfcuwZQHjEraZkGM2OOO8NbbGECOmXc9ZSI8Vz6R4BUEzhHp0U2x81UC
 Ok9DE9z/u+vf9AAwyBPloAAAA
To: kdevops@lists.linux.dev, mcgrof@kernel.org
Cc: d+samsung@kruces.com, Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729168974; l=2063;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=poG3CR1cuY1WAvBrr/SBnCU91zyl4d528WGWaCQq+Yo=;
 b=1tuzi0Vf0rCwsj9H0Emawxk57CVlIL1i14/gW0nPq29mmSlCmLLM/2AzBQ7e1Lyxhtd60oiTR
 kqpBkKy4RMWCd0bgiLz7UOTAlETVK7DZkDGoT1lLxkTQ4TLBIgcFK/b
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch set adds the PostgreSQL TPS variability benchmark using
sysbench workload.

I decided to split the sysbench workloads in 2: MySQL (docker) and
PostgreSQL (native). Some tasks are copy-pasted from MySQL task list but
I think this allows every workload to be self-contained. Althought it
duplicates code. What do you think?

I'm also using ansible lsp and lint and found quite some interesting
things fixed in the postgres yaml. Are you guys using anything similar?

Note: Plots and telemetry is still work in progress.

To: kdevops@lists.linux.dev
To: mcgrof@kernel.org
Cc: d+samsung@kruces.com

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
Daniel Gomez (5):
      sysbench: fix kconfig tabs
      sysbench: fix typos
      sysbench: fix SYSBENCH_MYSQL_INNODB_REDO_LOG_CAPACITY typo
      sysbench: split mysql-docker benchmark
      sysbench: add postgresql native TPS variablity support

 playbooks/roles/sysbench/defaults/main.yml         |  15 +
 .../sysbench/tasks/install-deps/debian/main.yml    |  47 ++
 playbooks/roles/sysbench/tasks/main.yaml           | 777 +------------------
 .../roles/sysbench/tasks/mysql-docker/main.yaml    | 773 +++++++++++++++++++
 .../sysbench/tasks/postgresql-native/main.yaml     | 708 ++++++++++++++++++
 playbooks/roles/sysbench/templates/mysql.conf.j2   |   2 +-
 .../sysbench/templates/postgresql-conf-000.conf.j2 | 820 +++++++++++++++++++++
 .../templates/postgresql-conf-default.conf.j2      | 820 +++++++++++++++++++++
 workflows/sysbench/Kconfig                         |  51 +-
 workflows/sysbench/Kconfig.docker                  |   8 +-
 workflows/sysbench/Kconfig.fs                      |  36 +-
 workflows/sysbench/Kconfig.native                  | 120 +++
 workflows/sysbench/Kconfig.xfs                     |   4 +-
 13 files changed, 3398 insertions(+), 783 deletions(-)
---
base-commit: 30a309572af702fddae3309933ca0fda92a24246
change-id: 20241017-add-postgresql-tps-var-0ba7c2fd9469

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>

