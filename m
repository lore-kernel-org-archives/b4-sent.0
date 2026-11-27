From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Fri, 27 Nov 2026 16:04:01 +0530
Subject: [PATCH v2 6/7] iio: Simplify trigger setup error checks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-19-oct-hid-iio-unified-print-framework-v2-6-3f476fe1a940@gmail.com>
References: <20261127-19-oct-hid-iio-unified-print-framework-v2-0-3f476fe1a940@gmail.com>
In-Reply-To: <20261127-19-oct-hid-iio-unified-print-framework-v2-0-3f476fe1a940@gmail.com>
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Joshua Crofts <crofts@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795775655; l=3522;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=pmCyyi/Q00a7W06XN+DdDqeCpGYAnLZhG3rV6Fd81Co=;
 b=VGrql/2ZZGijcxbJbKqbMEwcZ+cchfxxNM4xVRamqubMcJhGGLic7cLWpJmh/jpaTI5XR4LN9
 coRr998xlC9B/2d8MN+ZOpzgNwpiu4ZoxyAA01ZeQtwqhK7J8ZIwQ8z
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

devm_hid_sensor_setup_trigger() returns 0 on success and a
negative error code on failure. Replace open-coded error checks
using:
	if (ret < 0)
with:
	if (ret)
across HID sensor drivers using the helper.

This simplifies the code and aligns it with common kernel
error-handling style without changing behavior.

Suggested-by: Joshua Crofts <crofts@kernel.org>
Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/accel/hid-sensor-accel-3d.c              | 2 +-
 drivers/iio/gyro/hid-sensor-gyro-3d.c                | 2 +-
 drivers/iio/light/hid-sensor-als.c                   | 2 +-
 drivers/iio/magnetometer/hid-sensor-magn-3d.c        | 2 +-
 drivers/iio/position/hid-sensor-custom-intel-hinge.c | 2 +-
 5 files changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/accel/hid-sensor-accel-3d.c b/drivers/iio/accel/hid-sensor-accel-3d.c
index 414d62d2249f..d75ee16b8f45 100644
--- a/drivers/iio/accel/hid-sensor-accel-3d.c
+++ b/drivers/iio/accel/hid-sensor-accel-3d.c
@@ -372,7 +372,7 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &accel_state->common_attributes);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	accel_state->callbacks.send_event = accel_3d_proc_event;
diff --git a/drivers/iio/gyro/hid-sensor-gyro-3d.c b/drivers/iio/gyro/hid-sensor-gyro-3d.c
index cc81ac2ccdd1..d5acb38268af 100644
--- a/drivers/iio/gyro/hid-sensor-gyro-3d.c
+++ b/drivers/iio/gyro/hid-sensor-gyro-3d.c
@@ -308,7 +308,7 @@ static int hid_gyro_3d_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &gyro_state->common_attributes);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	gyro_state->callbacks.send_event = gyro_3d_proc_event;
diff --git a/drivers/iio/light/hid-sensor-als.c b/drivers/iio/light/hid-sensor-als.c
index ef864a2ba4b6..9b3c8d8345b9 100644
--- a/drivers/iio/light/hid-sensor-als.c
+++ b/drivers/iio/light/hid-sensor-als.c
@@ -409,7 +409,7 @@ static int hid_als_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &als_state->common_attributes);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	als_state->callbacks.send_event = als_proc_event;
diff --git a/drivers/iio/magnetometer/hid-sensor-magn-3d.c b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
index 3a8fbe1655dd..c179fcd364b9 100644
--- a/drivers/iio/magnetometer/hid-sensor-magn-3d.c
+++ b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
@@ -484,7 +484,7 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, name,
 					    &magn_state->magn_flux_attributes);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	magn_state->callbacks.send_event = magn_3d_proc_event;
diff --git a/drivers/iio/position/hid-sensor-custom-intel-hinge.c b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
index 4c59d8a0e7cd..9bc0262b27c4 100644
--- a/drivers/iio/position/hid-sensor-custom-intel-hinge.c
+++ b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
@@ -309,7 +309,7 @@ static int hid_hinge_probe(struct platform_device *pdev)
 	atomic_set(&st->common_attributes.data_ready, 0);
 	ret = devm_hid_sensor_setup_trigger(dev, indio_dev, indio_dev->name,
 					    &st->common_attributes);
-	if (ret < 0)
+	if (ret)
 		return ret;
 
 	st->callbacks.send_event = hinge_proc_event;

-- 
2.34.1

