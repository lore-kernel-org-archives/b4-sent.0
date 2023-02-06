From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Feb 2023 12:54:33 -0600
Subject: [PATCH v2 17/19] powerpc/pseries/lpar: convert to papr_sysparm API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v2-17-9aa6bd058063@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1675709663; l=3125;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=aaR7aumIxEJSYWOkDTaOL4g2oJrS4KScc2sc8zj694c=;
 b=g2MEa5WQIRxZgmsuUk4evMKnE0IGq2mUzOn1Sisy30/bQatvu7ONhSnfk2/kK0wTay1+B5wEu
 BMFJIcEeH6XDAVQOWEpJ9P8nZewWN8sRKmlw/ZPvkhQFUv57LbhGJdc
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Convert the TLB block invalidate characteristics discovery to the new
papr_sysparm API. This occurs too early in boot to use
papr_sysparm_buf_alloc(), so use a static buffer.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/platforms/pseries/lpar.c | 37 +++++++++--------------------------
 1 file changed, 9 insertions(+), 28 deletions(-)

diff --git a/arch/powerpc/platforms/pseries/lpar.c b/arch/powerpc/platforms/pseries/lpar.c
index 6597b2126ebb..2eab323f6970 100644
--- a/arch/powerpc/platforms/pseries/lpar.c
+++ b/arch/powerpc/platforms/pseries/lpar.c
@@ -32,6 +32,7 @@
 #include <asm/iommu.h>
 #include <asm/tlb.h>
 #include <asm/cputable.h>
+#include <asm/papr-sysparm.h>
 #include <asm/udbg.h>
 #include <asm/smp.h>
 #include <asm/trace.h>
@@ -1469,8 +1470,6 @@ static inline void __init check_lp_set_hblkrm(unsigned int lp,
 	}
 }
 
-#define SPLPAR_TLB_BIC_TOKEN		50
-
 /*
  * The size of the TLB Block Invalidate Characteristics is variable. But at the
  * maximum it will be the number of possible page sizes *2 + 10 bytes.
@@ -1481,42 +1480,24 @@ static inline void __init check_lp_set_hblkrm(unsigned int lp,
 
 void __init pseries_lpar_read_hblkrm_characteristics(void)
 {
-	const s32 token = rtas_token("ibm,get-system-parameter");
-	unsigned char local_buffer[SPLPAR_TLB_BIC_MAXLENGTH];
-	int call_status, len, idx, bpsize;
+	static struct papr_sysparm_buf buf __initdata;
+	int len, idx, bpsize;
 
 	if (!firmware_has_feature(FW_FEATURE_BLOCK_REMOVE))
 		return;
 
-	do {
-		spin_lock(&rtas_data_buf_lock);
-		memset(rtas_data_buf, 0, RTAS_DATA_BUF_SIZE);
-		call_status = rtas_call(token, 3, 1, NULL, SPLPAR_TLB_BIC_TOKEN,
-					__pa(rtas_data_buf), RTAS_DATA_BUF_SIZE);
-		memcpy(local_buffer, rtas_data_buf, SPLPAR_TLB_BIC_MAXLENGTH);
-		local_buffer[SPLPAR_TLB_BIC_MAXLENGTH - 1] = '\0';
-		spin_unlock(&rtas_data_buf_lock);
-	} while (rtas_busy_delay(call_status));
-
-	if (call_status != 0) {
-		pr_warn("%s %s Error calling get-system-parameter (0x%x)\n",
-			__FILE__, __func__, call_status);
+	if (papr_sysparm_get(PAPR_SYSPARM_TLB_BLOCK_INVALIDATE_ATTRS, &buf))
 		return;
-	}
 
-	/*
-	 * The first two (2) bytes of the data in the buffer are the length of
-	 * the returned data, not counting these first two (2) bytes.
-	 */
-	len = be16_to_cpu(*((u16 *)local_buffer)) + 2;
+	len = be16_to_cpu(buf.len);
 	if (len > SPLPAR_TLB_BIC_MAXLENGTH) {
 		pr_warn("%s too large returned buffer %d", __func__, len);
 		return;
 	}
 
-	idx = 2;
+	idx = 0;
 	while (idx < len) {
-		u8 block_shift = local_buffer[idx++];
+		u8 block_shift = buf.val[idx++];
 		u32 block_size;
 		unsigned int npsize;
 
@@ -1525,9 +1506,9 @@ void __init pseries_lpar_read_hblkrm_characteristics(void)
 
 		block_size = 1 << block_shift;
 
-		for (npsize = local_buffer[idx++];
+		for (npsize = buf.val[idx++];
 		     npsize > 0 && idx < len; npsize--)
-			check_lp_set_hblkrm((unsigned int) local_buffer[idx++],
+			check_lp_set_hblkrm((unsigned int)buf.val[idx++],
 					    block_size);
 	}
 

-- 
2.39.1

