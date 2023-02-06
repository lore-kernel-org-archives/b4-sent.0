From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Feb 2023 12:54:32 -0600
Subject: [PATCH v2 16/19] powerpc/pseries/hv-24x7: convert to papr_sysparm
 API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v2-16-9aa6bd058063@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1675709663; l=2846;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=lmBcfoH0lj/2CvQfdz+MmavuamXOYSbQQ5ghGV+grHI=;
 b=Zy9zVqbkchRAMfKGtvWK2WUVrJshDR0/y3x55iNQKrPuES4pmOm0HN9jOxxLakDMsqaysUbvP
 fU5fNWhPDbED3A8ZZ+5yE5lp6YlVIZW1WqfgCp8iYZ6UGKE1ee5UhWE
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

The new papr_sysparm API handles the details of system parameter
retrieval. Use that instead of open-coding the RTAS call, work area
management, and retries.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/perf/hv-24x7.c | 37 +++++++++++++++----------------------
 1 file changed, 15 insertions(+), 22 deletions(-)

diff --git a/arch/powerpc/perf/hv-24x7.c b/arch/powerpc/perf/hv-24x7.c
index fcfebf5bd378..f388b984a336 100644
--- a/arch/powerpc/perf/hv-24x7.c
+++ b/arch/powerpc/perf/hv-24x7.c
@@ -18,6 +18,7 @@
 #include <asm/firmware.h>
 #include <asm/hvcall.h>
 #include <asm/io.h>
+#include <asm/papr-sysparm.h>
 #include <linux/byteorder/generic.h>
 
 #include <asm/rtas.h>
@@ -66,8 +67,6 @@ static bool is_physical_domain(unsigned int domain)
  * Refer PAPR+ document to get parameter token value as '43'.
  */
 
-#define PROCESSOR_MODULE_INFO   43
-
 static u32 phys_sockets;	/* Physical sockets */
 static u32 phys_chipspersocket;	/* Physical chips per socket*/
 static u32 phys_coresperchip; /* Physical cores per chip */
@@ -79,8 +78,7 @@ static u32 phys_coresperchip; /* Physical cores per chip */
  */
 void read_24x7_sys_info(void)
 {
-	const s32 token = rtas_token("ibm,get-system-parameter");
-	int call_status;
+	struct papr_sysparm_buf *buf;
 
 	/*
 	 * Making system parameter: chips and sockets and cores per chip
@@ -90,27 +88,22 @@ void read_24x7_sys_info(void)
 	phys_chipspersocket = 1;
 	phys_coresperchip = 1;
 
-	do {
-		spin_lock(&rtas_data_buf_lock);
-		call_status = rtas_call(token, 3, 1, NULL, PROCESSOR_MODULE_INFO,
-					__pa(rtas_data_buf), RTAS_DATA_BUF_SIZE);
-		if (call_status == 0) {
-			int ntypes = be16_to_cpup((__be16 *)&rtas_data_buf[2]);
-			int len = be16_to_cpup((__be16 *)&rtas_data_buf[0]);
+	buf = papr_sysparm_buf_alloc();
+	if (!buf)
+		return;
 
-			if (len >= 8 && ntypes != 0) {
-				phys_sockets = be16_to_cpup((__be16 *)&rtas_data_buf[4]);
-				phys_chipspersocket = be16_to_cpup((__be16 *)&rtas_data_buf[6]);
-				phys_coresperchip = be16_to_cpup((__be16 *)&rtas_data_buf[8]);
-			}
+	if (!papr_sysparm_get(PAPR_SYSPARM_PROC_MODULE_INFO, buf)) {
+		int ntypes = be16_to_cpup((__be16 *)&buf->val[0]);
+		int len = be16_to_cpu(buf->len);
+
+		if (len >= 8 && ntypes != 0) {
+			phys_sockets = be16_to_cpup((__be16 *)&buf->val[2]);
+			phys_chipspersocket = be16_to_cpup((__be16 *)&buf->val[4]);
+			phys_coresperchip = be16_to_cpup((__be16 *)&buf->val[6]);
 		}
-		spin_unlock(&rtas_data_buf_lock);
-	} while (rtas_busy_delay(call_status));
-
-	if (call_status != 0) {
-		pr_err("Error calling get-system-parameter %d\n",
-		       call_status);
 	}
+
+	papr_sysparm_buf_free(buf);
 }
 
 /* Domains for which more than one result element are returned for each event. */

-- 
2.39.1

