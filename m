From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Nov 2023 07:42:57 -0600
Subject: [PATCH 5/7] powerpc/rtas: Move post_mobility_fixup() declaration
 to pseries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231106-rtas-trivial-v1-5-61847655c51f@linux.ibm.com>
References: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
In-Reply-To: <20231106-rtas-trivial-v1-0-61847655c51f@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699278208; l=2039;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=m3ZzkHGGDWvMrkkWKHzTjH9qFn2BzZzK6cBbnUv6bSA=;
 b=mMuQDapjwwiefuk4Pl7ud4nzuWz5Fvvb7rf7Cq8mjZ08nkRYg3YIXIP5SXANW/XsPjrkoF8zO
 aMDhLJMAciXDYZy1Uzf/NGuOvF6wBSwMG4x0ayPcwPKUnFeKpAPPj6V
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
index 8376f03f932a..bba4ad192b0f 100644
--- a/arch/powerpc/platforms/pseries/pseries.h
+++ b/arch/powerpc/platforms/pseries/pseries.h
@@ -55,6 +55,7 @@ extern int dlpar_detach_node(struct device_node *);
 extern int dlpar_acquire_drc(u32 drc_index);
 extern int dlpar_release_drc(u32 drc_index);
 extern int dlpar_unisolate_drc(u32 drc_index);
+extern void post_mobility_fixup(void);
 
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

