From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 10 Apr 2025 17:39:41 +0200
Subject: [PATCH v4 2/2] iio: imu: inv_icm42600: switch to use generic name
 irq get
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250410-iio-imu-inv-icm42600-rework-interrupt-using-names-v4-2-19e4e2f8f7eb@tdk.com>
References: <20250410-iio-imu-inv-icm42600-rework-interrupt-using-names-v4-0-19e4e2f8f7eb@tdk.com>
In-Reply-To: <20250410-iio-imu-inv-icm42600-rework-interrupt-using-names-v4-0-19e4e2f8f7eb@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744299633; l=4015;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=qd/hxVeO3e4TL1TWiCdGib5jkD+pRfqNEUkSgk4JLuI=;
 b=C/rjRf1MqCDkS1ufczeuaWQyPLa0n+ORNdq5a4c6DxAabsaLlvhoxTtQ3a3Xf9U/TBA9uR7Cu
 4NJ3YdZfiaDD/ADlK8QYQCoDqUa+PiNBCFf+nPAir9b9whJa4cYiEH7
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use generic fwnode_irq_get_byname() for getting interrupt pin using
interrupt name. Only INT1 is supported by the driver currently.

If not found fallback to first defined interrupt to keep compatibility.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600.h      |  2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c | 14 ++++++++++++--
 drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c  |  2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c  |  2 +-
 4 files changed, 15 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600.h b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
index 18787a43477b89db12caee597ab040af5c8f52d5..f893dbe6996506a33eb5d3be47e6765a923665c9 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
@@ -426,7 +426,7 @@ int inv_icm42600_set_temp_conf(struct inv_icm42600_state *st, bool enable,
 int inv_icm42600_debugfs_reg(struct iio_dev *indio_dev, unsigned int reg,
 			     unsigned int writeval, unsigned int *readval);
 
-int inv_icm42600_core_probe(struct regmap *regmap, int chip, int irq,
+int inv_icm42600_core_probe(struct regmap *regmap, int chip,
 			    inv_icm42600_bus_setup bus_setup);
 
 struct iio_dev *inv_icm42600_gyro_init(struct inv_icm42600_state *st);
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
index ef9875d3b79db116f9fb4f6d881a7979292c1792..63d46619ebfaa1372171129fca96381ef4606b2e 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_core.c
@@ -683,12 +683,13 @@ static void inv_icm42600_disable_pm(void *_data)
 	pm_runtime_disable(dev);
 }
 
-int inv_icm42600_core_probe(struct regmap *regmap, int chip, int irq,
+int inv_icm42600_core_probe(struct regmap *regmap, int chip,
 			    inv_icm42600_bus_setup bus_setup)
 {
 	struct device *dev = regmap_get_device(regmap);
+	struct fwnode_handle *fwnode = dev_fwnode(dev);
 	struct inv_icm42600_state *st;
-	int irq_type;
+	int irq, irq_type;
 	bool open_drain;
 	int ret;
 
@@ -697,6 +698,15 @@ int inv_icm42600_core_probe(struct regmap *regmap, int chip, int irq,
 		return -ENODEV;
 	}
 
+	/* get INT1 only supported interrupt or fallback to first interrupt */
+	irq = fwnode_irq_get_byname(fwnode, "INT1");
+	if (irq < 0 && irq != -EPROBE_DEFER) {
+		dev_info(dev, "no INT1 interrupt defined, fallback to first interrupt\n");
+		irq = fwnode_irq_get(fwnode, 0);
+	}
+	if (irq < 0)
+		return dev_err_probe(dev, irq, "error missing INT1 interrupt\n");
+
 	irq_type = irq_get_trigger_type(irq);
 	if (!irq_type)
 		irq_type = IRQF_TRIGGER_FALLING;
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c
index 04e440fe023aa3869529b0f0be003ea0544bfb8d..38cc0d7834fcb96dabc401f29d613cf9fc75b8f5 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c
@@ -67,7 +67,7 @@ static int inv_icm42600_probe(struct i2c_client *client)
 	if (IS_ERR(regmap))
 		return PTR_ERR(regmap);
 
-	return inv_icm42600_core_probe(regmap, chip, client->irq,
+	return inv_icm42600_core_probe(regmap, chip,
 				       inv_icm42600_i2c_bus_setup);
 }
 
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c
index 2bd2c4c8e50c3fe081e882aca6c64736510b474c..f40a09c4cbfc673e76922d13d61a3634785300ec 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c
@@ -64,7 +64,7 @@ static int inv_icm42600_probe(struct spi_device *spi)
 	if (IS_ERR(regmap))
 		return PTR_ERR(regmap);
 
-	return inv_icm42600_core_probe(regmap, chip, spi->irq,
+	return inv_icm42600_core_probe(regmap, chip,
 				       inv_icm42600_spi_bus_setup);
 }
 

-- 
2.49.0

