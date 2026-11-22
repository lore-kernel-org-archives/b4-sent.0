From: Roman Vivchar <rva333@protonmail.com>
Date: Sun, 22 Nov 2026 19:15:42 +0200
Subject: [PATCH v3 1/7] iio: light: stk3310: migrate to devm_* API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-6768-stk3337-v3-1-b0d0a924e843@protonmail.com>
References: <20261122-6768-stk3337-v3-0-b0d0a924e843@protonmail.com>
In-Reply-To: <20261122-6768-stk3337-v3-0-b0d0a924e843@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Joshua Crofts <crofts@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795367795; l=2793;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=0op2+wuVDhpkZWTj316+uOP3iudK90lB8euvzogwbR4=;
 b=cvgOwMN/d6emckerpitU2MxglfwkIlCCY1/WLT0l6KbFxqr4uRSz2yYqdqKk6YRgXLmnnmqph
 OIv64uYaL07BuLZMfjC15q3NWx5Q/3/mlLD2Gd+f6KTs0Zzosqbj+iS
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace manual .remove() and mutex_init() with devm_* helpers for
consistency with existing devm_request_threaded_irq().

Suggested-by: Joshua Crofts <crofts@kernel.org>
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/iio/light/stk3310.c | 37 +++++++++++++++++--------------------
 1 file changed, 17 insertions(+), 20 deletions(-)

diff --git a/drivers/iio/light/stk3310.c b/drivers/iio/light/stk3310.c
index e751e7c97bc1..708ac0503be0 100644
--- a/drivers/iio/light/stk3310.c
+++ b/drivers/iio/light/stk3310.c
@@ -10,6 +10,7 @@
 #include <linux/array_size.h>
 #include <linux/bits.h>
 #include <linux/dev_printk.h>
+#include <linux/device/devres.h>
 #include <linux/err.h>
 #include <linux/i2c.h>
 #include <linux/interrupt.h>
@@ -594,6 +595,11 @@ static int stk3310_set_state(struct stk3310_data *data, u8 state)
 	return ret;
 }
 
+static void stk3310_standby(void *data)
+{
+	stk3310_set_state(data, STK3310_STATE_STANDBY);
+}
+
 static int stk3310_init(struct iio_dev *indio_dev)
 {
 	int ret;
@@ -617,6 +623,10 @@ static int stk3310_init(struct iio_dev *indio_dev)
 		return ret;
 	}
 
+	ret = devm_add_action_or_reset(&client->dev, stk3310_standby, data);
+	if (ret)
+		return ret;
+
 	/* Enable PS interrupts */
 	ret = regmap_field_write(data->reg_int_ps, STK3310_PSINT_EN);
 	if (ret < 0) {
@@ -745,7 +755,9 @@ static int stk3310_probe(struct i2c_client *client)
 	device_property_read_u32(&client->dev, "proximity-near-level",
 				 &data->ps_near_level);
 
-	mutex_init(&data->lock);
+	ret = devm_mutex_init(dev, &data->lock);
+	if (ret)
+		return ret;
 
 	ret = stk3310_regmap_init(data);
 	if (ret < 0)
@@ -769,28 +781,14 @@ static int stk3310_probe(struct i2c_client *client)
 						IRQF_ONESHOT,
 						"stk3310_event", indio_dev);
 		if (ret)
-			goto err_standby;
+			return ret;
 	}
 
-	ret = iio_device_register(indio_dev);
-	if (ret < 0) {
-		dev_err(&client->dev, "device_register failed\n");
-		goto err_standby;
-	}
+	ret = devm_iio_device_register(dev, indio_dev);
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "device_register failed\n");
 
 	return 0;
-
-err_standby:
-	stk3310_set_state(data, STK3310_STATE_STANDBY);
-	return ret;
-}
-
-static void stk3310_remove(struct i2c_client *client)
-{
-	struct iio_dev *indio_dev = i2c_get_clientdata(client);
-
-	iio_device_unregister(indio_dev);
-	stk3310_set_state(iio_priv(indio_dev), STK3310_STATE_STANDBY);
 }
 
 static int stk3310_suspend(struct device *dev)
@@ -896,7 +894,6 @@ static struct i2c_driver stk3310_driver = {
 		.acpi_match_table = stk3310_acpi_id,
 	},
 	.probe =        stk3310_probe,
-	.remove =           stk3310_remove,
 	.id_table =         stk3310_i2c_id,
 };
 

-- 
2.56.1

