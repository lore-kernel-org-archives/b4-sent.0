From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Feb 2023 12:54:26 -0600
Subject: [PATCH v2 10/19] powerpc/rtas: add tracepoints around RTAS entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230125-b4-powerpc-rtas-queue-v2-10-9aa6bd058063@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1675709663; l=3071;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=5scexNa7Ih0QI44Wd77pHpg0KZ6geAmSW9N53TuzSCo=;
 b=bD6Liq6BeAwLuDHqmgYwXXGQ9Mq0N/VCpOhCWGPLrT5V1kjV03dxOEA/HjG9yF1b/LEbfH/rz
 nSMJMbagFa5D3Y8aNqcffMCwv93X2ki9slfD78Ug2iWnGoafm0nYwFB
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Submission Endpoint for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Decompose the RTAS entry C code into tracing and non-tracing variants,
calling the just-added tracepoints in the tracing-enabled path. Skip
tracing in contexts known to be unsafe (real mode, CPU offline).

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 59 +++++++++++++++++++++++++++++++++++++++++-----
 1 file changed, 53 insertions(+), 6 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 52c1ed7869b8..3290f25b9b34 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -38,6 +38,7 @@
 #include <asm/page.h>
 #include <asm/rtas.h>
 #include <asm/time.h>
+#include <asm/trace.h>
 #include <asm/udbg.h>
 
 struct rtas_filter {
@@ -523,24 +524,70 @@ static const struct rtas_function *rtas_token_to_function(s32 token)
 /* This is here deliberately so it's only used in this file */
 void enter_rtas(unsigned long);
 
+static void __do_enter_rtas(struct rtas_args *args)
+{
+	enter_rtas(__pa(args));
+	srr_regs_clobbered(); /* rtas uses SRRs, invalidate */
+}
+
+static void __do_enter_rtas_trace(struct rtas_args *args)
+{
+	const char *name = NULL;
+	/*
+	 * If the tracepoints that consume the function name aren't
+	 * active, avoid the lookup.
+	 */
+	if ((trace_rtas_input_enabled() || trace_rtas_output_enabled())) {
+		const s32 token = be32_to_cpu(args->token);
+		const struct rtas_function *func = rtas_token_to_function(token);
+
+		name = func->name;
+	}
+
+	trace_rtas_input(args, name);
+	trace_rtas_ll_entry(args);
+
+	__do_enter_rtas(args);
+
+	trace_rtas_ll_exit(args);
+	trace_rtas_output(args, name);
+}
+
 static void do_enter_rtas(struct rtas_args *args)
 {
-	unsigned long msr;
-
+	const unsigned long msr = mfmsr();
+	/*
+	 * Situations where we want to skip any active tracepoints for
+	 * safety reasons:
+	 *
+	 * 1. The last code executed on an offline CPU as it stops,
+	 *    i.e. we're about to call stop-self. The tracepoints'
+	 *    function name lookup uses xarray, which uses RCU, which
+	 *    isn't valid to call on an offline CPU.  Any events
+	 *    emitted on an offline CPU will be discarded anyway.
+	 *
+	 * 2. In real mode, as when invoking ibm,nmi-interlock from
+	 *    the pseries MCE handler. We cannot count on trace
+	 *    buffers or the entries in rtas_token_to_function_xarray
+	 *    to be contained in the RMO.
+	 */
+	const unsigned long mask = MSR_IR | MSR_DR;
+	const bool can_trace = likely(cpu_online(raw_smp_processor_id()) &&
+				      (msr & mask) == mask);
 	/*
 	 * Make sure MSR[RI] is currently enabled as it will be forced later
 	 * in enter_rtas.
 	 */
-	msr = mfmsr();
 	BUG_ON(!(msr & MSR_RI));
 
 	BUG_ON(!irqs_disabled());
 
 	hard_irq_disable(); /* Ensure MSR[EE] is disabled on PPC64 */
 
-	enter_rtas(__pa(args));
-
-	srr_regs_clobbered(); /* rtas uses SRRs, invalidate */
+	if (can_trace)
+		__do_enter_rtas_trace(args);
+	else
+		__do_enter_rtas(args);
 }
 
 struct rtas_t rtas;

-- 
2.39.1

