From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Mon, 20 Jul 2026 15:10:15 +0530
Subject: [PATCH 03/10] iio: accel: hid-sensor-accel-3d: use local struct
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hid-iio-local-struct-device-v1-3-74496fee6327@gmail.com>
References: <20260720-hid-iio-local-struct-device-v1-0-74496fee6327@gmail.com>
In-Reply-To: <20260720-hid-iio-local-struct-device-v1-0-74496fee6327@gmail.com>
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784540423; l=3184;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=CHrL5pLuWoANqRnTUQhBxvjRxrsqGaR+mjcFFDbcdqU=;
 b=jvPykdZK1FZL5BRq/q/lUtRSM7gO1wAB8CWI2GuTQYgmVnGABIc0qmpbT/Zod8t+3/eDeIOxv
 TstVMjJkp46C+vNCunsNzJt0K/Y7cHTZ8MprvLUPE48EpKBd4bmLbfZ
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a local struct device pointer derived from &pdev->dev.
This avoids repeated &pdev->dev usage and improves readability.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/accel/hid-sensor-accel-3d.c | 22 +++++++++++-----------
 1 file changed, 11 insertions(+), 11 deletions(-)

diff --git a/drivers/iio/accel/hid-sensor-accel-3d.c b/drivers/iio/accel/hid-sensor-accel-3d.c
index eb521125f4eb..5467ecc86b58 100644
--- a/drivers/iio/accel/hid-sensor-accel-3d.c
+++ b/drivers/iio/accel/hid-sensor-accel-3d.c
@@ -314,7 +314,8 @@ static int accel_3d_parse_report(struct platform_device *pdev,
 /* Function to initialize the processing for usage id */
 static int hid_accel_3d_probe(struct platform_device *pdev)
 {
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
+	struct device *dev = &pdev->dev;
+	struct hid_sensor_hub_device *hsdev = dev_get_platdata(dev);
 	int ret = 0;
 	const char *name;
 	struct iio_dev *indio_dev;
@@ -322,8 +323,7 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 	const struct iio_chan_spec *channel_spec;
 	int channel_size;
 
-	indio_dev = devm_iio_device_alloc(&pdev->dev,
-					  sizeof(struct accel_3d_state));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(struct accel_3d_state));
 	if (!indio_dev)
 		return -ENOMEM;
 
@@ -350,21 +350,21 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 						 accel_3d_sensitivity_addresses,
 						 ARRAY_SIZE(accel_3d_sensitivity_addresses));
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
+		dev_err(dev, "failed to setup common attributes\n");
 		return ret;
 	}
-	indio_dev->channels = devm_kmemdup(&pdev->dev, channel_spec,
-					   channel_size, GFP_KERNEL);
 
+	indio_dev->channels = devm_kmemdup(dev, channel_spec, channel_size, GFP_KERNEL);
 	if (!indio_dev->channels) {
-		dev_err(&pdev->dev, "failed to duplicate channels\n");
+		dev_err(dev, "failed to duplicate channels\n");
 		return -ENOMEM;
 	}
+
 	ret = accel_3d_parse_report(pdev, hsdev,
 				    (struct iio_chan_spec *)indio_dev->channels,
 				    hsdev->usage, accel_state);
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
+		dev_err(dev, "failed to setup attributes\n");
 		return ret;
 	}
 
@@ -377,7 +377,7 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 	ret = hid_sensor_setup_trigger(indio_dev, name,
 				       &accel_state->common_attributes);
 	if (ret < 0) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+		dev_err(dev, "trigger setup failed\n");
 		return ret;
 	}
 
@@ -387,13 +387,13 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 	ret = sensor_hub_register_callback(hsdev, hsdev->usage,
 					   &accel_state->callbacks);
 	if (ret < 0) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+		dev_err(dev, "callback reg failed\n");
 		goto error_remove_trigger;
 	}
 
 	ret = iio_device_register(indio_dev);
 	if (ret) {
-		dev_err(&pdev->dev, "device register failed\n");
+		dev_err(dev, "device register failed\n");
 		goto error_remove_callback;
 	}
 

-- 
2.34.1

