From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Fri, 27 Nov 2026 16:04:02 +0530
Subject: [PATCH v2 7/7] iio: Simplify callback registration error checks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-19-oct-hid-iio-unified-print-framework-v2-7-3f476fe1a940@gmail.com>
References: <20261127-19-oct-hid-iio-unified-print-framework-v2-0-3f476fe1a940@gmail.com>
In-Reply-To: <20261127-19-oct-hid-iio-unified-print-framework-v2-0-3f476fe1a940@gmail.com>
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795775655; l=4750;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=mGLaKUDpq2xrxFyO4D1gwOJXhOtVXrnf8YKu9o1By3I=;
 b=JGK1JRUAMSKl0bz8dFdCKS6CwY6mNPNXmb74SMesd85P+fEuWcfvj3IYiSOyNOqfjC5HxJXMC
 4JVCEj+0rzZB1Y8ixrUjx+VrAUBnY1WNz2MnTSfGzulUyra3BQtsGsF
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

devm_sensor_hub_register_callback() returns 0 on success and a
negative error code on failure. Replace open-coded error checks
using:
	if (ret < 0)
with:
	if (ret)
across HID sensor drivers using the helper.

This simplifies the code and aligns it with common kernel
error-handling style without changing behavior.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/accel/hid-sensor-accel-3d.c              | 2 +-
 drivers/iio/gyro/hid-sensor-gyro-3d.c                | 2 +-
 drivers/iio/light/hid-sensor-als.c                   | 2 +-
 drivers/iio/light/hid-sensor-prox.c                  | 2 +-
 drivers/iio/magnetometer/hid-sensor-magn-3d.c        | 2 +-
 drivers/iio/position/hid-sensor-custom-intel-hinge.c | 2 +-
 drivers/iio/pressure/hid-sensor-press.c              | 2 +-
 7 files changed, 7 insertions(+), 7 deletions(-)

diff --git a/drivers/iio/accel/hid-sensor-accel-3d.c b/drivers/iio/accel/hid-sensor-accel-3d.c
index d75ee16b8f45..386dbbda57d4 100644
--- a/drivers/iio/accel/hid-sensor-accel-3d.c
+++ b/drivers/iio/accel/hid-sensor-accel-3d.c
@@ -380,7 +380,7 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 	accel_state->callbacks.pdev = pdev;
 	ret = devm_sensor_hub_register_callback(dev, hsdev, hsdev->usage,
 						&accel_state->callbacks);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	return devm_iio_device_register(dev, indio_dev);
diff --git a/drivers/iio/gyro/hid-sensor-gyro-3d.c b/drivers/iio/gyro/hid-sensor-gyro-3d.c
index d5acb38268af..c89e5a7a3222 100644
--- a/drivers/iio/gyro/hid-sensor-gyro-3d.c
+++ b/drivers/iio/gyro/hid-sensor-gyro-3d.c
@@ -317,7 +317,7 @@ static int hid_gyro_3d_probe(struct platform_device *pdev)
 	ret = devm_sensor_hub_register_callback(dev, hsdev,
 						HID_USAGE_SENSOR_GYRO_3D,
 						&gyro_state->callbacks);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	return devm_iio_device_register(dev, indio_dev);
diff --git a/drivers/iio/light/hid-sensor-als.c b/drivers/iio/light/hid-sensor-als.c
index 9b3c8d8345b9..a7783b947564 100644
--- a/drivers/iio/light/hid-sensor-als.c
+++ b/drivers/iio/light/hid-sensor-als.c
@@ -417,7 +417,7 @@ static int hid_als_probe(struct platform_device *pdev)
 	als_state->callbacks.pdev = pdev;
 	ret = devm_sensor_hub_register_callback(dev, hsdev, hsdev->usage,
 						&als_state->callbacks);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	return devm_iio_device_register(dev, indio_dev);
diff --git a/drivers/iio/light/hid-sensor-prox.c b/drivers/iio/light/hid-sensor-prox.c
index 4d0c7dffc252..b793d7abc0f5 100644
--- a/drivers/iio/light/hid-sensor-prox.c
+++ b/drivers/iio/light/hid-sensor-prox.c
@@ -306,7 +306,7 @@ static int hid_prox_probe(struct platform_device *pdev)
 	prox_state->callbacks.pdev = pdev;
 	ret = devm_sensor_hub_register_callback(dev, hsdev, hsdev->usage,
 						&prox_state->callbacks);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	return devm_iio_device_register(dev, indio_dev);
diff --git a/drivers/iio/magnetometer/hid-sensor-magn-3d.c b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
index c179fcd364b9..742dc4130e66 100644
--- a/drivers/iio/magnetometer/hid-sensor-magn-3d.c
+++ b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
@@ -493,7 +493,7 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 	ret = devm_sensor_hub_register_callback(dev, hsdev,
 						HID_USAGE_SENSOR_COMPASS_3D,
 						&magn_state->callbacks);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	return devm_iio_device_register(dev, indio_dev);
diff --git a/drivers/iio/position/hid-sensor-custom-intel-hinge.c b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
index 9bc0262b27c4..4773577dcd57 100644
--- a/drivers/iio/position/hid-sensor-custom-intel-hinge.c
+++ b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
@@ -316,7 +316,7 @@ static int hid_hinge_probe(struct platform_device *pdev)
 	st->callbacks.capture_sample = hinge_capture_sample;
 	st->callbacks.pdev = pdev;
 	ret = devm_sensor_hub_register_callback(dev, hsdev, hsdev->usage, &st->callbacks);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	return devm_iio_device_register(dev, indio_dev);
diff --git a/drivers/iio/pressure/hid-sensor-press.c b/drivers/iio/pressure/hid-sensor-press.c
index 2d098ed35ff6..8b41e1461993 100644
--- a/drivers/iio/pressure/hid-sensor-press.c
+++ b/drivers/iio/pressure/hid-sensor-press.c
@@ -284,7 +284,7 @@ static int hid_press_probe(struct platform_device *pdev)
 	ret = devm_sensor_hub_register_callback(dev, hsdev,
 						HID_USAGE_SENSOR_PRESSURE,
 						&press_state->callbacks);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	return devm_iio_device_register(dev, indio_dev);

-- 
2.34.1

