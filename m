From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Tue, 16 Jun 2026 18:03:39 +0200
Subject: [PATCH v9 3/3] riscv: clocksource: Add p8700-gcru driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-riscv-time-mmio-v9-3-03af7bc8f2d8@htecgroup.com>
References: <20260616-riscv-time-mmio-v9-0-03af7bc8f2d8@htecgroup.com>
In-Reply-To: <20260616-riscv-time-mmio-v9-0-03af7bc8f2d8@htecgroup.com>
To: Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Paul Walmsley <pjw@kernel.org>, 
 John Stultz <jstultz@google.com>, Stephen Boyd <sboyd@kernel.org>, 
 Vivian Wang <wangruikang@iscas.ac.cn>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Chao-ying Fu <cfu@mips.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781625819; l=3298;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=3gylppdlQket8tUc4qx/+ik8cQwg9RhMZJmHFwMxyPQ=;
 b=JyCsFdiHFV3/q9WIm3YPS+zSuWcxmwYz8t77rpDBcMTZgG0NpVwHkBIYQkcbylZT39ppzBU0d
 cFqlf3WYa38BvaD6VaaUR57VrEEBsbXDozDyTeKbJGURy2xOyfBkXkn
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a clocksource driver for the P8700 GCRU.

Initialization uses helper functions
provided by clocksource/mmio.c and timer-of.c.

Since the GCRU does not support any kind of interrupts,
the default RISC-V clockevent implementation should suffice.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 drivers/clocksource/Kconfig       |  9 ++++++++
 drivers/clocksource/Makefile      |  1 +
 drivers/clocksource/timer-p8700.c | 47 +++++++++++++++++++++++++++++++++++++++
 3 files changed, 57 insertions(+)

diff --git a/drivers/clocksource/Kconfig b/drivers/clocksource/Kconfig
index ffcd23668763fe7707a4e917bf240caadbb09a8c..a775a301f3f08ca97699e46aaf3ccfaf99734e6b 100644
--- a/drivers/clocksource/Kconfig
+++ b/drivers/clocksource/Kconfig
@@ -672,6 +672,15 @@ config CLINT_TIMER
 	  This option enables the CLINT timer for RISC-V systems.  The CLINT
 	  driver is usually used for NoMMU RISC-V systems.
 
+config P8700_TIMER
+	bool "MIPS P8700 timer driver"
+	depends on GENERIC_SCHED_CLOCK && RISCV && RISCV_SBI && 64BIT
+	select CLKSRC_MMIO
+	select TIMER_PROBE
+	select TIMER_OF
+	help
+	  Enables support for MIPS P8700 timer driver.
+
 config CSKY_MP_TIMER
 	bool "SMP Timer for the C-SKY platform" if COMPILE_TEST
 	depends on CSKY
diff --git a/drivers/clocksource/Makefile b/drivers/clocksource/Makefile
index ec4452ee958f1a814c708aeba6412bea61d24892..fae9a58d6c8663a7c857b9ab7fdae05782b3551c 100644
--- a/drivers/clocksource/Makefile
+++ b/drivers/clocksource/Makefile
@@ -95,3 +95,4 @@ obj-$(CONFIG_CLKSRC_LOONGSON1_PWM)	+= timer-loongson1-pwm.o
 obj-$(CONFIG_EP93XX_TIMER)		+= timer-ep93xx.o
 obj-$(CONFIG_RALINK_TIMER)		+= timer-ralink.o
 obj-$(CONFIG_NXP_STM_TIMER)		+= timer-nxp-stm.o
+obj-$(CONFIG_P8700_TIMER)		+= timer-p8700.o
diff --git a/drivers/clocksource/timer-p8700.c b/drivers/clocksource/timer-p8700.c
new file mode 100644
index 0000000000000000000000000000000000000000..dd20b4e72fcdd77a6b33775f286d0945c2a2b659
--- /dev/null
+++ b/drivers/clocksource/timer-p8700.c
@@ -0,0 +1,47 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (C) 2025 MIPS.
+ */
+
+#include <linux/sched_clock.h>
+#include <linux/delay.h>
+#include <linux/of_address.h>
+#include <linux/init.h>
+#include <linux/interrupt.h>
+#include <linux/clocksource.h>
+
+#include "timer-of.h"
+
+static struct timer_of gcru_of = { .flags = TIMER_OF_BASE };
+static u64 __iomem *p8700_time_val __ro_after_init;
+
+static u64 notrace p8700_timer_sched_read(void)
+{
+	return (u64)readq_relaxed(p8700_time_val);
+}
+
+static int __init p8700_timer_init(struct device_node *node)
+{
+	int error = 0;
+
+	error = timer_of_init(node, &gcru_of);
+	if (error)
+		return error;
+
+	p8700_time_val = timer_of_base(&gcru_of);
+	/* Now init the mmio timer with the address we got from DT */
+	error = clocksource_mmio_init(p8700_time_val, "mips,p8700-gcru",
+				      riscv_timebase, 450, 64,
+				      clocksource_mmio_readq_up);
+	if (error) {
+		timer_of_cleanup(&gcru_of);
+		return error;
+	}
+
+	/* Sched clock */
+	sched_clock_register(p8700_timer_sched_read, 64, riscv_timebase);
+
+	return error;
+}
+
+TIMER_OF_DECLARE(p8700_timer, "mips,p8700-gcru", p8700_timer_init);

-- 
2.43.0

