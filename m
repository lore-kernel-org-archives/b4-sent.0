From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 23 Jul 2026 15:57:47 +0200
Subject: [PATCH 09/19] ARM: mvebu: add lowlevel support for Netgear RN104
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-rn102-rn104-series-v1-9-7698d25df866@gmail.com>
References: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
In-Reply-To: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784815061; l=1882;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=ZnmWEwKuJfDye7aJF8fWx4G4qnFxtjev2+5OWgN13Bs=;
 b=be8NV85NWaOxbmiBNmY2Gw1ZoeZb8Pmvj1+0XY2grxX5bZ1gsKnyfTI+aoDVBrd6v0i7FVsUm
 Ox2ZjjrSfWWB0lH8aBRxxvIOJ5v3bVgQokRxMjLvKyTeN/ByK7DHPn1
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 arch/arm/boards/netgear-rn104/lowlevel.c | 43 +++++++++++++++++++++++++-------
 1 file changed, 34 insertions(+), 9 deletions(-)

diff --git a/arch/arm/boards/netgear-rn104/lowlevel.c b/arch/arm/boards/netgear-rn104/lowlevel.c
index e693d13993..4fb5b6432b 100644
--- a/arch/arm/boards/netgear-rn104/lowlevel.c
+++ b/arch/arm/boards/netgear-rn104/lowlevel.c
@@ -1,24 +1,49 @@
 // SPDX-License-Identifier: GPL-2.0-only
 
-/*
- * Copyright (C) 2014  Uwe Kleine-Koenig <uwe@kleine-koenig.org>
- */
-
 #include <common.h>
 #include <asm/barebox-arm.h>
-#include <mach/mvebu/barebox-arm-head.h>
 #include <mach/mvebu/lowlevel.h>
+#include <mach/mvebu/barebox-arm-head.h>
+#include <mach/mvebu/armada-370-xp-regs.h>
 
 extern char __dtb_armada_370_rn104_bb_start[];
 
-ENTRY_FUNCTION_MVEBU(start_netgear_rn104, r0, r1, r2)
+#define INTERNAL_REG_BASE_ADDR	0x20080
+
+static __always_inline void mvebu_remap_registers(void)
+{
+	void __iomem *base = mvebu_get_initial_int_reg_base();
+
+	writel(MVEBU_REMAP_INT_REG_BASE, base + INTERNAL_REG_BASE_ADDR);
+}
+
+static unsigned long armada_370_xp_memory_find(void)
 {
-	void *fdt;
+	unsigned long mem_size = 0;
+
+	for (int cs = 0; cs < 4; cs++) {
+		u32 ctrl = readl(ARMADA_370_XP_SDRAM_BASE + DDR_SIZE_CSn(cs));
+
+		/* Skip non-enabled CS */
+		if ((ctrl & DDR_SIZE_ENABLED) != DDR_SIZE_ENABLED)
+			continue;
+
+		mem_size += (ctrl | ~DDR_SIZE_MASK) + 1;
+	}
 
-	arm_cpu_lowlevel_init();
+	return mem_size;
+}
+
+ENTRY_FUNCTION_MVEBU(start_netgear_rn104, r0, r1, r2)
+{
+    void *fdt;
 
+    arm_cpu_lowlevel_init();
+	
 	fdt = __dtb_armada_370_rn104_bb_start +
 		get_runtime_offset();
 
-	armada_370_xp_barebox_entry(fdt);
+	mvebu_remap_registers();
+	barebox_arm_entry(0, armada_370_xp_memory_find(), fdt);
+	// armada_370_xp_barebox_entry(fdt);
 }

-- 
2.47.3

