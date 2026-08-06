From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Thu, 06 Aug 2026 17:55:49 +0530
Subject: [PATCH v5 03/13] HID: hid-sensor-hub: introduce device managed API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-28-apr-iio-redundant-argument-v5-temp-v5-3-f1f92c1d830f@gmail.com>
References: <20260806-28-apr-iio-redundant-argument-v5-temp-v5-0-f1f92c1d830f@gmail.com>
In-Reply-To: <20260806-28-apr-iio-redundant-argument-v5-temp-v5-0-f1f92c1d830f@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786019201; l=3632;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=E6NeHcHn1od2bjcFdG8WUYv/9lNEM6tJvVUI7ONP3w0=;
 b=JYVSUlbW7/7kXX43nB26KQ64ZWCJUNjHLe8ae/jXHO55V1lUuuI+ab73jw3FQ7IINPfYtSi/e
 TIn2NT4VigxCVb57E9lcYF7Kf85SoLH0LbsrSV8AzueVg1F3vEdmS22
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sensor_hub_register_callback() is common API used for the HID IIO drivers,
prepare devm API devm_sensor_hub_register_callback() to acquire resource
during setup and release using device managed framework during drivers
fail, unbind or remove path.

store the required callback removal context (hsdev and usage_id) in a
dedicated struct sensor_hub_cb_devres, and register a devres action to
handle to release resource with devres framework and helper API.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/hid/hid-sensor-hub.c   | 32 ++++++++++++++++++++++++++++++++
 include/linux/hid-sensor-hub.h | 24 ++++++++++++++++++++++++
 2 files changed, 56 insertions(+)

diff --git a/drivers/hid/hid-sensor-hub.c b/drivers/hid/hid-sensor-hub.c
index 90666ff629de..31dbdce27dc6 100644
--- a/drivers/hid/hid-sensor-hub.c
+++ b/drivers/hid/hid-sensor-hub.c
@@ -187,6 +187,38 @@ int sensor_hub_remove_callback(struct hid_sensor_hub_device *hsdev,
 }
 EXPORT_SYMBOL_GPL(sensor_hub_remove_callback);
 
+static void sensor_hub_remove_callback_helper(void *ptr)
+{
+	struct sensor_hub_cb_devres *res = ptr;
+
+	sensor_hub_remove_callback(res->hsdev, res->usage_id);
+}
+
+int devm_sensor_hub_register_callback(struct device *dev,
+				      struct hid_sensor_hub_device *hsdev,
+				      u32 usage_id,
+				      struct hid_sensor_hub_callbacks *usage_callback)
+{
+	struct sensor_hub_cb_devres *res;
+	int ret;
+
+	ret = sensor_hub_register_callback(hsdev, usage_id, usage_callback);
+	if (ret)
+		return ret;
+
+	res = devm_kmalloc(dev, sizeof(*res), GFP_KERNEL);
+	if (!res) {
+		sensor_hub_remove_callback(hsdev, usage_id);
+		return -ENOMEM;
+	}
+
+	res->hsdev = hsdev;
+	res->usage_id = usage_id;
+
+	return devm_add_action_or_reset(dev, sensor_hub_remove_callback_helper, res);
+}
+EXPORT_SYMBOL_GPL(devm_sensor_hub_register_callback);
+
 int sensor_hub_set_feature(struct hid_sensor_hub_device *hsdev, u32 report_id,
 			   u32 field_index, int buffer_size, void *buffer)
 {
diff --git a/include/linux/hid-sensor-hub.h b/include/linux/hid-sensor-hub.h
index e71056553108..c00347b15513 100644
--- a/include/linux/hid-sensor-hub.h
+++ b/include/linux/hid-sensor-hub.h
@@ -75,6 +75,16 @@ struct hid_sensor_hub_device {
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
@@ -139,6 +149,20 @@ int sensor_hub_register_callback(struct hid_sensor_hub_device *hsdev,
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
+ */
+int devm_sensor_hub_register_callback(struct device *dev,
+				      struct hid_sensor_hub_device *hsdev,
+				      u32 usage_id,
+				      struct hid_sensor_hub_callbacks *usage_callback);
 
 /* Hid sensor hub core interfaces */
 

-- 
2.34.1

