From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 04 Nov 2026 10:01:00 +0000
Subject: [PATCH v7 2/2] i2c: amlogic: Add Amlogic A9 I2C controller driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-a9-i2c-v7-2-b31f2b53faf4@amlogic.com>
References: <20261104-a9-i2c-v7-0-b31f2b53faf4@amlogic.com>
In-Reply-To: <20261104-a9-i2c-v7-0-b31f2b53faf4@amlogic.com>
To: Junyi Zhao <junyi.zhao@amlogic.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Xianwei Zhao <xianwei.zhaol@amlogic.com>
Cc: Junyi Zhao <junyi.zhaol@amlogic.com>, linux-i2c@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793786462; l=14914;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=AdauvTfFnz0T2e/O5nR35xNEj9I6zRb+Fr4F98mB5zU=;
 b=M2S+iGFp7Ip8/QUrDPZLLD9y/ewAeViJfy9gn1pB42/bmsM5kQKT8eTLv/kVMBU2YCiK+Ha/U
 IOHvHdp0JezB8838Tk8hMstjQv3W6ySRifJlmvMqijo5rzkMezIe8DY
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Junyi Zhao <junyi.zhao@amlogic.com>

Add support for the new I2C controller used by Amlogic A9 SoCs.

Add a dedicated Kconfig option and Makefile entry for the A9 I2C
controller driver. And add Amlogic I2C controller entry to MAINTAINERS
to clarify the maintainers.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 MAINTAINERS                         |   9 +
 drivers/i2c/busses/Kconfig          |   8 +
 drivers/i2c/busses/Makefile         |   1 +
 drivers/i2c/busses/i2c-amlogic-a9.c | 432 ++++++++++++++++++++++++++++++++++++
 4 files changed, 450 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index a2d702919ef3..a56bdfefabad 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1371,6 +1371,15 @@ F:	Documentation/devicetree/bindings/perf/amlogic,g12-ddr-pmu.yaml
 F:	drivers/perf/amlogic/
 F:	include/soc/amlogic/
 
+AMLOGIC I2C DRIVER
+M:	Junyi Zhao <junyi.zhao@amlogic.com>
+M:	Xianwei Zhao <xianwei.zhao@amlogic.com>
+L:	linux-i2c@vger.kernel.org
+L:	linux-amlogic@lists.infradead.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/i2c/amlogic,a9-i2c.yaml
+F:	drivers/i2c/busses/i2c-amlogic-a9.c
+
 AMLOGIC ISP DRIVER
 M:	Keke Li <keke.li@amlogic.com>
 L:	linux-media@vger.kernel.org
diff --git a/drivers/i2c/busses/Kconfig b/drivers/i2c/busses/Kconfig
index 275aaa7f3583..50e031d97ed3 100644
--- a/drivers/i2c/busses/Kconfig
+++ b/drivers/i2c/busses/Kconfig
@@ -885,6 +885,14 @@ config I2C_MESON
 	  If you say yes to this option, support will be included for the
 	  I2C interface on the Amlogic Meson family of SoCs.
 
+config I2C_AMLOGIC_A9
+	tristate "Amlogic new I2C controller"
+	depends on ARCH_MESON || COMPILE_TEST
+	depends on COMMON_CLK
+	help
+	  If you say yes to this option, support will be included for the
+	  I2C interface on the new Amlogic family of SoCs.
+
 config I2C_MICROCHIP_CORE
 	tristate "Microchip FPGA I2C controller"
 	depends on ARCH_MICROCHIP_POLARFIRE || COMPILE_TEST
diff --git a/drivers/i2c/busses/Makefile b/drivers/i2c/busses/Makefile
index e5440de0fe14..343eec4b0889 100644
--- a/drivers/i2c/busses/Makefile
+++ b/drivers/i2c/busses/Makefile
@@ -82,6 +82,7 @@ obj-$(CONFIG_I2C_LPC2K)		+= i2c-lpc2k.o
 obj-$(CONFIG_I2C_LS2X)		+= i2c-ls2x.o
 obj-$(CONFIG_I2C_LS2X_V2)	+= i2c-ls2x-v2.o
 obj-$(CONFIG_I2C_MESON)		+= i2c-meson.o
+obj-$(CONFIG_I2C_AMLOGIC_A9)	+= i2c-amlogic-a9.o
 obj-$(CONFIG_I2C_MICROCHIP_CORE)	+= i2c-microchip-corei2c.o
 obj-$(CONFIG_I2C_MPC)		+= i2c-mpc.o
 obj-$(CONFIG_I2C_MT65XX)	+= i2c-mt65xx.o
diff --git a/drivers/i2c/busses/i2c-amlogic-a9.c b/drivers/i2c/busses/i2c-amlogic-a9.c
new file mode 100644
index 000000000000..d282f275d4d3
--- /dev/null
+++ b/drivers/i2c/busses/i2c-amlogic-a9.c
@@ -0,0 +1,432 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/*
+ * Copyright (C) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#include <linux/clk.h>
+#include <linux/completion.h>
+#include <linux/i2c.h>
+#include <linux/interrupt.h>
+#include <linux/io.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+
+/* Amlogic I2C register map */
+#define REG_CFG_RDY		0x00
+#define REG_CFG_I2C		0x04
+#define REG_CFG_START		0x08
+#define REG_CFG_BUS		0x0c
+#define REG_TX_RD_ADDR		0x10
+#define REG_TX_WR_ADDR		0x14
+#define REG_RX_RD_ADDR		0x18
+#define REG_RX_WR_ADDR		0x1c
+#define REG_CFG_TX		0x20
+#define REG_CFG_RX		0x24
+#define REG_CFG_IRQ_STATE	0x30
+#define REG_CFG_IRQ_ENABLE	0x34
+#define REG_SHAKE_BLK_CNT	0x38
+
+/* CFG RDY fields */
+#define RDY_TEE_ONLY		BIT(1)
+#define RDY_IF			BIT(0)
+
+/* CFG I2C fields */
+#define I2C_RX_THR		GENMASK(23, 16)
+#define I2C_TX_THR		GENMASK(15, 8)
+
+/* CFG BUS fields */
+#define BUS_NO_STOP		BIT(18)
+
+/* SCL = clk/b_ratio	if b_ratio<=8, SCL = clk/8 */
+#define BUS_RATIO_MASK		GENMASK(11, 0)
+
+/* CFG START fields */
+#define START_START		BIT(31)
+#define START_LEN		GENMASK(23, 12)
+#define START_LEN_SHIFT		12
+#define START_SLAVE_ADDR	GENMASK(10, 1)
+#define START_SADDR_SHIFT	1
+#define START_READ		BIT(0)
+
+/* CFG TX_RX fields */
+#define TX_RX_DATA		GENMASK(7, 0)
+
+/* CFG IRQ fields */
+#define IRQ_ALL_MASK		GENMASK(15, 0)
+#define A9_NCK_ERROR		BIT(0)
+#define A9_RX_THRESH_READ	BIT(5)
+#define A9_TX_THRESH_WRITE	BIT(6)
+#define A9_PHY_DONE		BIT(7)
+#define A9_TASK_DONE		BIT(8)
+#define A9_ALL_DONE		BIT(9)
+
+#define A9_TRANS_DONE		(A9_PHY_DONE | A9_NCK_ERROR)
+#define A9_TRANS_ERROR		(A9_NCK_ERROR)
+#define A9_ENABLE_IRQ_BIT	(A9_NCK_ERROR | A9_PHY_DONE)
+#define THRESH_MODE		(A9_RX_THRESH_READ | A9_TX_THRESH_WRITE)
+
+#define A9_I2C_FIFO_DEPTH	32
+#define A9_I2C_HALF_FIFO	(A9_I2C_FIFO_DEPTH >> 1)
+
+#define A9_I2C_MAX_XFER_SIZE	0xfff
+
+#define I2C_TIMEOUT_MS		500
+
+enum {
+	A9_STATE_IDLE,
+	A9_STATE_READ,
+	A9_STATE_WRITE,
+};
+
+enum fifo_fill_mode {
+	A9_FIFO_FILL_FULL,
+	A9_FIFO_FILL_HALF,
+};
+
+/**
+ * struct aml_i2c - Amlogic I2C device private data
+ *
+ * @adap:	I2C adapter instance
+ * @dev:	Pointer to device structure
+ * @regs:	Base address of the device memory mapped registers
+ * @clk:	Pointer to clock structure
+ * @msg:	Pointer to the current I2C message
+ * @state:	Current state in the driver state machine
+ * @pos:	Current position in the send/receive buffer
+ * @error:	Flag set when an error is received
+ * @lock:	To avoid race conditions between irq handler and xfer code
+ * @done:	Completion used to wait for transfer termination
+ * @clk_rate:	Clock source rate of I2C module
+ * @frequency:	Operating frequency of I2C bus clock
+ */
+struct aml_i2c {
+	struct i2c_adapter	adap;
+	struct device		*dev;
+	void __iomem		*regs;
+	struct clk		*clk;
+
+	struct i2c_msg		*msg;
+	int			state;
+	int			pos;
+	int			error;
+	/* protect reg access */
+	spinlock_t		lock;
+	struct completion	done;
+	unsigned long		clk_rate;
+	unsigned int		frequency;
+};
+
+static void aml_i2c_set_mask(struct aml_i2c *i2c, int reg, u32 mask, u32 val)
+{
+	u32 data;
+
+	data = readl(i2c->regs + reg);
+	data &= ~mask;
+	data |= val & mask;
+	writel(data, i2c->regs + reg);
+}
+
+/*
+ * SCL = clk/b_ratio. if b_ratio<=8, SCL = clk/8
+ */
+static int aml_i2c_set_clk_div(struct aml_i2c *i2c)
+{
+	unsigned long clk_rate = i2c->clk_rate;
+	unsigned int div;
+
+	div = DIV_ROUND_UP(clk_rate, i2c->frequency);
+
+	/* clock divider has 12 bits */
+	if (div >= (1 << 12)) {
+		dev_err(i2c->dev, "requested bus frequency too low\n");
+		return -EINVAL;
+	} else if (div < 8) {
+		dev_err(i2c->dev, "requested bus frequency too high\n");
+		return -EINVAL;
+	}
+	/* CFG_BUS reg:11 - 0 bits */
+	aml_i2c_set_mask(i2c, REG_CFG_BUS, BUS_RATIO_MASK, div);
+
+	return 0;
+}
+
+static void reset_fifo_pos(struct aml_i2c *i2c)
+{
+	writel(0x00, i2c->regs + REG_TX_RD_ADDR);
+	writel(0x00, i2c->regs + REG_TX_WR_ADDR);
+	writel(0x00, i2c->regs + REG_RX_WR_ADDR);
+	writel(0x00, i2c->regs + REG_RX_RD_ADDR);
+}
+
+static void clear_irq_status(struct aml_i2c *i2c, u32 irq_bits)
+{
+	writel(irq_bits, i2c->regs + REG_CFG_IRQ_STATE);
+}
+
+static int aml_i2c_init(struct aml_i2c *i2c)
+{
+	clear_irq_status(i2c, IRQ_ALL_MASK);
+	aml_i2c_set_mask(i2c, REG_CFG_BUS, BUS_NO_STOP, BUS_NO_STOP);
+	aml_i2c_set_mask(i2c, REG_CFG_I2C, I2C_RX_THR | I2C_TX_THR,
+			 (A9_I2C_FIFO_DEPTH << 16) | (A9_I2C_HALF_FIFO << 8));
+	reset_fifo_pos(i2c);
+
+	return aml_i2c_set_clk_div(i2c);
+}
+
+static void aml_i2c_prepare_xfer(struct aml_i2c *i2c, enum fifo_fill_mode mode)
+{
+	bool write = !(i2c->msg->flags & I2C_M_RD);
+	int i, count;
+
+	if (!write)
+		return;
+
+	count = min(i2c->msg->len - i2c->pos,
+		    mode == A9_FIFO_FILL_FULL ? A9_I2C_FIFO_DEPTH : A9_I2C_HALF_FIFO);
+
+	for (i = 0; i < count; i++)
+		writel(i2c->msg->buf[i2c->pos++], i2c->regs + REG_CFG_TX);
+}
+
+static irqreturn_t aml_i2c_irq(int irqno, void *dev_id)
+{
+	struct aml_i2c *i2c = dev_id;
+	u8 *buf = NULL;
+	u32 rd_len, i;
+	u32 rd_val;
+	u32 irq_state;
+
+	spin_lock(&i2c->lock);
+
+	irq_state = readl(i2c->regs + REG_CFG_IRQ_STATE);
+	if (i2c->state == A9_STATE_IDLE) {
+		dev_warn(i2c->dev, "i2c irq triggered abnormally, irq_state:0x%x,irq_en:0x%x\n",
+			 irq_state, readl(i2c->regs + REG_CFG_IRQ_ENABLE));
+		clear_irq_status(i2c, IRQ_ALL_MASK);
+		spin_unlock(&i2c->lock);
+		return IRQ_HANDLED;
+	}
+
+	if (irq_state & A9_TRANS_ERROR) {
+		i2c->error = -ENXIO;
+		goto complete_irq_out;
+	}
+
+	switch (i2c->state) {
+	case A9_STATE_READ:
+		buf = i2c->msg->buf;
+		rd_len = min(i2c->msg->len - i2c->pos, A9_I2C_FIFO_DEPTH);
+		for (i = 0; i < rd_len; i++) {
+			rd_val = readl(i2c->regs + REG_CFG_RX);
+			buf[i2c->pos++] = rd_val & TX_RX_DATA;
+		}
+		/* Rx must clear thresh after read fifo */
+		clear_irq_status(i2c, A9_RX_THRESH_READ);
+		break;
+	case A9_STATE_WRITE:
+		aml_i2c_prepare_xfer(i2c, A9_FIFO_FILL_HALF);
+		if (i2c->pos == i2c->msg->len)
+			aml_i2c_set_mask(i2c, REG_CFG_IRQ_ENABLE, A9_TX_THRESH_WRITE, 0);
+		/* Tx must clear thresh after write fifo */
+		clear_irq_status(i2c, A9_TX_THRESH_WRITE);
+		break;
+	default:
+		break;
+	}
+
+	if (!(irq_state & A9_TRANS_DONE) ||
+	    (i2c->state == A9_STATE_READ && i2c->pos < i2c->msg->len)) {
+		spin_unlock(&i2c->lock);
+		return IRQ_HANDLED;
+	}
+
+complete_irq_out:
+	i2c->state = A9_STATE_IDLE;
+	reset_fifo_pos(i2c);
+	aml_i2c_set_mask(i2c, REG_CFG_IRQ_ENABLE, A9_RX_THRESH_READ | A9_TX_THRESH_WRITE, 0);
+	clear_irq_status(i2c, IRQ_ALL_MASK);
+	spin_unlock(&i2c->lock);
+	complete(&i2c->done);
+
+	return IRQ_HANDLED;
+}
+
+static void aml_i2c_do_start(struct aml_i2c *i2c, struct i2c_msg *msg)
+{
+	unsigned int reg_val;
+	unsigned int trans_len;
+
+	trans_len = msg->len;
+	reg_val = (unsigned int)(((msg->addr & 0x7f) << START_SADDR_SHIFT) |
+				((msg->flags & I2C_M_RD) ? START_READ : 0) |
+				((trans_len & 0xfff) << START_LEN_SHIFT) | START_START);
+	aml_i2c_set_mask(i2c, REG_CFG_START,
+			 START_START | START_SLAVE_ADDR | START_READ | START_LEN, reg_val);
+	clear_irq_status(i2c, IRQ_ALL_MASK);
+	/* enable thresh mode */
+	if (trans_len > A9_I2C_FIFO_DEPTH) {
+		reg_val = (msg->flags & I2C_M_RD) ? A9_RX_THRESH_READ : A9_TX_THRESH_WRITE;
+		aml_i2c_set_mask(i2c, REG_CFG_IRQ_ENABLE,
+				 A9_RX_THRESH_READ | A9_TX_THRESH_WRITE, reg_val);
+	}
+}
+
+static int aml_i2c_xfer_msg(struct aml_i2c *i2c, struct i2c_msg *msg, bool last)
+{
+	unsigned long time_left, flags;
+
+	i2c->msg = msg;
+	i2c->pos = 0;
+	i2c->error = 0;
+
+	spin_lock_irqsave(&i2c->lock, flags);
+	i2c->state = (msg->flags & I2C_M_RD) ? A9_STATE_READ : A9_STATE_WRITE;
+	aml_i2c_prepare_xfer(i2c, A9_FIFO_FILL_FULL);
+	reinit_completion(&i2c->done);
+
+	aml_i2c_set_mask(i2c, REG_CFG_BUS, BUS_NO_STOP, (last ? 0 : BUS_NO_STOP));
+
+	/* Start the transfer */
+	aml_i2c_do_start(i2c, msg);
+	spin_unlock_irqrestore(&i2c->lock, flags);
+
+	time_left = msecs_to_jiffies(I2C_TIMEOUT_MS);
+	time_left = wait_for_completion_timeout(&i2c->done, time_left);
+
+	/*
+	 * Protect access to i2c struct and registers from interrupt
+	 * handlers triggered by a transfer terminated after the
+	 * timeout period
+	 */
+
+	if (!time_left) {
+		spin_lock_irqsave(&i2c->lock, flags);
+		i2c->state = A9_STATE_IDLE;
+		aml_i2c_set_mask(i2c, REG_CFG_IRQ_ENABLE,
+				 A9_RX_THRESH_READ | A9_TX_THRESH_WRITE, 0);
+		clear_irq_status(i2c, IRQ_ALL_MASK);
+		reset_fifo_pos(i2c);
+		spin_unlock_irqrestore(&i2c->lock, flags);
+		return -ETIMEDOUT;
+	}
+
+	return i2c->error;
+}
+
+static int aml_i2c_xfer(struct i2c_adapter *adap, struct i2c_msg *msgs, int num)
+{
+	struct aml_i2c *i2c = adap->algo_data;
+	int i, ret = 0;
+
+	for (i = 0; i < num; i++) {
+		ret = aml_i2c_xfer_msg(i2c, msgs + i, i == num - 1);
+		if (ret)
+			return ret;
+	}
+
+	return i;
+}
+
+static u32 aml_i2c_func(struct i2c_adapter *adap)
+{
+	return I2C_FUNC_I2C | (I2C_FUNC_SMBUS_EMUL & ~I2C_FUNC_SMBUS_QUICK);
+}
+
+static const struct i2c_adapter_quirks aml_i2c_quirks = {
+	.max_read_len = A9_I2C_MAX_XFER_SIZE,
+	.max_write_len = A9_I2C_MAX_XFER_SIZE,
+	.flags = I2C_AQ_NO_ZERO_LEN,
+};
+
+static const struct i2c_algorithm aml_i2c_algorithm = {
+	.xfer	= aml_i2c_xfer,
+	.functionality	= aml_i2c_func,
+};
+
+static int aml_i2c_probe(struct platform_device *pdev)
+{
+	struct device_node *np = pdev->dev.of_node;
+	struct aml_i2c *i2c;
+	struct i2c_timings timings;
+	int irq, ret;
+
+	i2c = devm_kzalloc(&pdev->dev, sizeof(struct aml_i2c), GFP_KERNEL);
+	if (!i2c)
+		return -ENOMEM;
+
+	i2c_parse_fw_timings(&pdev->dev, &timings, true);
+	i2c->frequency = timings.bus_freq_hz;
+
+	i2c->dev = &pdev->dev;
+	platform_set_drvdata(pdev, i2c);
+
+	spin_lock_init(&i2c->lock);
+	init_completion(&i2c->done);
+
+	i2c->regs  = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(i2c->regs))
+		return PTR_ERR(i2c->regs);
+
+	i2c->clk = devm_clk_get_enabled(&pdev->dev, NULL);
+	if (IS_ERR(i2c->clk))
+		return dev_err_probe(&pdev->dev, PTR_ERR(i2c->clk), "can't get enable clock\n");
+
+	i2c->clk_rate = clk_get_rate(i2c->clk);
+	if (i2c->clk_rate == 0)
+		return dev_err_probe(&pdev->dev, -EINVAL, "failed to get clk rate\n");
+
+	ret = aml_i2c_init(i2c);
+	if (ret < 0)
+		return dev_err_probe(&pdev->dev, ret, "fail init i2c\n");
+
+	irq = platform_get_irq(pdev, 0);
+	if (irq < 0)
+		return dev_err_probe(&pdev->dev, irq, "can't find IRQ\n");
+
+	ret = devm_request_irq(&pdev->dev, irq, aml_i2c_irq, 0, dev_name(&pdev->dev), i2c);
+	if (ret < 0)
+		return dev_err_probe(&pdev->dev, ret, "can't request IRQ\n");
+	/* Enable error & done irq */
+	writel(A9_ENABLE_IRQ_BIT, i2c->regs + REG_CFG_IRQ_ENABLE);
+	strscpy(i2c->adap.name, "Amlogic I2C adapter",
+		sizeof(i2c->adap.name));
+	i2c->adap.owner = THIS_MODULE;
+	i2c->adap.algo = &aml_i2c_algorithm;
+	i2c->adap.quirks = &aml_i2c_quirks;
+	i2c->adap.dev.parent = &pdev->dev;
+	i2c->adap.dev.of_node = np;
+	i2c->adap.algo_data = i2c;
+
+	return i2c_add_adapter(&i2c->adap);
+}
+
+static void aml_i2c_remove(struct platform_device *pdev)
+{
+	struct aml_i2c *i2c = platform_get_drvdata(pdev);
+
+	i2c_del_adapter(&i2c->adap);
+}
+
+static const struct of_device_id aml_i2c_match[] = {
+	{	.compatible = "amlogic,a9-i2c",},
+	{ }
+};
+
+MODULE_DEVICE_TABLE(of, aml_i2c_match);
+
+static struct platform_driver aml_i2c_driver = {
+	.probe   = aml_i2c_probe,
+	.remove  = aml_i2c_remove,
+	.driver  = {
+		.name  = "amlogic-i2c",
+		.of_match_table = aml_i2c_match,
+	},
+};
+
+module_platform_driver(aml_i2c_driver);
+
+MODULE_DESCRIPTION("Amlogic I2C Bus driver");
+MODULE_AUTHOR("Junyi Zhao <junyi.zhao@amlogic.com>");
+MODULE_LICENSE("GPL");

-- 
2.52.0

