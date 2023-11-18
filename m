From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 17 Nov 2023 23:14:21 -0600
Subject: [PATCH v4 03/13] powerpc/rtas: Add function return status
 constants
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231117-papr-sys_rtas-vs-lockdown-v4-3-b794d8cb8502@linux.ibm.com>
References: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
In-Reply-To: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700284468; l=2303;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=/0cQWJ0fcN9gXsUM7HxYGX+8BK/jrvUmX+i1qFlOqiw=;
 b=1RW2UEKbW6NKFu0TwYzs+57VDaj9Wcs7euyYNaJ0VrSAh7AeJK+VkxvVG6toPpkvdDLbX2HQz
 PUGtL2wxX/2AC1MOEmA2eTygF+hMbEp/vXOsOnJjwbbG1o6oQpAlaWS
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Not all of the generic RTAS function statuses specified in PAPR have
symbolic constants and descriptions in rtas.h. Fix this, providing a
little more background, slightly updating the existing wording, and
improving the formatting.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/include/asm/rtas.h | 25 +++++++++++++++++++------
 1 file changed, 19 insertions(+), 6 deletions(-)

diff --git a/arch/powerpc/include/asm/rtas.h b/arch/powerpc/include/asm/rtas.h
index c697c3c74694..b73010583a8d 100644
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
+ * Status Word Values" in PAPR+ 7.2.8: "Return Codes". If a function
+ * can return a value in this table then generally it has the meaning
+ * listed here. More extended commentary in the documentation for
+ * rtas_call().
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

