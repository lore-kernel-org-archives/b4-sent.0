From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Sat, 19 Sep 2026 16:06:26 +0530
Subject: [PATCH v6 03/14] HID: hid-sensor-hub: introduce device managed API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-28-apr-iio-redundant-argument-v5-temp-v6-3-d577b2371b3c@gmail.com>
References: <20260919-28-apr-iio-redundant-argument-v5-temp-v6-0-d577b2371b3c@gmail.com>
In-Reply-To: <20260919-28-apr-iio-redundant-argument-v5-temp-v6-0-d577b2371b3c@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789814199; l=4401;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=X2I8hMTXE1/MLkTlWKifhsxsUQ6NP23KYfZXkjSBpog=;
 b=ZRinwmoJCRG3gJ5kdyYLdZx5Ac9AWx2SXTQZlP+Zocimt/3x9g7z6i7rH/heYcWUzk+aKvSEv
 d/WJO12XC4jDC/ztCQSZfhJBrSe/CAURBRv9K1LIyL0dGPp8e8sx+H8
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sensor_hub_register_callback() is common API used for the HID IIO drivers,
prepare devm API devm_sensor_hub_register_callback() to acquire resource
during setup and release using device managed framework during drivers
fail, unbind or remove path.

Store the required callback removal context (hsdev and usage_id) in a
dedicated struct sensor_hub_cb_devres, and register resources with
devres framework and helper API.

Suggested-by: Jonathan Cameron <jic23@kernel.org>
Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
Changes in v6:
- Add kernel-doc for return statement for the new devm_*() API, as
  suggested by Andy.
- Keep kernel-doc for new devm_*() API in public header file, along
  side where existing API documentation is available.
- With suggestion/input from Jonathan, use devres and cleanup frameworks
  together to implement device managed API support with less complexity.
---
 drivers/hid/hid-sensor-hub.c   | 35 +++++++++++++++++++++++++++++++++++
 include/linux/hid-sensor-hub.h | 26 ++++++++++++++++++++++++++
 2 files changed, 61 insertions(+)

diff --git a/drivers/hid/hid-sensor-hub.c b/drivers/hid/hid-sensor-hub.c
index 6470a290ebfc..de35e72b4d88 100644
--- a/drivers/hid/hid-sensor-hub.c
+++ b/drivers/hid/hid-sensor-hub.c
@@ -4,7 +4,9 @@
  * Copyright (c) 2012, Intel Corporation.
  */
 
+#include <linux/cleanup.h>
 #include <linux/device.h>
+#include <linux/device/devres.h>
 #include <linux/hid.h>
 #include <linux/module.h>
 #include <linux/slab.h>
@@ -187,6 +189,39 @@ int sensor_hub_remove_callback(struct hid_sensor_hub_device *hsdev,
 }
 EXPORT_SYMBOL_GPL(sensor_hub_remove_callback);
 
+DEFINE_FREE(devres_free, struct sensor_hub_cb_devres *, if (_T) devres_free(_T))
+
+static void devm_sensor_hub_remove_callback(struct device *dev, void *res)
+{
+	struct sensor_hub_cb_devres *dr = res;
+
+	sensor_hub_remove_callback(dr->hsdev, dr->usage_id);
+}
+
+int devm_sensor_hub_register_callback(struct device *dev,
+				      struct hid_sensor_hub_device *hsdev,
+				      u32 usage_id,
+				      struct hid_sensor_hub_callbacks *usage_callback)
+{
+	struct sensor_hub_cb_devres *dr __free(devres_free) = NULL;
+	int ret;
+
+	dr = devres_alloc(devm_sensor_hub_remove_callback, sizeof(*dr), GFP_KERNEL);
+	if (!dr)
+		return -ENOMEM;
+
+	ret = sensor_hub_register_callback(hsdev, usage_id, usage_callback);
+	if (ret)
+		return ret;
+
+	dr->hsdev = hsdev;
+	dr->usage_id = usage_id;
+	devres_add(dev, no_free_ptr(dr));
+
+	return 0;
+}
+EXPORT_SYMBOL_GPL(devm_sensor_hub_register_callback);
+
 int sensor_hub_set_feature(struct hid_sensor_hub_device *hsdev, u32 report_id,
 			   u32 field_index, int buffer_size, void *buffer)
 {
diff --git a/include/linux/hid-sensor-hub.h b/include/linux/hid-sensor-hub.h
index ab5cc8db3fbb..aa4ff9a95d86 100644
--- a/include/linux/hid-sensor-hub.h
+++ b/include/linux/hid-sensor-hub.h
@@ -79,6 +79,16 @@ struct hid_sensor_hub_device {
 	struct sensor_hub_pending pending;
 };
 
+/**
+ * struct sensor_hub_cb_devres - devres data for sensor hub callbacks
+ * @hsdev:	Hub device instance.
+ * @usage_id:	Usage ID associated with registered callback
+ */
+struct sensor_hub_cb_devres {
+	struct hid_sensor_hub_device *hsdev;
+	u32 usage_id;
+};
+
 /**
  * struct hid_sensor_hub_callbacks - Client callback functions
  * @pdev:		Platform device instance of the client driver.
@@ -143,6 +153,22 @@ int sensor_hub_register_callback(struct hid_sensor_hub_device *hsdev,
 int sensor_hub_remove_callback(struct hid_sensor_hub_device *hsdev,
 			u32 usage_id);
 
+/**
+ * devm_sensor_hub_register_callback() - Managed register client callbacks
+ * @dev: Device for resource management
+ * @hsdev: Hub device instance
+ * @usage_id: Usage id of the client (e.g. 0x200076 for Gyro)
+ * @usage_callback: Callback function storage
+ *
+ * This is the devres (managed) version of sensor_hub_register_callback().
+ * The callback will be automatically unregistered when the device is detached.
+
+ * Return: 0 on success, negative error code on failure.
+ */
+int devm_sensor_hub_register_callback(struct device *dev,
+				      struct hid_sensor_hub_device *hsdev,
+				      u32 usage_id,
+				      struct hid_sensor_hub_callbacks *usage_callback);
 
 /* Hid sensor hub core interfaces */
 

-- 
2.34.1

