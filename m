From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Tue, 12 Dec 2023 11:01:51 -0600
Subject: [PATCH v6 04/13] powerpc/rtas: Add function return status
 constants
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231212-papr-sys_rtas-vs-lockdown-v6-4-e9eafd0c8c6c@linux.ibm.com>
References: <20231212-papr-sys_rtas-vs-lockdown-v6-0-e9eafd0c8c6c@linux.ibm.com>
In-Reply-To: <20231212-papr-sys_rtas-vs-lockdown-v6-0-e9eafd0c8c6c@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, 
 "Aneesh Kumar K.V (IBM)" <aneesh.kumar@kernel.org>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702400518; l=2372;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=kCuJERDzmYgBzIZZ4Ubp2I3CxXEFkU4/FSvd3ux6m2U=;
 b=/mQxR+SCfy9UGffS35M1O6Op1mRYFpUyzbwU16Me21B79U9claW/fyc4Y26+Bza10+MC3y3nc
 5snQfvXqBH/C+03O0WaXH6jzhHF9y41BBooAIfV0ZCUdwmh9PTETlEh
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Not all of the generic RTAS function statuses specified in PAPR have
symbolic constants and descriptions in rtas.h. Fix this, providing a
little more background, slightly updating the existing wording, and
improving the formatting.

Reviewed-by: Aneesh Kumar K.V (IBM) <aneesh.kumar@kernel.org>
Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/include/asm/rtas.h | 25 +++++++++++++++++++------
 1 file changed, 19 insertions(+), 6 deletions(-)

diff --git a/arch/powerpc/include/asm/rtas.h b/arch/powerpc/include/asm/rtas.h
index a7110ed52e25..08d19e6904f7 100644
--- a/arch/powerpc/include/asm/rtas.h
+++ b/arch/powerpc/include/asm/rtas.h
@@ -201,12 +201,25 @@ typedef struct {
 /* Memory set aside for sys_rtas to use with calls that need a work area. */
 #define RTAS_USER_REGION_SIZE (64 * 1024)
 
-/* RTAS return status codes */
-#define RTAS_HARDWARE_ERROR	-1    /* Hardware Error */
-#define RTAS_BUSY		-2    /* RTAS Busy */
-#define RTAS_INVALID_PARAMETER	-3    /* Invalid indicator/domain/sensor etc. */
-#define RTAS_EXTENDED_DELAY_MIN	9900
-#define RTAS_EXTENDED_DELAY_MAX	9905
+/*
+ * Common RTAS function return values, derived from the table "RTAS
+ * Status Word Values" in PAPR+ v2.13 7.2.8: "Return Codes". If a
+ * function can return a value in this table then generally it has the
+ * meaning listed here. More extended commentary in the documentation
+ * for rtas_call().
+ *
+ * RTAS functions may use negative and positive numbers not in this
+ * set for function-specific error and success conditions,
+ * respectively.
+ */
+#define RTAS_SUCCESS                     0 /* Success. */
+#define RTAS_HARDWARE_ERROR             -1 /* Hardware or other unspecified error. */
+#define RTAS_BUSY                       -2 /* Retry immediately. */
+#define RTAS_INVALID_PARAMETER          -3 /* Invalid indicator/domain/sensor etc. */
+#define RTAS_UNEXPECTED_STATE_CHANGE    -7 /* Seems limited to EEH and slot reset. */
+#define RTAS_EXTENDED_DELAY_MIN       9900 /* Retry after delaying for ~1ms. */
+#define RTAS_EXTENDED_DELAY_MAX       9905 /* Retry after delaying for ~100s. */
+#define RTAS_ML_ISOLATION_ERROR      -9000 /* Multi-level isolation error. */
 
 /* statuses specific to ibm,suspend-me */
 #define RTAS_SUSPEND_ABORTED     9000 /* Suspension aborted */

-- 
2.41.0

