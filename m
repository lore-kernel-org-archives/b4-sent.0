From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 27 Oct 2026 23:36:56 +0800
Subject: [PATCH RFC 05/18] mailbox: add A210 AP to E902 doorbell support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-a210-scmi-v1-5-74d58ce85bd8@iscas.ac.cn>
References: <20261027-a210-scmi-v1-0-74d58ce85bd8@iscas.ac.cn>
In-Reply-To: <20261027-a210-scmi-v1-0-74d58ce85bd8@iscas.ac.cn>
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 Icenowy Zheng <uwu@icenowy.me>, Inochi Amaoto <inochiama@gmail.com>, 
 Vivian Wang <wangruikang@iscas.ac.cn>, Yao Zi <me@ziyao.cc>, 
 Jiaxun Yang <jiaxun.yang@flygoat.com>
Cc: arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-gpio@vger.kernel.org, 
 Paul Walmsley <paul.walmsley@sifive.com>, linux-clk@vger.kernel.org, 
 linux-serial@vger.kernel.org, Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793115418; l=8211;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=pLva0nJyHQFfWlXZh8n8KXWXAeVUeNiyxYGb1x4wcm0=;
 b=BiCwE0j7Kvf0cmWQxNjtI/pChIG6VD1XrOqQtolK6RR1M19OVBYAkQXsMfhtvHbhs25g9uGgU
 quI+ZjBPUAWDj47ORNCXwSlVHviinFBMrpCx3mFvE6nToxYKKQvdzqk
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the AP doorbell transport. Allow firmware to retain endpoint clocks
so that SCMI can provide clocks without depending on itself.

E902 completions and notifications share one interrupt. When the E902
to AP data bank is described, firmware tags each doorbell in INFO0 or
INFO1 and the driver exposes notifications as receive-only channel 1.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/mailbox/Kconfig        |   9 ++
 drivers/mailbox/Makefile       |   2 +
 drivers/mailbox/mailbox-a210.c | 205 +++++++++++++++++++++++++++++++++++++++++
 3 files changed, 216 insertions(+)

diff --git a/drivers/mailbox/Kconfig b/drivers/mailbox/Kconfig
index ab869769e278..e48f40000851 100644
--- a/drivers/mailbox/Kconfig
+++ b/drivers/mailbox/Kconfig
@@ -409,4 +409,13 @@ config AXIADO_MAILBOX
 	  Axiado SoCs.
 	  If unsure, say N.
 
+config ZHIHE_A210_MBOX
+	bool "Zhihe A210 AP to E902 mailbox"
+	depends on OF && (ARCH_ZHIHE || COMPILE_TEST)
+	help
+	  Enable the AP doorbell channel to running E902 firmware on A210.
+	  Clients exchange their payloads through shared memory and signal
+	  completion themselves. The controller does not carry vendor RPCs.
+	  Enable this for an SCMI server running on the A210 E902 processor.
+
 endif
diff --git a/drivers/mailbox/Makefile b/drivers/mailbox/Makefile
index 45dc59bb3e7f..f537ebb8aaff 100644
--- a/drivers/mailbox/Makefile
+++ b/drivers/mailbox/Makefile
@@ -86,3 +86,5 @@ obj-$(CONFIG_BCM74110_MAILBOX)	+= bcm74110-mailbox.o
 obj-$(CONFIG_RISCV_SBI_MPXY_MBOX)	+= riscv-sbi-mpxy-mbox.o
 
 obj-$(CONFIG_AXIADO_MAILBOX)	+= axiado-mailbox.o
+
+obj-$(CONFIG_ZHIHE_A210_MBOX) += mailbox-a210.o
diff --git a/drivers/mailbox/mailbox-a210.c b/drivers/mailbox/mailbox-a210.c
new file mode 100644
index 000000000000..767bb4fe7b40
--- /dev/null
+++ b/drivers/mailbox/mailbox-a210.c
@@ -0,0 +1,205 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* AP and E902 doorbell channels on the Zhihe A210. */
+#include <linux/clk.h>
+#include <linux/interrupt.h>
+#include <linux/io.h>
+#include <linux/mailbox_controller.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+#include <linux/spinlock.h>
+
+#define A210_MBOX_STATUS		0x00
+#define A210_MBOX_CLEAR		0x04
+#define A210_MBOX_MASK		0x0c
+#define A210_MBOX_GENERATE	0x10
+#define A210_MBOX_INFO(n)	(0x14 + 4 * (n))
+#define A210_MBOX_E902_PENDING	BIT(0)
+#define A210_MBOX_NOTIFY		BIT(6)
+
+/* Channel 0 carries AP requests and completions, channel 1 E902 notifications. */
+#define A210_MBOX_CHANS		2
+
+struct a210_mbox {
+	struct mbox_controller controller;
+	struct mbox_chan channels[A210_MBOX_CHANS];
+	void __iomem *local;
+	void __iomem *remote;
+	void __iomem *rx;
+	struct clk_bulk_data clocks[2];
+	/* Protects the shared interrupt mask and the set of started channels. */
+	spinlock_t lock;
+	unsigned long started;
+	int irq;
+};
+
+static void a210_mbox_mask(struct a210_mbox *mbox, unsigned int index, bool enable)
+{
+	unsigned long flags;
+	u32 value;
+
+	spin_lock_irqsave(&mbox->lock, flags);
+	if (enable)
+		__set_bit(index, &mbox->started);
+	else
+		__clear_bit(index, &mbox->started);
+	value = readl(mbox->local + A210_MBOX_MASK);
+	if (mbox->started)
+		value |= A210_MBOX_E902_PENDING;
+	else
+		value &= ~A210_MBOX_E902_PENDING;
+	writel(value, mbox->local + A210_MBOX_MASK);
+	spin_unlock_irqrestore(&mbox->lock, flags);
+}
+
+static irqreturn_t a210_mbox_irq(int irq, void *data)
+{
+	struct a210_mbox *mbox = data;
+
+	if (!(readl(mbox->local + A210_MBOX_MASK) & A210_MBOX_E902_PENDING))
+		return IRQ_NONE;
+	if (!(readl(mbox->local + A210_MBOX_STATUS) & A210_MBOX_E902_PENDING))
+		return IRQ_NONE;
+
+	writel(A210_MBOX_E902_PENDING, mbox->local + A210_MBOX_CLEAR);
+	if (!mbox->rx) {
+		mbox_chan_received_data(&mbox->channels[0], NULL);
+		return IRQ_HANDLED;
+	}
+
+	/* E902 sets INFO<n> before ringing the shared doorbell for channel n. */
+	for (unsigned int i = 0; i < A210_MBOX_CHANS; i++) {
+		if (!readl(mbox->rx + A210_MBOX_INFO(i)))
+			continue;
+		writel(0, mbox->rx + A210_MBOX_INFO(i));
+		if (test_bit(i, &mbox->started))
+			mbox_chan_received_data(&mbox->channels[i], NULL);
+	}
+	return IRQ_HANDLED;
+}
+
+static unsigned int a210_mbox_index(struct a210_mbox *mbox, struct mbox_chan *channel)
+{
+	return channel - mbox->channels;
+}
+
+static int a210_mbox_send(struct mbox_chan *channel, void *data)
+{
+	struct a210_mbox *mbox = channel->con_priv;
+
+	/* E902 notifications are receive-only. */
+	if (a210_mbox_index(mbox, channel))
+		return -EINVAL;
+
+	/* Payload and completion ownership belong to the shared-memory client. */
+	writel(A210_MBOX_NOTIFY, mbox->remote + A210_MBOX_GENERATE);
+	return 0;
+}
+
+static int a210_mbox_startup(struct mbox_chan *channel)
+{
+	struct a210_mbox *mbox = channel->con_priv;
+	unsigned int index = a210_mbox_index(mbox, channel);
+
+	if (mbox->rx)
+		writel(0, mbox->rx + A210_MBOX_INFO(index));
+	else
+		writel(A210_MBOX_E902_PENDING, mbox->local + A210_MBOX_CLEAR);
+	a210_mbox_mask(mbox, index, true);
+	return 0;
+}
+
+static void a210_mbox_shutdown(struct mbox_chan *channel)
+{
+	struct a210_mbox *mbox = channel->con_priv;
+
+	a210_mbox_mask(mbox, a210_mbox_index(mbox, channel), false);
+	synchronize_irq(mbox->irq);
+}
+
+static const struct mbox_chan_ops a210_mbox_ops = {
+	.send_data = a210_mbox_send,
+	.startup = a210_mbox_startup,
+	.shutdown = a210_mbox_shutdown,
+};
+
+static void a210_mbox_disable_clocks(void *data)
+{
+	struct a210_mbox *mbox = data;
+
+	clk_bulk_disable_unprepare(ARRAY_SIZE(mbox->clocks), mbox->clocks);
+}
+
+static int a210_mbox_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct a210_mbox *mbox;
+	int ret;
+
+	mbox = devm_kzalloc(dev, sizeof(*mbox), GFP_KERNEL);
+	if (!mbox)
+		return -ENOMEM;
+
+	mbox->local = devm_platform_ioremap_resource_byname(pdev, "interrupt");
+	if (IS_ERR(mbox->local))
+		return PTR_ERR(mbox->local);
+	mbox->remote = devm_platform_ioremap_resource_byname(pdev, "tx");
+	if (IS_ERR(mbox->remote))
+		return PTR_ERR(mbox->remote);
+	if (platform_get_resource_byname(pdev, IORESOURCE_MEM, "rx")) {
+		mbox->rx = devm_platform_ioremap_resource_byname(pdev, "rx");
+		if (IS_ERR(mbox->rx))
+			return PTR_ERR(mbox->rx);
+	}
+	mbox->irq = platform_get_irq(pdev, 0);
+	if (mbox->irq < 0)
+		return mbox->irq;
+
+	mbox->clocks[0].id = "local";
+	mbox->clocks[1].id = "remote";
+	ret = devm_clk_bulk_get_optional(dev, ARRAY_SIZE(mbox->clocks), mbox->clocks);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to get mailbox clocks\n");
+	ret = clk_bulk_prepare_enable(ARRAY_SIZE(mbox->clocks), mbox->clocks);
+	if (ret)
+		return ret;
+	ret = devm_add_action_or_reset(dev, a210_mbox_disable_clocks, mbox);
+	if (ret)
+		return ret;
+
+	spin_lock_init(&mbox->lock);
+	a210_mbox_mask(mbox, 0, false);
+	for (unsigned int i = 0; i < A210_MBOX_CHANS; i++)
+		mbox->channels[i].con_priv = mbox;
+	mbox->controller.dev = dev;
+	mbox->controller.chans = mbox->channels;
+	mbox->controller.num_chans = mbox->rx ? A210_MBOX_CHANS : 1;
+	mbox->controller.ops = &a210_mbox_ops;
+	/* The client acknowledges completion after consuming shared memory. */
+	ret = devm_request_irq(dev, mbox->irq, a210_mbox_irq, IRQF_SHARED,
+			       dev_name(dev), mbox);
+	if (ret)
+		return ret;
+
+	return devm_mbox_controller_register(dev, &mbox->controller);
+}
+
+static const struct of_device_id a210_mbox_match[] = {
+	{ .compatible = "zhihe,a210-ap-mailbox" },
+	{}
+};
+MODULE_DEVICE_TABLE(of, a210_mbox_match);
+
+static struct platform_driver a210_mbox_driver = {
+	.probe = a210_mbox_probe,
+	.driver = {
+		.name = "a210-mailbox",
+		.of_match_table = a210_mbox_match,
+		/* Running E902 firmware continuously accesses the remote bank. */
+		.suppress_bind_attrs = true,
+	},
+};
+module_platform_driver(a210_mbox_driver);
+
+MODULE_AUTHOR("Han Gao <gaohan@iscas.ac.cn>");
+MODULE_DESCRIPTION("Zhihe A210 AP to E902 doorbell");
+MODULE_LICENSE("GPL");

-- 
2.55.0

