From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 18 May 2026 09:50:26 +0200
Subject: [PATCH v8 2/5] iio: magnetometer: ak8975: unify messages with help
 of dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260518-magnetometer-fixes-post-pickup-v8-2-088d610108a0@gmail.com>
References: <20260518-magnetometer-fixes-post-pickup-v8-0-088d610108a0@gmail.com>
In-Reply-To: <20260518-magnetometer-fixes-post-pickup-v8-0-088d610108a0@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779090640; l=2737;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=2kbW615Mv/xUTO+xPzb4dUlB6TkMmy9QpDavmVUaJbY=;
 b=I4XXT7/pz1eAh0xTKhSW6xAzWYqVEw1N9TltuBLfxUgXME7G+Nlc6wv2zFBXxHxQdv9eVaQ3L
 kH4+ZFe6zCDD4vGXwLRGpfejH4luAUM+Eds/qtVa8bRkHRqMp+WcerW
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
 drivers/iio/magnetometer/ak8975.c | 37 +++++++++++++------------------------
 1 file changed, 13 insertions(+), 24 deletions(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index de4402201783430fc69369f1accaab35145e9f0c..e7cd28ab37aaeb2b68758a42ba40a87c71bd1e24 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -495,14 +495,10 @@ static int ak8975_who_i_am(const struct ak8975_data *data,
 							AK09912_REG_WIA1,
 							sizeof(wia_val),
 							wia_val);
-	if (ret < 0) {
-		dev_err(&client->dev, "Error reading WIA\n");
-		return ret;
-	}
-	if (ret != sizeof(wia_val)) {
-		dev_err(&client->dev, "Error reading WIA\n");
-		return -EIO;
-	}
+	if (ret < 0)
+		return dev_err_probe(&client->dev, ret, "Error reading WIA\n");
+	if (ret != sizeof(wia_val))
+		return dev_err_probe(&client->dev, -EIO, "Error reading WIA\n");
 
 	if (wia_val[0] != AK8975_DEVICE_ID)
 		return -ENODEV;
@@ -1033,18 +1029,15 @@ static int ak8975_probe(struct i2c_client *client)
 		return ret;
 
 	ret = ak8975_who_i_am(data, data->def->type);
-	if (ret) {
-		dev_err(&client->dev, "Unexpected device\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "Unexpected device\n");
+
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
@@ -1060,20 +1053,16 @@ static int ak8975_probe(struct i2c_client *client)
 	ret = devm_iio_triggered_buffer_setup(dev, indio_dev, NULL,
 					      ak8975_handle_trigger,
 					      &ak8975_buffer_setup_ops);
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

