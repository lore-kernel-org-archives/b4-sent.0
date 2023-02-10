From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 10 Feb 2023 12:41:53 -0600
Subject: [PATCH v3 05/20] powerpc/pseries/setup: add missing RTAS retry
 status handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v3-5-26929c8cce78@linux.ibm.com>
References: <20230125-b4-powerpc-rtas-queue-v3-0-26929c8cce78@linux.ibm.com>
In-Reply-To: <20230125-b4-powerpc-rtas-queue-v3-0-26929c8cce78@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Kajol Jain <kjain@linux.ibm.com>, Laurent Dufour <ldufour@linux.ibm.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Andrew Donnellan <ajd@linux.ibm.com>, Nick Child <nnac123@linux.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1676054526; l=1829;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=aH9kPV3aFPMqcCE52OuDxtWD73a59nhFm3joQpSLnP0=;
 b=25wCYjC4s7Jnh+6h2rMHJD2wlV+bFYheTI9QdhYFuoa/n9EHeQW7dj2UNgW3hu7bB4qGn0GFZ
 M8N+qKKCIj3CXO0bKBgZjjyKkX2yrrFXDFX3D9MsYs/8mcHFeVtIixU
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

The ibm,get-system-parameter RTAS function may return -2 or 990x,
which indicate that the caller should try again.

pSeries_cmo_feature_init() ignores this, making it possible to fail to
detect cooperative memory overcommit capabilities during boot.

Move the RTAS call into a conventional rtas_busy_delay()-based
loop, dropping unnecessary clearing of rtas_data_buf.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/setup.c | 20 ++++++++++++--------
 1 file changed, 12 insertions(+), 8 deletions(-)

diff --git a/arch/powerpc/platforms/pseries/setup.c b/arch/powerpc/platforms/pseries/setup.c
index 8ef3270515a9..74e50b6b28d4 100644
--- a/arch/powerpc/platforms/pseries/setup.c
+++ b/arch/powerpc/platforms/pseries/setup.c
@@ -941,21 +941,25 @@ void pSeries_coalesce_init(void)
  */
 static void __init pSeries_cmo_feature_init(void)
 {
+	const s32 token = rtas_token("ibm,get-system-parameter");
 	char *ptr, *key, *value, *end;
 	int call_status;
 	int page_order = IOMMU_PAGE_SHIFT_4K;
 
 	pr_debug(" -> fw_cmo_feature_init()\n");
-	spin_lock(&rtas_data_buf_lock);
-	memset(rtas_data_buf, 0, RTAS_DATA_BUF_SIZE);
-	call_status = rtas_call(rtas_token("ibm,get-system-parameter"), 3, 1,
-				NULL,
-				CMO_CHARACTERISTICS_TOKEN,
-				__pa(rtas_data_buf),
-				RTAS_DATA_BUF_SIZE);
 
-	if (call_status != 0) {
+	do {
+		spin_lock(&rtas_data_buf_lock);
+		call_status = rtas_call(token, 3, 1, NULL,
+					CMO_CHARACTERISTICS_TOKEN,
+					__pa(rtas_data_buf),
+					RTAS_DATA_BUF_SIZE);
+		if (call_status == 0)
+			break;
 		spin_unlock(&rtas_data_buf_lock);
+	} while (rtas_busy_delay(call_status));
+
+	if (call_status != 0) {
 		pr_debug("CMO not available\n");
 		pr_debug(" <- fw_cmo_feature_init()\n");
 		return;

-- 
2.39.1

