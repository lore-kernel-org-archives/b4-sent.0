From: Daniel Gomez <da.gomez@samsung.com>
Date: Thu, 17 Oct 2024 14:42:43 +0200
Subject: [PATCH 1/5] sysbench: fix kconfig tabs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241017-add-postgresql-tps-var-v1-1-4996d45426af@samsung.com>
References: <20241017-add-postgresql-tps-var-v1-0-4996d45426af@samsung.com>
In-Reply-To: <20241017-add-postgresql-tps-var-v1-0-4996d45426af@samsung.com>
To: kdevops@lists.linux.dev, mcgrof@kernel.org
Cc: d+samsung@kruces.com, Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729168974; l=702;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=n9zuQZ+KTMba0vEMVBEHRYHPXbQoGBm0dlsF88evts4=;
 b=bTjI7euGMdKwA0qZFuHyuwDn2AnMQsSxqhmxNdD+QcF2oG6UJ3UUEqnVOV1kGJwtWn+7wLRHj
 vfJx1/rt356A80/iKVdoS/D0IbPWWEtFYTSHJdwsx7pX3hJ3gbcI1I4
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace spaces with tabs.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 workflows/sysbench/Kconfig.xfs | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/workflows/sysbench/Kconfig.xfs b/workflows/sysbench/Kconfig.xfs
index adc0b03..060d58c 100644
--- a/workflows/sysbench/Kconfig.xfs
+++ b/workflows/sysbench/Kconfig.xfs
@@ -12,8 +12,8 @@ config SYSBENCH_SUPPORTED_FILESYSTEM_XFS
 	default y
 
 choice
-    prompt "XFS filesystem sector size to use"
-    default SYSBENCH_XFS_SECTOR_SIZE_4K
+	prompt "XFS filesystem sector size to use"
+	default SYSBENCH_XFS_SECTOR_SIZE_4K
 
 config SYSBENCH_XFS_SECTOR_SIZE_512
 	bool "512 bytes"

-- 
2.39.2

