From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Tue, 14 Nov 2023 11:22:27 -0600
Subject: [PATCH v2 3/5] powerpc/rtas: Move post_mobility_fixup()
 declaration to pseries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231114-rtas-trivial-v2-3-59cbab208d57@linux.ibm.com>
References: <20231114-rtas-trivial-v2-0-59cbab208d57@linux.ibm.com>
In-Reply-To: <20231114-rtas-trivial-v2-0-59cbab208d57@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: Andrew Donnellan <ajd@linux.ibm.com>, 
 Hari Bathini <hbathini@linux.ibm.com>, 
 Mahesh Salgaonkar <mahesh@linux.ibm.com>, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699982560; l=2032;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=h/8tPPiIjitb/+VzF8lSVFUByA0wcuUdyaagJFN8WDE=;
 b=LSylu9PpeBUy6NL2msK8eRE5i8/qz8eg8QtQdPhfRHzRfVK2DQC4fA5i2ID6PGDj3zrtyhyY8
 7OKrbEW7wl4Bpl37cnIrctHNhSryb92SjHJnSxPDh5DsYY8JtKTPJaf
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a pseries-specific function declaration that doesn't belong in
rtas.h. Move it to the pseries platform code and adjust
pseries/suspend.c accordingly.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/include/asm/rtas.h          | 1 -
 arch/powerpc/platforms/pseries/pseries.h | 1 +
 arch/powerpc/platforms/pseries/suspend.c | 1 +
 3 files changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/powerpc/include/asm/rtas.h b/arch/powerpc/include/asm/rtas.h
index c6568a647cd0..2365668fc13e 100644
--- a/arch/powerpc/include/asm/rtas.h
+++ b/arch/powerpc/include/asm/rtas.h
@@ -444,7 +444,6 @@ extern void pSeries_log_error(char *buf, unsigned int err_type, int fatal);
 #ifdef CONFIG_PPC_PSERIES
 extern time64_t last_rtas_event;
 extern int clobbering_unread_rtas_event(void);
-extern void post_mobility_fixup(void);
 int rtas_syscall_dispatch_ibm_suspend_me(u64 handle);
 #else
 static inline int clobbering_unread_rtas_event(void) { return 0; }
diff --git a/arch/powerpc/platforms/pseries/pseries.h b/arch/powerpc/platforms/pseries/pseries.h
index 8376f03f932a..1c2d736f600d 100644
--- a/arch/powerpc/platforms/pseries/pseries.h
+++ b/arch/powerpc/platforms/pseries/pseries.h
@@ -55,6 +55,7 @@ extern int dlpar_detach_node(struct device_node *);
 extern int dlpar_acquire_drc(u32 drc_index);
 extern int dlpar_release_drc(u32 drc_index);
 extern int dlpar_unisolate_drc(u32 drc_index);
+void post_mobility_fixup(void);
 
 void queue_hotplug_event(struct pseries_hp_errorlog *hp_errlog);
 int handle_dlpar_errorlog(struct pseries_hp_errorlog *hp_errlog);
diff --git a/arch/powerpc/platforms/pseries/suspend.c b/arch/powerpc/platforms/pseries/suspend.c
index 5c43435472cc..382003dfdb9a 100644
--- a/arch/powerpc/platforms/pseries/suspend.c
+++ b/arch/powerpc/platforms/pseries/suspend.c
@@ -13,6 +13,7 @@
 #include <asm/mmu.h>
 #include <asm/rtas.h>
 #include <asm/topology.h>
+#include "pseries.h"
 
 static struct device suspend_dev;
 

-- 
2.41.0

