From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 03 Nov 2026 03:45:08 +0800
Subject: [PATCH RFC v3 05/17] mailbox: add Zhihe A210 AP to E902 mailbox
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-a210-scmi-v3-5-ee6b31580808@iscas.ac.cn>
References: <20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn>
In-Reply-To: <20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn>
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>, 
 Michal Simek <michal.simek@amd.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Linus Walleij <linusw@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
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
 linux-serial@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793648705; l=7374;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=Z7rtD2lVv6OIg4Vqe4Ikd4EKS6jFLkfoX9GIDAAsyp4=;
 b=VrOF7udLcDMVqx667ugeUMpkqXHz40e/x5dOG22NIXupxPiSI/4m12WowhII4y0a+jNIua+MQ
 VjdvRvtrVyxBOac3UusDx0riIWfcXEcwv2P1AymO4vKOpG25rZoaynf
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a mailbox controller for the doorbells between the A210 application
processors and the E902 management core. It serves as the SCMI
transport to the E902 firmware.

Channel 0 rings E902 and receives its completions. Channel 1 is receive
only and carries E902 notifications. Both share one interrupt, and E902
writes INFO0 or INFO1 to tell them apart.

The E902 firmware keeps both mailboxes clocked and out of reset, so the
driver does not manage clocks or resets.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/mailbox/Kconfig        |   9 +++
 drivers/mailbox/Makefile       |   2 +
 drivers/mailbox/mailbox-a210.c | 176 +++++++++++++++++++++++++++++++++++++++++
 3 files changed, 187 insertions(+)

diff --git a/drivers/mailbox/Kconfig b/drivers/mailbox/Kconfig
index ab869769e278..6d620b0dde6f 100644
--- a/drivers/mailbox/Kconfig
+++ b/drivers/mailbox/Kconfig
@@ -409,4 +409,13 @@ config AXIADO_MAILBOX
 	  Axiado SoCs.
 	  If unsure, say N.
 
+config ZHIHE_A210_MBOX
+	bool "Zhihe A210 AP to E902 mailbox"
+	depends on OF && (ARCH_ZHIHE || COMPILE_TEST)
+	help
+	  Mailbox driver for the doorbells between the application
+	  processors and the E902 management core of the Zhihe A210. The
+	  doorbells carry no data, so clients pass their messages through
+	  shared memory. Say Y to use the SCMI firmware on the E902.
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
index 000000000000..0b66fded6b09
--- /dev/null
+++ b/drivers/mailbox/mailbox-a210.c
@@ -0,0 +1,176 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* Zhihe A210 application processor to E902 mailbox */
+#include <linux/interrupt.h>
+#include <linux/io.h>
+#include <linux/mailbox_controller.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+#include <linux/spinlock.h>
+
+/* The local mailbox holds the INFO bank and, one page up, the AP interrupt. */
+#define A210_MBOX_STATUS		0x1000
+#define A210_MBOX_CLEAR		0x1004
+#define A210_MBOX_MASK		0x100c
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
+
+	/* E902 sets INFO<n> before ringing the shared doorbell for channel n. */
+	for (unsigned int i = 0; i < A210_MBOX_CHANS; i++) {
+		if (!readl(mbox->local + A210_MBOX_INFO(i)))
+			continue;
+		writel(0, mbox->local + A210_MBOX_INFO(i));
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
+	writel(0, mbox->local + A210_MBOX_INFO(index));
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
+	mbox->local = devm_platform_ioremap_resource_byname(pdev, "local");
+	if (IS_ERR(mbox->local))
+		return PTR_ERR(mbox->local);
+	mbox->remote = devm_platform_ioremap_resource_byname(pdev, "remote");
+	if (IS_ERR(mbox->remote))
+		return PTR_ERR(mbox->remote);
+	mbox->irq = platform_get_irq(pdev, 0);
+	if (mbox->irq < 0)
+		return mbox->irq;
+
+	spin_lock_init(&mbox->lock);
+	a210_mbox_mask(mbox, 0, false);
+	for (unsigned int i = 0; i < A210_MBOX_CHANS; i++)
+		mbox->channels[i].con_priv = mbox;
+	/*
+	 * Neither txdone_irq nor txdone_poll is set: the client acknowledges
+	 * completion after consuming shared memory.
+	 */
+	mbox->controller.dev = dev;
+	mbox->controller.chans = mbox->channels;
+	mbox->controller.num_chans = A210_MBOX_CHANS;
+	mbox->controller.ops = &a210_mbox_ops;
+
+	ret = devm_request_irq(dev, mbox->irq, a210_mbox_irq, 0, dev_name(dev),
+			       mbox);
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
+MODULE_DESCRIPTION("Zhihe A210 AP to E902 mailbox");
+MODULE_LICENSE("GPL");

-- 
2.55.0

