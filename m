From: Akshat Singh <automobilehacks@gmail.com>
Date: Tue, 24 Nov 2026 08:45:30 +0000
Subject: [PATCH v2 2/3] irqchip/econet-en751221: Chain the handler to all
 parent interrupts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-en751221-intc-all-lines-v2-2-a33a520aac81@gmail.com>
References: <20261124-en751221-intc-all-lines-v2-0-a33a520aac81@gmail.com>
In-Reply-To: <20261124-en751221-intc-all-lines-v2-0-a33a520aac81@gmail.com>
To: Caleb James DeLisle <cjd@cjdns.fr>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thomas Bogendoerfer <tsbogend@alpha.franken.de>
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Akshat Singh <automobilehacks@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795509928; l=3728;
 i=automobilehacks@gmail.com; s=20261115; h=from:subject:message-id;
 bh=VZCgiuiY7QIYEHouyvIqPyfILwIC7tAkcoA/yaFvT+k=;
 b=SttxCKv/Gvd/uBU9vyU0kHgc+T9zJbhU0l30WFlwbGMzb+DJSFATrRpIotiYoSrQywPG3t4me
 t/qJIKIJfxAAcF4817M07CPS/N5vu8hKKKvvkCH0uMaApDynPdmUaln
X-Developer-Key: i=automobilehacks@gmail.com; a=ed25519;
 pk=wYmYXn6wy/XN0edTCg6D7UtE9nYLei8mbfqydGGCdf4=
X-Endpoint-Received: by B4 Relay for automobilehacks@gmail.com/20261115 with auth_id=1535
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The EN751221 interrupt controller does not drive one CPU interrupt line
per source. It presents the number of the pending interrupt plus one, in
binary, on the CPU interrupt lines IP2-IP7. In VEIC mode the CPU takes
that number as the vector, but without VEIC the driver chains its handler
to the first parent interrupt only, IP2 in the existing device trees. An
odd-numbered interrupt then never interrupts the CPU by itself: it is
handled only when an even-numbered one happens to run the handler, which
on an idle system is the next timer interrupt. That covers the frame
engine's QDMA (21), xHCI (17) and the first PCIe port (23).

A kernel built without CONFIG_CPU_MIPSR2_IRQ_EI always takes the
non-VEIC path. On a Nokia G-140W-C running such a kernel, this delayed
received packets by up to 10 ms, and ping round-trip times to the device
cycled through 1-11 ms.

Without VEIC, chain the handler to every parent interrupt listed in the
device tree. One interrupt usually raises several lines, so the later
runs of the handler find nothing pending; don't count those as spurious.

VEIC mode is unchanged.

Fixes: 1902a59cf5f9 ("irqchip: Add EcoNet EN751221 INTC")
Tested-by: Caleb James DeLisle <cjd@cjdns.fr>
Signed-off-by: Akshat Singh <automobilehacks@gmail.com>
---
 drivers/irqchip/irq-econet-en751221.c | 33 ++++++++++++++++++++++++++++++---
 1 file changed, 30 insertions(+), 3 deletions(-)

diff --git a/drivers/irqchip/irq-econet-en751221.c b/drivers/irqchip/irq-econet-en751221.c
index 2ca5d9018..4c1680152 100644
--- a/drivers/irqchip/irq-econet-en751221.c
+++ b/drivers/irqchip/irq-econet-en751221.c
@@ -18,6 +18,15 @@
  * When VPE#1 requests IRQ 30, the driver manipulates the mask bit for IRQ 29,
  * telling the hardware to mask VPE#1's view of IRQ 30.
  *
+ * The controller does not give each source its own CPU interrupt line. It
+ * presents the number of the pending interrupt plus one, in binary, on the
+ * CPU interrupt lines IP2-IP7, which a CPU in VEIC mode takes as the vector.
+ * Without VEIC, IRQ 21, for example, shows up as 22 = 0b010110 on IP3, IP4
+ * and IP6, so the controller is chained to every CPU line listed in its
+ * "interrupts" property. Chained to IP2 alone, it would see the odd-numbered
+ * IRQs only when an even-numbered one, such as the timer, happened to run
+ * the handler.
+ *
  * Copyright (C) 2025 Caleb James DeLisle <cjd@cjdns.fr>
  */
 
@@ -145,9 +154,12 @@ static void econet_intc_from_parent(struct irq_desc *desc)
 	pending0 = ioread32(econet_intc.membase + REG_PENDING0);
 	pending1 = ioread32(econet_intc.membase + REG_PENDING1);
 
-	if (unlikely(!(pending0 | pending1))) {
-		spurious_interrupt();
-	} else {
+	/*
+	 * An interrupt usually raises several CPU lines. It is handled when
+	 * the first of them runs this function, and the others find nothing
+	 * pending.
+	 */
+	if (pending0 | pending1) {
 		domain = irq_desc_get_handler_data(desc);
 		econet_intc_handle_pending(domain, pending0, 0);
 		econet_intc_handle_pending(domain, pending1, 32);
@@ -461,7 +473,22 @@ static int __init econet_intc_of_init(struct device_node *node, struct device_no
 		if (ret)
 			return ret;
 	} else {
+		int nr_parents = of_irq_count(node);
+
 		irq_set_chained_handler_and_data(irq, econet_intc_from_parent, domain);
+
+		for (int i = 1; i < nr_parents; i++) {
+			int virq = irq_of_parse_and_map(node, i);
+
+			if (!virq) {
+				pr_warn("%pOF: DT: Failed to get IRQ %d from 'interrupts'\n",
+					node, i);
+				continue;
+			}
+
+			irq_set_chained_handler_and_data(virq, econet_intc_from_parent,
+							 domain);
+		}
 	}
 
 	econet_intc.domain = domain;

-- 
2.43.0

