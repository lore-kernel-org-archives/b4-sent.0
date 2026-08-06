From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Thu, 06 Aug 2026 17:55:55 +0530
Subject: [PATCH v5 09/13] iio: magnetometer: hid-sensor-magn-3d: convert
 probe and teardown to devm-managed resources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-28-apr-iio-redundant-argument-v5-temp-v5-9-f1f92c1d830f@gmail.com>
References: <20260806-28-apr-iio-redundant-argument-v5-temp-v5-0-f1f92c1d830f@gmail.com>
In-Reply-To: <20260806-28-apr-iio-redundant-argument-v5-temp-v5-0-f1f92c1d830f@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786019201; l=3629;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=psVvPChQvmnDeqq5c0sAzyCmhiEktLAbJoySPLiD/3g=;
 b=JtmCBV4eRexLF3nQbqCZPGXDJ+m0LWy9uJ7HS+T109gjkI2MPjw4XbwnB3NtiCCKh3iPppLI7
 ithdY7N7IYHDiuNlj1utSJUSzElVk4zSPD4mNuT1AgTV1FaQV0o7I7w
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert HID IIO driver resource management to use devm-managed helpers,
tying the lifetime of all resources to the device.

HID trigger setup, IIO registration, and sensor hub callback resource
are now managed using devm APIs. Cleanup logic previously handled
explicitly in probe error and teardown paths.

This simplifies the probe path by removing goto-based error handling,
eliminates the remove callback entirely.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/magnetometer/hid-sensor-magn-3d.c | 41 ++++++---------------------
 1 file changed, 9 insertions(+), 32 deletions(-)

diff --git a/drivers/iio/magnetometer/hid-sensor-magn-3d.c b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
index 5402cffa8326..c8b4fa7785c9 100644
--- a/drivers/iio/magnetometer/hid-sensor-magn-3d.c
+++ b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
@@ -450,7 +450,8 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 /* Function to initialize the processing for usage id */
 static int hid_magn_3d_probe(struct platform_device *pdev)
 {
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
+	struct device *dev = &pdev->dev;
+	struct hid_sensor_hub_device *hsdev = dev_get_platdata(dev);
 	int ret = 0;
 	static char *name = "magn_3d";
 	struct iio_dev *indio_dev;
@@ -498,8 +499,8 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 
 	atomic_set(&magn_state->magn_flux_attributes.data_ready, 0);
 
-	ret = hid_sensor_setup_trigger(indio_dev, name,
-				       &magn_state->magn_flux_attributes);
+	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
+					    &magn_state->magn_flux_attributes);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "trigger setup failed\n");
 		return ret;
@@ -508,38 +509,15 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 	magn_state->callbacks.send_event = magn_3d_proc_event;
 	magn_state->callbacks.capture_sample = magn_3d_capture_sample;
 	magn_state->callbacks.pdev = pdev;
-	ret = sensor_hub_register_callback(hsdev, HID_USAGE_SENSOR_COMPASS_3D,
-					   &magn_state->callbacks);
+	ret = devm_sensor_hub_register_callback(dev, hsdev,
+						HID_USAGE_SENSOR_COMPASS_3D,
+						&magn_state->callbacks);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "callback reg failed\n");
-		goto error_remove_trigger;
-	}
-
-	ret = iio_device_register(indio_dev);
-	if (ret) {
-		dev_err(&pdev->dev, "device register failed\n");
-		goto error_remove_callback;
+		return ret;
 	}
 
-	return ret;
-
-error_remove_callback:
-	sensor_hub_remove_callback(hsdev, HID_USAGE_SENSOR_COMPASS_3D);
-error_remove_trigger:
-	hid_sensor_remove_trigger(&magn_state->magn_flux_attributes);
-	return ret;
-}
-
-/* Function to deinitialize the processing for usage id */
-static void hid_magn_3d_remove(struct platform_device *pdev)
-{
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
-	struct iio_dev *indio_dev = platform_get_drvdata(pdev);
-	struct magn_3d_state *magn_state = iio_priv(indio_dev);
-
-	iio_device_unregister(indio_dev);
-	sensor_hub_remove_callback(hsdev, HID_USAGE_SENSOR_COMPASS_3D);
-	hid_sensor_remove_trigger(&magn_state->magn_flux_attributes);
+	return devm_iio_device_register(dev, indio_dev);
 }
 
 static const struct platform_device_id hid_magn_3d_ids[] = {
@@ -558,7 +536,6 @@ static struct platform_driver hid_magn_3d_platform_driver = {
 		.pm	= &hid_sensor_pm_ops,
 	},
 	.probe		= hid_magn_3d_probe,
-	.remove		= hid_magn_3d_remove,
 };
 module_platform_driver(hid_magn_3d_platform_driver);
 

-- 
2.34.1

