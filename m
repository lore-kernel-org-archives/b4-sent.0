From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 12 Oct 2026 20:33:01 +0300
Subject: [PATCH 06/11] i2c: Add Cortina Systems CS75xx I2C controller
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-b4-cs75xx-s2-v1-6-8a7641b7b79c@gmail.com>
References: <20261012-b4-cs75xx-s2-v1-0-8a7641b7b79c@gmail.com>
In-Reply-To: <20261012-b4-cs75xx-s2-v1-0-8a7641b7b79c@gmail.com>
To: Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-i2c@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791826375; l=11869;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=FzeI9vB9Tx+9xPCOTDziE7128Dfo7jMIa4F1RPWlSzI=;
 b=n90WQuS64dRRo/gw9BAQI8QHarFqsTBfpcNemz6m5HukXu1y1j3oKN5YTThJk707OE3j9HEDq
 EEXS356FQOvCCaRt4zXNbM6AykDrmuC8g49Ors922ZHgXHBw9E2FFz0
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The I2C ("Bi-Wire") controller of the Cortina Systems CS75xx SoCs
transfers one byte per command, with a command register much like the
OpenCores one (start, stop, read, write, acknowledge), and raises an
interrupt when a command has completed.

Messages are sent with a repeated start between them and a stop after
the last one. Every message needs at least one data byte, so SMBus quick
commands are not supported. Arbitration loss is reported as -EAGAIN and
retried by the core.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/i2c/busses/Kconfig      |  11 ++
 drivers/i2c/busses/Makefile     |   1 +
 drivers/i2c/busses/i2c-cs75xx.c | 354 ++++++++++++++++++++++++++++++++++++++++
 3 files changed, 366 insertions(+)

diff --git a/drivers/i2c/busses/Kconfig b/drivers/i2c/busses/Kconfig
index d7b895083..a65e951a5 100644
--- a/drivers/i2c/busses/Kconfig
+++ b/drivers/i2c/busses/Kconfig
@@ -520,6 +520,17 @@ config I2C_CADENCE
 	  Say yes here to select Cadence I2C Host Controller. This controller is
 	  e.g. used by Xilinx Zynq.
 
+config I2C_CS75XX
+	tristate "Cortina Systems CS75xx I2C controller"
+	depends on ARCH_CORTINA_ACCESS || COMPILE_TEST
+	depends on HAS_IOMEM
+	help
+	  Say yes here to support the I2C ("Bi-Wire") controller of the
+	  Cortina Systems CS75xx SoCs.
+
+	  This driver can also be built as a module. If so, the module
+	  will be called i2c-cs75xx.
+
 config I2C_CBUS_GPIO
 	tristate "CBUS I2C driver"
 	depends on GPIOLIB || COMPILE_TEST
diff --git a/drivers/i2c/busses/Makefile b/drivers/i2c/busses/Makefile
index 3755c54b3..aab1beeb2 100644
--- a/drivers/i2c/busses/Makefile
+++ b/drivers/i2c/busses/Makefile
@@ -47,6 +47,7 @@ obj-$(CONFIG_I2C_BCM2835)	+= i2c-bcm2835.o
 obj-$(CONFIG_I2C_BCM_IPROC)	+= i2c-bcm-iproc.o
 obj-$(CONFIG_I2C_CADENCE)	+= i2c-cadence.o
 obj-$(CONFIG_I2C_CBUS_GPIO)	+= i2c-cbus-gpio.o
+obj-$(CONFIG_I2C_CS75XX)	+= i2c-cs75xx.o
 obj-$(CONFIG_I2C_CGBC)		+= i2c-cgbc.o
 obj-$(CONFIG_I2C_CPM)		+= i2c-cpm.o
 obj-$(CONFIG_I2C_DAVINCI)	+= i2c-davinci.o
diff --git a/drivers/i2c/busses/i2c-cs75xx.c b/drivers/i2c/busses/i2c-cs75xx.c
new file mode 100644
index 000000000..2d40f099d
--- /dev/null
+++ b/drivers/i2c/busses/i2c-cs75xx.c
@@ -0,0 +1,354 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Cortina Systems CS75xx I2C ("Bi-Wire") controller
+ *
+ * The controller works one byte at a time: software writes the byte to
+ * transmit and a command (start, stop, read, write, acknowledge) and gets
+ * an interrupt when the command has completed.
+ */
+
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/clk.h>
+#include <linux/completion.h>
+#include <linux/delay.h>
+#include <linux/i2c.h>
+#include <linux/interrupt.h>
+#include <linux/io.h>
+#include <linux/iopoll.h>
+#include <linux/mod_devicetable.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+#include <linux/property.h>
+#include <linux/spinlock.h>
+
+#define CS75XX_I2C_CFG		0x00
+#define CS75XX_I2C_CTRL		0x04
+#define CS75XX_I2C_TXR		0x08
+#define CS75XX_I2C_RXR		0x0c
+#define CS75XX_I2C_ACK		0x10
+#define CS75XX_I2C_IE		0x14
+#define CS75XX_I2C_INT		0x18
+
+#define CS75XX_I2C_CFG_EN	BIT(0)
+#define CS75XX_I2C_CFG_PRER	GENMASK(31, 16)
+
+#define CS75XX_I2C_CTRL_DONE	BIT(0)
+#define CS75XX_I2C_CTRL_NACK	BIT(3)
+#define CS75XX_I2C_CTRL_WRITE	BIT(4)
+#define CS75XX_I2C_CTRL_READ	BIT(5)
+#define CS75XX_I2C_CTRL_STOP	BIT(6)
+#define CS75XX_I2C_CTRL_START	BIT(7)
+
+#define CS75XX_I2C_ACK_AL	BIT(0)
+#define CS75XX_I2C_ACK_BUSY	BIT(1)
+#define CS75XX_I2C_ACK_NACK	BIT(2)
+
+#define CS75XX_I2C_INT_DONE	BIT(0)
+
+enum cs75xx_i2c_state {
+	CS75XX_I2C_IDLE,
+	CS75XX_I2C_ADDR,
+	CS75XX_I2C_WRITE,
+	CS75XX_I2C_READ,
+};
+
+struct cs75xx_i2c {
+	struct i2c_adapter adap;
+	struct device *dev;
+	void __iomem *base;
+	unsigned long ref_rate;
+	u32 bus_rate;
+
+	spinlock_t lock;	/* protects the transfer state */
+	struct completion done;
+	enum cs75xx_i2c_state state;
+	struct i2c_msg *msg;
+	unsigned int pos;
+	bool last;
+	int err;
+};
+
+static void cs75xx_i2c_hw_init(struct cs75xx_i2c *i2c)
+{
+	u32 prer = DIV_ROUND_UP(i2c->ref_rate, 5 * i2c->bus_rate) - 1;
+
+	if (readl(i2c->base + CS75XX_I2C_CFG) & CS75XX_I2C_CFG_EN) {
+		writel(0, i2c->base + CS75XX_I2C_CFG);
+		usleep_range(5000, 10000);
+	}
+
+	writel(FIELD_PREP(CS75XX_I2C_CFG_PRER, prer) | CS75XX_I2C_CFG_EN,
+	       i2c->base + CS75XX_I2C_CFG);
+	usleep_range(5000, 10000);
+}
+
+static void cs75xx_i2c_finish(struct cs75xx_i2c *i2c, int err)
+{
+	i2c->err = err;
+	i2c->state = CS75XX_I2C_IDLE;
+	complete(&i2c->done);
+}
+
+/* Start the transfer of the next data byte of the message */
+static void cs75xx_i2c_next_byte(struct cs75xx_i2c *i2c)
+{
+	struct i2c_msg *msg = i2c->msg;
+	bool last_byte = i2c->pos == msg->len - 1;
+	u32 cmd;
+
+	if (msg->flags & I2C_M_RD) {
+		i2c->state = CS75XX_I2C_READ;
+		cmd = CS75XX_I2C_CTRL_READ;
+		/* Do not acknowledge the last byte of a read */
+		if (last_byte)
+			cmd |= CS75XX_I2C_CTRL_NACK;
+	} else {
+		i2c->state = CS75XX_I2C_WRITE;
+		writel(msg->buf[i2c->pos++], i2c->base + CS75XX_I2C_TXR);
+		cmd = CS75XX_I2C_CTRL_WRITE;
+	}
+
+	if (last_byte && i2c->last)
+		cmd |= CS75XX_I2C_CTRL_STOP;
+
+	writel(cmd, i2c->base + CS75XX_I2C_CTRL);
+}
+
+static void cs75xx_i2c_process(struct cs75xx_i2c *i2c, u32 ack)
+{
+	struct i2c_msg *msg = i2c->msg;
+
+	if (ack & CS75XX_I2C_ACK_AL) {
+		writel(CS75XX_I2C_CTRL_STOP, i2c->base + CS75XX_I2C_CTRL);
+		cs75xx_i2c_finish(i2c, -EAGAIN);
+		return;
+	}
+
+	switch (i2c->state) {
+	case CS75XX_I2C_ADDR:
+		if (ack & CS75XX_I2C_ACK_NACK) {
+			writel(CS75XX_I2C_CTRL_STOP, i2c->base + CS75XX_I2C_CTRL);
+			cs75xx_i2c_finish(i2c, -ENXIO);
+			return;
+		}
+		cs75xx_i2c_next_byte(i2c);
+		break;
+
+	case CS75XX_I2C_WRITE:
+		if (i2c->pos == msg->len) {
+			cs75xx_i2c_finish(i2c, 0);
+			return;
+		}
+		if (ack & CS75XX_I2C_ACK_NACK) {
+			writel(CS75XX_I2C_CTRL_STOP, i2c->base + CS75XX_I2C_CTRL);
+			cs75xx_i2c_finish(i2c, -EIO);
+			return;
+		}
+		cs75xx_i2c_next_byte(i2c);
+		break;
+
+	case CS75XX_I2C_READ:
+		msg->buf[i2c->pos++] = readl(i2c->base + CS75XX_I2C_RXR);
+		if (i2c->pos == msg->len) {
+			cs75xx_i2c_finish(i2c, 0);
+			return;
+		}
+		cs75xx_i2c_next_byte(i2c);
+		break;
+
+	case CS75XX_I2C_IDLE:
+		/* Completion of a stop issued on error, nothing to do */
+		break;
+	}
+}
+
+static irqreturn_t cs75xx_i2c_isr(int irq, void *dev_id)
+{
+	struct cs75xx_i2c *i2c = dev_id;
+	u32 ctrl, ack;
+
+	if (!(readl(i2c->base + CS75XX_I2C_INT) & CS75XX_I2C_INT_DONE))
+		return IRQ_NONE;
+
+	writel(CS75XX_I2C_INT_DONE, i2c->base + CS75XX_I2C_INT);
+
+	/* The done flag is cleared by writing it back */
+	ctrl = readl(i2c->base + CS75XX_I2C_CTRL);
+	writel(ctrl, i2c->base + CS75XX_I2C_CTRL);
+
+	ack = readl(i2c->base + CS75XX_I2C_ACK);
+
+	spin_lock(&i2c->lock);
+	cs75xx_i2c_process(i2c, ack);
+	spin_unlock(&i2c->lock);
+
+	return IRQ_HANDLED;
+}
+
+static int cs75xx_i2c_xfer_msg(struct cs75xx_i2c *i2c, struct i2c_msg *msg,
+			       bool last)
+{
+	unsigned long time_left;
+
+	spin_lock_irq(&i2c->lock);
+	reinit_completion(&i2c->done);
+	i2c->msg = msg;
+	i2c->pos = 0;
+	i2c->last = last;
+	i2c->err = 0;
+	i2c->state = CS75XX_I2C_ADDR;
+	writel(i2c_8bit_addr_from_msg(msg), i2c->base + CS75XX_I2C_TXR);
+	writel(CS75XX_I2C_CTRL_START | CS75XX_I2C_CTRL_WRITE,
+	       i2c->base + CS75XX_I2C_CTRL);
+	spin_unlock_irq(&i2c->lock);
+
+	time_left = wait_for_completion_timeout(&i2c->done, i2c->adap.timeout);
+	if (!time_left) {
+		spin_lock_irq(&i2c->lock);
+		i2c->state = CS75XX_I2C_IDLE;
+		spin_unlock_irq(&i2c->lock);
+		dev_err(i2c->dev, "transfer timed out, resetting the controller\n");
+		cs75xx_i2c_hw_init(i2c);
+		return -ETIMEDOUT;
+	}
+
+	return i2c->err;
+}
+
+static int cs75xx_i2c_xfer(struct i2c_adapter *adap, struct i2c_msg *msgs,
+			   int num)
+{
+	struct cs75xx_i2c *i2c = i2c_get_adapdata(adap);
+	u32 val;
+	int i, ret;
+
+	/*
+	 * Let the stop condition of the previous transfer complete and drop
+	 * its interrupt, so that it is not taken for the next address phase.
+	 */
+	if (readl_poll_timeout(i2c->base + CS75XX_I2C_ACK, val,
+			       !(val & CS75XX_I2C_ACK_BUSY), 10, 1000))
+		dev_dbg(i2c->dev, "bus still busy\n");
+	writel(CS75XX_I2C_INT_DONE, i2c->base + CS75XX_I2C_INT);
+
+	for (i = 0; i < num; i++) {
+		ret = cs75xx_i2c_xfer_msg(i2c, &msgs[i], i == num - 1);
+		if (ret)
+			return ret;
+	}
+
+	return num;
+}
+
+static u32 cs75xx_i2c_func(struct i2c_adapter *adap)
+{
+	return I2C_FUNC_I2C | (I2C_FUNC_SMBUS_EMUL & ~I2C_FUNC_SMBUS_QUICK);
+}
+
+static const struct i2c_algorithm cs75xx_i2c_algo = {
+	.xfer = cs75xx_i2c_xfer,
+	.functionality = cs75xx_i2c_func,
+};
+
+/* A message always carries at least one data byte after the address */
+static const struct i2c_adapter_quirks cs75xx_i2c_quirks = {
+	.flags = I2C_AQ_NO_ZERO_LEN,
+};
+
+static void cs75xx_i2c_disable(void *data)
+{
+	struct cs75xx_i2c *i2c = data;
+
+	writel(0, i2c->base + CS75XX_I2C_IE);
+	writel(0, i2c->base + CS75XX_I2C_CFG);
+}
+
+static int cs75xx_i2c_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct cs75xx_i2c *i2c;
+	struct clk *clk;
+	int irq, ret;
+
+	i2c = devm_kzalloc(dev, sizeof(*i2c), GFP_KERNEL);
+	if (!i2c)
+		return -ENOMEM;
+
+	i2c->dev = dev;
+	spin_lock_init(&i2c->lock);
+	init_completion(&i2c->done);
+
+	i2c->base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(i2c->base))
+		return PTR_ERR(i2c->base);
+
+	irq = platform_get_irq(pdev, 0);
+	if (irq < 0)
+		return irq;
+
+	clk = devm_clk_get_enabled(dev, NULL);
+	if (IS_ERR(clk))
+		return dev_err_probe(dev, PTR_ERR(clk), "failed to get clock\n");
+
+	i2c->ref_rate = clk_get_rate(clk);
+	if (device_property_read_u32(dev, "clock-frequency", &i2c->bus_rate))
+		i2c->bus_rate = I2C_MAX_STANDARD_MODE_FREQ;
+	if (!i2c->ref_rate || !i2c->bus_rate ||
+	    i2c->bus_rate > I2C_MAX_FAST_MODE_FREQ ||
+	    i2c->ref_rate / (5 * i2c->bus_rate) > FIELD_MAX(CS75XX_I2C_CFG_PRER) + 1)
+		return dev_err_probe(dev, -EINVAL,
+				     "unsupported bus frequency %u Hz\n",
+				     i2c->bus_rate);
+
+	cs75xx_i2c_hw_init(i2c);
+
+	writel(0, i2c->base + CS75XX_I2C_IE);
+	writel(CS75XX_I2C_INT_DONE, i2c->base + CS75XX_I2C_INT);
+
+	ret = devm_add_action_or_reset(dev, cs75xx_i2c_disable, i2c);
+	if (ret)
+		return ret;
+
+	ret = devm_request_irq(dev, irq, cs75xx_i2c_isr, 0, dev_name(dev), i2c);
+	if (ret)
+		return ret;
+
+	writel(CS75XX_I2C_INT_DONE, i2c->base + CS75XX_I2C_IE);
+
+	i2c->adap.owner = THIS_MODULE;
+	i2c->adap.algo = &cs75xx_i2c_algo;
+	i2c->adap.quirks = &cs75xx_i2c_quirks;
+	i2c->adap.retries = 3;
+	i2c->adap.dev.parent = dev;
+	i2c->adap.dev.of_node = dev->of_node;
+	strscpy(i2c->adap.name, dev_name(dev), sizeof(i2c->adap.name));
+	i2c_set_adapdata(&i2c->adap, i2c);
+
+	ret = devm_i2c_add_adapter(dev, &i2c->adap);
+	if (ret)
+		return ret;
+
+	dev_dbg(dev, "bus %u Hz, reference %lu Hz\n", i2c->bus_rate,
+		i2c->ref_rate);
+
+	return 0;
+}
+
+static const struct of_device_id cs75xx_i2c_of_match[] = {
+	{ .compatible = "cortina,cs7542-i2c" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, cs75xx_i2c_of_match);
+
+static struct platform_driver cs75xx_i2c_driver = {
+	.probe = cs75xx_i2c_probe,
+	.driver = {
+		.name = "cs75xx-i2c",
+		.of_match_table = cs75xx_i2c_of_match,
+	},
+};
+module_platform_driver(cs75xx_i2c_driver);
+
+MODULE_DESCRIPTION("Cortina Systems CS75xx I2C controller driver");
+MODULE_LICENSE("GPL");

-- 
2.53.0

