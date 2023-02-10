From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 10 Feb 2023 12:41:50 -0600
Subject: [PATCH v3 02/20] powerpc/perf/hv-24x7: add missing RTAS retry
 status handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v3-2-26929c8cce78@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1676054526; l=2749;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=/LsCrvhYcOs18AHY/8B4mKFcVOBSY003WWGJyJqeLe0=;
 b=ZtSG+fMDWIFBs7flEYvN9jwjkoddW1zCVZP5gfzHkcV7//YeDYL8514caZxYEwdZTG7yOOmEg
 gR9zdleLJ89C0RlhKMsfZINGExFdL0prcNhLZ4rIIq89TMlBaE9RBAh
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

The ibm,get-system-parameter RTAS function may return -2 or 990x,
which indicate that the caller should try again. read_24x7_sys_info()
ignores this, allowing transient failures in reporting processor
module information.

Move the RTAS call into a coventional rtas_busy_delay()-based loop,
along with the parsing of results on success.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Fixes: 8ba214267382 ("powerpc/hv-24x7: Add rtas call in hv-24x7 driver to get processor details")
---
 arch/powerpc/perf/hv-24x7.c | 42 ++++++++++++++++++------------------------
 1 file changed, 18 insertions(+), 24 deletions(-)

diff --git a/arch/powerpc/perf/hv-24x7.c b/arch/powerpc/perf/hv-24x7.c
index 33c23225fd54..fcfebf5bd378 100644
--- a/arch/powerpc/perf/hv-24x7.c
+++ b/arch/powerpc/perf/hv-24x7.c
@@ -79,9 +79,8 @@ static u32 phys_coresperchip; /* Physical cores per chip */
  */
 void read_24x7_sys_info(void)
 {
-	int call_status, len, ntypes;
-
-	spin_lock(&rtas_data_buf_lock);
+	const s32 token = rtas_token("ibm,get-system-parameter");
+	int call_status;
 
 	/*
 	 * Making system parameter: chips and sockets and cores per chip
@@ -91,32 +90,27 @@ void read_24x7_sys_info(void)
 	phys_chipspersocket = 1;
 	phys_coresperchip = 1;
 
-	call_status = rtas_call(rtas_token("ibm,get-system-parameter"), 3, 1,
-				NULL,
-				PROCESSOR_MODULE_INFO,
-				__pa(rtas_data_buf),
-				RTAS_DATA_BUF_SIZE);
+	do {
+		spin_lock(&rtas_data_buf_lock);
+		call_status = rtas_call(token, 3, 1, NULL, PROCESSOR_MODULE_INFO,
+					__pa(rtas_data_buf), RTAS_DATA_BUF_SIZE);
+		if (call_status == 0) {
+			int ntypes = be16_to_cpup((__be16 *)&rtas_data_buf[2]);
+			int len = be16_to_cpup((__be16 *)&rtas_data_buf[0]);
+
+			if (len >= 8 && ntypes != 0) {
+				phys_sockets = be16_to_cpup((__be16 *)&rtas_data_buf[4]);
+				phys_chipspersocket = be16_to_cpup((__be16 *)&rtas_data_buf[6]);
+				phys_coresperchip = be16_to_cpup((__be16 *)&rtas_data_buf[8]);
+			}
+		}
+		spin_unlock(&rtas_data_buf_lock);
+	} while (rtas_busy_delay(call_status));
 
 	if (call_status != 0) {
 		pr_err("Error calling get-system-parameter %d\n",
 		       call_status);
-	} else {
-		len = be16_to_cpup((__be16 *)&rtas_data_buf[0]);
-		if (len < 8)
-			goto out;
-
-		ntypes = be16_to_cpup((__be16 *)&rtas_data_buf[2]);
-
-		if (!ntypes)
-			goto out;
-
-		phys_sockets = be16_to_cpup((__be16 *)&rtas_data_buf[4]);
-		phys_chipspersocket = be16_to_cpup((__be16 *)&rtas_data_buf[6]);
-		phys_coresperchip = be16_to_cpup((__be16 *)&rtas_data_buf[8]);
 	}
-
-out:
-	spin_unlock(&rtas_data_buf_lock);
 }
 
 /* Domains for which more than one result element are returned for each event. */

-- 
2.39.1

