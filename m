From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 21:41:35 +0300
Subject: [PATCH 2/3] hwrng: Add Cortina Systems CS7542 TRNG driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-trng-v1-2-92d9ffcee531@gmail.com>
References: <20261123-b4-cs7542-trng-v1-0-92d9ffcee531@gmail.com>
In-Reply-To: <20261123-b4-cs7542-trng-v1-0-92d9ffcee531@gmail.com>
To: Olivia Mackall <olivia@selenic.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-crypto@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459294; l=6425;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=CejmhadnINs86sI3uuQCpiGMjWxvRmque4I7XB53Ot4=;
 b=/mF0/7U7u87NRBflb7R5E4A221BOZ0XmRS/f0yI/Up5OecriUR3Q4vfEr+r0XZjrrcp1yELoF
 Pbusqw00garBqjEwA82DrwLB0WgCshIeF1HdjCplyH9jlFaGIiHJtgQ
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adapt the OpenWrt implementation to use a syscon regmap for the shared
scratch bit. Bound polling and retain a pending request across
nonblocking calls instead of entering a blocking poll when wait=false.
Handle partial output and wipe the temporary data on error paths.

Retain the existing OpenWrt entropy quality setting of 512 for review.
Hardware output smoke tests do not establish an entropy estimate.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/char/hw_random/Kconfig       |  11 +++
 drivers/char/hw_random/Makefile      |   1 +
 drivers/char/hw_random/cs75xx-trng.c | 159 +++++++++++++++++++++++++++++++++++
 3 files changed, 171 insertions(+)

diff --git a/drivers/char/hw_random/Kconfig b/drivers/char/hw_random/Kconfig
index d3108991c..1c6a3f9f8 100644
--- a/drivers/char/hw_random/Kconfig
+++ b/drivers/char/hw_random/Kconfig
@@ -648,6 +648,17 @@ config HW_RANDOM_QCOM
 	  To compile this driver as a module, choose M here. The
 	  module will be called qcom-rng. If unsure, say N.
 
+
+config HW_RANDOM_CS75XX
+	tristate "Cortina Systems CS7542 random number generator"
+	depends on OF && HAS_IOMEM
+	select MFD_SYSCON
+	help
+	  Support the Elliptic random number generator in the CS7542 SoC.
+	  Access the shared global control block through a syscon regmap.
+	  Provide polled reads through the hardware RNG framework.
+	  The module will be named cs75xx-trng.
+
 endif # HW_RANDOM
 
 config UML_RANDOM
diff --git a/drivers/char/hw_random/Makefile b/drivers/char/hw_random/Makefile
index 8fce2aa6c..b7b5fdaa7 100644
--- a/drivers/char/hw_random/Makefile
+++ b/drivers/char/hw_random/Makefile
@@ -55,3 +55,4 @@ obj-$(CONFIG_HW_RANDOM_ROCKCHIP) += rockchip-rng.o
 obj-$(CONFIG_HW_RANDOM_JH7110) += jh7110-trng.o
 obj-$(CONFIG_HW_RANDOM_XILINX) += xilinx-trng.o
 obj-$(CONFIG_HW_RANDOM_QCOM) += qcom-rng.o
+obj-$(CONFIG_HW_RANDOM_CS75XX)		+= cs75xx-trng.o
diff --git a/drivers/char/hw_random/cs75xx-trng.c b/drivers/char/hw_random/cs75xx-trng.c
new file mode 100644
index 000000000..38a1958df
--- /dev/null
+++ b/drivers/char/hw_random/cs75xx-trng.c
@@ -0,0 +1,159 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Cortina CS75xx (Goldengate) true random number generator
+ *
+ * The block is an Elliptic TRNG: control at 0x00, interrupt status at 0x04,
+ * interrupt enable at 0x08 and four data words from 0x10. A new value is
+ * requested with GEN_NEW and is ready when the DONE status bit is set.
+ * The vendor driver also sets bit 5 of the GLOBAL_SCRATCH register before
+ * using the block, so does this one.
+ */
+
+#include <linux/bits.h>
+#include <linux/hw_random.h>
+#include <linux/io.h>
+#include <linux/iopoll.h>
+#include <linux/mfd/syscon.h>
+#include <linux/mod_devicetable.h>
+#include <linux/of.h>
+#include <linux/regmap.h>
+#include <linux/slab.h>
+#include <linux/string.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+
+#define TRNG_CTRL		0x00
+#define TRNG_CTRL_GEN_NEW	BIT(0)
+#define TRNG_CTRL_RESEED	BIT(31)
+#define TRNG_IRQ_STAT		0x04
+#define TRNG_IRQ_EN		0x08
+#define TRNG_IRQ_DONE		BIT(27)
+#define TRNG_DATA		0x10
+#define TRNG_WORDS		4
+
+#define GLOBAL_SCRATCH		0xc0
+#define GLOBAL_SCRATCH_TRNG	BIT(5)
+
+#define TRNG_TIMEOUT_US		10000
+
+struct cs75xx_trng {
+	struct hwrng rng;
+	void __iomem *base;
+	struct regmap *global;
+	bool pending;
+};
+
+static int cs75xx_trng_wait(struct cs75xx_trng *t)
+{
+	u32 val;
+	int ret;
+
+	ret = readl_poll_timeout(t->base + TRNG_IRQ_STAT, val,
+				 val & TRNG_IRQ_DONE, 1, TRNG_TIMEOUT_US);
+	writel(TRNG_IRQ_DONE, t->base + TRNG_IRQ_STAT);
+	return ret;
+}
+
+static int cs75xx_trng_init(struct hwrng *rng)
+{
+	struct cs75xx_trng *t = container_of(rng, struct cs75xx_trng, rng);
+	int ret;
+
+	ret = regmap_update_bits(t->global, GLOBAL_SCRATCH,
+				 GLOBAL_SCRATCH_TRNG, GLOBAL_SCRATCH_TRNG);
+	if (ret)
+		return ret;
+	writel(0, t->base + TRNG_IRQ_EN);
+	writel(TRNG_IRQ_DONE, t->base + TRNG_IRQ_STAT);
+	t->pending = false;
+	writel(TRNG_CTRL_RESEED, t->base + TRNG_CTRL);
+	return cs75xx_trng_wait(t);
+}
+
+static int cs75xx_trng_read(struct hwrng *rng, void *buf, size_t max, bool wait)
+{
+	struct cs75xx_trng *t = container_of(rng, struct cs75xx_trng, rng);
+	u32 data[TRNG_WORDS];
+	size_t done = 0;
+	int i, ret;
+
+	while (done < max) {
+		size_t n = min(max - done, sizeof(data));
+
+		if (!t->pending) {
+			writel(TRNG_IRQ_DONE, t->base + TRNG_IRQ_STAT);
+			writel(TRNG_CTRL_GEN_NEW, t->base + TRNG_CTRL);
+			t->pending = true;
+		}
+
+		if (wait) {
+			ret = cs75xx_trng_wait(t);
+		} else {
+			if (!(readl(t->base + TRNG_IRQ_STAT) & TRNG_IRQ_DONE))
+				break;
+			writel(TRNG_IRQ_DONE, t->base + TRNG_IRQ_STAT);
+			ret = 0;
+		}
+		t->pending = false;
+		if (ret) {
+			memzero_explicit(data, sizeof(data));
+			return done ? done : ret;
+		}
+
+		for (i = 0; i < TRNG_WORDS; i++)
+			data[i] = readl(t->base + TRNG_DATA + 4 * i);
+		memcpy((u8 *)buf + done, data, n);
+		done += n;
+
+		if (!wait)
+			break;
+	}
+
+	memzero_explicit(data, sizeof(data));
+	return done;
+}
+
+static int cs75xx_trng_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct cs75xx_trng *t;
+
+	t = devm_kzalloc(dev, sizeof(*t), GFP_KERNEL);
+	if (!t)
+		return -ENOMEM;
+
+	t->base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(t->base))
+		return PTR_ERR(t->base);
+
+	t->global = syscon_regmap_lookup_by_phandle(dev->of_node,
+						    "cortina,syscon");
+	if (IS_ERR(t->global))
+		return dev_err_probe(dev, PTR_ERR(t->global),
+				     "cannot get global control regmap\n");
+
+	t->rng.name = dev_name(dev);
+	t->rng.init = cs75xx_trng_init;
+	t->rng.read = cs75xx_trng_read;
+	t->rng.quality = 512;
+
+	return devm_hwrng_register(dev, &t->rng);
+}
+
+static const struct of_device_id cs75xx_trng_of_match[] = {
+	{ .compatible = "cortina,cs7542-trng" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, cs75xx_trng_of_match);
+
+static struct platform_driver cs75xx_trng_driver = {
+	.probe = cs75xx_trng_probe,
+	.driver = {
+		.name = "cs75xx-trng",
+		.of_match_table = cs75xx_trng_of_match,
+	},
+};
+module_platform_driver(cs75xx_trng_driver);
+
+MODULE_DESCRIPTION("Cortina CS75xx TRNG driver");
+MODULE_LICENSE("GPL");

-- 
2.53.0

