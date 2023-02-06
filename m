From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Feb 2023 12:54:19 -0600
Subject: [PATCH v2 03/19] powerpc/pseries/lpar: add missing RTAS retry
 status handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v2-3-9aa6bd058063@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1675709663; l=2144;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=ajtkYWVOaFKCXAuikYVhaPDQDEeGzBrJnlrOFdrl4PE=;
 b=yUbbTlfhqzUtPdBb1ORSX8ZPMDzrxB5eN3eHY8Ckaj9IXVFBrKMppVJRyqkXKx96NuFUfMT8x
 UualyMegJwaBNj2IGYbjZfn4bmzxtz8Jit9ZJFo3w7DUyY6Vpp7x+Q9
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

The ibm,get-system-parameter RTAS function may return -2 or 990x,
which indicate that the caller should try again.

pseries_lpar_read_hblkrm_characteristics() ignores this, making it
possible to incorrectly detect TLB block invalidation characteristics
at boot.

Move the RTAS call into a coventional rtas_busy_delay()-based loop.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Fixes: 1211ee61b4a8 ("powerpc/pseries: Read TLB Block Invalidate Characteristics")
---
 arch/powerpc/platforms/pseries/lpar.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/arch/powerpc/platforms/pseries/lpar.c b/arch/powerpc/platforms/pseries/lpar.c
index 97ef6499e501..6597b2126ebb 100644
--- a/arch/powerpc/platforms/pseries/lpar.c
+++ b/arch/powerpc/platforms/pseries/lpar.c
@@ -1481,22 +1481,22 @@ static inline void __init check_lp_set_hblkrm(unsigned int lp,
 
 void __init pseries_lpar_read_hblkrm_characteristics(void)
 {
+	const s32 token = rtas_token("ibm,get-system-parameter");
 	unsigned char local_buffer[SPLPAR_TLB_BIC_MAXLENGTH];
 	int call_status, len, idx, bpsize;
 
 	if (!firmware_has_feature(FW_FEATURE_BLOCK_REMOVE))
 		return;
 
-	spin_lock(&rtas_data_buf_lock);
-	memset(rtas_data_buf, 0, RTAS_DATA_BUF_SIZE);
-	call_status = rtas_call(rtas_token("ibm,get-system-parameter"), 3, 1,
-				NULL,
-				SPLPAR_TLB_BIC_TOKEN,
-				__pa(rtas_data_buf),
-				RTAS_DATA_BUF_SIZE);
-	memcpy(local_buffer, rtas_data_buf, SPLPAR_TLB_BIC_MAXLENGTH);
-	local_buffer[SPLPAR_TLB_BIC_MAXLENGTH - 1] = '\0';
-	spin_unlock(&rtas_data_buf_lock);
+	do {
+		spin_lock(&rtas_data_buf_lock);
+		memset(rtas_data_buf, 0, RTAS_DATA_BUF_SIZE);
+		call_status = rtas_call(token, 3, 1, NULL, SPLPAR_TLB_BIC_TOKEN,
+					__pa(rtas_data_buf), RTAS_DATA_BUF_SIZE);
+		memcpy(local_buffer, rtas_data_buf, SPLPAR_TLB_BIC_MAXLENGTH);
+		local_buffer[SPLPAR_TLB_BIC_MAXLENGTH - 1] = '\0';
+		spin_unlock(&rtas_data_buf_lock);
+	} while (rtas_busy_delay(call_status));
 
 	if (call_status != 0) {
 		pr_warn("%s %s Error calling get-system-parameter (0x%x)\n",

-- 
2.39.1

