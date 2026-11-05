From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Thu, 05 Nov 2026 18:11:47 +0530
Subject: [PATCH 5/5] iio: add probe error messages to hid humidity and
 temperature drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-19-oct-hid-iio-unified-print-framework-v1-5-0b360d9552d9@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793882514; l=2747;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=pqrTibW6X6wmyhSq73zPndRC7AMaVbRCIIh1jJudpww=;
 b=xYz2qJEQp8CP8Zje+A07HfMJ0cMKw5+tDlmZT9RtOt5bBGiufccWgXnBDojMFKZkqDortjY2G
 j52vb/dhz9DCJMh8byOnnUxjcB7/fHNLDV0Intqf4nrdzU8JNS04hA/
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hid_sensor_parse_common_attributes() and the driver-specific
*_parse_report() helpers may fail during probe without emitting any
diagnostic information. Add error messages for these failure paths so
that probe failures can be more easily identified from kernel logs,
while preserving the original error codes.

This also improves consistency with other HID IIO drivers that provide
probe-time diagnostics.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/humidity/hid-sensor-humidity.c       | 4 ++--
 drivers/iio/temperature/hid-sensor-temperature.c | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/humidity/hid-sensor-humidity.c b/drivers/iio/humidity/hid-sensor-humidity.c
index 12c88efe66be..ed7997056f69 100644
--- a/drivers/iio/humidity/hid-sensor-humidity.c
+++ b/drivers/iio/humidity/hid-sensor-humidity.c
@@ -214,7 +214,7 @@ static int hid_humidity_probe(struct platform_device *pdev)
 					humidity_sensitivity_addresses,
 					ARRAY_SIZE(humidity_sensitivity_addresses));
 	if (ret)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	humid_chans = devm_kmemdup(&pdev->dev, humidity_channels,
 				   sizeof(humidity_channels), GFP_KERNEL);
@@ -224,7 +224,7 @@ static int hid_humidity_probe(struct platform_device *pdev)
 	ret = humidity_parse_report(pdev, hsdev, humid_chans,
 				    HID_USAGE_SENSOR_HUMIDITY, humid_st);
 	if (ret)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->channels = humid_chans;
 	indio_dev->num_channels = ARRAY_SIZE(humidity_channels);
diff --git a/drivers/iio/temperature/hid-sensor-temperature.c b/drivers/iio/temperature/hid-sensor-temperature.c
index ac5a287d1de3..2dcf8cb375b1 100644
--- a/drivers/iio/temperature/hid-sensor-temperature.c
+++ b/drivers/iio/temperature/hid-sensor-temperature.c
@@ -211,7 +211,7 @@ static int hid_temperature_probe(struct platform_device *pdev)
 					temperature_sensitivity_addresses,
 					ARRAY_SIZE(temperature_sensitivity_addresses));
 	if (ret)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	temp_chans = devm_kmemdup(&pdev->dev, temperature_channels,
 				  sizeof(temperature_channels), GFP_KERNEL);
@@ -221,7 +221,7 @@ static int hid_temperature_probe(struct platform_device *pdev)
 	ret = temperature_parse_report(pdev, hsdev, temp_chans,
 				       HID_USAGE_SENSOR_TEMPERATURE, temp_st);
 	if (ret)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->channels = temp_chans;
 	indio_dev->num_channels = ARRAY_SIZE(temperature_channels);

-- 
2.34.1

