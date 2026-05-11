From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 13:26:14 +0200
Subject: [PATCH v7 5/8] iio: magnetometer: ak8975: unify messages with help
 of dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260511-magnetometer-fixes-post-pickup-v7-5-9d910faa28b6@gmail.com>
References: <20260511-magnetometer-fixes-post-pickup-v7-0-9d910faa28b6@gmail.com>
In-Reply-To: <20260511-magnetometer-fixes-post-pickup-v7-0-9d910faa28b6@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778498777; l=2489;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=Z/54TpFJCPFYq21Icav+9C0RoiajzMWR1WO6QMN1t3U=;
 b=Ej34ZzIDxj3COcfEXGiT8oT4U0AkL8Er4H76Jqnvzq0rqqvfcdS/RmhrbhuJmJYH9m6PJ+wtw
 JArK6WiCYoqDt8bdBmexKCIbqGpj1+rIprK5a5PEsbvpXH9668mKmVz
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Shevchenko <andriy.shevchenko@linux.intel.com>

Unify error messages that might appear during probe phase by
switching to use dev_err_probe().

Signed-off-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Reviewed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 30 ++++++++++--------------------
 1 file changed, 10 insertions(+), 20 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index 43259ad4990e2a7a40a0fa60a6ee040c42426b70..2f1442e71607873e869351c379a40dae713a1c84 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -495,10 +495,8 @@ static int ak8975_who_i_am(const struct ak8975_data *data,
 							AK09912_REG_WIA1,
 							sizeof(wia_val),
 							wia_val);
-	if (ret < 0) {
-		dev_err(&client->dev, "Error reading WIA\n");
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(&client->dev, ret, "Error reading WIA\n");
 
 	if (wia_val[0] != AK8975_DEVICE_ID)
 		return -ENODEV;
@@ -996,18 +994,14 @@ static int ak8975_probe(struct i2c_client *client)
 		return ret;
 
 	ret = ak8975_who_i_am(data, data->def->type);
-	if (ret) {
-		dev_err(&client->dev, "Unexpected device\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "Unexpected device\n");
 	dev_dbg(&client->dev, "Asahi compass chip %s\n", name);
 
 	/* Perform some basic start-of-day setup of the device. */
 	ret = ak8975_setup(data);
-	if (ret) {
-		dev_err(&client->dev, "%s initialization fails\n", name);
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "%s initialization fails\n", name);
 
 	ret = devm_mutex_init(dev, &data->lock);
 	if (ret)
@@ -1022,20 +1016,16 @@ static int ak8975_probe(struct i2c_client *client)
 
 	ret = devm_iio_triggered_buffer_setup(dev, indio_dev, NULL,
 					      ak8975_handle_trigger, NULL);
-	if (ret) {
-		dev_err(&client->dev, "triggered buffer setup failed\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "triggered buffer setup failed\n");
 
 	ret = devm_pm_runtime_enable(dev);
 	if (ret)
 		return ret;
 
 	ret = devm_iio_device_register(dev, indio_dev);
-	if (ret) {
-		dev_err(&client->dev, "device register failed\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "device register failed\n");
 
 	/*
 	 * The device comes online in 500us, so add two orders of magnitude

-- 
2.47.3

