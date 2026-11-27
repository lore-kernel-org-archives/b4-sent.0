From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Fri, 27 Nov 2026 16:04:00 +0530
Subject: [PATCH v2 5/7] iio: add probe error messages to hid humidity and
 temperature drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-19-oct-hid-iio-unified-print-framework-v2-5-3f476fe1a940@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795775655; l=2747;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=ZN+WHoqE9qU2ewu4pc1p2V/3TtyK73/jGZBLtNQtK8w=;
 b=dB/qKhcUNlC1QUpZbrpr9ulUu09qcXXAYyfTb90k97kqd0YbfgkOJP+ogvbZZRQt2lkj9XH9p
 wTmE7pJTrTyDnuozWdykqgjHc8QCFL7SuES4GqDSaW/FEkmK7y0+0pQ
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
index 95dc4c4726f2..388a7b02fa1d 100644
--- a/drivers/iio/humidity/hid-sensor-humidity.c
+++ b/drivers/iio/humidity/hid-sensor-humidity.c
@@ -210,7 +210,7 @@ static int hid_humidity_probe(struct platform_device *pdev)
 					humidity_sensitivity_addresses,
 					ARRAY_SIZE(humidity_sensitivity_addresses));
 	if (ret)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	humid_chans = devm_kmemdup(&pdev->dev, humidity_channels,
 				   sizeof(humidity_channels), GFP_KERNEL);
@@ -220,7 +220,7 @@ static int hid_humidity_probe(struct platform_device *pdev)
 	ret = humidity_parse_report(pdev, hsdev, humid_chans,
 				    HID_USAGE_SENSOR_HUMIDITY, humid_st);
 	if (ret)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->channels = humid_chans;
 	indio_dev->num_channels = ARRAY_SIZE(humidity_channels);
diff --git a/drivers/iio/temperature/hid-sensor-temperature.c b/drivers/iio/temperature/hid-sensor-temperature.c
index 6c112b444627..ef657c1cb043 100644
--- a/drivers/iio/temperature/hid-sensor-temperature.c
+++ b/drivers/iio/temperature/hid-sensor-temperature.c
@@ -207,7 +207,7 @@ static int hid_temperature_probe(struct platform_device *pdev)
 					temperature_sensitivity_addresses,
 					ARRAY_SIZE(temperature_sensitivity_addresses));
 	if (ret)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to setup common attributes\n");
 
 	temp_chans = devm_kmemdup(&pdev->dev, temperature_channels,
 				  sizeof(temperature_channels), GFP_KERNEL);
@@ -217,7 +217,7 @@ static int hid_temperature_probe(struct platform_device *pdev)
 	ret = temperature_parse_report(pdev, hsdev, temp_chans,
 				       HID_USAGE_SENSOR_TEMPERATURE, temp_st);
 	if (ret)
-		return ret;
+		return dev_err_probe(dev, ret, "failed to setup attributes\n");
 
 	indio_dev->channels = temp_chans;
 	indio_dev->num_channels = ARRAY_SIZE(temperature_channels);

-- 
2.34.1

