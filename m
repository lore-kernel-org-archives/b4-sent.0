From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 07 Dec 2023 17:35:40 -0600
Subject: [PATCH v5 01/13] powerpc/rtas: Avoid warning on invalid token
 argument to sys_rtas()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231207-papr-sys_rtas-vs-lockdown-v5-1-2ce965636a58@linux.ibm.com>
References: <20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com>
In-Reply-To: <20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, 
 "Aneesh Kumar K.V (IBM)" <aneesh.kumar@kernel.org>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701992313; l=3232;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=xeEDYmcM08Jdm+cCjHTDeI5+EGF9mkp/57/09NU+nko=;
 b=x1jr589dxoLwH/h3af6DMHW4I1NGr6J6QDI/D8Xe8QlQKVZIctKTGl413xAv39ysoDjvqlLxt
 lEOH23jEi+fDqK02ENHiPMIItMC1gw8BUPiuajjyvzN3GqzUEkn30kb
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rtas_token_to_function() WARNs when passed an invalid token; it's
meant to catch bugs in kernel-based users of RTAS functions. However,
user space controls the token value passed to rtas_token_to_function()
by block_rtas_call(), so user space with sufficient privilege to use
sys_rtas() can trigger the warnings at will:

  unexpected failed lookup for token 2048
  WARNING: CPU: 20 PID: 2247 at arch/powerpc/kernel/rtas.c:556
    rtas_token_to_function+0xfc/0x110
  ...
  NIP rtas_token_to_function+0xfc/0x110
  LR  rtas_token_to_function+0xf8/0x110
  Call Trace:
    rtas_token_to_function+0xf8/0x110 (unreliable)
    sys_rtas+0x188/0x880
    system_call_exception+0x268/0x530
    system_call_common+0x160/0x2c4

It's desirable to continue warning on bogus tokens in
rtas_token_to_function(). Currently it is used to look up RTAS
function descriptors when tracing, where we know there has to have
been a successful descriptor lookup by different means already, and it
would be a serious inconsistency for the reverse lookup to fail.

So instead of weakening rtas_token_to_function()'s contract by
removing the warnings, introduce rtas_token_to_function_untrusted(),
which has no opinion on failed lookups. Convert block_rtas_call() and
rtas_token_to_function() to use it.

Fixes: 8252b88294d2 ("powerpc/rtas: improve function information lookups")
Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 19 +++++++++++++++++--
 1 file changed, 17 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index c49f078382a9..ce37dc9860ef 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -544,6 +544,21 @@ static int __init rtas_token_to_function_xarray_init(void)
 }
 arch_initcall(rtas_token_to_function_xarray_init);
 
+/*
+ * For use by sys_rtas(), where the token value is provided by user
+ * space and we don't want to warn on failed lookups.
+ */
+static const struct rtas_function *rtas_token_to_function_untrusted(s32 token)
+{
+	return xa_load(&rtas_token_to_function_xarray, token);
+}
+
+/*
+ * Reverse lookup for deriving the function descriptor from a
+ * known-good token value in contexts where the former is not already
+ * available. @token must be valid, e.g. derived from the result of a
+ * prior lookup against the function table.
+ */
 static const struct rtas_function *rtas_token_to_function(s32 token)
 {
 	const struct rtas_function *func;
@@ -551,7 +566,7 @@ static const struct rtas_function *rtas_token_to_function(s32 token)
 	if (WARN_ONCE(token < 0, "invalid token %d", token))
 		return NULL;
 
-	func = xa_load(&rtas_token_to_function_xarray, token);
+	func = rtas_token_to_function_untrusted(token);
 
 	if (WARN_ONCE(!func, "unexpected failed lookup for token %d", token))
 		return NULL;
@@ -1721,7 +1736,7 @@ static bool block_rtas_call(int token, int nargs,
 	 * If this token doesn't correspond to a function the kernel
 	 * understands, you're not allowed to call it.
 	 */
-	func = rtas_token_to_function(token);
+	func = rtas_token_to_function_untrusted(token);
 	if (!func)
 		goto err;
 	/*

-- 
2.41.0

