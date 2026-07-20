From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Mon, 20 Jul 2026 15:10:22 +0530
Subject: [PATCH 10/10] iio: pressure: hid-sensor-press: use local struct
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hid-iio-local-struct-device-v1-10-74496fee6327@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784540423; l=3124;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=KprakpDFPiwIPtA12YpCnWpXHOfCF0716+NW98RCOhE=;
 b=mbh6hvgT9+rdmxJAM7i6ZzhwW0uWhPEsY2qlpJRuZk5H5A2g9/mwOrgF4jjVli0KhtGFMDejv
 rnm20xClbDSCLTLM6gNtNHecByJDjUsgamb2JohWEbDuU2CfRcaUwOU
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a local struct device pointer derived from &pdev->dev.
This avoids repeated &pdev->dev usage and improves readability.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/pressure/hid-sensor-press.c | 19 ++++++++++---------
 1 file changed, 10 insertions(+), 9 deletions(-)

diff --git a/drivers/iio/pressure/hid-sensor-press.c b/drivers/iio/pressure/hid-sensor-press.c
index e688b0776547..fee170aa4379 100644
--- a/drivers/iio/pressure/hid-sensor-press.c
+++ b/drivers/iio/pressure/hid-sensor-press.c
@@ -230,13 +230,14 @@ static int press_parse_report(struct platform_device *pdev,
 /* Function to initialize the processing for usage id */
 static int hid_press_probe(struct platform_device *pdev)
 {
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
+	struct device *dev = &pdev->dev;
+	struct hid_sensor_hub_device *hsdev = dev_get_platdata(dev);
 	int ret = 0;
 	static const char *name = "press";
 	struct iio_dev *indio_dev;
 	struct press_state *press_state;
 
-	indio_dev = devm_iio_device_alloc(&pdev->dev, sizeof(struct press_state));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(struct press_state));
 	if (!indio_dev)
 		return -ENOMEM;
 	platform_set_drvdata(pdev, indio_dev);
@@ -251,14 +252,14 @@ static int hid_press_probe(struct platform_device *pdev)
 					press_sensitivity_addresses,
 					ARRAY_SIZE(press_sensitivity_addresses));
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
+		dev_err(dev, "failed to setup common attributes\n");
 		return ret;
 	}
 
-	indio_dev->channels = devm_kmemdup(&pdev->dev, press_channels,
+	indio_dev->channels = devm_kmemdup(dev, press_channels,
 					   sizeof(press_channels), GFP_KERNEL);
 	if (!indio_dev->channels) {
-		dev_err(&pdev->dev, "failed to duplicate channels\n");
+		dev_err(dev, "failed to duplicate channels\n");
 		return -ENOMEM;
 	}
 
@@ -266,7 +267,7 @@ static int hid_press_probe(struct platform_device *pdev)
 				 (struct iio_chan_spec *)indio_dev->channels,
 				 HID_USAGE_SENSOR_PRESSURE, press_state);
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
+		dev_err(dev, "failed to setup attributes\n");
 		return ret;
 	}
 
@@ -281,7 +282,7 @@ static int hid_press_probe(struct platform_device *pdev)
 	ret = hid_sensor_setup_trigger(indio_dev, name,
 				       &press_state->common_attributes);
 	if (ret) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+		dev_err(dev, "trigger setup failed\n");
 		return ret;
 	}
 
@@ -291,13 +292,13 @@ static int hid_press_probe(struct platform_device *pdev)
 	ret = sensor_hub_register_callback(hsdev, HID_USAGE_SENSOR_PRESSURE,
 					   &press_state->callbacks);
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

