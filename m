From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Tue, 07 Jul 2026 00:29:44 +0530
Subject: [PATCH v3 2/2] iio: hid-sensors: Use implicit NULL pointer checks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-15-jun-hid-iio-alignment-v3-2-8791574ad0fe@gmail.com>
References: <20260707-15-jun-hid-iio-alignment-v3-0-8791574ad0fe@gmail.com>
In-Reply-To: <20260707-15-jun-hid-iio-alignment-v3-0-8791574ad0fe@gmail.com>
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Maxwell Doose <m32285159@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783364398; l=3664;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=3RAm/9fCDgZ6JcS6QdkUTQ3GjGLFQPfNTNuM9gSAv0g=;
 b=JOAOk6ZrE83ZQ2UWEXvSbWcZUqf6u7r4ZVp1uwCeqGnAy5UWgXu6lSxPC8Hd0FFoG4TFAaHel
 tKb9tKB2mh1CgOYeXpeoneaGPnoOGz2xrniBFf20xETQoSYVr9aM4eS
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace explicit NULL pointer comparisons with implicit checks across
HID sensor IIO drivers to fix kernel coding style.

CHECK: Comparison to NULL could be written ...

No functional change.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Reviewed-by: Maxwell Doose <m32285159@gmail.com>
---
 drivers/iio/accel/hid-sensor-accel-3d.c             | 2 +-
 drivers/iio/common/hid-sensors/hid-sensor-trigger.c | 2 +-
 drivers/iio/magnetometer/hid-sensor-magn-3d.c       | 4 ++--
 drivers/iio/orientation/hid-sensor-incl-3d.c        | 2 +-
 drivers/iio/orientation/hid-sensor-rotation.c       | 2 +-
 5 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/accel/hid-sensor-accel-3d.c b/drivers/iio/accel/hid-sensor-accel-3d.c
index 3986a0bdaf44..ccf27491d880 100644
--- a/drivers/iio/accel/hid-sensor-accel-3d.c
+++ b/drivers/iio/accel/hid-sensor-accel-3d.c
@@ -325,7 +325,7 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 
 	indio_dev = devm_iio_device_alloc(&pdev->dev,
 					  sizeof(struct accel_3d_state));
-	if (indio_dev == NULL)
+	if (!indio_dev)
 		return -ENOMEM;
 
 	platform_set_drvdata(pdev, indio_dev);
diff --git a/drivers/iio/common/hid-sensors/hid-sensor-trigger.c b/drivers/iio/common/hid-sensors/hid-sensor-trigger.c
index fffaebe8c7f0..60808e2430ca 100644
--- a/drivers/iio/common/hid-sensors/hid-sensor-trigger.c
+++ b/drivers/iio/common/hid-sensors/hid-sensor-trigger.c
@@ -266,7 +266,7 @@ int hid_sensor_setup_trigger(struct iio_dev *indio_dev, const char *name,
 
 	trig = iio_trigger_alloc(indio_dev->dev.parent,
 				 "%s-dev%d", name, iio_device_id(indio_dev));
-	if (trig == NULL) {
+	if (!trig) {
 		dev_err(&indio_dev->dev, "Trigger Allocate Failed\n");
 		return -ENOMEM;
 	}
diff --git a/drivers/iio/magnetometer/hid-sensor-magn-3d.c b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
index 6c95ce84067d..bbe52d4e924b 100644
--- a/drivers/iio/magnetometer/hid-sensor-magn-3d.c
+++ b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
@@ -322,7 +322,7 @@ static int magn_3d_capture_sample(struct hid_sensor_hub_device *hsdev,
 
 	iio_val = magn_state->magn_val_addr[offset];
 
-	if (iio_val != NULL)
+	if (iio_val)
 		*iio_val = *((u32 *)raw_data);
 	else
 		ret = -EINVAL;
@@ -461,7 +461,7 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 
 	indio_dev = devm_iio_device_alloc(&pdev->dev,
 					  sizeof(struct magn_3d_state));
-	if (indio_dev == NULL)
+	if (!indio_dev)
 		return -ENOMEM;
 
 	platform_set_drvdata(pdev, indio_dev);
diff --git a/drivers/iio/orientation/hid-sensor-incl-3d.c b/drivers/iio/orientation/hid-sensor-incl-3d.c
index 05c75e7246af..5cf0e6363811 100644
--- a/drivers/iio/orientation/hid-sensor-incl-3d.c
+++ b/drivers/iio/orientation/hid-sensor-incl-3d.c
@@ -302,7 +302,7 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 
 	indio_dev = devm_iio_device_alloc(&pdev->dev,
 					  sizeof(struct incl_3d_state));
-	if (indio_dev == NULL)
+	if (!indio_dev)
 		return -ENOMEM;
 
 	platform_set_drvdata(pdev, indio_dev);
diff --git a/drivers/iio/orientation/hid-sensor-rotation.c b/drivers/iio/orientation/hid-sensor-rotation.c
index bd918feb3617..412fb467a694 100644
--- a/drivers/iio/orientation/hid-sensor-rotation.c
+++ b/drivers/iio/orientation/hid-sensor-rotation.c
@@ -274,7 +274,7 @@ static int hid_dev_rot_probe(struct platform_device *pdev)
 
 	indio_dev = devm_iio_device_alloc(&pdev->dev,
 					  sizeof(struct dev_rot_state));
-	if (indio_dev == NULL)
+	if (!indio_dev)
 		return -ENOMEM;
 
 	platform_set_drvdata(pdev, indio_dev);

-- 
2.34.1

