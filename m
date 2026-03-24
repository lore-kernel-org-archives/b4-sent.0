From: Vasiliy Doylov <nekocwd@mainlining.org>
Date: Wed, 25 Mar 2026 01:15:00 +0300
Subject: [PATCH v4 2/3] media: i2c: Add driver for LC898217XC VCM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-media-i2c-lc898217xc-initial-driver-v4-2-6ad6fd74915e@mainlining.org>
References: <20260325-media-i2c-lc898217xc-initial-driver-v4-0-6ad6fd74915e@mainlining.org>
In-Reply-To: <20260325-media-i2c-lc898217xc-initial-driver-v4-0-6ad6fd74915e@mainlining.org>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, david@ixit.cz
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Antonio Rische <nt8r@protonmail.com>, 
 Vasiliy Doylov <nekocwd@mainlining.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=10078;
 i=nekocwd@mainlining.org; h=from:subject:message-id;
 bh=TSF2fdmC50QumBOtoiKQxyVKKAuDxiAUNa62Jot5f/4=;
 b=owGbwMvMwCVmXFbadLHr1XTG02pJDJmHeZ44J+64XP5v2olDy+eYvhKfr8bDY5znbF311zQzu
 TSAa+XvjlIWBjEuBlkxRZbu94fvPZjHy1qq/okXZg4rE8gQBi5OAZjI8R0M/5TZNWeHLl5+Vndj
 2gUDL07N+ivmL46LmioFctnsuH266RzDf9+f06Se7TaViz95vWT1P9+fhX8j/7LxvzkR2Ryy4sv
 imTwA
X-Developer-Key: i=nekocwd@mainlining.org; a=openpgp;
 fpr=8BEFC3DEE09E0D057527F20D33767582D18AEA97
X-Endpoint-Received: by B4 Relay for nekocwd@mainlining.org/default with auth_id=692
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

LC898217XC is a 11 bit DAC, designed for linear control
of voice coil motor. This driver creates a V4L2 subdevice
and provides control to set the desired focus.

Tested on Oneplus 6 (oneplus-enchilada)

Signed-off-by: Vasiliy Doylov <nekocwd@mainlining.org>
---
 drivers/media/i2c/Kconfig      |   9 ++
 drivers/media/i2c/Makefile     |   1 +
 drivers/media/i2c/lc898217xc.c | 289 +++++++++++++++++++++++++++++++++++++++++
 3 files changed, 299 insertions(+)

diff --git a/drivers/media/i2c/Kconfig b/drivers/media/i2c/Kconfig
index 20482be35f26..c0b52f007802 100644
--- a/drivers/media/i2c/Kconfig
+++ b/drivers/media/i2c/Kconfig
@@ -901,6 +901,15 @@ config VIDEO_DW9807_VCM
 	  capability. This is designed for linear control of
 	  voice coil motors, controlled via I2C serial interface.
 
+config VIDEO_LC898217XC
+	tristate "LC898217XC lens voice coil support"
+	select V4L2_CCI_I2C
+	help
+	  This is a driver for the LC898217XC camera lens voice coil.
+	  LC898217XC is a 11 bit DAC with 110mA output current sink
+	  capability. This is designed for linear control of
+	  voice coil motors, controlled via I2C serial interface.
+
 endif
 
 menu "Flash devices"
diff --git a/drivers/media/i2c/Makefile b/drivers/media/i2c/Makefile
index a3a6396df3c4..7da1a5cc092e 100644
--- a/drivers/media/i2c/Makefile
+++ b/drivers/media/i2c/Makefile
@@ -64,6 +64,7 @@ obj-$(CONFIG_VIDEO_IMX415) += imx415.o
 obj-$(CONFIG_VIDEO_IR_I2C) += ir-kbd-i2c.o
 obj-$(CONFIG_VIDEO_ISL7998X) += isl7998x.o
 obj-$(CONFIG_VIDEO_KS0127) += ks0127.o
+obj-$(CONFIG_VIDEO_LC898217XC) += lc898217xc.o
 obj-$(CONFIG_VIDEO_LM3560) += lm3560.o
 obj-$(CONFIG_VIDEO_LM3646) += lm3646.o
 obj-$(CONFIG_VIDEO_LT6911UXE) += lt6911uxe.o
diff --git a/drivers/media/i2c/lc898217xc.c b/drivers/media/i2c/lc898217xc.c
new file mode 100644
index 000000000000..cfac7e7ce3d6
--- /dev/null
+++ b/drivers/media/i2c/lc898217xc.c
@@ -0,0 +1,289 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+// Copyright (c) 2025 Vasiliy Doylov <nekocwd@mainlining.org>
+
+#include <linux/delay.h>
+#include <linux/i2c.h>
+#include <linux/module.h>
+#include <linux/pm_runtime.h>
+#include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
+#include <media/v4l2-async.h>
+#include <media/v4l2-cci.h>
+#include <media/v4l2-ctrls.h>
+#include <media/v4l2-device.h>
+#include <media/v4l2-fwnode.h>
+#include <media/v4l2-subdev.h>
+#include <media/v4l2-event.h>
+
+#define LC898217XC_NAME "lc898217xc"
+/* Actuator has 11 bit resolution */
+#define LC898217XC_MAX_FOCUS_POS (2048 - 1)
+#define LC898217XC_MIN_FOCUS_POS 0
+#define LC898217XC_FOCUS_STEPS 1
+#define LC898217XC_DAC_ADDR CCI_REG16(0x84)
+
+static const char *const lc898217xc_supply_names[] = {
+	"vdd",
+	"vana",
+};
+
+struct lc898217xc {
+	struct regulator_bulk_data supplies[ARRAY_SIZE(lc898217xc_supply_names)];
+	struct v4l2_ctrl_handler ctrls;
+	struct v4l2_subdev sd;
+	struct regmap *regmap;
+};
+
+static inline struct lc898217xc *sd_to_lc898217xc(struct v4l2_subdev *subdev)
+{
+	return container_of(subdev, struct lc898217xc, sd);
+}
+
+static int lc898217xc_set_dac(struct lc898217xc *lc898217xc, u16 val)
+{
+	struct i2c_client *client = v4l2_get_subdevdata(&lc898217xc->sd);
+	int ret;
+
+	ret = cci_write(lc898217xc->regmap, LC898217XC_DAC_ADDR, val, NULL);
+	if (ret)
+		dev_err(&client->dev, "failed to set DAC: %d\n", ret);
+
+	return ret;
+}
+
+static int lc898217xc_power_on(struct lc898217xc *lc898217xc)
+{
+	int ret;
+
+	ret = regulator_bulk_enable(ARRAY_SIZE(lc898217xc_supply_names),
+				    lc898217xc->supplies);
+	if (ret < 0)
+		return ret;
+
+	usleep_range(8000, 10000);
+	return 0;
+}
+
+static int lc898217xc_power_off(struct lc898217xc *lc898217xc)
+{
+	regulator_bulk_disable(ARRAY_SIZE(lc898217xc_supply_names),
+			       lc898217xc->supplies);
+	return 0;
+}
+
+static int __maybe_unused lc898217xc_runtime_suspend(struct device *dev)
+{
+	struct v4l2_subdev *sd = dev_get_drvdata(dev);
+	struct lc898217xc *lc898217xc = sd_to_lc898217xc(sd);
+
+	lc898217xc_power_off(lc898217xc);
+	return 0;
+}
+
+static int __maybe_unused lc898217xc_runtime_resume(struct device *dev)
+{
+	struct v4l2_subdev *sd = dev_get_drvdata(dev);
+	struct lc898217xc *lc898217xc = sd_to_lc898217xc(sd);
+	int ret;
+
+	ret = lc898217xc_power_on(lc898217xc);
+	if (ret < 0) {
+		dev_err(dev, "failed to enable regulators\n");
+		return ret;
+	}
+
+	__v4l2_ctrl_handler_setup(&lc898217xc->ctrls);
+
+	return ret;
+}
+
+static int lc898217xc_set_ctrl(struct v4l2_ctrl *ctrl)
+{
+	struct lc898217xc *lc898217xc = container_of(ctrl->handler,
+						     struct lc898217xc, ctrls);
+
+	if (ctrl->id == V4L2_CID_FOCUS_ABSOLUTE)
+		return lc898217xc_set_dac(lc898217xc, ctrl->val);
+
+	return 0;
+}
+
+static const struct v4l2_ctrl_ops lc898217xc_ctrl_ops = {
+	.s_ctrl = lc898217xc_set_ctrl,
+};
+
+static int lc898217xc_open(struct v4l2_subdev *sd, struct v4l2_subdev_fh *fh)
+{
+	return pm_runtime_resume_and_get(sd->dev);
+}
+
+static int lc898217xc_close(struct v4l2_subdev *sd, struct v4l2_subdev_fh *fh)
+{
+	pm_runtime_put_autosuspend(sd->dev);
+
+	return 0;
+}
+
+static const struct v4l2_subdev_internal_ops lc898217xc_int_ops = {
+	.open = lc898217xc_open,
+	.close = lc898217xc_close,
+};
+
+static const struct v4l2_subdev_core_ops lc898217xc_core_ops = {
+	.log_status = v4l2_ctrl_subdev_log_status,
+};
+
+static const struct v4l2_subdev_ops lc898217xc_ops = {
+	.core = &lc898217xc_core_ops,
+};
+
+static int lc898217xc_init_controls(struct lc898217xc *lc898217xc)
+{
+	struct v4l2_ctrl_handler *hdl = &lc898217xc->ctrls;
+	const struct v4l2_ctrl_ops *ops = &lc898217xc_ctrl_ops;
+
+	v4l2_ctrl_handler_init(hdl, 1);
+
+	v4l2_ctrl_new_std(hdl, ops, V4L2_CID_FOCUS_ABSOLUTE,
+			  LC898217XC_MIN_FOCUS_POS,
+			  LC898217XC_MAX_FOCUS_POS,
+			  LC898217XC_FOCUS_STEPS, 0);
+
+	if (hdl->error)
+		return hdl->error;
+
+	lc898217xc->sd.ctrl_handler = hdl;
+
+	return 0;
+}
+
+static int lc898217xc_probe(struct i2c_client *client)
+{
+	struct device *dev = &client->dev;
+	struct lc898217xc *lc898217xc;
+	unsigned int i;
+	int ret;
+
+	lc898217xc = devm_kzalloc(dev, sizeof(*lc898217xc), GFP_KERNEL);
+	if (!lc898217xc)
+		return -ENOMEM;
+
+	lc898217xc->regmap = devm_cci_regmap_init_i2c(client, 8);
+	if (IS_ERR(lc898217xc->regmap))
+		return dev_err_probe(dev, PTR_ERR(lc898217xc->regmap),
+				     "failed to initialize CCI\n");
+
+	/* Initialize subdev */
+	v4l2_i2c_subdev_init(&lc898217xc->sd, client, &lc898217xc_ops);
+
+	for (i = 0; i < ARRAY_SIZE(lc898217xc_supply_names); i++)
+		lc898217xc->supplies[i].supply = lc898217xc_supply_names[i];
+
+	ret = devm_regulator_bulk_get(dev, ARRAY_SIZE(lc898217xc_supply_names),
+				      lc898217xc->supplies);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to get regulators\n");
+
+	ret = lc898217xc_power_on(lc898217xc);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to enable regulators\n");
+
+	ret = lc898217xc_init_controls(lc898217xc);
+	if (ret) {
+		dev_err_probe(dev, ret, "failed to init v4l2 controls\n");
+		goto err_power_off;
+	}
+
+	/* Initialize subdev */
+	lc898217xc->sd.flags |= V4L2_SUBDEV_FL_HAS_DEVNODE;
+	lc898217xc->sd.internal_ops = &lc898217xc_int_ops;
+
+	ret = media_entity_pads_init(&lc898217xc->sd.entity, 0, NULL);
+	if (ret < 0) {
+		dev_err_probe(dev, ret, "failed to init media entity pads");
+		goto err_free_handler;
+	}
+
+	lc898217xc->sd.entity.function = MEDIA_ENT_F_LENS;
+
+	/*
+	 * Enable runtime PM. As the device has been powered manually, mark it
+	 * as active, and increase the usage count without resuming the device.
+	 */
+	pm_runtime_set_active(dev);
+	pm_runtime_get_noresume(dev);
+	pm_runtime_enable(dev);
+
+	ret = v4l2_async_register_subdev(&lc898217xc->sd);
+	if (ret < 0) {
+		dev_err_probe(dev, ret, "failed to register V4L2 subdev\n");
+		goto err_pm;
+	}
+
+	/*
+	 * Finally, enable autosuspend and decrease the usage count. The device
+	 * will get suspended after the autosuspend delay, turning the power
+	 * off.
+	 */
+	pm_runtime_set_autosuspend_delay(dev, 1000);
+	pm_runtime_use_autosuspend(dev);
+	pm_runtime_put_autosuspend(dev);
+
+	return 0;
+
+err_pm:
+	pm_runtime_disable(dev);
+	pm_runtime_put_noidle(dev);
+	media_entity_cleanup(&lc898217xc->sd.entity);
+err_free_handler:
+	v4l2_ctrl_handler_free(&lc898217xc->ctrls);
+err_power_off:
+	lc898217xc_power_off(lc898217xc);
+	return ret;
+}
+
+static void lc898217xc_remove(struct i2c_client *client)
+{
+	struct v4l2_subdev *sd = i2c_get_clientdata(client);
+	struct lc898217xc *lc898217xc = sd_to_lc898217xc(sd);
+	struct device *dev = &client->dev;
+
+	v4l2_async_unregister_subdev(&lc898217xc->sd);
+	v4l2_ctrl_handler_free(&lc898217xc->ctrls);
+	media_entity_cleanup(&lc898217xc->sd.entity);
+
+	/*
+	 * Disable runtime PM. In case runtime PM is disabled in the kernel,
+	 * make sure to turn power off manually.
+	 */
+	pm_runtime_disable(dev);
+	if (!pm_runtime_status_suspended(dev))
+		lc898217xc_power_off(lc898217xc);
+	pm_runtime_set_suspended(dev);
+}
+
+static const struct of_device_id lc898217xc_of_table[] = {
+	{ .compatible = "onnn,lc898217xc" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, lc898217xc_of_table);
+
+static const struct dev_pm_ops lc898217xc_pm_ops = {
+	SET_RUNTIME_PM_OPS(lc898217xc_runtime_suspend,
+			   lc898217xc_runtime_resume, NULL)
+};
+
+static struct i2c_driver lc898217xc_i2c_driver = {
+	.driver = {
+		.name = LC898217XC_NAME,
+		.pm = &lc898217xc_pm_ops,
+		.of_match_table = lc898217xc_of_table,
+	},
+	.probe = lc898217xc_probe,
+	.remove = lc898217xc_remove,
+};
+module_i2c_driver(lc898217xc_i2c_driver);
+
+MODULE_AUTHOR("Vasiliy Doylov <nekocwd@mainlining.org>");
+MODULE_DESCRIPTION("Onsemi LC898217XC VCM driver");
+MODULE_LICENSE("GPL");

-- 
2.50.1

