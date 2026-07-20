From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Mon, 20 Jul 2026 15:10:20 +0530
Subject: [PATCH 08/10] iio: orientation: hid-sensor-rotation: use local
 struct device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hid-iio-local-struct-device-v1-8-74496fee6327@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784540423; l=3414;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=5/qXdvEQ0B9F64BZkAHHH7V+NgRa7Impnj2qIRjxP4Q=;
 b=cVVzT3tBshdolEVrxo3qxVbdqjBCh5wsAh1ITk3Yt7815M8Bv8dRw7uLu0FYRk3ZAMY3VWFSA
 +oh0B+u0ixjAipgf5doQIEgPHdLDwkmG1/KU35ZkA5iBuHEVvesE9bJ
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a local struct device pointer derived from &pdev->dev.
This avoids repeated &pdev->dev usage and improves readability.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/orientation/hid-sensor-rotation.c | 24 +++++++++++-------------
 1 file changed, 11 insertions(+), 13 deletions(-)

diff --git a/drivers/iio/orientation/hid-sensor-rotation.c b/drivers/iio/orientation/hid-sensor-rotation.c
index 9e13a0ecd584..50a684efeb45 100644
--- a/drivers/iio/orientation/hid-sensor-rotation.c
+++ b/drivers/iio/orientation/hid-sensor-rotation.c
@@ -238,6 +238,7 @@ static int dev_rot_parse_report(struct platform_device *pdev,
 				u32 usage_id,
 				struct dev_rot_state *st)
 {
+	struct device *dev = &pdev->dev;
 	int ret;
 
 	ret = sensor_hub_input_get_attribute_info(hsdev,
@@ -248,11 +249,8 @@ static int dev_rot_parse_report(struct platform_device *pdev,
 	if (ret)
 		return ret;
 
-	dev_dbg(&pdev->dev, "dev_rot %x:%x\n", st->quaternion.index,
-		st->quaternion.report_id);
-
-	dev_dbg(&pdev->dev, "dev_rot: attrib size %d\n",
-				st->quaternion.size);
+	dev_dbg(dev, "dev_rot %x:%x\n", st->quaternion.index, st->quaternion.report_id);
+	dev_dbg(dev, "dev_rot: attrib size %d\n", st->quaternion.size);
 
 	st->scale_precision = hid_sensor_format_scale(
 				hsdev->usage,
@@ -265,14 +263,14 @@ static int dev_rot_parse_report(struct platform_device *pdev,
 /* Function to initialize the processing for usage id */
 static int hid_dev_rot_probe(struct platform_device *pdev)
 {
-	struct hid_sensor_hub_device *hsdev = dev_get_platdata(&pdev->dev);
+	struct device *dev = &pdev->dev;
+	struct hid_sensor_hub_device *hsdev = dev_get_platdata(dev);
 	int ret;
 	char *name;
 	struct iio_dev *indio_dev;
 	struct dev_rot_state *rot_state;
 
-	indio_dev = devm_iio_device_alloc(&pdev->dev,
-					  sizeof(struct dev_rot_state));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(struct dev_rot_state));
 	if (!indio_dev)
 		return -ENOMEM;
 
@@ -302,13 +300,13 @@ static int hid_dev_rot_probe(struct platform_device *pdev)
 						 rotation_sensitivity_addresses,
 						 ARRAY_SIZE(rotation_sensitivity_addresses));
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup common attributes\n");
+		dev_err(dev, "failed to setup common attributes\n");
 		return ret;
 	}
 
 	ret = dev_rot_parse_report(pdev, hsdev, hsdev->usage, rot_state);
 	if (ret) {
-		dev_err(&pdev->dev, "failed to setup attributes\n");
+		dev_err(dev, "failed to setup attributes\n");
 		return ret;
 	}
 
@@ -323,7 +321,7 @@ static int hid_dev_rot_probe(struct platform_device *pdev)
 	ret = hid_sensor_setup_trigger(indio_dev, name,
 				       &rot_state->common_attributes);
 	if (ret) {
-		dev_err(&pdev->dev, "trigger setup failed\n");
+		dev_err(dev, "trigger setup failed\n");
 		return ret;
 	}
 
@@ -333,13 +331,13 @@ static int hid_dev_rot_probe(struct platform_device *pdev)
 	ret = sensor_hub_register_callback(hsdev, hsdev->usage,
 					   &rot_state->callbacks);
 	if (ret) {
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

