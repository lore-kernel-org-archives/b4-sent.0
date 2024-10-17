From: Daniel Gomez <da.gomez@samsung.com>
Date: Thu, 17 Oct 2024 14:42:44 +0200
Subject: [PATCH 2/5] sysbench: fix typos
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241017-add-postgresql-tps-var-v1-2-4996d45426af@samsung.com>
References: <20241017-add-postgresql-tps-var-v1-0-4996d45426af@samsung.com>
In-Reply-To: <20241017-add-postgresql-tps-var-v1-0-4996d45426af@samsung.com>
To: kdevops@lists.linux.dev, mcgrof@kernel.org
Cc: d+samsung@kruces.com, Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729168974; l=3816;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=UTr1BKBV5HFpUQVsZDsOm4nn5v0XoS7KL6NOzpU7v84=;
 b=rOF4v+eBtQqvybhaVDx0B5uxY+drw4sIU2JAjcIOVwk7GUTL26sL0H1mTCJGFKSIIJnI9LPeM
 Y4CwMp+G5JoBm4EIMGtjBFdi0z33b9naFvNvTf3K2N374bPb7mPa02m
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Minor typos found.

pre-commit run codespell --files workflows/sysbench/Kconfig*
codespell................................................................Passed

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 workflows/sysbench/Kconfig        | 2 +-
 workflows/sysbench/Kconfig.docker | 8 ++++----
 workflows/sysbench/Kconfig.fs     | 6 +++---
 3 files changed, 8 insertions(+), 8 deletions(-)

diff --git a/workflows/sysbench/Kconfig b/workflows/sysbench/Kconfig
index b5111f1..f3878c7 100644
--- a/workflows/sysbench/Kconfig
+++ b/workflows/sysbench/Kconfig
@@ -40,7 +40,7 @@ config SYSBENCH_MYSQL_INNOODB_REDO_LOG_CAPACITY
 	help
 	  innodb_dedicated_server=ON is not compatible with innodb_flush_method=O_DIRECT
 	  and so we do what we can. See the following values which MySQL does
-	  recommand use when dedicated server is enabled, we just have to compute
+	  recommend use when dedicated server is enabled, we just have to compute
 	  on our own and test on our own:
 
 	  https://dev.mysql.com/doc/refman/8.0/en/innodb-dedicated-server.html
diff --git a/workflows/sysbench/Kconfig.docker b/workflows/sysbench/Kconfig.docker
index 2153e14..469d918 100644
--- a/workflows/sysbench/Kconfig.docker
+++ b/workflows/sysbench/Kconfig.docker
@@ -40,7 +40,7 @@ config SYSBENCH_MYSQL_CONTAINER_NAME
 	  Set the name for the MySQL Docker container.
 
 config SYSBENCH_MYSQL_CONTAINER_PYTHON_PATH
-	string "The MySQL container pytyhon path"
+	string "The MySQL container python path"
 	default "/usr/local/lib/python3.9/site-packages" if SYSBENCH_MYSQL_CONTAINER_IMAGE_8_0
 	output yaml
 	help
@@ -60,7 +60,7 @@ config SYSBENCH_MYSQL_CONTAINER_HOST_CLIENT_CONFIG_PATH
 	  us make edits on the node.
 
 config SYSBENCH_MYSQL_CONTAINER_CLIENT_CONFIG
-	string "The MySQL container client configuraton file"
+	string "The MySQL container client configuration file"
 	default "/root/.my.cnf"
 	output yaml
 	help
@@ -101,7 +101,7 @@ config SYSBENCH_MYSQL_CONTAINER_HOST_ROOT_PATH
 	  When using a container, in order to support telemetry we rely on
 	  a mysqlsh plugin which we git clone on the node where we will
 	  run the container on. We use a container volume to let the container
-	  get access to this clone. This specificies the path on the node which
+	  get access to this clone. This specifies the path on the node which
 	  we will use a docker volume passed onto the container as the
 	  /root/ directory.
 
@@ -145,4 +145,4 @@ config SYSBENCH_DOCKER_TELEMETRY_PATH
 	default SYSBENCH_TELEMETRY_PATH
 	output yaml
 	help
-	  Where to place telemetry informaton inside the docker container.
+	  Where to place telemetry information inside the docker container.
diff --git a/workflows/sysbench/Kconfig.fs b/workflows/sysbench/Kconfig.fs
index 75f163e..b0f6e61 100644
--- a/workflows/sysbench/Kconfig.fs
+++ b/workflows/sysbench/Kconfig.fs
@@ -7,12 +7,12 @@ config SYSBENCH_TEST_ATOMICS
 	output yaml
 	select KDEVOPS_BASELINE_AND_DEV
 	help
-	  This type of test is aimed of testing the emperical value of support
+	  This type of test is aimed of testing the empirical value of support
 	  for large atomics on storage devices and its impact on databases.
-	  Most drives today support only power-fail safe gaurantees when writing
+	  Most drives today support only power-fail safe guarantees when writing
 	  up to 4 KiB. Drives which support 16 KiB atomic writes or larger can
 	  take advanage of software features in databases which typically
-	  do software work arounds to gaurantee writes above 4 KiB will be
+	  do software work arounds to guarantee writes above 4 KiB will be
 	  recoverable in case of power failure.
 
 	  Different database have different features one can disable if one has

-- 
2.39.2

