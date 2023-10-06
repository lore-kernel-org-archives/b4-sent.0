From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 06 Oct 2023 16:01:06 -0500
Subject: [PATCH 3/7] powerpc/rtas: serialize ibm,get-vpd service with
 papr-vpd sequences
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231006-papr-sys_rtas-vs-lockdown-v1-3-3a36bfb66e2e@linux.ibm.com>
References: <20231006-papr-sys_rtas-vs-lockdown-v1-0-3a36bfb66e2e@linux.ibm.com>
In-Reply-To: <20231006-papr-sys_rtas-vs-lockdown-v1-0-3a36bfb66e2e@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>
Cc: linuxppc-dev@lists.ozlabs.org, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1696626070; l=2480;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=TLQEPvXfc9R9GBYp7+/JmWBLObxsGORpqehfwb/txZ8=;
 b=UHaQGOqqHEUmH9IJF52wkgojMjEit0tdQ9iE5mO/lOPjb1DGUSFlv3zAvQp3dvCL3t3+UPsY1
 BiloGJ+MJfECcjL7ytTpDpunuuqe+zgDMhKktiqRcC1LPxbN/d13du3
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Take the papr-vpd driver's internal mutex when sys_rtas performs
ibm,get-vpd calls. This prevents sys_rtas(ibm,get-vpd) calls from
interleaving with sequences performed by the driver, ensuring that
such sequences are not disrupted.

However, it cannot prevent the driver from interleaving with sequences
that are initiated via sys_rtas, since control returns to user space
with each sys_rtas(ibm,get-vpd) call.

Emit a notice on first use of sys_rtas(ibm,get-vpd) encouraging users
to migrate to /dev/papr-vpd.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index eddc031c4b95..70ae118d2a13 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -37,6 +37,7 @@
 #include <asm/machdep.h>
 #include <asm/mmu.h>
 #include <asm/page.h>
+#include <asm/papr-vpd.h>
 #include <asm/rtas-work-area.h>
 #include <asm/rtas.h>
 #include <asm/time.h>
@@ -1861,6 +1862,28 @@ SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 		goto copy_return;
 	}
 
+	if (token == rtas_function_token(RTAS_FN_IBM_GET_VPD)) {
+		/*
+		 * ibm,get-vpd potentially needs to be invoked
+		 * multiple times to obtain complete results.
+		 * Interleaved ibm,get-vpd sequences disrupt each
+		 * other.
+		 *
+		 * /dev/papr-vpd doesn't have this problem and users
+		 * do not need to be aware of each other to use it
+		 * safely.
+		 *
+		 * We can prevent this call from disrupting a
+		 * /dev/papr-vpd-initiated sequence in progress by
+		 * reaching into the driver to take its internal
+		 * lock. Unfortunately there is no way to prevent
+		 * interference in the other direction without
+		 * resorting to even worse hacks.
+		 */
+		pr_notice_once("Calling ibm,get-vpd via sys_rtas is allowed but deprecated. Use /dev/papr-vpd instead.\n");
+		papr_vpd_mutex_lock();
+	}
+
 	buff_copy = get_errorlog_buffer();
 
 	raw_spin_lock_irqsave(&rtas_lock, flags);
@@ -1870,6 +1893,9 @@ SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 	do_enter_rtas(&rtas_args);
 	args = rtas_args;
 
+	if (token == rtas_function_token(RTAS_FN_IBM_GET_VPD))
+		papr_vpd_mutex_unlock();
+
 	/* A -1 return code indicates that the last command couldn't
 	   be completed due to a hardware error. */
 	if (be32_to_cpu(args.rets[0]) == -1)

-- 
2.41.0

