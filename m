From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Tue, 15 Apr 2025 16:47:32 +0200
Subject: [PATCH v2 2/2] iio: imu: inv_icm42600: add wakeup functionality
 for Wake-on-Motion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250415-losd-3-inv-icm42600-add-wom-support-v2-2-de94dfb92b7e@tdk.com>
References: <20250415-losd-3-inv-icm42600-add-wom-support-v2-0-de94dfb92b7e@tdk.com>
In-Reply-To: <20250415-losd-3-inv-icm42600-add-wom-support-v2-0-de94dfb92b7e@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744728454; l=5749;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=CuFRYaRZxPuw+fgDSMa7IYo+bKSh1dwxzccbZhiX9sA=;
 b=vbuV00uOU5VTIzGu9D4r3pMAh4mKVxn8sBkrGlWTDOc5qrgJHSGLTivgyBPW++UvzimZdDFVi
 BNoL2+3nGkKB9e0sKWYFKS+GCYCAYTnFFr/9S7F9qOsLuUGYZyIb8ec
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When Wake-on-Motion is on, enable system wakeup and keep chip on for
waking up system with interrupt.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600.h       |  2 +
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c |  3 ++
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c  | 65 +++++++++++++++++------
 3 files changed, 54 insertions(+), 16 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600.h b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
index f5adebe4640fc36c5dc9810b515369d4909ba834..768d773a9129c5d64f0af1959504889ffbc9c131 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
@@ -151,6 +151,7 @@ struct inv_icm42600_apex {
  *  @map:		regmap pointer.
  *  @vdd_supply:	VDD voltage regulator for the chip.
  *  @vddio_supply:	I/O voltage regulator for the chip.
+ *  @irq:		chip irq, required to enable/disable and set wakeup
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
index 94515166c1fcdf6cc7ba4843334f51cb14696eba..2249f551f10f3211dadde2f6aa1dccd9b704f146 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c
@@ -1162,6 +1162,9 @@ struct iio_dev *inv_icm42600_accel_init(struct inv_icm42600_state *st)
 	if (ret)
 		return ERR_PTR(ret);
 
+	/* accel events are wakeup capable */
+	device_set_wakeup_capable(&indio_dev->dev, true);
+
 	return indio_dev;
 }
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
index 9a2150ab9e874f17d7fda731cb131c3f688a75a3..14b64d14a6241ec60c23b64486a615a84513ae3c 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
@@ -765,6 +765,7 @@ int inv_icm42600_core_probe(struct regmap *regmap, int chip,
 	mutex_init(&st->lock);
 	st->chip = chip;
 	st->map = regmap;
+	st->irq = irq;
 
 	ret = iio_read_mount_matrix(dev, &st->orientation);
 	if (ret) {
@@ -843,6 +844,9 @@ EXPORT_SYMBOL_NS_GPL(inv_icm42600_core_probe, "IIO_ICM42600");
 static int inv_icm42600_suspend(struct device *dev)
 {
 	struct inv_icm42600_state *st = dev_get_drvdata(dev);
+	struct device *accel_dev;
+	bool wakeup;
+	int accel_conf;
 	int ret;
 
 	mutex_lock(&st->lock);
@@ -863,20 +867,33 @@ static int inv_icm42600_suspend(struct device *dev)
 			goto out_unlock;
 	}
 
-	/* disable APEX features */
-	if (st->apex.wom.enable) {
-		ret = inv_icm42600_disable_wom(st);
-		if (ret)
-			goto out_unlock;
+	/* keep chip on and wake-up capable if APEX and wakeup on */
+	accel_dev = &st->indio_accel->dev;
+	wakeup = (st->apex.on && device_may_wakeup(accel_dev)) ? true : false;
+
+	if (!wakeup) {
+		/* disable APEX features and accel if wakeup disabled */
+		if (st->apex.wom.enable) {
+			ret = inv_icm42600_disable_wom(st);
+			if (ret)
+				goto out_unlock;
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
 		goto out_unlock;
 
-	regulator_disable(st->vddio_supply);
+	/* disable vddio regulator if chip is sleeping */
+	if (!wakeup)
+		regulator_disable(st->vddio_supply);
 
 out_unlock:
 	mutex_unlock(&st->lock);
@@ -892,13 +909,25 @@ static int inv_icm42600_resume(struct device *dev)
 	struct inv_icm42600_state *st = dev_get_drvdata(dev);
 	struct inv_icm42600_sensor_state *gyro_st = iio_priv(st->indio_gyro);
 	struct inv_icm42600_sensor_state *accel_st = iio_priv(st->indio_accel);
+	struct device *accel_dev;
+	bool wakeup;
 	int ret;
 
 	mutex_lock(&st->lock);
 
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
+			goto out_unlock;
+	} else {
+		enable_irq(st->irq);
+		disable_irq_wake(st->irq);
+	}
 
 	pm_runtime_disable(dev);
 	pm_runtime_set_active(dev);
@@ -911,11 +940,13 @@ static int inv_icm42600_resume(struct device *dev)
 	if (ret)
 		goto out_unlock;
 
-	/* restore APEX features */
-	if (st->apex.wom.enable) {
-		ret = inv_icm42600_enable_wom(st);
-		if (ret)
-			goto out_unlock;
+	/* restore APEX features if disabled */
+	if (!wakeup) {
+		if (st->apex.wom.enable) {
+			ret = inv_icm42600_enable_wom(st);
+			if (ret)
+				goto out_unlock;
+		}
 	}
 
 	/* restore FIFO data streaming */
@@ -924,6 +955,8 @@ static int inv_icm42600_resume(struct device *dev)
 		inv_sensors_timestamp_reset(&accel_st->ts);
 		ret = regmap_write(st->map, INV_ICM42600_REG_FIFO_CONFIG,
 				   INV_ICM42600_FIFO_CONFIG_STREAM);
+		if (ret)
+			goto out_unlock;
 	}
 
 out_unlock:

-- 
2.49.0

