From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Sat, 19 Sep 2026 16:06:31 +0530
Subject: [PATCH v6 08/14] iio: light: hid-sensor-als: convert probe and
 teardown to devm-managed resources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-28-apr-iio-redundant-argument-v5-temp-v6-8-d577b2371b3c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789814199; l=3431;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=YJB29GHZCncYhwv+cTV1yg7AaHm7y9Zh7SdPyAgjnjg=;
 b=rxTjzmt+VTokVEDbnlBNIeMJPtCUNrZfx8Bx8qIsUGqyGZmNLIt5QzhbzKeIkHZg3W1DpodaD
 TJNeZ/QGM7oDuDdauJLuXIiOUg0QAwKlcpKj6YNRHdcJcd9oJcn7Py1
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
 drivers/iio/light/hid-sensor-als.c | 39 ++++++++------------------------------
 1 file changed, 8 insertions(+), 31 deletions(-)

diff --git a/drivers/iio/light/hid-sensor-als.c b/drivers/iio/light/hid-sensor-als.c
index 10bf46ea4f47..633fd1569987 100644
--- a/drivers/iio/light/hid-sensor-als.c
+++ b/drivers/iio/light/hid-sensor-als.c
@@ -348,7 +348,8 @@ static int als_parse_report(struct platform_device *pdev,
 /* Function to initialize the processing for usage id */
 static int hid_als_probe(struct platform_device *pdev)
 {
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
+	struct device *dev = &pdev->dev;
+	struct hid_sensor_hub_device *hsdev = dev_get_platdata(dev);
 	int ret = 0;
 	static const char *name = "als";
 	struct iio_dev *indio_dev;
@@ -396,8 +397,8 @@ static int hid_als_probe(struct platform_device *pdev)
 
 	atomic_set(&als_state->common_attributes.data_ready, 0);
 
-	ret = hid_sensor_setup_trigger(indio_dev, name,
-				       &als_state->common_attributes);
+	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
+					    &als_state->common_attributes);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "trigger setup failed\n");
 		return ret;
@@ -406,37 +407,14 @@ static int hid_als_probe(struct platform_device *pdev)
 	als_state->callbacks.send_event = als_proc_event;
 	als_state->callbacks.capture_sample = als_capture_sample;
 	als_state->callbacks.pdev = pdev;
-	ret = sensor_hub_register_callback(hsdev, hsdev->usage, &als_state->callbacks);
+	ret = devm_sensor_hub_register_callback(dev, hsdev, hsdev->usage,
+						&als_state->callbacks);
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
-	sensor_hub_remove_callback(hsdev, hsdev->usage);
-error_remove_trigger:
-	hid_sensor_remove_trigger(&als_state->common_attributes);
-	return ret;
-}
-
-/* Function to deinitialize the processing for usage id */
-static void hid_als_remove(struct platform_device *pdev)
-{
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
-	struct iio_dev *indio_dev = platform_get_drvdata(pdev);
-	struct als_state *als_state = iio_priv(indio_dev);
-
-	iio_device_unregister(indio_dev);
-	sensor_hub_remove_callback(hsdev, hsdev->usage);
-	hid_sensor_remove_trigger(&als_state->common_attributes);
+	return devm_iio_device_register(dev, indio_dev);
 }
 
 static const struct platform_device_id hid_als_ids[] = {
@@ -459,7 +437,6 @@ static struct platform_driver hid_als_platform_driver = {
 		.pm	= &hid_sensor_pm_ops,
 	},
 	.probe		= hid_als_probe,
-	.remove		= hid_als_remove,
 };
 module_platform_driver(hid_als_platform_driver);
 

-- 
2.34.1

