From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 20 Feb 2025 21:52:07 +0100
Subject: [PATCH 2/2] iio: imu: inv_icm42600: add wakeup functionality for
 Wake-on-Motion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250220-losd-3-inv-icm42600-add-wom-support-v1-2-9b937f986954@tdk.com>
References: <20250220-losd-3-inv-icm42600-add-wom-support-v1-0-9b937f986954@tdk.com>
In-Reply-To: <20250220-losd-3-inv-icm42600-add-wom-support-v1-0-9b937f986954@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740084731; l=6425;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=8Io0EZ7K8Wv02WRA2dEENs6nrBC8x2QlcG1u9PLvBfA=;
 b=opslEaIOiZYxTBdkrE9ZX8xumphDLqQK/S5q28KGiWwSiCKOmeyNFh7mrLX5WvGz6cMIxwtm9
 vqfww5O9bRzAA/0W3J1wG0/J/H+Ry5kTWK0IccG78C7Zi+0hpVtfNyQ
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When Wake-on-Motion is on, enable system wakeup and keep chip on for
waking up system with interrupt.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600.h       |  2 +
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c |  3 +
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c  | 89 +++++++++++++++--------
 3 files changed, 63 insertions(+), 31 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600.h b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
index 8dfbeaf1c768d7d25cb58ecf9804446f3cbbd465..baf1dcd714800e84ccd21dc1d1e486849c77a9ae 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
@@ -151,6 +151,7 @@ struct inv_icm42600_apex {
  *  @map:		regmap pointer.
  *  @vdd_supply:	VDD voltage regulator for the chip.
  *  @vddio_supply:	I/O voltage regulator for the chip.
+ *  @irq:		chip irq.
  *  @orientation:	sensor chip orientation relative to main hardware.
  *  @conf:		chip sensors configurations.
  *  @suspended:		suspended sensors configuration.
@@ -168,6 +169,7 @@ struct inv_icm42600_state {
 	struct regmap *map;
 	struct regulator *vdd_supply;
 	struct regulator *vddio_supply;
+	int irq;
 	struct iio_mount_matrix orientation;
 	struct inv_icm42600_conf conf;
 	struct inv_icm42600_suspended suspended;
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
index 8ce2276b3edc61cc1ea26810198dd0057054ec48..4240e8c576f4d07af5434e9a91dfda532f87ffb9 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
@@ -1149,6 +1149,9 @@ struct iio_dev *inv_icm42600_accel_init(struct inv_icm42600_state *st)
 	if (ret)
 		return ERR_PTR(ret);
 
+	/* accel events are wakeup capable */
+	device_set_wakeup_capable(&indio_dev->dev, true);
+
 	return indio_dev;
 }
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
index c0fd2770d66f02d1965fa07f819fd2db9a1d6bd2..f94bda5dc094d6cc85e3facbd480b830bfbaa3f9 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
@@ -751,6 +751,7 @@ int inv_icm42600_core_probe(struct regmap *regmap, int chip, int irq,
 	mutex_init(&st->lock);
 	st->chip = chip;
 	st->map = regmap;
+	st->irq = irq;
 
 	ret = iio_read_mount_matrix(dev, &st->orientation);
 	if (ret) {
@@ -829,44 +830,56 @@ EXPORT_SYMBOL_NS_GPL(inv_icm42600_core_probe, "IIO_ICM42600");
 static int inv_icm42600_suspend(struct device *dev)
 {
 	struct inv_icm42600_state *st = dev_get_drvdata(dev);
+	struct device *accel_dev;
+	bool wakeup;
+	int accel_conf;
 	int ret;
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
 
 	st->suspended.gyro = st->conf.gyro.mode;
 	st->suspended.accel = st->conf.accel.mode;
 	st->suspended.temp = st->conf.temp_en;
-	if (pm_runtime_suspended(dev)) {
-		ret = 0;
-		goto out_unlock;
-	}
+	if (pm_runtime_suspended(dev))
+		return 0;
 
 	/* disable FIFO data streaming */
 	if (st->fifo.on) {
 		ret = regmap_write(st->map, INV_ICM42600_REG_FIFO_CONFIG,
 				   INV_ICM42600_FIFO_CONFIG_BYPASS);
 		if (ret)
-			goto out_unlock;
+			return ret;
 	}
 
-	/* disable APEX features */
-	if (st->apex.wom.enable) {
-		ret = inv_icm42600_set_wom(st, false);
-		if (ret)
-			goto out_unlock;
+	/* keep chip on and wake-up capable if APEX and wakeup on */
+	accel_dev = &st->indio_accel->dev;
+	wakeup = (st->apex.on && device_may_wakeup(accel_dev)) ? true : false;
+
+	if (!wakeup) {
+		/* disable APEX features and accel if wakeup disabled */
+		if (st->apex.wom.enable) {
+			ret = inv_icm42600_set_wom(st, false);
+			if (ret)
+				return ret;
+		}
+		accel_conf = INV_ICM42600_SENSOR_MODE_OFF;
+	} else {
+		/* keep accel on and setup irq for wakeup */
+		accel_conf = st->conf.accel.mode;
+		enable_irq_wake(st->irq);
+		disable_irq(st->irq);
 	}
 
 	ret = inv_icm42600_set_pwr_mgmt0(st, INV_ICM42600_SENSOR_MODE_OFF,
-					 INV_ICM42600_SENSOR_MODE_OFF, false,
-					 NULL);
+					 accel_conf, false, NULL);
 	if (ret)
-		goto out_unlock;
+		return ret;
 
-	regulator_disable(st->vddio_supply);
+	/* disable vddio regulator if chip is sleeping */
+	if (!wakeup)
+		regulator_disable(st->vddio_supply);
 
-out_unlock:
-	mutex_unlock(&st->lock);
-	return ret;
+	return 0;
 }
 
 /*
@@ -878,13 +891,25 @@ static int inv_icm42600_resume(struct device *dev)
 	struct inv_icm42600_state *st = dev_get_drvdata(dev);
 	struct inv_icm42600_sensor_state *gyro_st = iio_priv(st->indio_gyro);
 	struct inv_icm42600_sensor_state *accel_st = iio_priv(st->indio_accel);
+	struct device *accel_dev;
+	bool wakeup;
 	int ret;
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
 
-	ret = inv_icm42600_enable_regulator_vddio(st);
-	if (ret)
-		goto out_unlock;
+	/* check wakeup capability */
+	accel_dev = &st->indio_accel->dev;
+	wakeup = (st->apex.on && device_may_wakeup(accel_dev)) ? true : false;
+
+	/* restore vddio if cut off or irq state */
+	if (!wakeup) {
+		ret = inv_icm42600_enable_regulator_vddio(st);
+		if (ret)
+			return ret;
+	} else {
+		enable_irq(st->irq);
+		disable_irq_wake(st->irq);
+	}
 
 	pm_runtime_disable(dev);
 	pm_runtime_set_active(dev);
@@ -895,13 +920,15 @@ static int inv_icm42600_resume(struct device *dev)
 					 st->suspended.accel,
 					 st->suspended.temp, NULL);
 	if (ret)
-		goto out_unlock;
+		return ret;
 
-	/* restore APEX features */
-	if (st->apex.wom.enable) {
-		ret = inv_icm42600_set_wom(st, true);
-		if (ret)
-			goto out_unlock;
+	/* restore APEX features if disabled */
+	if (!wakeup) {
+		if (st->apex.wom.enable) {
+			ret = inv_icm42600_set_wom(st, true);
+			if (ret)
+				return ret;
+		}
 	}
 
 	/* restore FIFO data streaming */
@@ -910,11 +937,11 @@ static int inv_icm42600_resume(struct device *dev)
 		inv_sensors_timestamp_reset(&accel_st->ts);
 		ret = regmap_write(st->map, INV_ICM42600_REG_FIFO_CONFIG,
 				   INV_ICM42600_FIFO_CONFIG_STREAM);
+		if (ret)
+			return ret;
 	}
 
-out_unlock:
-	mutex_unlock(&st->lock);
-	return ret;
+	return 0;
 }
 
 /* Runtime suspend will turn off sensors that are enabled by iio devices. */

-- 
2.48.1

