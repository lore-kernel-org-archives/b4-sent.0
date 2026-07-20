From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Mon, 20 Jul 2026 15:10:19 +0530
Subject: [PATCH 07/10] iio: orientation: hid-sensor-incl-3d: use local
 struct device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hid-iio-local-struct-device-v1-7-74496fee6327@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784540423; l=3070;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=V5UXFAlSPanQN9gs2HGz9qITKyYoV6OuXxqP/NGEa/Y=;
 b=D7vt8syI2oxwosTVoFt+oAH202h7xOa5P+L3z+qyd/qWd1kPjcSDWX98A4jTYSC1aoOppzc0h
 Ak0O9onSHo0A8mDA+5Iqu4f+lz0am+0QVkJ1RYVBCSYHvHbjdstQCn4
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a local struct device pointer derived from &pdev->dev.
This avoids repeated &pdev->dev usage and improves readability.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/orientation/hid-sensor-incl-3d.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/iio/orientation/hid-sensor-incl-3d.c b/drivers/iio/orientation/hid-sensor-incl-3d.c
index aea28321db95..ff28aed47c75 100644
--- a/drivers/iio/orientation/hid-sensor-incl-3d.c
+++ b/drivers/iio/orientation/hid-sensor-incl-3d.c
@@ -293,14 +293,14 @@ static int incl_3d_parse_report(struct platform_device *pdev,
 /* Function to initialize the processing for usage id */
 static int hid_incl_3d_probe(struct platform_device *pdev)
 {
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
+	struct device *dev = &pdev->dev;
+	struct hid_sensor_hub_device *hsdev = dev_get_platdata(dev);
 	int ret;
 	static char *name = "incli_3d";
 	struct iio_dev *indio_dev;
 	struct incl_3d_state *incl_state;
 
-	indio_dev = devm_iio_device_alloc(&pdev->dev,
-					  sizeof(struct incl_3d_state));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(struct incl_3d_state));
 	if (!indio_dev)
 		return -ENOMEM;
 
@@ -316,14 +316,14 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 				incl_3d_sensitivity_addresses,
 				ARRAY_SIZE(incl_3d_sensitivity_addresses));
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
+		dev_err(dev, "failed to setup common attributes\n");
 		return ret;
 	}
 
-	indio_dev->channels = devm_kmemdup(&pdev->dev, incl_3d_channels,
+	indio_dev->channels = devm_kmemdup(dev, incl_3d_channels,
 					   sizeof(incl_3d_channels), GFP_KERNEL);
 	if (!indio_dev->channels) {
-		dev_err(&pdev->dev, "failed to duplicate channels\n");
+		dev_err(dev, "failed to duplicate channels\n");
 		return -ENOMEM;
 	}
 
@@ -332,7 +332,7 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 				   HID_USAGE_SENSOR_INCLINOMETER_3D,
 				   incl_state);
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
+		dev_err(dev, "failed to setup attributes\n");
 		return ret;
 	}
 
@@ -346,7 +346,7 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 	ret = hid_sensor_setup_trigger(indio_dev, name,
 				       &incl_state->common_attributes);
 	if (ret) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+		dev_err(dev, "trigger setup failed\n");
 		return ret;
 	}
 
@@ -357,13 +357,13 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 					   HID_USAGE_SENSOR_INCLINOMETER_3D,
 					   &incl_state->callbacks);
 	if (ret) {
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

