From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Mon, 20 Jul 2026 15:10:18 +0530
Subject: [PATCH 06/10] iio: magnetometer: hid-sensor-magn-3d: use local
 struct device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hid-iio-local-struct-device-v1-6-74496fee6327@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784540423; l=5803;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=YcOmzT5cC/xJwy/yQyWOjATzzvkHHHTaevRR0MmJczM=;
 b=WGETJTQxWY5k5eqWvp33D6N1o+Ng6+pWgbHDfsAWMQAyzfKxjgz27FK7s8jACacy9yT8Ti0/F
 DyMYsh3X303ApaiTdFuV6Pp55kpdAD7MKG1LozBrEkAhZjsWfws/jcI
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a local struct device pointer derived from &pdev->dev.
This avoids repeated &pdev->dev usage and improves readability.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/magnetometer/hid-sensor-magn-3d.c | 43 ++++++++++++---------------
 1 file changed, 19 insertions(+), 24 deletions(-)

diff --git a/drivers/iio/magnetometer/hid-sensor-magn-3d.c b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
index ad18f233ee16..c9077adde882 100644
--- a/drivers/iio/magnetometer/hid-sensor-magn-3d.c
+++ b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
@@ -337,6 +337,7 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 				u32 usage_id,
 				struct magn_3d_state *st)
 {
+	struct device *dev = &pdev->dev;
 	int i;
 	int attr_count = 0;
 	struct iio_chan_spec *_channels;
@@ -357,35 +358,30 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 	}
 
 	if (attr_count <= 0) {
-		dev_err(&pdev->dev,
-			"failed to find any supported usage attributes in report\n");
+		dev_err(dev, "failed to find any supported usage attributes in report\n");
 		return  -EINVAL;
 	}
 
-	dev_dbg(&pdev->dev, "magn_3d Found %d usage attributes\n", attr_count);
-	dev_dbg(&pdev->dev, "magn_3d X: %x:%x Y: %x:%x Z: %x:%x\n",
+	dev_dbg(dev, "magn_3d Found %d usage attributes\n", attr_count);
+	dev_dbg(dev, "magn_3d X: %x:%x Y: %x:%x Z: %x:%x\n",
 		st->magn[0].index,
 		st->magn[0].report_id,
 		st->magn[1].index, st->magn[1].report_id,
 		st->magn[2].index, st->magn[2].report_id);
 
 	/* Setup IIO channel array */
-	_channels = devm_kcalloc(&pdev->dev, attr_count,
-				 sizeof(struct iio_chan_spec),
-				 GFP_KERNEL);
+	_channels = devm_kcalloc(dev, attr_count, sizeof(struct iio_chan_spec), GFP_KERNEL);
 	if (!_channels) {
-		dev_err(&pdev->dev,
-			"failed to allocate space for iio channels\n");
+		dev_err(dev, "failed to allocate space for iio channels\n");
 		return -ENOMEM;
 	}
 
 	/* attr_count include timestamp channel, and the iio_vals should be aligned to 8byte */
-	st->iio_vals = devm_kcalloc(&pdev->dev,
+	st->iio_vals = devm_kcalloc(dev,
 				    ((attr_count + 1) % 2 + (attr_count + 1) / 2) * 2,
 				    sizeof(u32), GFP_KERNEL);
 	if (!st->iio_vals) {
-		dev_err(&pdev->dev,
-			"failed to allocate space for iio values array\n");
+		dev_err(dev, "failed to allocate space for iio values array\n");
 		return -ENOMEM;
 	}
 
@@ -412,14 +408,13 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 	}
 
 	if (*chan_count <= 0) {
-		dev_err(&pdev->dev,
-			"failed to find any magnetic channels setup\n");
+		dev_err(dev, "failed to find any magnetic channels setup\n");
 		return -EINVAL;
 	}
 
 	*channels = _channels;
 
-	dev_dbg(&pdev->dev, "magn_3d Setup %d IIO channels\n", *chan_count);
+	dev_dbg(dev, "magn_3d Setup %d IIO channels\n", *chan_count);
 
 	st->magn_flux_attr.scale_precision = hid_sensor_format_scale(
 				HID_USAGE_SENSOR_COMPASS_3D,
@@ -439,7 +434,7 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 			HID_USAGE_SENSOR_DATA_MOD_CHANGE_SENSITIVITY_ABS |
 			HID_USAGE_SENSOR_ORIENT_COMP_MAGN_NORTH,
 			&st->rot_attributes.sensitivity);
-		dev_dbg(&pdev->dev, "Sensitivity index:report %d:%d\n",
+		dev_dbg(dev, "Sensitivity index:report %d:%d\n",
 			st->rot_attributes.sensitivity.index,
 			st->rot_attributes.sensitivity.report_id);
 	}
@@ -450,7 +445,8 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 /* Function to initialize the processing for usage id */
 static int hid_magn_3d_probe(struct platform_device *pdev)
 {
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
+	struct device *dev = &pdev->dev;
+	struct hid_sensor_hub_device *hsdev = dev_get_platdata(dev);
 	int ret = 0;
 	static char *name = "magn_3d";
 	struct iio_dev *indio_dev;
@@ -458,8 +454,7 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 	struct iio_chan_spec *channels;
 	int chan_count = 0;
 
-	indio_dev = devm_iio_device_alloc(&pdev->dev,
-					  sizeof(struct magn_3d_state));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(struct magn_3d_state));
 	if (!indio_dev)
 		return -ENOMEM;
 
@@ -475,7 +470,7 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 				magn_3d_sensitivity_addresses,
 				ARRAY_SIZE(magn_3d_sensitivity_addresses));
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
+		dev_err(dev, "failed to setup common attributes\n");
 		return ret;
 	}
 	magn_state->rot_attributes = magn_state->magn_flux_attributes;
@@ -486,7 +481,7 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 				   &channels, &chan_count,
 				   HID_USAGE_SENSOR_COMPASS_3D, magn_state);
 	if (ret) {
-		dev_err(&pdev->dev, "failed to parse report\n");
+		dev_err(dev, "failed to parse report\n");
 		return ret;
 	}
 
@@ -501,7 +496,7 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 	ret = hid_sensor_setup_trigger(indio_dev, name,
 				       &magn_state->magn_flux_attributes);
 	if (ret < 0) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+		dev_err(dev, "trigger setup failed\n");
 		return ret;
 	}
 
@@ -511,13 +506,13 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 	ret = sensor_hub_register_callback(hsdev, HID_USAGE_SENSOR_COMPASS_3D,
 					   &magn_state->callbacks);
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

