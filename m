From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Fri, 27 Nov 2026 16:03:57 +0530
Subject: [PATCH v2 2/7] iio: Remove redundant devm_kmemdup() allocation
 failure messages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-19-oct-hid-iio-unified-print-framework-v2-2-3f476fe1a940@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795775655; l=3473;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=GYfroI7CBTuLtaumkcLBm2D6Hmur3RtVQHOcYJz2ogE=;
 b=BGDTzPKzN/BeVJrvdEJkhbhtL5lLClYiMMVIkVsiPohuTfBfcbT7Fj0oHA2ufzJFFz5jnXQgH
 x649m2cIl75Ay1oeU4wlAPkTzGYznCwsCXtebU20/iIchkshEe5rX6B
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several HID IIO drivers print a dev_err() message before returning
-ENOMEM when devm_kmemdup() fails.

The failure is already conveyed by the returned error code and the log
messages do not provide additional debugging information. Remove the
redundant messages to reduce log noise.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/accel/hid-sensor-accel-3d.c      | 7 +++----
 drivers/iio/gyro/hid-sensor-gyro-3d.c        | 4 +---
 drivers/iio/orientation/hid-sensor-incl-3d.c | 4 +---
 drivers/iio/pressure/hid-sensor-press.c      | 4 +---
 4 files changed, 6 insertions(+), 13 deletions(-)

diff --git a/drivers/iio/accel/hid-sensor-accel-3d.c b/drivers/iio/accel/hid-sensor-accel-3d.c
index 51f1ae6b222f..f9e04ed2a7cd 100644
--- a/drivers/iio/accel/hid-sensor-accel-3d.c
+++ b/drivers/iio/accel/hid-sensor-accel-3d.c
@@ -354,13 +354,12 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 		dev_err(&pdev->dev, "failed to setup common attributes\n");
 		return ret;
 	}
+
 	indio_dev->channels = devm_kmemdup(&pdev->dev, channel_spec,
 					   channel_size, GFP_KERNEL);
-
-	if (!indio_dev->channels) {
-		dev_err(&pdev->dev, "failed to duplicate channels\n");
+	if (!indio_dev->channels)
 		return -ENOMEM;
-	}
+
 	ret = accel_3d_parse_report(pdev, hsdev,
 				    (struct iio_chan_spec *)indio_dev->channels,
 				    hsdev->usage, accel_state);
diff --git a/drivers/iio/gyro/hid-sensor-gyro-3d.c b/drivers/iio/gyro/hid-sensor-gyro-3d.c
index ebf34365819c..a785a9fc7f9d 100644
--- a/drivers/iio/gyro/hid-sensor-gyro-3d.c
+++ b/drivers/iio/gyro/hid-sensor-gyro-3d.c
@@ -292,10 +292,8 @@ static int hid_gyro_3d_probe(struct platform_device *pdev)
 
 	indio_dev->channels = devm_kmemdup(&pdev->dev, gyro_3d_channels,
 					   sizeof(gyro_3d_channels), GFP_KERNEL);
-	if (!indio_dev->channels) {
-		dev_err(&pdev->dev, "failed to duplicate channels\n");
+	if (!indio_dev->channels)
 		return -ENOMEM;
-	}
 
 	ret = gyro_3d_parse_report(pdev, hsdev,
 				   (struct iio_chan_spec *)indio_dev->channels,
diff --git a/drivers/iio/orientation/hid-sensor-incl-3d.c b/drivers/iio/orientation/hid-sensor-incl-3d.c
index 4570a698cf0e..2aed92c3526d 100644
--- a/drivers/iio/orientation/hid-sensor-incl-3d.c
+++ b/drivers/iio/orientation/hid-sensor-incl-3d.c
@@ -323,10 +323,8 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 
 	indio_dev->channels = devm_kmemdup(&pdev->dev, incl_3d_channels,
 					   sizeof(incl_3d_channels), GFP_KERNEL);
-	if (!indio_dev->channels) {
-		dev_err(&pdev->dev, "failed to duplicate channels\n");
+	if (!indio_dev->channels)
 		return -ENOMEM;
-	}
 
 	ret = incl_3d_parse_report(pdev, hsdev,
 				   (struct iio_chan_spec *)indio_dev->channels,
diff --git a/drivers/iio/pressure/hid-sensor-press.c b/drivers/iio/pressure/hid-sensor-press.c
index b081990ffc03..9506284bb798 100644
--- a/drivers/iio/pressure/hid-sensor-press.c
+++ b/drivers/iio/pressure/hid-sensor-press.c
@@ -258,10 +258,8 @@ static int hid_press_probe(struct platform_device *pdev)
 
 	indio_dev->channels = devm_kmemdup(&pdev->dev, press_channels,
 					   sizeof(press_channels), GFP_KERNEL);
-	if (!indio_dev->channels) {
-		dev_err(&pdev->dev, "failed to duplicate channels\n");
+	if (!indio_dev->channels)
 		return -ENOMEM;
-	}
 
 	ret = press_parse_report(pdev, hsdev,
 				 (struct iio_chan_spec *)indio_dev->channels,

-- 
2.34.1

