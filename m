From: Fabio Forni <development@redaril.me>
Date: Thu, 08 Oct 2026 23:27:59 +0200
Subject: [PATCH] iio: afe: iio-rescale: Add platform IDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-iio_rescale_platform_ids-v1-1-019f1c144022@redaril.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqDMBBA0avIrBuIoRjbq5QShmSiA9bIjEghe
 HeDy7f4v4KSMCm8uwpCByuXtaF/dBBnXCcynJrBWTf01o6GuQQhjbhQ2Bbcc5Ff4KTGJoc+YXz
 5J0LLN6HM/3v9+Z7nBX4+cQZqAAAA
X-Change-ID: 20261008-iio_rescale_platform_ids-0d2a7dac974a
To: Peter Rosin <peda@lysator.liu.se>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fabio Forni <development@redaril.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2514;
 i=development@redaril.me; h=from:subject:message-id;
 bh=lvuR+QebAMjMI31UmklRwBBfWEf2jwig4BQ8unLKdow=;
 b=kA0DAAoWgcJymq2hamcByyZiAGrICuChWTkRFreAg1lxyLYmsekEsNX+aIaBAxwp0zBFHYtBd
 4h1BAAWCgAdFiEE/0Iysos2NDLajxh9gcJymq2hamcFAmrICuAACgkQgcJymq2hamfjFQEAirpA
 ncsel/jCwPi3z1NCt4yT74lqYoQmcO1Z6l3mv9oBALiHrP0yg++SvBU4Rkdfvavd34K0penzEYU
 FhkxjwlAO
X-Developer-Key: i=development@redaril.me; a=openpgp;
 fpr=FF4232B28B363432DA8F187D81C2729AADA16A67
X-Endpoint-Received: by B4 Relay for development@redaril.me/default with auth_id=1033
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a rescaler is probed starting from a `struct swnode`,
device_get_match_data() will always set rescale->cfg to NULL,
because device_get_match_data() is unimplemented for software nodes.

This commit makes the probe function fall back to platform IDs when
it couldn't fetch the rescaler configuration from the match table.

Signed-off-by: Fabio Forni <development@redaril.me>
---
 drivers/iio/afe/iio-rescale.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/drivers/iio/afe/iio-rescale.c b/drivers/iio/afe/iio-rescale.c
index 3a6a09ffa526..fcdeeacedbe8 100644
--- a/drivers/iio/afe/iio-rescale.c
+++ b/drivers/iio/afe/iio-rescale.c
@@ -517,12 +517,28 @@ static const struct of_device_id rescale_match[] = {
 };
 MODULE_DEVICE_TABLE(of, rescale_match);
 
+static const struct platform_device_id rescale_platform_ids[] = {
+	{ .name = "current-sense-amplifier",
+	  .driver_data = CURRENT_SENSE_AMPLIFIER, },
+	{ .name = "current-sense-shunt",
+	  .driver_data = CURRENT_SENSE_SHUNT, },
+	{ .name = "voltage-divider",
+	  .driver_data = VOLTAGE_DIVIDER, },
+	{ .name = "temperature-sense-rtd",
+	  .driver_data = TEMP_SENSE_RTD, },
+	{ .name = "temperature-transducer",
+	  .driver_data = TEMP_TRANSDUCER, },
+	{ }
+};
+MODULE_DEVICE_TABLE(platform, rescale_platform_ids);
+
 static int rescale_probe(struct platform_device *pdev)
 {
 	struct device *dev = &pdev->dev;
 	struct iio_dev *indio_dev;
 	struct iio_channel *source;
 	struct rescale *rescale;
+	const struct platform_device_id *id;
 	int sizeof_ext_info;
 	int sizeof_priv;
 	int i;
@@ -548,6 +564,15 @@ static int rescale_probe(struct platform_device *pdev)
 	rescale = iio_priv(indio_dev);
 
 	rescale->cfg = device_get_match_data(dev);
+	if (!rescale->cfg) {
+		id = platform_get_device_id(pdev);
+		if (!id)
+			return dev_err_probe(dev,
+					     -EINVAL,
+					     "missing or invalid device configuration");
+
+		rescale->cfg = &rescale_cfg[id->driver_data];
+	}
 	rescale->numerator = 1;
 	rescale->denominator = 1;
 	rescale->offset = 0;
@@ -602,6 +627,7 @@ static struct platform_driver rescale_driver = {
 		.name = "iio-rescale",
 		.of_match_table = rescale_match,
 	},
+	.id_table = rescale_platform_ids,
 };
 module_platform_driver(rescale_driver);
 

---
base-commit: 6c377d19d4a5116d9bec5203aa3c6c11523e7898
change-id: 20261008-iio_rescale_platform_ids-0d2a7dac974a

Best regards,
-- 
Fabio Forni <development@redaril.me>

