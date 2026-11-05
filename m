From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Thu, 05 Nov 2026 18:11:46 +0530
Subject: [PATCH 4/5] iio: Use dev_err_probe() in HID IIO device drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-19-oct-hid-iio-unified-print-framework-v1-4-0b360d9552d9@gmail.com>
References: <20261105-19-oct-hid-iio-unified-print-framework-v1-0-0b360d9552d9@gmail.com>
In-Reply-To: <20261105-19-oct-hid-iio-unified-print-framework-v1-0-0b360d9552d9@gmail.com>
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793882514; l=11269;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=rCumOrJWrJ0JIAoVaoKix1QmO2Ic3aRD6anaToQ5B9A=;
 b=ibyG4jTs+GjpQVs93XdTCWXgzrRlKSAYQkuPv0R/Q1cAK8JFYvqmn9jqEeeFAbCOM8bkOfKLj
 lCzrsoC9HCTD35/DBDEU8h/7mqASSlqV8S0DBzRMLa574yCOrxDtMVI
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use dev_err_probe() in probe paths to simplify error handling and
properly handle deferred probe errors, avoiding unnecessary log
messages.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/accel/hid-sensor-accel-3d.c              | 12 ++++--------
 drivers/iio/gyro/hid-sensor-gyro-3d.c                | 12 ++++--------
 drivers/iio/light/hid-sensor-als.c                   | 12 ++++--------
 drivers/iio/light/hid-sensor-prox.c                  | 12 ++++--------
 drivers/iio/magnetometer/hid-sensor-magn-3d.c        | 13 +++++--------
 drivers/iio/orientation/hid-sensor-incl-3d.c         | 12 ++++--------
 drivers/iio/orientation/hid-sensor-rotation.c        | 12 ++++--------
 drivers/iio/position/hid-sensor-custom-intel-hinge.c | 12 ++++--------
 drivers/iio/pressure/hid-sensor-press.c              | 12 ++++--------
 9 files changed, 37 insertions(+), 72 deletions(-)

diff --git a/drivers/iio/accel/hid-sensor-accel-3d.c b/drivers/iio/accel/hid-sensor-accel-3d.c
index f9e04ed2a7cd..414d62d2249f 100644
--- a/drivers/iio/accel/hid-sensor-accel-3d.c
+++ b/drivers/iio/accel/hid-sensor-accel-3d.c
@@ -350,10 +350,8 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 						 &accel_state->common_attributes,
 						 accel_3d_sensitivity_addresses,
 						 ARRAY_SIZE(accel_3d_sensitivity_addresses));
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	indio_dev->channels = devm_kmemdup(&pdev->dev, channel_spec,
 					   channel_size, GFP_KERNEL);
@@ -363,10 +361,8 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 	ret = accel_3d_parse_report(pdev, hsdev,
 				    (struct iio_chan_spec *)indio_dev->channels,
 				    hsdev->usage, accel_state);
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->info = &accel_3d_info;
 	indio_dev->name = name;
diff --git a/drivers/iio/gyro/hid-sensor-gyro-3d.c b/drivers/iio/gyro/hid-sensor-gyro-3d.c
index a785a9fc7f9d..cc81ac2ccdd1 100644
--- a/drivers/iio/gyro/hid-sensor-gyro-3d.c
+++ b/drivers/iio/gyro/hid-sensor-gyro-3d.c
@@ -285,10 +285,8 @@ static int hid_gyro_3d_probe(struct platform_device *pdev)
 						&gyro_state->common_attributes,
 						gyro_3d_sensitivity_addresses,
 						ARRAY_SIZE(gyro_3d_sensitivity_addresses));
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	indio_dev->channels = devm_kmemdup(&pdev->dev, gyro_3d_channels,
 					   sizeof(gyro_3d_channels), GFP_KERNEL);
@@ -298,10 +296,8 @@ static int hid_gyro_3d_probe(struct platform_device *pdev)
 	ret = gyro_3d_parse_report(pdev, hsdev,
 				   (struct iio_chan_spec *)indio_dev->channels,
 				   HID_USAGE_SENSOR_GYRO_3D, gyro_state);
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->num_channels = ARRAY_SIZE(gyro_3d_channels);
 	indio_dev->info = &gyro_3d_info;
diff --git a/drivers/iio/light/hid-sensor-als.c b/drivers/iio/light/hid-sensor-als.c
index 88c7b1ce9a19..9c136f3f0859 100644
--- a/drivers/iio/light/hid-sensor-als.c
+++ b/drivers/iio/light/hid-sensor-als.c
@@ -369,18 +369,14 @@ static int hid_als_probe(struct platform_device *pdev)
 					&als_state->common_attributes,
 					als_sensitivity_addresses,
 					ARRAY_SIZE(als_sensitivity_addresses));
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	ret = als_parse_report(pdev, hsdev,
 			       hsdev->usage,
 			       als_state);
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	/* Add timestamp channel */
 	als_state->channels[als_state->num_channels] = als_channels[CHANNEL_SCAN_INDEX_TIMESTAMP];
diff --git a/drivers/iio/light/hid-sensor-prox.c b/drivers/iio/light/hid-sensor-prox.c
index af4becb2e7dd..4d0c7dffc252 100644
--- a/drivers/iio/light/hid-sensor-prox.c
+++ b/drivers/iio/light/hid-sensor-prox.c
@@ -280,16 +280,12 @@ static int hid_prox_probe(struct platform_device *pdev)
 					&prox_state->common_attributes,
 					prox_sensitivity_addresses,
 					ARRAY_SIZE(prox_sensitivity_addresses));
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	ret = prox_parse_report(pdev, hsdev, prox_state);
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->num_channels = prox_state->num_channels;
 	indio_dev->channels = prox_state->channels;
diff --git a/drivers/iio/magnetometer/hid-sensor-magn-3d.c b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
index fb9a561706a8..3ea479f19c79 100644
--- a/drivers/iio/magnetometer/hid-sensor-magn-3d.c
+++ b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
@@ -463,10 +463,9 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 				&magn_state->magn_flux_attributes,
 				magn_3d_sensitivity_addresses,
 				ARRAY_SIZE(magn_3d_sensitivity_addresses));
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
+
 	magn_state->rot_attributes = magn_state->magn_flux_attributes;
 	/* sensitivity of rot_attribute is not the same as magn_flux_attributes */
 	magn_state->rot_attributes.sensitivity.index = -1;
@@ -474,10 +473,8 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 	ret = magn_3d_parse_report(pdev, hsdev,
 				   &channels, &chan_count,
 				   HID_USAGE_SENSOR_COMPASS_3D, magn_state);
-	if (ret) {
-		dev_err(&pdev->dev, "failed to parse report\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->channels = channels;
 	indio_dev->num_channels = chan_count;
diff --git a/drivers/iio/orientation/hid-sensor-incl-3d.c b/drivers/iio/orientation/hid-sensor-incl-3d.c
index 2aed92c3526d..8ef3645d9b18 100644
--- a/drivers/iio/orientation/hid-sensor-incl-3d.c
+++ b/drivers/iio/orientation/hid-sensor-incl-3d.c
@@ -316,10 +316,8 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 				&incl_state->common_attributes,
 				incl_3d_sensitivity_addresses,
 				ARRAY_SIZE(incl_3d_sensitivity_addresses));
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	indio_dev->channels = devm_kmemdup(&pdev->dev, incl_3d_channels,
 					   sizeof(incl_3d_channels), GFP_KERNEL);
@@ -330,10 +328,8 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 				   (struct iio_chan_spec *)indio_dev->channels,
 				   HID_USAGE_SENSOR_INCLINOMETER_3D,
 				   incl_state);
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->num_channels = ARRAY_SIZE(incl_3d_channels);
 	indio_dev->info = &incl_3d_info;
diff --git a/drivers/iio/orientation/hid-sensor-rotation.c b/drivers/iio/orientation/hid-sensor-rotation.c
index d74fee4b56c8..269ae2e6c095 100644
--- a/drivers/iio/orientation/hid-sensor-rotation.c
+++ b/drivers/iio/orientation/hid-sensor-rotation.c
@@ -338,16 +338,12 @@ static int hid_dev_rot_probe(struct platform_device *pdev)
 						 &rot_state->common_attributes,
 						 rotation_sensitivity_addresses,
 						 ARRAY_SIZE(rotation_sensitivity_addresses));
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	ret = dev_rot_parse_report(pdev, hsdev, hsdev->usage, rot_state);
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->channels = dev_rot_channels;
 	indio_dev->num_channels = ARRAY_SIZE(dev_rot_channels);
diff --git a/drivers/iio/position/hid-sensor-custom-intel-hinge.c b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
index 0b5e3f71e962..4c59d8a0e7cd 100644
--- a/drivers/iio/position/hid-sensor-custom-intel-hinge.c
+++ b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
@@ -287,10 +287,8 @@ static int hid_hinge_probe(struct platform_device *pdev)
 						 &st->common_attributes,
 						 hinge_sensitivity_addresses,
 						 ARRAY_SIZE(hinge_sensitivity_addresses));
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	indio_dev->num_channels = ARRAY_SIZE(hinge_channels);
 	indio_dev->channels = devm_kmemdup(&pdev->dev, hinge_channels,
@@ -301,10 +299,8 @@ static int hid_hinge_probe(struct platform_device *pdev)
 	ret = hinge_parse_report(pdev, hsdev,
 				 (struct iio_chan_spec *)indio_dev->channels,
 				 hsdev->usage, st);
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->info = &hinge_info;
 	indio_dev->name = "hinge";
diff --git a/drivers/iio/pressure/hid-sensor-press.c b/drivers/iio/pressure/hid-sensor-press.c
index 9506284bb798..2d098ed35ff6 100644
--- a/drivers/iio/pressure/hid-sensor-press.c
+++ b/drivers/iio/pressure/hid-sensor-press.c
@@ -251,10 +251,8 @@ static int hid_press_probe(struct platform_device *pdev)
 					&press_state->common_attributes,
 					press_sensitivity_addresses,
 					ARRAY_SIZE(press_sensitivity_addresses));
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	indio_dev->channels = devm_kmemdup(&pdev->dev, press_channels,
 					   sizeof(press_channels), GFP_KERNEL);
@@ -264,10 +262,8 @@ static int hid_press_probe(struct platform_device *pdev)
 	ret = press_parse_report(pdev, hsdev,
 				 (struct iio_chan_spec *)indio_dev->channels,
 				 HID_USAGE_SENSOR_PRESSURE, press_state);
-	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->num_channels =
 				ARRAY_SIZE(press_channels);

-- 
2.34.1

