From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 07 Dec 2023 17:35:44 -0600
Subject: [PATCH v5 05/13] powerpc/rtas: Move token validation from
 block_rtas_call() to sys_rtas()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231207-papr-sys_rtas-vs-lockdown-v5-5-2ce965636a58@linux.ibm.com>
References: <20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com>
In-Reply-To: <20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, 
 "Aneesh Kumar K.V (IBM)" <aneesh.kumar@kernel.org>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701992313; l=4049;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=YJ8XAU16ii/pvuHPIAGYv4KpDMx7gyMB9kIrkfNOG9o=;
 b=2FfzYwCiS7b8YynVFaZT9pKnnvCNmhP/Ocq9qpzH4mZtZI9jwuCev9X3eeRsEY+Uzbta6DwKb
 Ka4fPWJs/RKDn+9OzkZ67jK3FrpX4sQn9O7a9Xdna2pqQ8xSOjXe6Mm
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rtas system call handler sys_rtas() delegates certain input
validation steps to a helper function: block_rtas_call(). One of these
steps ensures that the user-supplied token value maps to a known RTAS
function. This is done by performing a "reverse" token-to-function
lookup via rtas_token_to_function_untrusted() to obtain an
rtas_function object.

In changes to come, sys_rtas() itself will need the function
descriptor for the token. To prepare:

* Move the lookup and validation up into sys_rtas() and pass the
  resulting rtas_function pointer to block_rtas_call(), which is
  otherwise unconcerned with the token value.

* Change block_rtas_call() to report the RTAS function name instead of
  the token value on validation failures, since it can now rely on
  having a valid function descriptor.

One behavior change is that sys_rtas() now silently errors out when
passed a bad token, before calling block_rtas_call(). So we will no
longer log "RTAS call blocked - exploit attempt?" on invalid
tokens. This is consistent with how sys_rtas() currently handles other
"metadata" (nargs and nret), while block_rtas_call() is primarily
concerned with validating the arguments to be passed to specific RTAS
functions.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 32 ++++++++++++++++----------------
 1 file changed, 16 insertions(+), 16 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index f60a8e7bd5ed..ca5bb0b994ac 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -1738,24 +1738,18 @@ static bool in_rmo_buf(u32 base, u32 end)
 		end < (rtas_rmo_buf + RTAS_USER_REGION_SIZE);
 }
 
-static bool block_rtas_call(int token, int nargs,
+static bool block_rtas_call(const struct rtas_function *func, int nargs,
 			    struct rtas_args *args)
 {
-	const struct rtas_function *func;
 	const struct rtas_filter *f;
-	const bool is_platform_dump = token == rtas_function_token(RTAS_FN_IBM_PLATFORM_DUMP);
-	const bool is_config_conn = token == rtas_function_token(RTAS_FN_IBM_CONFIGURE_CONNECTOR);
+	const bool is_platform_dump =
+		func == &rtas_function_table[RTAS_FNIDX__IBM_PLATFORM_DUMP];
+	const bool is_config_conn =
+		func == &rtas_function_table[RTAS_FNIDX__IBM_CONFIGURE_CONNECTOR];
 	u32 base, size, end;
 
 	/*
-	 * If this token doesn't correspond to a function the kernel
-	 * understands, you're not allowed to call it.
-	 */
-	func = rtas_token_to_function_untrusted(token);
-	if (!func)
-		goto err;
-	/*
-	 * And only functions with filters attached are allowed.
+	 * Only functions with filters attached are allowed.
 	 */
 	f = func->filter;
 	if (!f)
@@ -1812,14 +1806,15 @@ static bool block_rtas_call(int token, int nargs,
 	return false;
 err:
 	pr_err_ratelimited("sys_rtas: RTAS call blocked - exploit attempt?\n");
-	pr_err_ratelimited("sys_rtas: token=0x%x, nargs=%d (called by %s)\n",
-			   token, nargs, current->comm);
+	pr_err_ratelimited("sys_rtas: %s nargs=%d (called by %s)\n",
+			   func->name, nargs, current->comm);
 	return true;
 }
 
 /* We assume to be passed big endian arguments */
 SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 {
+	const struct rtas_function *func;
 	struct pin_cookie cookie;
 	struct rtas_args args;
 	unsigned long flags;
@@ -1849,13 +1844,18 @@ SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 			   nargs * sizeof(rtas_arg_t)) != 0)
 		return -EFAULT;
 
-	if (token == RTAS_UNKNOWN_SERVICE)
+	/*
+	 * If this token doesn't correspond to a function the kernel
+	 * understands, you're not allowed to call it.
+	 */
+	func = rtas_token_to_function_untrusted(token);
+	if (!func)
 		return -EINVAL;
 
 	args.rets = &args.args[nargs];
 	memset(args.rets, 0, nret * sizeof(rtas_arg_t));
 
-	if (block_rtas_call(token, nargs, &args))
+	if (block_rtas_call(func, nargs, &args))
 		return -EINVAL;
 
 	if (token_is_restricted_errinjct(token)) {

-- 
2.41.0

