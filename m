From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 18 Sep 2026 21:06:48 +1000
Subject: [PATCH v2 05/10] mailbox: apple: Add DockChannel FIFO controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-apple-mtp-keyboard-final-v2-5-a5c685e50b60@gmail.com>
References: <20260918-apple-mtp-keyboard-final-v2-0-a5c685e50b60@gmail.com>
In-Reply-To: <20260918-apple-mtp-keyboard-final-v2-0-a5c685e50b60@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 Michael Reeves <michael.reeves077@gmail.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-input@vger.kernel.org, 
 Yureka Lilian <yureka@cyberchaos.dev>, Julian Braha <julianbraha@gmail.com>, 
 Sasha Finkelstein <k@chaosmail.tech>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789729608; l=14131;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=YFF10Kqmtk7csxs7Cb6Mh4jBfI181i2phOXGxRRbrcw=;
 b=rhFupCvXwN6y7/o7iOGjoz1YrE3frVAQoFjvqdYSJfXq6CatcY4gNxFV1UoWVoMEFgP3MDsXl
 3SnKNACAOjxDwQMAAycdAvd3Dyg9BW0X9j17OYGYVf1lLzewkICmk1d
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DockChannel is a hardware FIFO used by Apple coprocessors for
low-latency byte-stream communication with the AP.

Add a mailbox controller that preallocates RX storage, tracks IRQ
enable state in software, and reports TX completion from the TX-empty
interrupt.

Reject messages larger than the FIFO and return -EBUSY while the
previous message is still pending. This keeps the provider usable for
future small-message clients such as serial transports without a TX
worker.

Handle RX and TX interrupts in a thread so mailbox callbacks and locking
run outside hard-IRQ context.

Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 MAINTAINERS                               |   2 +
 drivers/mailbox/Kconfig                   |  12 +
 drivers/mailbox/Makefile                  |   2 +
 drivers/mailbox/apple-dockchannel.c       | 371 ++++++++++++++++++++++++++++++
 include/linux/mailbox/apple-dockchannel.h |  29 +++
 5 files changed, 416 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 7fe2ebb5e..e5be5934c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2677,6 +2677,7 @@ F:	drivers/input/touchscreen/apple_z2.c
 F:	drivers/iommu/apple-dart.c
 F:	drivers/iommu/io-pgtable-dart.c
 F:	drivers/irqchip/irq-apple-aic.c
+F:	drivers/mailbox/apple-dockchannel.c
 F:	drivers/mfd/macsmc.c
 F:	drivers/nvme/host/apple.c
 F:	drivers/nvmem/apple-efuses.c
@@ -2695,6 +2696,7 @@ F:	drivers/video/backlight/apple_dwi_bl.c
 F:	drivers/watchdog/apple_wdt.c
 F:	include/dt-bindings/interrupt-controller/apple-aic.h
 F:	include/dt-bindings/pinctrl/apple.h
+F:	include/linux/mailbox/apple-dockchannel.h
 F:	include/linux/mfd/macsmc.h
 F:	include/linux/soc/apple/*
 F:	include/uapi/drm/asahi_drm.h
diff --git a/drivers/mailbox/Kconfig b/drivers/mailbox/Kconfig
index ab869769e..503d3286f 100644
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
index 45dc59bb3..61b15fe45 100644
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
index 000000000..d0a66e1b7
--- /dev/null
+++ b/drivers/mailbox/apple-dockchannel.c
@@ -0,0 +1,371 @@
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
+#include <linux/spinlock.h>
+#include <linux/unaligned.h>
+
+#define APPLE_DOCKCHANNEL_FIFO_SIZE	0x800
+
+#define IRQ_MASK			0x0
+#define IRQ_FLAG			0x4
+
+#define IRQ_TX				BIT(2)
+#define IRQ_RX				BIT(3)
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
+
+	const u8 *tx_buf;
+	size_t tx_len;
+	size_t tx_pos;
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
+static void apple_dockchannel_write_pending(struct apple_dockchannel *dc)
+{
+	size_t left = dc->tx_len - dc->tx_pos;
+	const u8 *p = dc->tx_buf + dc->tx_pos;
+
+	while (left) {
+		size_t avail;
+		size_t block;
+
+		avail = readl_relaxed(dc->data_base + DATA_TX_FREE);
+		if (!avail)
+			break;
+
+		block = min(left, avail);
+
+		while (block >= sizeof(u32)) {
+			writel_relaxed(get_unaligned_le32(p),
+				       dc->data_base + DATA_TX32);
+			p += sizeof(u32);
+			left -= sizeof(u32);
+			block -= sizeof(u32);
+		}
+
+		while (block) {
+			writel_relaxed(*p++, dc->data_base + DATA_TX8);
+			left--;
+			block--;
+		}
+	}
+
+	dc->tx_pos = dc->tx_len - left;
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
+	dc->tx_buf = msg->data;
+	dc->tx_len = msg->len;
+	dc->tx_pos = 0;
+	dc->tx_active = true;
+
+	apple_dockchannel_write_pending(dc);
+	writel_relaxed(APPLE_DOCKCHANNEL_FIFO_SIZE,
+		       dc->config_base + CONFIG_TX_THRESH);
+	apple_dockchannel_irq_enable(dc, IRQ_TX);
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
+	apple_dockchannel_irq_enable(dc, IRQ_RX);
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
+	apple_dockchannel_irq_disable(dc, IRQ_TX | IRQ_RX);
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
+	flags = readl_relaxed(dc->irq_base + IRQ_FLAG);
+
+	spin_lock_irqsave(&dc->lock, irqflags);
+
+	pending = flags & dc->irq_mask & (IRQ_TX | IRQ_RX);
+	if (!pending)
+		goto out_unlock_none;
+
+	if (pending & IRQ_TX) {
+		if (apple_dockchannel_tx_empty(dc)) {
+			apple_dockchannel_irq_disable(dc, IRQ_TX);
+			tx_done = dc->tx_active;
+			dc->tx_active = false;
+		} else {
+			pending &= ~IRQ_TX;
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
+	if (!(pending & IRQ_RX))
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
+	spin_unlock_irqrestore(&dc->lock, irqflags);
+
+	if (flags & (IRQ_TX | IRQ_RX))
+		writel_relaxed(flags & (IRQ_TX | IRQ_RX),
+			       dc->irq_base + IRQ_FLAG);
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
+	int ret;
+
+	dc = devm_kzalloc(dev, sizeof(*dc), GFP_KERNEL);
+	if (!dc)
+		return -ENOMEM;
+
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
+					apple_dockchannel_irq_thread, IRQF_ONESHOT,
+					dev_name(dev), dc);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to request IRQ\n");
+
+	disable_irq(dc->irq);
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
+	{ .compatible = "apple,t8122-dockchannel" },
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
index 000000000..04d2fc44f
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
2.55.0

