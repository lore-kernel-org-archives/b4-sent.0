From: Ben Zong-You Xie <ben717@andestech.com>
Date: Tue, 11 Aug 2026 14:29:49 +0800
Subject: [PATCH v5 2/4] i2c: add Andes I2C driver support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-atciic100-v5-2-1d306c21dba3@andestech.com>
References: <20260811-atciic100-v5-0-1d306c21dba3@andestech.com>
In-Reply-To: <20260811-atciic100-v5-0-1d306c21dba3@andestech.com>
To: Andi Shyti <andi.shyti@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-i2c@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Ben Zong-You Xie <ben717@andestech.com>
X-Mailer: b4 0.15-dev-09770
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786429789; l=11439;
 i=ben717@andestech.com; s=20260120; h=from:subject:message-id;
 bh=anfOM9cdAboej+C0cpOCCkEAR/UEiOCs3AOuyLG0+c0=;
 b=bJ8IvlzyJwaGn5ET6cq3AbWhiiKNmKoW2RcUC17YdFu8xtzFrxX+huitzy8nNPwtgJ/SG6qud
 /TarIQlhTA6A5HQDTl4922ZOiR3o6rBAy9+kbjM+PIgOKj+NAgKq5DB
X-Developer-Key: i=ben717@andestech.com; a=ed25519;
 pk=nb8L7zQKGJpYk0yvrYKjViOZ34A36g1ZIsCmCsP518s=
X-Endpoint-Received: by B4 Relay for ben717@andestech.com/20260120 with auth_id=610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Andes I2C driver. Andes I2C can act as either a
controller or a target, depending on the control register settings. Now,
we only support controller mode.

Signed-off-by: Ben Zong-You Xie <ben717@andestech.com>
---
 drivers/i2c/busses/Kconfig     |  10 ++
 drivers/i2c/busses/Makefile    |   1 +
 drivers/i2c/busses/i2c-andes.c | 341 +++++++++++++++++++++++++++++++++++++++++
 3 files changed, 352 insertions(+)

diff --git a/drivers/i2c/busses/Kconfig b/drivers/i2c/busses/Kconfig
index d7b89508311f..73f1946bd8b7 100644
--- a/drivers/i2c/busses/Kconfig
+++ b/drivers/i2c/busses/Kconfig
@@ -446,6 +446,16 @@ config I2C_AT91_SLAVE_EXPERIMENTAL
 	    - There are some mismatches with a SAMA5D4 as slave and a SAMA5D2 as
 	    master.
 
+config I2C_ANDES
+	tristate "Andes I2C Controller"
+	depends on ARCH_ANDES || COMPILE_TEST
+	help
+	  If you say yes to this option, support will be included for the
+	  Andes I2C controller.
+
+	  This support is also available as a module. If so, the module
+	  will be called i2c-andes.
+
 config I2C_AU1550
 	tristate "Au1550/Au1200/Au1300 SMBus interface"
 	depends on MIPS_ALCHEMY
diff --git a/drivers/i2c/busses/Makefile b/drivers/i2c/busses/Makefile
index 3755c54b3d82..6fe6ded04d2d 100644
--- a/drivers/i2c/busses/Makefile
+++ b/drivers/i2c/busses/Makefile
@@ -41,6 +41,7 @@ obj-$(CONFIG_I2C_ASPEED)	+= i2c-aspeed.o
 obj-$(CONFIG_I2C_AT91)		+= i2c-at91.o
 i2c-at91-y			:= i2c-at91-core.o i2c-at91-master.o
 i2c-at91-$(CONFIG_I2C_AT91_SLAVE_EXPERIMENTAL)	+= i2c-at91-slave.o
+obj-$(CONFIG_I2C_ANDES)		+= i2c-andes.o
 obj-$(CONFIG_I2C_AU1550)	+= i2c-au1550.o
 obj-$(CONFIG_I2C_AXXIA)		+= i2c-axxia.o
 obj-$(CONFIG_I2C_BCM2835)	+= i2c-bcm2835.o
diff --git a/drivers/i2c/busses/i2c-andes.c b/drivers/i2c/busses/i2c-andes.c
new file mode 100644
index 000000000000..5f135d8c9b13
--- /dev/null
+++ b/drivers/i2c/busses/i2c-andes.c
@@ -0,0 +1,341 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Driver for Andes I2C controller, used in Andes AE350 platform and QiLai SoC
+ *
+ * Copyright (C) 2026 Andes Technology Corporation.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/completion.h>
+#include <linux/iopoll.h>
+#include <linux/i2c.h>
+#include <linux/of_device.h>
+#include <linux/platform_device.h>
+#include <linux/regmap.h>
+#include <linux/spinlock.h>
+
+#define ANDES_I2C_ID_REG		0x0
+#define ANDES_I2C_ID_MASK		GENMASK(31, 8)
+#define ANDES_I2C_ID			0x020210
+
+#define	ANDES_I2C_CFG_REG		0x10
+#define ANDES_I2C_CFG_FIFOSIZE		GENMASK(1, 0)
+
+#define	ANDES_I2C_INTEN_REG		0x14
+#define	ANDES_I2C_INTEN_FIFO_EMPTY	BIT(0)
+#define	ANDES_I2C_INTEN_FIFO_FULL	BIT(1)
+#define	ANDES_I2C_INTEN_CMPL		BIT(9)
+
+#define	ANDES_I2C_STATUS_REG		0x18
+#define ANDES_I2C_STATUS_FIFO_EMPTY	BIT(0)
+#define ANDES_I2C_STATUS_FIFO_FULL	BIT(1)
+#define ANDES_I2C_STATUS_ADDR_HIT	BIT(3)
+#define ANDES_I2C_STATUS_CMPL		BIT(9)
+#define ANDES_I2C_STATUS_W1C		GENMASK(9, 3)
+
+#define	ANDES_I2C_ADDR_REG		0x1C
+
+#define	ANDES_I2C_DATA_REG		0x20
+
+#define	ANDES_I2C_CTRL_REG		0x24
+#define ANDES_I2C_CTRL_DATA_CNT		GENMASK(7, 0)
+#define ANDES_I2C_CTRL_DIR		BIT(8)
+#define ANDES_I2C_CTRL_PHASE		GENMASK(12, 9)
+
+#define	ANDES_I2C_CMD_REG		0x28
+#define ANDES_I2C_CMD_ACTION		GENMASK(2, 0)
+#define ANDES_I2C_CMD_TRANS		BIT(0)
+
+#define	ANDES_I2C_SETUP_REG		0x2C
+#define ANDES_I2C_SETUP_IICEN		BIT(0)
+#define ANDES_I2C_SETUP_REQ		BIT(2)
+
+#define ANDES_I2C_TPM_REG		0x30
+
+#define ANDES_I2C_TIMEOUT_US		400000
+#define ANDES_I2C_TIMEOUT		usecs_to_jiffies(ANDES_I2C_TIMEOUT_US)
+
+#define ANDES_I2C_MAX_DATA_LEN		256
+
+struct andes_i2c {
+	struct i2c_adapter adap;
+	struct completion completion;
+	spinlock_t lock;
+	struct regmap *map;
+	u8 *buf;
+	unsigned int fifo_size;
+	int irq;
+	u16 buf_len;
+	bool addr_hit;
+	bool xfer_done;
+};
+
+static const struct regmap_config andes_i2c_regmap_config = {
+	.name = "andes_i2c",
+	.reg_bits = 32,
+	.reg_stride = 4,
+	.val_bits = 32,
+	.pad_bits = 0,
+	.max_register = ANDES_I2C_TPM_REG,
+	.cache_type = REGCACHE_NONE,
+};
+
+static void andes_i2c_xfer_common(struct andes_i2c *i2c, u32 status)
+{
+	unsigned long flags;
+	unsigned int fsize = i2c->fifo_size;
+	unsigned int val;
+
+	spin_lock_irqsave(&i2c->lock, flags);
+	if (status & ANDES_I2C_STATUS_FIFO_EMPTY) {
+		/* Disable the FIFO empty interrupt for the last write */
+		if (i2c->buf_len <= fsize) {
+			fsize = i2c->buf_len;
+			regmap_clear_bits(i2c->map, ANDES_I2C_INTEN_REG,
+					  ANDES_I2C_INTEN_FIFO_EMPTY);
+		}
+
+		while (fsize--) {
+			val = *i2c->buf++;
+			regmap_write(i2c->map, ANDES_I2C_DATA_REG, val);
+			i2c->buf_len--;
+		}
+	} else if (status & ANDES_I2C_STATUS_FIFO_FULL) {
+		while (fsize--) {
+			regmap_read(i2c->map, ANDES_I2C_DATA_REG, &val);
+			*i2c->buf++ = (u8)val;
+			i2c->buf_len--;
+		}
+	}
+
+	if (status & ANDES_I2C_STATUS_CMPL) {
+		i2c->xfer_done = true;
+		if (status & ANDES_I2C_STATUS_ADDR_HIT)
+			i2c->addr_hit = true;
+
+		/* Write 1 to clear the status */
+		regmap_set_bits(i2c->map, ANDES_I2C_STATUS_REG,
+				ANDES_I2C_STATUS_W1C);
+
+		/* For the last read, retrieve all remaining data in FIFO. */
+		while (i2c->buf_len > 0) {
+			regmap_read(i2c->map, ANDES_I2C_DATA_REG, &val);
+			*i2c->buf++ = (u8)val;
+			i2c->buf_len--;
+		}
+	}
+
+	spin_unlock_irqrestore(&i2c->lock, flags);
+}
+
+static irqreturn_t andes_i2c_irq_handler(int irq, void *data)
+{
+	struct andes_i2c *i2c = data;
+	u32 i2c_status;
+
+	regmap_read(i2c->map, ANDES_I2C_STATUS_REG, &i2c_status);
+	andes_i2c_xfer_common(i2c, i2c_status);
+	if (i2c->xfer_done)
+		complete(&i2c->completion);
+
+	return IRQ_HANDLED;
+}
+
+static int andes_i2c_xfer_wait(struct andes_i2c *i2c, struct i2c_msg *msg)
+{
+	unsigned int mask;
+	unsigned int i2c_ctrl;
+
+	/*
+	 * Set the data count. If there are 256 bytes to be transmitted, write
+	 * zero to the data count field.
+	 */
+	regmap_update_bits(i2c->map, ANDES_I2C_CTRL_REG,
+			   ANDES_I2C_CTRL_DATA_CNT,
+			   FIELD_PREP(ANDES_I2C_CTRL_DATA_CNT, i2c->buf_len));
+
+	regmap_set_bits(i2c->map, ANDES_I2C_CTRL_REG, ANDES_I2C_CTRL_PHASE);
+	if (msg->flags & I2C_M_RD)
+		regmap_set_bits(i2c->map, ANDES_I2C_CTRL_REG,
+				ANDES_I2C_CTRL_DIR);
+	else
+		regmap_clear_bits(i2c->map, ANDES_I2C_CTRL_REG,
+				  ANDES_I2C_CTRL_DIR);
+
+	regmap_write(i2c->map, ANDES_I2C_ADDR_REG, msg->addr);
+
+	if (i2c->irq >= 0) {
+		mask = ANDES_I2C_INTEN_CMPL;
+		mask |= (msg->flags & I2C_M_RD) ? ANDES_I2C_INTEN_FIFO_FULL
+						: ANDES_I2C_INTEN_FIFO_EMPTY;
+		regmap_set_bits(i2c->map, ANDES_I2C_INTEN_REG, mask);
+	}
+
+	regmap_set_bits(i2c->map, ANDES_I2C_CMD_REG, ANDES_I2C_CMD_TRANS);
+	if (i2c->irq >= 0) {
+		unsigned long time_left;
+
+		time_left = wait_for_completion_timeout(&i2c->completion,
+							ANDES_I2C_TIMEOUT);
+		if (!time_left)
+			return -ETIMEDOUT;
+
+		if (!i2c->addr_hit)
+			return -ENXIO;
+
+		regmap_write(i2c->map, ANDES_I2C_INTEN_REG, 0);
+		reinit_completion(&i2c->completion);
+	} else {
+		unsigned int val;
+		int ret;
+
+		mask = ANDES_I2C_STATUS_CMPL;
+		mask |= (msg->flags & I2C_M_RD) ? ANDES_I2C_STATUS_FIFO_FULL
+						: ANDES_I2C_STATUS_FIFO_EMPTY;
+		while (!i2c->xfer_done) {
+			ret = regmap_read_poll_timeout(i2c->map,
+						       ANDES_I2C_STATUS_REG,
+						       val, val & mask, 2000,
+						       ANDES_I2C_TIMEOUT_US);
+			if (ret)
+				return ret;
+
+			andes_i2c_xfer_common(i2c, val);
+		}
+
+		if (!i2c->addr_hit)
+			return -ENXIO;
+	}
+
+	/* Check if all data is successfully transmitted */
+	regmap_read(i2c->map, ANDES_I2C_CTRL_REG, &i2c_ctrl);
+	if (FIELD_GET(ANDES_I2C_CTRL_DATA_CNT, i2c_ctrl))
+		return -EIO;
+
+	return 0;
+}
+
+static int andes_i2c_xfer(struct i2c_adapter *adap, struct i2c_msg *msg,
+			  int num)
+{
+	int i;
+	struct i2c_msg *m;
+	struct andes_i2c *i2c = i2c_get_adapdata(adap);
+	int ret;
+
+	for (i = 0; i < num; i++) {
+		m = &msg[i];
+		i2c->addr_hit = false;
+		i2c->buf = m->buf;
+		i2c->buf_len = m->len;
+		i2c->xfer_done = false;
+		ret = andes_i2c_xfer_wait(i2c, m);
+		if (ret < 0)
+			return ret;
+	}
+
+	return num;
+}
+
+static u32 andes_i2c_func(struct i2c_adapter *adap)
+{
+	return I2C_FUNC_I2C | I2C_FUNC_SMBUS_EMUL;
+}
+
+static struct i2c_algorithm andes_i2c_algo = {
+	.xfer = andes_i2c_xfer,
+	.functionality = andes_i2c_func,
+};
+
+static const struct i2c_adapter_quirks andes_i2c_quirks = {
+	.flags = I2C_AQ_NO_ZERO_LEN,
+	.max_write_len = ANDES_I2C_MAX_DATA_LEN,
+	.max_read_len = ANDES_I2C_MAX_DATA_LEN,
+};
+
+static int andes_i2c_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct andes_i2c *i2c;
+	void __iomem *reg_base;
+	u32 i2c_id;
+	int ret;
+	struct i2c_adapter *adap;
+
+	i2c = devm_kzalloc(dev, sizeof(*i2c), GFP_KERNEL);
+	if (!i2c)
+		return -ENOMEM;
+
+	reg_base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(reg_base))
+		return dev_err_probe(dev, PTR_ERR(reg_base),
+				     "failed to map I/O space\n");
+
+	i2c->map = devm_regmap_init_mmio(dev, reg_base,
+					 &andes_i2c_regmap_config);
+	if (IS_ERR(i2c->map))
+		return dev_err_probe(dev, PTR_ERR(i2c->map),
+				     "failed to initialize regmap\n");
+
+	regmap_read(i2c->map, ANDES_I2C_ID_REG, &i2c_id);
+	if (FIELD_GET(ANDES_I2C_ID_MASK, i2c_id) != ANDES_I2C_ID)
+		return dev_err_probe(dev, -ENODEV, "unmatched hardware ID 0x%x\n",
+				     i2c_id);
+
+	i2c->irq = platform_get_irq(pdev, 0);
+	if (i2c->irq >= 0) {
+		ret = devm_request_irq(dev, i2c->irq, andes_i2c_irq_handler, 0,
+				       dev_name(dev), i2c);
+		if (ret < 0)
+			return dev_err_probe(dev, ret, "unable to request IRQ %d\n",
+					     i2c->irq);
+	} else {
+		dev_warn(dev, "no IRQ resource, falling back to poll mode\n");
+	}
+
+	spin_lock_init(&i2c->lock);
+	init_completion(&i2c->completion);
+	adap = &i2c->adap;
+	strscpy(adap->name, pdev->name, sizeof(adap->name));
+	adap->algo = &andes_i2c_algo;
+	adap->class = I2C_CLASS_HWMON;
+	adap->dev.parent = dev;
+	adap->dev.of_node = dev->of_node;
+	adap->owner = THIS_MODULE;
+	adap->quirks = &andes_i2c_quirks;
+	adap->retries = 1;
+	adap->timeout = ANDES_I2C_TIMEOUT;
+	i2c_set_adapdata(adap, i2c);
+	platform_set_drvdata(pdev, i2c);
+	ret = devm_i2c_add_adapter(dev, adap);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to add adapter\n");
+
+	regmap_read(i2c->map, ANDES_I2C_CFG_REG, &i2c->fifo_size);
+	i2c->fifo_size = 2 << FIELD_GET(ANDES_I2C_CFG_FIFOSIZE, i2c->fifo_size);
+
+	regmap_set_bits(i2c->map, ANDES_I2C_SETUP_REG,
+			ANDES_I2C_SETUP_IICEN | ANDES_I2C_SETUP_REQ);
+	return 0;
+}
+
+static const struct of_device_id andes_i2c_of_match[] = {
+	{ .compatible = "andestech,ae350-i2c" },
+	{ /* sentinel */ }
+};
+
+MODULE_DEVICE_TABLE(of, andes_i2c_of_match);
+
+static struct platform_driver andes_i2c_platform_driver = {
+	.driver = {
+		.name = "andes_i2c",
+		.of_match_table	= andes_i2c_of_match,
+	},
+	.probe = andes_i2c_probe,
+};
+
+module_platform_driver(andes_i2c_platform_driver);
+
+MODULE_AUTHOR("Ben Zong-You Xie <ben717@andestech.com>");
+MODULE_DESCRIPTION("Andes I2C controller driver");
+MODULE_LICENSE("GPL");

-- 
2.34.1

