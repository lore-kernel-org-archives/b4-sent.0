From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Thu, 05 Nov 2026 18:11:43 +0530
Subject: [PATCH 1/5] iio: Remove redundant probe error messages for HID
 device drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-19-oct-hid-iio-unified-print-framework-v1-1-0b360d9552d9@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793882513; l=10007;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=XV2z3tFhteTyo/o8BbdeZKmdc/LTZEfsUYtzauJOE7o=;
 b=O9sOes+JM7vc7Gn3CQ0n1Jdh2GMTtORpsWXU2ah1f4CVRTbumaOvb07bIlaKQcbSXDMnPej74
 tK8JvMoBH8mD0KpA4mFLLBwfsu6aBsx7PSZc14otAzHV66yk9+n8URV
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

devm_hid_sensor_setup_trigger() already logs an error when the request
fails for trigger allocation or registration failure, making the
explicit dev_err() redundant.

Similarly, devm_sensor_hub_register_callback() returns -EINVAL, -ENOMEM
or 0 (success), making the dev_err() in the probe path redundant.

Remove both messages from HID-IIO device drivers.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/accel/hid-sensor-accel-3d.c              | 8 ++------
 drivers/iio/gyro/hid-sensor-gyro-3d.c                | 8 ++------
 drivers/iio/light/hid-sensor-als.c                   | 8 ++------
 drivers/iio/light/hid-sensor-prox.c                  | 8 ++------
 drivers/iio/magnetometer/hid-sensor-magn-3d.c        | 8 ++------
 drivers/iio/orientation/hid-sensor-incl-3d.c         | 8 ++------
 drivers/iio/orientation/hid-sensor-rotation.c        | 8 ++------
 drivers/iio/position/hid-sensor-custom-intel-hinge.c | 8 ++------
 drivers/iio/pressure/hid-sensor-press.c              | 8 ++------
 9 files changed, 18 insertions(+), 54 deletions(-)

diff --git a/drivers/iio/accel/hid-sensor-accel-3d.c b/drivers/iio/accel/hid-sensor-accel-3d.c
index 7ba0228f18b4..51f1ae6b222f 100644
--- a/drivers/iio/accel/hid-sensor-accel-3d.c
+++ b/drivers/iio/accel/hid-sensor-accel-3d.c
@@ -377,20 +377,16 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &accel_state->common_attributes);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	accel_state->callbacks.send_event = accel_3d_proc_event;
 	accel_state->callbacks.capture_sample = accel_3d_capture_sample;
 	accel_state->callbacks.pdev = pdev;
 	ret = devm_sensor_hub_register_callback(dev, hsdev, hsdev->usage,
 						&accel_state->callbacks);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	return devm_iio_device_register(dev, indio_dev);
 }
diff --git a/drivers/iio/gyro/hid-sensor-gyro-3d.c b/drivers/iio/gyro/hid-sensor-gyro-3d.c
index 66778315e86d..ebf34365819c 100644
--- a/drivers/iio/gyro/hid-sensor-gyro-3d.c
+++ b/drivers/iio/gyro/hid-sensor-gyro-3d.c
@@ -314,10 +314,8 @@ static int hid_gyro_3d_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &gyro_state->common_attributes);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	gyro_state->callbacks.send_event = gyro_3d_proc_event;
 	gyro_state->callbacks.capture_sample = gyro_3d_capture_sample;
@@ -325,10 +323,8 @@ static int hid_gyro_3d_probe(struct platform_device *pdev)
 	ret = devm_sensor_hub_register_callback(dev, hsdev,
 						HID_USAGE_SENSOR_GYRO_3D,
 						&gyro_state->callbacks);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	return devm_iio_device_register(dev, indio_dev);
 }
diff --git a/drivers/iio/light/hid-sensor-als.c b/drivers/iio/light/hid-sensor-als.c
index 633fd1569987..88c7b1ce9a19 100644
--- a/drivers/iio/light/hid-sensor-als.c
+++ b/drivers/iio/light/hid-sensor-als.c
@@ -399,20 +399,16 @@ static int hid_als_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &als_state->common_attributes);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	als_state->callbacks.send_event = als_proc_event;
 	als_state->callbacks.capture_sample = als_capture_sample;
 	als_state->callbacks.pdev = pdev;
 	ret = devm_sensor_hub_register_callback(dev, hsdev, hsdev->usage,
 						&als_state->callbacks);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	return devm_iio_device_register(dev, indio_dev);
 }
diff --git a/drivers/iio/light/hid-sensor-prox.c b/drivers/iio/light/hid-sensor-prox.c
index 355b7b02868c..af4becb2e7dd 100644
--- a/drivers/iio/light/hid-sensor-prox.c
+++ b/drivers/iio/light/hid-sensor-prox.c
@@ -302,20 +302,16 @@ static int hid_prox_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &prox_state->common_attributes);
-	if (ret) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+	if (ret)
 		return ret;
-	}
 
 	prox_state->callbacks.send_event = prox_proc_event;
 	prox_state->callbacks.capture_sample = prox_capture_sample;
 	prox_state->callbacks.pdev = pdev;
 	ret = devm_sensor_hub_register_callback(dev, hsdev, hsdev->usage,
 						&prox_state->callbacks);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	return devm_iio_device_register(dev, indio_dev);
 }
diff --git a/drivers/iio/magnetometer/hid-sensor-magn-3d.c b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
index c8b4fa7785c9..911b15a5175d 100644
--- a/drivers/iio/magnetometer/hid-sensor-magn-3d.c
+++ b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
@@ -501,10 +501,8 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &magn_state->magn_flux_attributes);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	magn_state->callbacks.send_event = magn_3d_proc_event;
 	magn_state->callbacks.capture_sample = magn_3d_capture_sample;
@@ -512,10 +510,8 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 	ret = devm_sensor_hub_register_callback(dev, hsdev,
 						HID_USAGE_SENSOR_COMPASS_3D,
 						&magn_state->callbacks);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	return devm_iio_device_register(dev, indio_dev);
 }
diff --git a/drivers/iio/orientation/hid-sensor-incl-3d.c b/drivers/iio/orientation/hid-sensor-incl-3d.c
index b5f70732d035..4570a698cf0e 100644
--- a/drivers/iio/orientation/hid-sensor-incl-3d.c
+++ b/drivers/iio/orientation/hid-sensor-incl-3d.c
@@ -346,10 +346,8 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &incl_state->common_attributes);
-	if (ret) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+	if (ret)
 		return ret;
-	}
 
 	incl_state->callbacks.send_event = incl_3d_proc_event;
 	incl_state->callbacks.capture_sample = incl_3d_capture_sample;
@@ -357,10 +355,8 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 	ret = devm_sensor_hub_register_callback(dev, hsdev,
 						HID_USAGE_SENSOR_INCLINOMETER_3D,
 						&incl_state->callbacks);
-	if (ret) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+	if (ret)
 		return ret;
-	}
 
 	return devm_iio_device_register(dev, indio_dev);
 }
diff --git a/drivers/iio/orientation/hid-sensor-rotation.c b/drivers/iio/orientation/hid-sensor-rotation.c
index f97c278f16cb..d74fee4b56c8 100644
--- a/drivers/iio/orientation/hid-sensor-rotation.c
+++ b/drivers/iio/orientation/hid-sensor-rotation.c
@@ -359,20 +359,16 @@ static int hid_dev_rot_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &rot_state->common_attributes);
-	if (ret) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+	if (ret)
 		return ret;
-	}
 
 	rot_state->callbacks.send_event = dev_rot_proc_event;
 	rot_state->callbacks.capture_sample = dev_rot_capture_sample;
 	rot_state->callbacks.pdev = pdev;
 	ret = devm_sensor_hub_register_callback(dev, hsdev, hsdev->usage,
 						&rot_state->callbacks);
-	if (ret) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+	if (ret)
 		return ret;
-	}
 
 	return devm_iio_device_register(dev, indio_dev);
 }
diff --git a/drivers/iio/position/hid-sensor-custom-intel-hinge.c b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
index 101d84b533c9..0b5e3f71e962 100644
--- a/drivers/iio/position/hid-sensor-custom-intel-hinge.c
+++ b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
@@ -313,19 +313,15 @@ static int hid_hinge_probe(struct platform_device *pdev)
 	atomic_set(&st->common_attributes.data_ready, 0);
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, indio_dev->name,
 					    &st->common_attributes);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	st->callbacks.send_event = hinge_proc_event;
 	st->callbacks.capture_sample = hinge_capture_sample;
 	st->callbacks.pdev = pdev;
 	ret = devm_sensor_hub_register_callback(dev, hsdev, hsdev->usage, &st->callbacks);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	return devm_iio_device_register(dev, indio_dev);
 }
diff --git a/drivers/iio/pressure/hid-sensor-press.c b/drivers/iio/pressure/hid-sensor-press.c
index 8ebb8f54a0cb..b081990ffc03 100644
--- a/drivers/iio/pressure/hid-sensor-press.c
+++ b/drivers/iio/pressure/hid-sensor-press.c
@@ -281,10 +281,8 @@ static int hid_press_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &press_state->common_attributes);
-	if (ret) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+	if (ret)
 		return ret;
-	}
 
 	press_state->callbacks.send_event = press_proc_event;
 	press_state->callbacks.capture_sample = press_capture_sample;
@@ -292,10 +290,8 @@ static int hid_press_probe(struct platform_device *pdev)
 	ret = devm_sensor_hub_register_callback(dev, hsdev,
 						HID_USAGE_SENSOR_PRESSURE,
 						&press_state->callbacks);
-	if (ret < 0) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+	if (ret < 0)
 		return ret;
-	}
 
 	return devm_iio_device_register(dev, indio_dev);
 }

-- 
2.34.1

