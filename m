From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Mon, 20 Jul 2026 15:10:16 +0530
Subject: [PATCH 04/10] iio: light: hid-sensor-als: use local struct device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hid-iio-local-struct-device-v1-4-74496fee6327@gmail.com>
References: <20260720-hid-iio-local-struct-device-v1-0-74496fee6327@gmail.com>
In-Reply-To: <20260720-hid-iio-local-struct-device-v1-0-74496fee6327@gmail.com>
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784540423; l=2688;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=F+9XUfQNCvbfNIZ2ifuF+mpRN7/StD6NN5AhbF5V6Y8=;
 b=Y+oYtiAJLpfMR6CVD19JRUm0qQnntcGFjkjixGjdZlhJsIWR58mOnAbfnVXlfLRkMEGkrfRa1
 U+LUfTprABvBrXvlxJgt5Y1Ao20GAjzSB+4H0gC0QOmO7TlQ00NSfd9
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a local struct device pointer derived from &pdev->dev.
This avoids repeated &pdev->dev usage and improves readability.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/light/hid-sensor-als.c | 15 ++++++++-------
 1 file changed, 8 insertions(+), 7 deletions(-)

diff --git a/drivers/iio/light/hid-sensor-als.c b/drivers/iio/light/hid-sensor-als.c
index 6fb6ace26834..44088f9dff81 100644
--- a/drivers/iio/light/hid-sensor-als.c
+++ b/drivers/iio/light/hid-sensor-als.c
@@ -346,13 +346,14 @@ static int als_parse_report(struct platform_device *pdev,
 /* Function to initialize the processing for usage id */
 static int hid_als_probe(struct platform_device *pdev)
 {
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
+	struct device *dev = &pdev->dev;
+	struct hid_sensor_hub_device *hsdev = dev_get_platdata(dev);
 	int ret = 0;
 	static const char *name = "als";
 	struct iio_dev *indio_dev;
 	struct als_state *als_state;
 
-	indio_dev = devm_iio_device_alloc(&pdev->dev, sizeof(struct als_state));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(struct als_state));
 	if (!indio_dev)
 		return -ENOMEM;
 	platform_set_drvdata(pdev, indio_dev);
@@ -367,7 +368,7 @@ static int hid_als_probe(struct platform_device *pdev)
 					als_sensitivity_addresses,
 					ARRAY_SIZE(als_sensitivity_addresses));
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
+		dev_err(dev, "failed to setup common attributes\n");
 		return ret;
 	}
 
@@ -375,7 +376,7 @@ static int hid_als_probe(struct platform_device *pdev)
 			       hsdev->usage,
 			       als_state);
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
+		dev_err(dev, "failed to setup attributes\n");
 		return ret;
 	}
 
@@ -397,7 +398,7 @@ static int hid_als_probe(struct platform_device *pdev)
 	ret = hid_sensor_setup_trigger(indio_dev, name,
 				       &als_state->common_attributes);
 	if (ret < 0) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+		dev_err(dev, "trigger setup failed\n");
 		return ret;
 	}
 
@@ -406,13 +407,13 @@ static int hid_als_probe(struct platform_device *pdev)
 	als_state->callbacks.pdev = pdev;
 	ret = sensor_hub_register_callback(hsdev, hsdev->usage, &als_state->callbacks);
 	if (ret < 0) {
-		dev_err(&pdev->dev, "callback reg failed\n");
+		dev_err(dev, "callback reg failed\n");
 		goto error_remove_trigger;
 	}
 
 	ret = iio_device_register(indio_dev);
 	if (ret) {
-		dev_err(&pdev->dev, "device register failed\n");
+		dev_err(dev, "device register failed\n");
 		goto error_remove_callback;
 	}
 

-- 
2.34.1

