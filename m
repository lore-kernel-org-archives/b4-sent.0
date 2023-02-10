From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 10 Feb 2023 12:41:57 -0600
Subject: [PATCH v3 09/20] powerpc/rtas: strengthen do_enter_rtas() type
 safety, drop inline
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v3-9-26929c8cce78@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1676054526; l=2269;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=d4FGezxSoWRmh1ICl0HR7WdiQaBhV+CR2OanO0P5nbg=;
 b=qNLDmfDOJ9zKOETTzA9O76tSyJBAv1b6eIgJSd1UdzvbINVRq8xhPcDYwgojuMgdKgje8XDUw
 dOBy146vrTADNGd9uX91AzNnsT/EvmZmcnNJ39Fp/+1wxrXp+w4Cj+v
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Make do_enter_rtas() take a pointer to struct rtas_args and do the
__pa() conversion in one place instead of leaving it to callers. This
also makes it possible to introduce enter/exit tracepoints that access
the rtas_args struct fields.

There's no apparent reason to force inlining of do_enter_rtas()
either, and it seems to bloat the code a bit. Let the compiler decide.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Reviewed-by: Andrew Donnellan <ajd@linux.ibm.com>
Reviewed-by: Nicholas Piggin <npiggin@gmail.com>
---
 arch/powerpc/kernel/rtas.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 3c7151f4f2ba..d2622b997b68 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -523,7 +523,7 @@ static const struct rtas_function *rtas_token_to_function(s32 token)
 /* This is here deliberately so it's only used in this file */
 void enter_rtas(unsigned long);
 
-static inline void do_enter_rtas(unsigned long args)
+static void do_enter_rtas(struct rtas_args *args)
 {
 	unsigned long msr;
 
@@ -538,7 +538,7 @@ static inline void do_enter_rtas(unsigned long args)
 
 	hard_irq_disable(); /* Ensure MSR[EE] is disabled on PPC64 */
 
-	enter_rtas(args);
+	enter_rtas(__pa(args));
 
 	srr_regs_clobbered(); /* rtas uses SRRs, invalidate */
 }
@@ -892,7 +892,7 @@ static char *__fetch_rtas_last_error(char *altbuf)
 	save_args = rtas_args;
 	rtas_args = err_args;
 
-	do_enter_rtas(__pa(&rtas_args));
+	do_enter_rtas(&rtas_args);
 
 	err_args = rtas_args;
 	rtas_args = save_args;
@@ -939,7 +939,7 @@ va_rtas_call_unlocked(struct rtas_args *args, int token, int nargs, int nret,
 	for (i = 0; i < nret; ++i)
 		args->rets[i] = 0;
 
-	do_enter_rtas(__pa(args));
+	do_enter_rtas(args);
 }
 
 void rtas_call_unlocked(struct rtas_args *args, int token, int nargs, int nret, ...)
@@ -1757,7 +1757,7 @@ SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 	raw_spin_lock_irqsave(&rtas_lock, flags);
 
 	rtas_args = args;
-	do_enter_rtas(__pa(&rtas_args));
+	do_enter_rtas(&rtas_args);
 	args = rtas_args;
 
 	/* A -1 return code indicates that the last command couldn't

-- 
2.39.1

