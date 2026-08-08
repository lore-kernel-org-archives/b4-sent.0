From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Sat, 08 Aug 2026 22:28:13 +0530
Subject: [PATCH v5 1/4] iio: accel: mma8452: convert to bulk regulator
 usage
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-1-d177e93ce3f8@gmail.com>
References: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-0-d177e93ce3f8@gmail.com>
In-Reply-To: <20260808-15-apr-pm-iio-mma8452-v4-temp-v5-0-d177e93ce3f8@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786208304; l=5696;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=msc6kn8HwdwOjnZXXGBlOINiVjEatD5na+kGlio23Jk=;
 b=flE64OqSBpLo8l8ux06XgdPSFkdD8PQ+YYa+Uagrp45wQ3vbRX+ARyt6+s8rIOvMK1LrbhSew
 7pxmnkcuem3DBijQWV/6xehxkVIzFL1RTOxrvTSB9RQdxrynuDVqdC8
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The "vdd" and "vddio" regulators are always controlled together. Switch
to the regulator bulk API to handle setup, enable, and disable paths in
a single call.

No functional change intended.

Suggested-by: Jonathan Cameron <Jonathan.Cameron@huawei.com>
Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
---
changes in v4:
- added explicit header with input from Joshua Crofts
- validate new member of structure with `pahole` and `bloat-o-meter`
  comment from Andy
  ./scripts/bloat-o-meter mma8452-before.o mma8452-after.o
  add/remove: 0/0 grow/shrink: 0/6 up/down: 0/-1013 (-1013)
  Function                                     old     new   delta
  _entry_ptr                                    72      56     -16
  _entry                                       396     308     -88
  mma8452_remove                               646     548     -98
  mma8452_runtime_suspend                      633     467    -166
  mma8452_runtime_resume                       939     639    -300
  mma8452_probe                               4247    3902    -345
  Total: Before=36561, After=35548, chg -2.77%

  pahole before:
    /* size: 288, cachelines: 5, members: 10 */
    /* sum members: 278, holes: 2, sum holes: 10 */

  pahole after:
    /* size: 320, cachelines: 5, members: 9 */
    /* sum members: 310, holes: 2, sum holes: 10 */
  summary: overall size of driver is optimized and all new member are in same cacheline
- v3 link -> https://lore.kernel.org/all/20260505174640.3998281-7-sanjayembedded@gmail.com/
---
 drivers/iio/accel/mma8452.c | 60 ++++++++++++---------------------------------
 1 file changed, 16 insertions(+), 44 deletions(-)

diff --git a/drivers/iio/accel/mma8452.c b/drivers/iio/accel/mma8452.c
index 7d683686dd9d..772463d5ff47 100644
--- a/drivers/iio/accel/mma8452.c
+++ b/drivers/iio/accel/mma8452.c
@@ -18,6 +18,7 @@
  * TODO: orientation events
  */
 
+#include <linux/array_size.h>
 #include <linux/delay.h>
 #include <linux/i2c.h>
 #include <linux/module.h>
@@ -110,8 +111,7 @@ struct mma8452_data {
 	u8 data_cfg;
 	const struct mma_chip_info *chip_info;
 	int sleep_val;
-	struct regulator *vdd_reg;
-	struct regulator *vddio_reg;
+	struct regulator_bulk_data regs[2];
 
 	/* Ensure correct alignment of time stamp when present */
 	struct {
@@ -1569,25 +1569,15 @@ static int mma8452_probe(struct i2c_client *client)
 	if (ret)
 		return ret;
 
-	data->vdd_reg = devm_regulator_get(&client->dev, "vdd");
-	if (IS_ERR(data->vdd_reg))
-		return dev_err_probe(&client->dev, PTR_ERR(data->vdd_reg),
-				     "failed to get VDD regulator!\n");
-
-	data->vddio_reg = devm_regulator_get(&client->dev, "vddio");
-	if (IS_ERR(data->vddio_reg))
-		return dev_err_probe(&client->dev, PTR_ERR(data->vddio_reg),
-				     "failed to get VDDIO regulator!\n");
-
-	ret = regulator_enable(data->vdd_reg);
+	data->regs[0].supply = "vdd";
+	data->regs[1].supply = "vddio";
+	ret = devm_regulator_bulk_get(dev, ARRAY_SIZE(data->regs), data->regs);
 	if (ret)
-		return dev_err_probe(dev, ret, "failed to enable VDD regulator!\n");
+		return dev_err_probe(dev, ret, "failed to get regulators\n");
 
-	ret = regulator_enable(data->vddio_reg);
-	if (ret) {
-		dev_err_probe(dev, ret, "failed to enable VDDIO regulator!\n");
-		goto disable_regulator_vdd;
-	}
+	ret = regulator_bulk_enable(ARRAY_SIZE(data->regs), data->regs);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to enable regulators\n");
 
 	ret = i2c_smbus_read_byte_data(client, MMA8452_WHO_AM_I);
 	if (ret < 0)
@@ -1722,10 +1712,7 @@ static int mma8452_probe(struct i2c_client *client)
 	mma8452_trigger_cleanup(indio_dev);
 
 disable_regulators:
-	regulator_disable(data->vddio_reg);
-
-disable_regulator_vdd:
-	regulator_disable(data->vdd_reg);
+	regulator_bulk_disable(ARRAY_SIZE(data->regs), data->regs);
 
 	return ret;
 }
@@ -1747,8 +1734,7 @@ static void mma8452_remove(struct i2c_client *client)
 	mma8452_trigger_cleanup(indio_dev);
 	mma8452_standby(iio_priv(indio_dev));
 
-	regulator_disable(data->vddio_reg);
-	regulator_disable(data->vdd_reg);
+	regulator_bulk_disable(ARRAY_SIZE(data->regs), data->regs);
 }
 
 #ifdef CONFIG_PM
@@ -1766,15 +1752,9 @@ static int mma8452_runtime_suspend(struct device *dev)
 		return -EAGAIN;
 	}
 
-	ret = regulator_disable(data->vddio_reg);
-	if (ret) {
-		dev_err(dev, "failed to disable VDDIO regulator\n");
-		return ret;
-	}
-
-	ret = regulator_disable(data->vdd_reg);
+	ret = regulator_bulk_disable(ARRAY_SIZE(data->regs), data->regs);
 	if (ret) {
-		dev_err(dev, "failed to disable VDD regulator\n");
+		dev_err(dev, "failed to disable regulators\n");
 		return ret;
 	}
 
@@ -1787,16 +1767,9 @@ static int mma8452_runtime_resume(struct device *dev)
 	struct mma8452_data *data = iio_priv(indio_dev);
 	int ret, sleep_val;
 
-	ret = regulator_enable(data->vdd_reg);
-	if (ret) {
-		dev_err(dev, "failed to enable VDD regulator\n");
-		return ret;
-	}
-
-	ret = regulator_enable(data->vddio_reg);
+	ret = regulator_bulk_enable(ARRAY_SIZE(data->regs), data->regs);
 	if (ret) {
-		dev_err(dev, "failed to enable VDDIO regulator\n");
-		regulator_disable(data->vdd_reg);
+		dev_err(dev, "failed to enable regulators\n");
 		return ret;
 	}
 
@@ -1814,8 +1787,7 @@ static int mma8452_runtime_resume(struct device *dev)
 	return 0;
 
 runtime_resume_failed:
-	regulator_disable(data->vddio_reg);
-	regulator_disable(data->vdd_reg);
+	regulator_bulk_disable(ARRAY_SIZE(data->regs), data->regs);
 
 	return ret;
 }

-- 
2.34.1

