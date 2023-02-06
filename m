From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Feb 2023 12:54:30 -0600
Subject: [PATCH v2 14/19] powerpc/pseries: convert CMO probe to
 papr_sysparm API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v2-14-9aa6bd058063@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1675709663; l=2134;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=wgP5ZTThR3IKKt3zP//ktPHmiyHjfPLomTgdKwAbQNo=;
 b=10X5+/bu59ydOVlRz84QvTlOQTdP/Af+KYekNiR+pmfiFunrH3qtGr5QafteST2n1boJwR+jy
 BOk1GdLfMQcBWQwZYAdU9qcc3trF0z4iI05lpF++ptrKdN2d8op82Xb
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Convert the direct invocation of the ibm,get-system-parameter RTAS
function to papr_sysparm_get().

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/setup.c | 23 ++++++-----------------
 1 file changed, 6 insertions(+), 17 deletions(-)

diff --git a/arch/powerpc/platforms/pseries/setup.c b/arch/powerpc/platforms/pseries/setup.c
index 74e50b6b28d4..420a2fa48292 100644
--- a/arch/powerpc/platforms/pseries/setup.c
+++ b/arch/powerpc/platforms/pseries/setup.c
@@ -57,6 +57,7 @@
 #include <asm/pmc.h>
 #include <asm/xics.h>
 #include <asm/xive.h>
+#include <asm/papr-sysparm.h>
 #include <asm/ppc-pci.h>
 #include <asm/i8259.h>
 #include <asm/udbg.h>
@@ -941,32 +942,21 @@ void pSeries_coalesce_init(void)
  */
 static void __init pSeries_cmo_feature_init(void)
 {
-	const s32 token = rtas_token("ibm,get-system-parameter");
+	static struct papr_sysparm_buf buf __initdata;
+	static_assert(sizeof(buf.val) >= CMO_MAXLENGTH);
 	char *ptr, *key, *value, *end;
-	int call_status;
 	int page_order = IOMMU_PAGE_SHIFT_4K;
 
 	pr_debug(" -> fw_cmo_feature_init()\n");
 
-	do {
-		spin_lock(&rtas_data_buf_lock);
-		call_status = rtas_call(token, 3, 1, NULL,
-					CMO_CHARACTERISTICS_TOKEN,
-					__pa(rtas_data_buf),
-					RTAS_DATA_BUF_SIZE);
-		if (call_status == 0)
-			break;
-		spin_unlock(&rtas_data_buf_lock);
-	} while (rtas_busy_delay(call_status));
-
-	if (call_status != 0) {
+	if (papr_sysparm_get(PAPR_SYSPARM_COOP_MEM_OVERCOMMIT_ATTRS, &buf)) {
 		pr_debug("CMO not available\n");
 		pr_debug(" <- fw_cmo_feature_init()\n");
 		return;
 	}
 
-	end = rtas_data_buf + CMO_MAXLENGTH - 2;
-	ptr = rtas_data_buf + 2;	/* step over strlen value */
+	end = &buf.val[CMO_MAXLENGTH];
+	ptr = &buf.val[0];
 	key = value = ptr;
 
 	while (*ptr && (ptr <= end)) {
@@ -1012,7 +1002,6 @@ static void __init pSeries_cmo_feature_init(void)
 	} else
 		pr_debug("CMO not enabled, PrPSP=%d, SecPSP=%d\n", CMO_PrPSP,
 		         CMO_SecPSP);
-	spin_unlock(&rtas_data_buf_lock);
 	pr_debug(" <- fw_cmo_feature_init()\n");
 }
 

-- 
2.39.1

