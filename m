From: Daniel Gomez <da.gomez@samsung.com>
Date: Thu, 17 Oct 2024 14:42:45 +0200
Subject: [PATCH 3/5] sysbench: fix SYSBENCH_MYSQL_INNODB_REDO_LOG_CAPACITY
 typo
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241017-add-postgresql-tps-var-v1-3-4996d45426af@samsung.com>
References: <20241017-add-postgresql-tps-var-v1-0-4996d45426af@samsung.com>
In-Reply-To: <20241017-add-postgresql-tps-var-v1-0-4996d45426af@samsung.com>
To: kdevops@lists.linux.dev, mcgrof@kernel.org
Cc: d+samsung@kruces.com, Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729168974; l=1470;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=DB+ZvmYhPF9qcb4ltw+jE9FcUQQhau5ZlPsY+YOxAuo=;
 b=1dAdZeKxMdp1V4OuCSct5Q+ylOiWo9OrvwPf3VL3O99STA5i64q0pPDm1cqGmxnf4gIClS4zp
 GkWx4aP700NCAaJdtarhdiUIz3pBKVlm0E3NkRV0AHRAYLu2gvfooP8
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Just remove the extra "o".

No functional changes.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 playbooks/roles/sysbench/templates/mysql.conf.j2 | 2 +-
 workflows/sysbench/Kconfig                       | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/playbooks/roles/sysbench/templates/mysql.conf.j2 b/playbooks/roles/sysbench/templates/mysql.conf.j2
index f00fa40..225099c 100644
--- a/playbooks/roles/sysbench/templates/mysql.conf.j2
+++ b/playbooks/roles/sysbench/templates/mysql.conf.j2
@@ -33,7 +33,7 @@ default-authentication-plugin=mysql_native_password
 # For systems with above 10 GiB RAM: 0.5625 * (RAM in GB)
 # n1-standard-16: 33.75G
 # i4i.4xlarge: 72G
-innodb_redo_log_capacity        = {{ sysbench_mysql_innoodb_redo_log_capacity }}
+innodb_redo_log_capacity        = {{ sysbench_mysql_innodb_redo_log_capacity }}
 
 # For systems with above 4 GiB RAM: 0.75 * (RAM in GB)
 # n1-standard-16: 45G
diff --git a/workflows/sysbench/Kconfig b/workflows/sysbench/Kconfig
index f3878c7..35ff821 100644
--- a/workflows/sysbench/Kconfig
+++ b/workflows/sysbench/Kconfig
@@ -33,7 +33,7 @@ config SYSBENCH_MYSQL_TABLE_ENGINE
 	output yaml
 	default "innodb" if SYSBENCH_TYPE_MYSQL_DOCKER
 
-config SYSBENCH_MYSQL_INNOODB_REDO_LOG_CAPACITY
+config SYSBENCH_MYSQL_INNODB_REDO_LOG_CAPACITY
 	string "innodb_redo_log_capacity"
 	output yaml
 	default "1G" if SYSBENCH_TYPE_MYSQL_DOCKER

-- 
2.39.2

