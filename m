From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Feb 2023 12:54:28 -0600
Subject: [PATCH v2 12/19] powerpc/pseries/dlpar: use RTAS work area API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v2-12-9aa6bd058063@linux.ibm.com>
References: <20230125-b4-powerpc-rtas-queue-v2-0-9aa6bd058063@linux.ibm.com>
In-Reply-To: <20230125-b4-powerpc-rtas-queue-v2-0-9aa6bd058063@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Kajol Jain <kjain@linux.ibm.com>, Laurent Dufour <ldufour@linux.ibm.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Andrew Donnellan <ajd@linux.ibm.com>, Nick Child <nnac123@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1675709663; l=2354;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=9dtec63TyTAEuoicCzxLzqqe0gY/Ou+fcqwMt3OKZi4=;
 b=hp7Eyn3aDtjazWR66YZJl+askh38zNTJB8W1M2enk+AjTFOT3ZPGXtB2Gore79uN7q4XiJU1v
 7YmmKcr/ZmxB254Gt9l+qzSOJqqTlvIHmi3Upu/8KyXPNMxS74h1l4c
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Hold a work area object for the duration of the RTAS
ibm,configure-connector sequence, eliminating locking and copying
around each RTAS call.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/dlpar.c | 27 +++++++++------------------
 1 file changed, 9 insertions(+), 18 deletions(-)

diff --git a/arch/powerpc/platforms/pseries/dlpar.c b/arch/powerpc/platforms/pseries/dlpar.c
index 498d6efcb5ae..9b65b50a5456 100644
--- a/arch/powerpc/platforms/pseries/dlpar.c
+++ b/arch/powerpc/platforms/pseries/dlpar.c
@@ -22,6 +22,7 @@
 #include <asm/machdep.h>
 #include <linux/uaccess.h>
 #include <asm/rtas.h>
+#include <asm/rtas-work-area.h>
 
 static struct workqueue_struct *pseries_hp_wq;
 
@@ -137,6 +138,7 @@ struct device_node *dlpar_configure_connector(__be32 drc_index,
 	struct property *property;
 	struct property *last_property = NULL;
 	struct cc_workarea *ccwa;
+	struct rtas_work_area *work_area;
 	char *data_buf;
 	int cc_token;
 	int rc = -1;
@@ -145,29 +147,18 @@ struct device_node *dlpar_configure_connector(__be32 drc_index,
 	if (cc_token == RTAS_UNKNOWN_SERVICE)
 		return NULL;
 
-	data_buf = kzalloc(RTAS_DATA_BUF_SIZE, GFP_KERNEL);
-	if (!data_buf)
-		return NULL;
+	work_area = rtas_work_area_alloc(SZ_4K);
+	data_buf = rtas_work_area_raw_buf(work_area);
 
 	ccwa = (struct cc_workarea *)&data_buf[0];
 	ccwa->drc_index = drc_index;
 	ccwa->zero = 0;
 
 	do {
-		/* Since we release the rtas_data_buf lock between configure
-		 * connector calls we want to re-populate the rtas_data_buffer
-		 * with the contents of the previous call.
-		 */
-		spin_lock(&rtas_data_buf_lock);
-
-		memcpy(rtas_data_buf, data_buf, RTAS_DATA_BUF_SIZE);
-		rc = rtas_call(cc_token, 2, 1, NULL, rtas_data_buf, NULL);
-		memcpy(data_buf, rtas_data_buf, RTAS_DATA_BUF_SIZE);
-
-		spin_unlock(&rtas_data_buf_lock);
-
-		if (rtas_busy_delay(rc))
-			continue;
+		do {
+			rc = rtas_call(cc_token, 2, 1, NULL,
+				       rtas_work_area_phys(work_area), NULL);
+		} while (rtas_busy_delay(rc));
 
 		switch (rc) {
 		case COMPLETE:
@@ -227,7 +218,7 @@ struct device_node *dlpar_configure_connector(__be32 drc_index,
 	} while (rc);
 
 cc_error:
-	kfree(data_buf);
+	rtas_work_area_free(work_area);
 
 	if (rc) {
 		if (first_dn)

-- 
2.39.1

