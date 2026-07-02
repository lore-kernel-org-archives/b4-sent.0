From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Thu, 02 Jul 2026 21:48:00 +0530
Subject: [PATCH v2 3/6] iio: hid-sensors: Use implicit NULL pointer checks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260702-15-jun-hid-iio-alignment-v2-3-b87f01f5efbc@gmail.com>
References: <20260702-15-jun-hid-iio-alignment-v2-0-b87f01f5efbc@gmail.com>
In-Reply-To: <20260702-15-jun-hid-iio-alignment-v2-0-b87f01f5efbc@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Maxwell Doose <m32285159@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783009082; l=2751;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=owJksSx1dj5lBGugetx8eR38mlNEZXWL0V9RnRI1bTA=;
 b=J2Re/LF0jpUXJ/f0vGjv0UIgfPjwNTHsnp1woLJC6yNvcSxKFWkzAuZZdr9qo1EAbksq+zVU9
 DvDZqgZimZfBbJ0KYhCO5On+F3cBDSI1e3UBA+XSdok/jW6cy8z0zIJ
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace explicit NULL pointer comparisons with implicit checks across
HID sensor IIO drivers to follow the preferred kernel coding style.

Convert 'if (indio_dev == NULL)' -> 'if (!indio_dev)'.

No functional change.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Reviewed-by: Maxwell Doose <m32285159@gmail.com>
---
 drivers/iio/accel/hid-sensor-accel-3d.c       | 2 +-
 drivers/iio/magnetometer/hid-sensor-magn-3d.c | 2 +-
 drivers/iio/orientation/hid-sensor-incl-3d.c  | 2 +-
 drivers/iio/orientation/hid-sensor-rotation.c | 2 +-
 4 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/accel/hid-sensor-accel-3d.c b/drivers/iio/accel/hid-sensor-accel-3d.c
index 9197f3424c0c..225f8dd65ab1 100644
--- a/drivers/iio/accel/hid-sensor-accel-3d.c
+++ b/drivers/iio/accel/hid-sensor-accel-3d.c
@@ -325,7 +325,7 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 
 	indio_dev = devm_iio_device_alloc(&pdev->dev,
 					  sizeof(struct accel_3d_state));
-	if (indio_dev == NULL)
+	if (!indio_dev)
 		return -ENOMEM;
 
 	platform_set_drvdata(pdev, indio_dev);
diff --git a/drivers/iio/magnetometer/hid-sensor-magn-3d.c b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
index ad10fa20fae0..738bad65d74d 100644
--- a/drivers/iio/magnetometer/hid-sensor-magn-3d.c
+++ b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
@@ -463,7 +463,7 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 
 	indio_dev = devm_iio_device_alloc(&pdev->dev,
 					  sizeof(struct magn_3d_state));
-	if (indio_dev == NULL)
+	if (!indio_dev)
 		return -ENOMEM;
 
 	platform_set_drvdata(pdev, indio_dev);
diff --git a/drivers/iio/orientation/hid-sensor-incl-3d.c b/drivers/iio/orientation/hid-sensor-incl-3d.c
index 870c8929491e..c8efb0dab8b6 100644
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
index 2dad0453fc67..6db253c1635d 100644
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

