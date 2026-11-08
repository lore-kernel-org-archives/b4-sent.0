From: Michael Reeves <michael.reeves077@gmail.com>
Date: Sun, 08 Nov 2026 07:25:08 +0000
Subject: [PATCH v5 3/8] mailbox: apple: Add DockChannel FIFO controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-apple-mtp-keyboard-v5-3-e2c97b82669a@gmail.com>
References: <20261108-b4-apple-mtp-keyboard-v5-0-e2c97b82669a@gmail.com>
In-Reply-To: <20261108-b4-apple-mtp-keyboard-v5-0-e2c97b82669a@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 Michael Reeves <michael.reeves077@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-input@vger.kernel.org, Hector Martin <marcan@marcan.st>, 
 Yureka Lilian <yureka@cyberchaos.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794122710; l=14071;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=K7hhrZIatfZg7i24mu5pAphK+bqi3zU919/6Tyjop5o=;
 b=Byvo3GSRlszaOfNWgZW4v6oeUF5wbrHDBseGIt3X7wDesVHCD1trbEyA0iEwoyYSC6LVEuWLK
 8xv7yEaIOpMDPUmrN05YP7pIoNL3b3hYU95hxu1yYlbcrMfn6TcqlpY
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DockChannel is a hardware FIFO used by Apple coprocessors for
low-latency byte-stream communication with the AP.

Expose it as a mailbox controller for HID and future serial clients,
with TX completion signalled by the TX-empty interrupt. Handle interrupts
in a thread so mailbox callbacks run outside hard-IRQ context.

Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Suggested-by: Yureka Lilian <yureka@cyberchaos.dev>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 MAINTAINERS                               |   2 +
 drivers/mailbox/Kconfig                   |  12 +
 drivers/mailbox/Makefile                  |   2 +
 drivers/mailbox/apple-dockchannel.c       | 357 ++++++++++++++++++++++++++++++
 include/linux/mailbox/apple-dockchannel.h |  29 +++
 5 files changed, 402 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 41b12717c657..79fedd4af69c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2754,6 +2754,7 @@ F:	drivers/input/touchscreen/apple_z2.c
 F:	drivers/iommu/apple-dart.c
 F:	drivers/iommu/io-pgtable-dart.c
 F:	drivers/irqchip/irq-apple-aic.c
+F:	drivers/mailbox/apple-dockchannel.c
 F:	drivers/mfd/macsmc.c
 F:	drivers/nvme/host/apple.c
 F:	drivers/nvmem/apple-efuses.c
@@ -2772,6 +2773,7 @@ F:	drivers/video/backlight/apple_dwi_bl.c
 F:	drivers/watchdog/apple_wdt.c
 F:	include/dt-bindings/interrupt-controller/apple-aic.h
 F:	include/dt-bindings/pinctrl/apple.h
+F:	include/linux/mailbox/apple-dockchannel.h
 F:	include/linux/mfd/macsmc.h
 F:	include/linux/soc/apple/*
 F:	include/uapi/drm/asahi_drm.h
diff --git a/drivers/mailbox/Kconfig b/drivers/mailbox/Kconfig
index ab869769e278..503d3286fa11 100644
--- a/drivers/mailbox/Kconfig
+++ b/drivers/mailbox/Kconfig
@@ -36,6 +36,18 @@ config ARM_MHU_V3
 	  that provides different means of transports: supported extensions
 	  will be discovered and possibly managed at probe-time.
 
+config APPLE_DOCKCHANNEL
+	tristate "Apple DockChannel FIFO mailbox"
+	depends on ARCH_APPLE || COMPILE_TEST
+	depends on HAS_IOMEM
+	depends on OF
+	help
+	  DockChannel is a hardware FIFO used on Apple Silicon SoCs for
+	  communication between the application processor and co-processors.
+	  This driver exposes DockChannel FIFOs through the mailbox framework.
+
+	  Say Y here if you have an M2 or later Apple MacBook.
+
 config AST2700_MBOX
 	tristate "ASPEED AST2700 IPC driver"
 	depends on ARCH_ASPEED || COMPILE_TEST
diff --git a/drivers/mailbox/Makefile b/drivers/mailbox/Makefile
index 45dc59bb3e7f..61b15fe45595 100644
--- a/drivers/mailbox/Makefile
+++ b/drivers/mailbox/Makefile
@@ -11,6 +11,8 @@ obj-$(CONFIG_ARM_MHU_V2)	+= arm_mhuv2.o
 
 obj-$(CONFIG_ARM_MHU_V3)	+= arm_mhuv3.o
 
+obj-$(CONFIG_APPLE_DOCKCHANNEL)	+= apple-dockchannel.o
+
 obj-$(CONFIG_AST2700_MBOX)	+= ast2700-mailbox.o
 
 obj-$(CONFIG_CV1800_MBOX)	+= cv1800-mailbox.o
diff --git a/drivers/mailbox/apple-dockchannel.c b/drivers/mailbox/apple-dockchannel.c
new file mode 100644
index 000000000000..4400d767f6ad
--- /dev/null
+++ b/drivers/mailbox/apple-dockchannel.c
@@ -0,0 +1,357 @@
+// SPDX-License-Identifier: GPL-2.0-only OR MIT
+/*
+ * Apple DockChannel mailbox controller
+ *
+ * Copyright The Asahi Linux Contributors
+ *
+ * DockChannel is a byte FIFO used by Apple co-processors. This driver exposes a
+ * single FIFO pair as a Linux mailbox channel and moves payload bytes with PIO.
+ * There is no DMA involved, so relaxed MMIO accessors are sufficient for the
+ * FIFO accesses themselves.
+ */
+
+#include <linux/device.h>
+#include <linux/interrupt.h>
+#include <linux/io.h>
+#include <linux/mailbox/apple-dockchannel.h>
+#include <linux/mailbox_controller.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/property.h>
+#include <linux/spinlock.h>
+#include <linux/unaligned.h>
+
+#define APPLE_DOCKCHANNEL_FIFO_SIZE	0x800
+
+#define IRQ_MASK			0x0
+#define IRQ_FLAG			0x4
+
+#define CONFIG_TX_THRESH		0x0
+#define CONFIG_RX_THRESH		0x4
+
+#define DATA_TX8			0x4
+#define DATA_TX32			0x10
+#define DATA_TX_FREE			0x14
+#define DATA_RX8			0x1c
+#define DATA_RX32			0x28
+#define DATA_RX_COUNT			0x2c
+
+struct apple_dockchannel {
+	struct device *dev;
+	struct mbox_controller controller;
+	struct mbox_chan chan;
+
+	void __iomem *irq_base;
+	void __iomem *config_base;
+	void __iomem *data_base;
+	int irq;
+
+	spinlock_t lock; /* protects IRQ mask and TX state */
+	u32 irq_mask;
+	u32 irq_tx;
+	u32 irq_rx;
+
+	bool tx_active;
+
+	u8 rx_buf[APPLE_DOCKCHANNEL_FIFO_SIZE];
+};
+
+static void apple_dockchannel_irq_update(struct apple_dockchannel *dc,
+					 u32 bits, bool enable)
+{
+	if (enable)
+		dc->irq_mask |= bits;
+	else
+		dc->irq_mask &= ~bits;
+	writel_relaxed(dc->irq_mask, dc->irq_base + IRQ_MASK);
+}
+
+static void apple_dockchannel_irq_enable(struct apple_dockchannel *dc, u32 bits)
+{
+	/*
+	 * IRQ_FLAG is write-to-clear. Clear stale latched flags before
+	 * unmasking so the next interrupt reflects current FIFO state.
+	 */
+	writel_relaxed(bits, dc->irq_base + IRQ_FLAG);
+	apple_dockchannel_irq_update(dc, bits, true);
+}
+
+static void apple_dockchannel_irq_disable(struct apple_dockchannel *dc, u32 bits)
+{
+	apple_dockchannel_irq_update(dc, bits, false);
+}
+
+static bool apple_dockchannel_tx_empty(struct apple_dockchannel *dc)
+{
+	return readl_relaxed(dc->data_base + DATA_TX_FREE) ==
+	       APPLE_DOCKCHANNEL_FIFO_SIZE;
+}
+
+static void apple_dockchannel_write(struct apple_dockchannel *dc,
+				    const void *buf, size_t count)
+{
+	const u8 *p = buf;
+
+	while (count >= sizeof(u32)) {
+		writel_relaxed(get_unaligned_le32(p), dc->data_base + DATA_TX32);
+		p += sizeof(u32);
+		count -= sizeof(u32);
+	}
+
+	/* TX data is in bits [7:0]; RX uses those bits for the count. */
+	while (count--)
+		writel_relaxed(*p++, dc->data_base + DATA_TX8);
+}
+
+static void apple_dockchannel_read(struct apple_dockchannel *dc, void *buf,
+				   size_t count)
+{
+	u8 *p = buf;
+	size_t left = count;
+
+	while (left >= sizeof(u32)) {
+		put_unaligned_le32(readl_relaxed(dc->data_base + DATA_RX32), p);
+		p += sizeof(u32);
+		left -= sizeof(u32);
+	}
+
+	while (left) {
+		/*
+		 * The byte FIFO register returns the byte in bits [15:8] on
+		 * these instances.
+		 */
+		*p++ = readl_relaxed(dc->data_base + DATA_RX8) >> 8;
+		left--;
+	}
+}
+
+static int apple_dockchannel_send_data(struct mbox_chan *chan, void *data)
+{
+	struct apple_dockchannel *dc = chan->con_priv;
+	struct apple_dockchannel_msg *msg = data;
+	unsigned long flags;
+
+	if (!msg || !msg->data || !msg->len)
+		return -EINVAL;
+
+	if (msg->len > APPLE_DOCKCHANNEL_FIFO_SIZE)
+		return -EMSGSIZE;
+
+	spin_lock_irqsave(&dc->lock, flags);
+
+	if (dc->tx_active || !apple_dockchannel_tx_empty(dc)) {
+		spin_unlock_irqrestore(&dc->lock, flags);
+		return -EBUSY;
+	}
+
+	dc->tx_active = true;
+
+	apple_dockchannel_write(dc, msg->data, msg->len);
+	writel_relaxed(APPLE_DOCKCHANNEL_FIFO_SIZE,
+		       dc->config_base + CONFIG_TX_THRESH);
+	apple_dockchannel_irq_enable(dc, dc->irq_tx);
+
+	spin_unlock_irqrestore(&dc->lock, flags);
+
+	return 0;
+}
+
+static int apple_dockchannel_startup(struct mbox_chan *chan)
+{
+	struct apple_dockchannel *dc = chan->con_priv;
+	unsigned long flags;
+
+	spin_lock_irqsave(&dc->lock, flags);
+	/*
+	 * The mailbox framework has no per-client RX threshold. Use byte
+	 * granularity because UART-style DockChannel clients require it.
+	 */
+	writel_relaxed(1, dc->config_base + CONFIG_RX_THRESH);
+	apple_dockchannel_irq_enable(dc, dc->irq_rx);
+	spin_unlock_irqrestore(&dc->lock, flags);
+
+	enable_irq(dc->irq);
+
+	return 0;
+}
+
+static void apple_dockchannel_shutdown(struct mbox_chan *chan)
+{
+	struct apple_dockchannel *dc = chan->con_priv;
+	unsigned long flags;
+
+	disable_irq(dc->irq);
+
+	spin_lock_irqsave(&dc->lock, flags);
+	apple_dockchannel_irq_disable(dc, dc->irq_tx | dc->irq_rx);
+	dc->tx_active = false;
+	spin_unlock_irqrestore(&dc->lock, flags);
+}
+
+static const struct mbox_chan_ops apple_dockchannel_mbox_ops = {
+	.send_data = apple_dockchannel_send_data,
+	.startup = apple_dockchannel_startup,
+	.shutdown = apple_dockchannel_shutdown,
+};
+
+static irqreturn_t apple_dockchannel_irq_thread(int irq, void *data)
+{
+	struct apple_dockchannel *dc = data;
+	unsigned long irqflags;
+	u32 flags;
+	u32 pending;
+	bool tx_done = false;
+
+	spin_lock_irqsave(&dc->lock, irqflags);
+
+	flags = readl_relaxed(dc->irq_base + IRQ_FLAG);
+
+	pending = flags & dc->irq_mask & (dc->irq_tx | dc->irq_rx);
+	if (!pending)
+		goto out_unlock_none;
+
+	if (pending & dc->irq_tx) {
+		if (apple_dockchannel_tx_empty(dc)) {
+			apple_dockchannel_irq_disable(dc, dc->irq_tx);
+			tx_done = dc->tx_active;
+			dc->tx_active = false;
+		} else {
+			pending &= ~dc->irq_tx;
+		}
+	}
+
+	writel_relaxed(pending, dc->irq_base + IRQ_FLAG);
+
+	spin_unlock_irqrestore(&dc->lock, irqflags);
+
+	if (tx_done)
+		mbox_chan_txdone(&dc->chan, 0);
+
+	if (!(pending & dc->irq_rx))
+		return pending ? IRQ_HANDLED : IRQ_NONE;
+
+	for (;;) {
+		struct apple_dockchannel_msg msg;
+		size_t avail;
+
+		avail = readl_relaxed(dc->data_base + DATA_RX_COUNT);
+		if (!avail)
+			break;
+
+		avail = min_t(size_t, avail, APPLE_DOCKCHANNEL_FIFO_SIZE);
+
+		apple_dockchannel_read(dc, dc->rx_buf, avail);
+
+		msg.data = dc->rx_buf;
+		msg.len = avail;
+		mbox_chan_received_data(&dc->chan, &msg);
+	}
+
+	return IRQ_HANDLED;
+
+out_unlock_none:
+	if (flags & (dc->irq_tx | dc->irq_rx))
+		writel_relaxed(flags & (dc->irq_tx | dc->irq_rx),
+			       dc->irq_base + IRQ_FLAG);
+	spin_unlock_irqrestore(&dc->lock, irqflags);
+
+	return IRQ_NONE;
+}
+
+static struct mbox_chan *
+apple_dockchannel_of_xlate(struct mbox_controller *mbox,
+			   const struct of_phandle_args *spec)
+{
+	if (spec->args_count != 0)
+		return ERR_PTR(-EINVAL);
+
+	return &mbox->chans[0];
+}
+
+static int apple_dockchannel_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct apple_dockchannel *dc;
+	u32 irq_index = 1;
+	int ret;
+
+	dc = devm_kzalloc(dev, sizeof(*dc), GFP_KERNEL);
+	if (!dc)
+		return -ENOMEM;
+
+	/* Older keyboard devicetrees implicitly select interrupt pair 1. */
+	if (device_property_present(dev, "apple,irq-index")) {
+		ret = device_property_read_u32(dev, "apple,irq-index", &irq_index);
+		if (ret)
+			return dev_err_probe(dev, ret, "invalid interrupt pair index\n");
+	}
+	if (irq_index > 15)
+		return dev_err_probe(dev, -EINVAL, "interrupt pair index out of range\n");
+
+	dc->irq_tx = BIT(2 * irq_index);
+	dc->irq_rx = BIT(2 * irq_index + 1);
+	dc->dev = dev;
+	spin_lock_init(&dc->lock);
+	platform_set_drvdata(pdev, dc);
+
+	dc->irq_base = devm_platform_ioremap_resource_byname(pdev, "irq");
+	if (IS_ERR(dc->irq_base))
+		return PTR_ERR(dc->irq_base);
+
+	dc->config_base = devm_platform_ioremap_resource_byname(pdev, "config");
+	if (IS_ERR(dc->config_base))
+		return PTR_ERR(dc->config_base);
+
+	dc->data_base = devm_platform_ioremap_resource_byname(pdev, "data");
+	if (IS_ERR(dc->data_base))
+		return PTR_ERR(dc->data_base);
+
+	writel_relaxed(0, dc->irq_base + IRQ_MASK);
+	writel_relaxed(~0, dc->irq_base + IRQ_FLAG);
+
+	dc->irq = platform_get_irq(pdev, 0);
+	if (dc->irq < 0)
+		return dc->irq;
+
+	ret = devm_request_threaded_irq(dev, dc->irq, NULL,
+					apple_dockchannel_irq_thread,
+					IRQF_ONESHOT | IRQF_NO_AUTOEN,
+					dev_name(dev), dc);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to request IRQ\n");
+
+	dc->chan.con_priv = dc;
+	dc->controller.dev = dev;
+	dc->controller.ops = &apple_dockchannel_mbox_ops;
+	dc->controller.chans = &dc->chan;
+	dc->controller.num_chans = 1;
+	dc->controller.txdone_irq = true;
+	dc->controller.of_xlate = apple_dockchannel_of_xlate;
+
+	ret = devm_mbox_controller_register(dev, &dc->controller);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to register mailbox\n");
+
+	return 0;
+}
+
+static const struct of_device_id apple_dockchannel_of_match[] = {
+	{ .compatible = "apple,t8112-dockchannel" },
+	{},
+};
+MODULE_DEVICE_TABLE(of, apple_dockchannel_of_match);
+
+static struct platform_driver apple_dockchannel_driver = {
+	.driver = {
+		.name = "apple-dockchannel",
+		.of_match_table = apple_dockchannel_of_match,
+	},
+	.probe = apple_dockchannel_probe,
+};
+module_platform_driver(apple_dockchannel_driver);
+
+MODULE_DESCRIPTION("Apple DockChannel mailbox controller");
+MODULE_AUTHOR("Hector Martin <marcan@marcan.st>");
+MODULE_AUTHOR("Michael Reeves <michael.reeves077@gmail.com>");
+MODULE_LICENSE("Dual MIT/GPL");
diff --git a/include/linux/mailbox/apple-dockchannel.h b/include/linux/mailbox/apple-dockchannel.h
new file mode 100644
index 000000000000..04d2fc44f12f
--- /dev/null
+++ b/include/linux/mailbox/apple-dockchannel.h
@@ -0,0 +1,29 @@
+/* SPDX-License-Identifier: GPL-2.0-only OR MIT */
+/*
+ * Apple DockChannel mailbox message format.
+ *
+ * Copyright The Asahi Linux Contributors
+ */
+
+#ifndef _LINUX_MAILBOX_APPLE_DOCKCHANNEL_H_
+#define _LINUX_MAILBOX_APPLE_DOCKCHANNEL_H_
+
+#include <linux/types.h>
+
+/**
+ * struct apple_dockchannel_msg - DockChannel mailbox payload
+ * @data: Pointer to the byte stream payload
+ * @len: Number of payload bytes
+ *
+ * For TX, @data must remain valid until mbox_send_message() completes or the
+ * client receives tx_done in non-blocking mode.
+ *
+ * For RX, @data is owned by the controller and is valid only for the duration
+ * of the rx_callback.
+ */
+struct apple_dockchannel_msg {
+	void *data;
+	size_t len;
+};
+
+#endif /* _LINUX_MAILBOX_APPLE_DOCKCHANNEL_H_ */

-- 
2.56.0

