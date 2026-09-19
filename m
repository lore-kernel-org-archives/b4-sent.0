From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Sat, 19 Sep 2026 16:06:37 +0530
Subject: [PATCH v6 14/14] iio: temperature: hid-sensor-temperature: convert
 probe and teardown to devm-managed resources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-28-apr-iio-redundant-argument-v5-temp-v6-14-d577b2371b3c@gmail.com>
References: <20260919-28-apr-iio-redundant-argument-v5-temp-v6-0-d577b2371b3c@gmail.com>
In-Reply-To: <20260919-28-apr-iio-redundant-argument-v5-temp-v6-0-d577b2371b3c@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789814199; l=3471;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=1Xb2KI32YvGlS/Xf3zjMfPomVo3QjnOydjNIX/ii4Sk=;
 b=PMW2nTN2cnFdguySR2C8vQb0ytoKT1PRHbd3zQGsre6RwZ6Kitm/xx4KDZwGqIEpTTFyqAWkl
 /dUsZcTaRwkAocZXal0WZte9Sj1FIXoWVTe8y0liH0tpqMlFykzkyVs
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
 drivers/iio/temperature/hid-sensor-temperature.c | 39 ++++++------------------
 1 file changed, 9 insertions(+), 30 deletions(-)

diff --git a/drivers/iio/temperature/hid-sensor-temperature.c b/drivers/iio/temperature/hid-sensor-temperature.c
index aa5a2b872247..ac5a287d1de3 100644
--- a/drivers/iio/temperature/hid-sensor-temperature.c
+++ b/drivers/iio/temperature/hid-sensor-temperature.c
@@ -189,11 +189,12 @@ static struct hid_sensor_hub_callbacks temperature_callbacks = {
 /* Function to initialize the processing for usage id */
 static int hid_temperature_probe(struct platform_device *pdev)
 {
+	struct device *dev = &pdev->dev;
+	struct hid_sensor_hub_device *hsdev = dev_get_platdata(dev);
 	static const char *name = "temperature";
 	struct iio_dev *indio_dev;
 	struct temperature_state *temp_st;
 	struct iio_chan_spec *temp_chans;
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
 	int ret;
 
 	indio_dev = devm_iio_device_alloc(&pdev->dev, sizeof(*temp_st));
@@ -230,42 +231,21 @@ static int hid_temperature_probe(struct platform_device *pdev)
 
 	atomic_set(&temp_st->common_attributes.data_ready, 0);
 
-	ret = hid_sensor_setup_trigger(indio_dev, name,
-				       &temp_st->common_attributes);
+	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
+					    &temp_st->common_attributes);
 	if (ret)
 		return ret;
 
 	platform_set_drvdata(pdev, indio_dev);
 
 	temperature_callbacks.pdev = pdev;
-	ret = sensor_hub_register_callback(hsdev, HID_USAGE_SENSOR_TEMPERATURE,
-					   &temperature_callbacks);
+	ret = devm_sensor_hub_register_callback(dev, hsdev,
+						HID_USAGE_SENSOR_TEMPERATURE,
+						&temperature_callbacks);
 	if (ret)
-		goto error_remove_trigger;
-
-	ret = iio_device_register(indio_dev);
-	if (ret)
-		goto error_remove_callback;
-
-	return ret;
-
-error_remove_callback:
-	sensor_hub_remove_callback(hsdev, HID_USAGE_SENSOR_TEMPERATURE);
-error_remove_trigger:
-	hid_sensor_remove_trigger(&temp_st->common_attributes);
-	return ret;
-}
-
-/* Function to deinitialize the processing for usage id */
-static void hid_temperature_remove(struct platform_device *pdev)
-{
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
-	struct iio_dev *indio_dev = platform_get_drvdata(pdev);
-	struct temperature_state *temp_st = iio_priv(indio_dev);
+		return ret;
 
-	iio_device_unregister(indio_dev);
-	sensor_hub_remove_callback(hsdev, HID_USAGE_SENSOR_TEMPERATURE);
-	hid_sensor_remove_trigger(&temp_st->common_attributes);
+	return devm_iio_device_register(dev, indio_dev);
 }
 
 static const struct platform_device_id hid_temperature_ids[] = {
@@ -284,7 +264,6 @@ static struct platform_driver hid_temperature_platform_driver = {
 		.pm	= &hid_sensor_pm_ops,
 	},
 	.probe		= hid_temperature_probe,
-	.remove		= hid_temperature_remove,
 };
 module_platform_driver(hid_temperature_platform_driver);
 

-- 
2.34.1

