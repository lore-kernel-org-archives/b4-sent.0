From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Mar 2023 15:33:45 -0600
Subject: [PATCH 6/8] powerpc/rtas: lockdep annotations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230220-rtas-queue-for-6-4-v1-6-010e4416f13f@linux.ibm.com>
References: <20230220-rtas-queue-for-6-4-v1-0-010e4416f13f@linux.ibm.com>
In-Reply-To: <20230220-rtas-queue-for-6-4-v1-0-010e4416f13f@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Tyrel Datwyler <tyreld@linux.ibm.com>, 
 Scott Cheloha <cheloha@linux.ibm.com>, Andrew Donnellan <ajd@linux.ibm.com>, 
 Nick Child <nnac123@linux.ibm.com>, Laurent Dufour <ldufour@linux.ibm.com>, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678138471; l=4264;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=TIYvEdY23gtBTIiUG7IOtdTO7sVemxII+naaI6fhqrI=;
 b=G81ih7ytuTYeJtOafeh8+PWdLr0CDAIDjMOYZ9Z7li2Vgm4lTR3Ny7UI2WB4UCM1XZf3WGCVQ
 tiK7vd4VW8jCEhGPM4seOBzaJBay6jbKAOjGEnTQhJiYCCgyi0DZyxf
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add lockdep annotations for the following properties that must hold:

* Any error log retrieval must be atomically coupled with the prior
  RTAS call, without a window for another RTAS call to occur before the
  error log can be retrieved.

* All users of the core rtas_args parameter block must hold rtas_lock.

Move the definitions of rtas_lock and rtas_args up in the file so that
__do_enter_rtas_trace() can refer to them.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 33 +++++++++++++++++++++++----------
 1 file changed, 23 insertions(+), 10 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 96a10a0abe3a..633c925164e7 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -16,6 +16,7 @@
 #include <linux/init.h>
 #include <linux/kconfig.h>
 #include <linux/kernel.h>
+#include <linux/lockdep.h>
 #include <linux/memblock.h>
 #include <linux/of.h>
 #include <linux/of_fdt.h>
@@ -453,6 +454,16 @@ static struct rtas_function rtas_function_table[] __ro_after_init = {
 	},
 };
 
+/*
+ * Nearly all RTAS calls need to be serialized. All uses of the
+ * default rtas_args block must hold rtas_lock.
+ *
+ * Exceptions to the RTAS serialization requirement (e.g. stop-self)
+ * must use a separate rtas_args structure.
+ */
+static DEFINE_RAW_SPINLOCK(rtas_lock);
+static struct rtas_args rtas_args;
+
 /**
  * rtas_function_token() - RTAS function token lookup.
  * @handle: Function handle, e.g. RTAS_FN_EVENT_SCAN.
@@ -560,6 +571,9 @@ static void __do_enter_rtas(struct rtas_args *args)
 static void __do_enter_rtas_trace(struct rtas_args *args)
 {
 	const char *name = NULL;
+
+	if (args == &rtas_args)
+		lockdep_assert_held(&rtas_lock);
 	/*
 	 * If the tracepoints that consume the function name aren't
 	 * active, avoid the lookup.
@@ -619,16 +633,6 @@ static void do_enter_rtas(struct rtas_args *args)
 
 struct rtas_t rtas;
 
-/*
- * Nearly all RTAS calls need to be serialized. All uses of the
- * default rtas_args block must hold rtas_lock.
- *
- * Exceptions to the RTAS serialization requirement (e.g. stop-self)
- * must use a separate rtas_args structure.
- */
-static DEFINE_RAW_SPINLOCK(rtas_lock);
-static struct rtas_args rtas_args;
-
 DEFINE_SPINLOCK(rtas_data_buf_lock);
 EXPORT_SYMBOL_GPL(rtas_data_buf_lock);
 
@@ -951,6 +955,8 @@ static char *__fetch_rtas_last_error(char *altbuf)
 	u32 bufsz;
 	char *buf = NULL;
 
+	lockdep_assert_held(&rtas_lock);
+
 	if (token == -1)
 		return NULL;
 
@@ -1107,6 +1113,7 @@ static bool token_is_restricted_errinjct(s32 token)
  */
 int rtas_call(int token, int nargs, int nret, int *outputs, ...)
 {
+	struct pin_cookie cookie;
 	va_list list;
 	int i;
 	unsigned long flags;
@@ -1133,6 +1140,8 @@ int rtas_call(int token, int nargs, int nret, int *outputs, ...)
 	}
 
 	raw_spin_lock_irqsave(&rtas_lock, flags);
+	cookie = lockdep_pin_lock(&rtas_lock);
+
 	/* We use the global rtas args buffer */
 	args = &rtas_args;
 
@@ -1150,6 +1159,7 @@ int rtas_call(int token, int nargs, int nret, int *outputs, ...)
 			outputs[i] = be32_to_cpu(args->rets[i + 1]);
 	ret = (nret > 0) ? be32_to_cpu(args->rets[0]) : 0;
 
+	lockdep_unpin_lock(&rtas_lock, cookie);
 	raw_spin_unlock_irqrestore(&rtas_lock, flags);
 
 	if (buff_copy) {
@@ -1781,6 +1791,7 @@ static bool block_rtas_call(int token, int nargs,
 /* We assume to be passed big endian arguments */
 SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 {
+	struct pin_cookie cookie;
 	struct rtas_args args;
 	unsigned long flags;
 	char *buff_copy, *errbuf = NULL;
@@ -1849,6 +1860,7 @@ SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 	buff_copy = get_errorlog_buffer();
 
 	raw_spin_lock_irqsave(&rtas_lock, flags);
+	cookie = lockdep_pin_lock(&rtas_lock);
 
 	rtas_args = args;
 	do_enter_rtas(&rtas_args);
@@ -1859,6 +1871,7 @@ SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 	if (be32_to_cpu(args.rets[0]) == -1)
 		errbuf = __fetch_rtas_last_error(buff_copy);
 
+	lockdep_unpin_lock(&rtas_lock, cookie);
 	raw_spin_unlock_irqrestore(&rtas_lock, flags);
 
 	if (buff_copy) {

-- 
2.39.1

