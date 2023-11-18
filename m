From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 17 Nov 2023 23:14:22 -0600
Subject: [PATCH v4 04/13] powerpc/rtas: Factor out function descriptor
 lookup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231117-papr-sys_rtas-vs-lockdown-v4-4-b794d8cb8502@linux.ibm.com>
References: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
In-Reply-To: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700284468; l=2119;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=TOsUuive8ZDuMn3c0pP1+3FEVlK9o1TubebHmOMML3o=;
 b=zqlcoBdc9ZuM5GyIUAIWeB+L+P280dA3eNOArlopnW0cZ849RgyNyAfJQmgZuc5n1rA2yt8wr
 bqdRigAIEUQBUKp8b0WibrM57+lkVsM4eG9dai7PDoF0VISP6CQ87Wu
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the function descriptor table lookup out of rtas_function_token()
into a separate routine for use in new code to follow. No functional
change.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 31 +++++++++++++++++++------------
 1 file changed, 19 insertions(+), 12 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index f0051881348a..1fc0b3fffdd1 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -469,29 +469,36 @@ static struct rtas_function rtas_function_table[] __ro_after_init = {
 static DEFINE_RAW_SPINLOCK(rtas_lock);
 static struct rtas_args rtas_args;
 
-/**
- * rtas_function_token() - RTAS function token lookup.
- * @handle: Function handle, e.g. RTAS_FN_EVENT_SCAN.
- *
- * Context: Any context.
- * Return: the token value for the function if implemented by this platform,
- *         otherwise RTAS_UNKNOWN_SERVICE.
- */
-s32 rtas_function_token(const rtas_fn_handle_t handle)
+static struct rtas_function *rtas_function_lookup(const rtas_fn_handle_t handle)
 {
 	const size_t index = handle.index;
 	const bool out_of_bounds = index >= ARRAY_SIZE(rtas_function_table);
 
 	if (WARN_ONCE(out_of_bounds, "invalid function index %zu", index))
-		return RTAS_UNKNOWN_SERVICE;
+		return NULL;
 	/*
 	 * Various drivers attempt token lookups on non-RTAS
 	 * platforms.
 	 */
 	if (!rtas.dev)
-		return RTAS_UNKNOWN_SERVICE;
+		return NULL;
+
+	return &rtas_function_table[index];
+}
+
+/**
+ * rtas_function_token() - RTAS function token lookup.
+ * @handle: Function handle, e.g. RTAS_FN_EVENT_SCAN.
+ *
+ * Context: Any context.
+ * Return: the token value for the function if implemented by this platform,
+ *         otherwise RTAS_UNKNOWN_SERVICE.
+ */
+s32 rtas_function_token(const rtas_fn_handle_t handle)
+{
+	const struct rtas_function *func = rtas_function_lookup(handle);
 
-	return rtas_function_table[index].token;
+	return func ? func->token : RTAS_UNKNOWN_SERVICE;
 }
 EXPORT_SYMBOL_GPL(rtas_function_token);
 

-- 
2.41.0

