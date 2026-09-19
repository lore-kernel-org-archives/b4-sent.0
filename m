From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Sat, 19 Sep 2026 16:06:25 +0530
Subject: [PATCH v6 02/14] iio: hid-sensors: introduce device managed API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-28-apr-iio-redundant-argument-v5-temp-v6-2-d577b2371b3c@gmail.com>
References: <20260919-28-apr-iio-redundant-argument-v5-temp-v6-0-d577b2371b3c@gmail.com>
In-Reply-To: <20260919-28-apr-iio-redundant-argument-v5-temp-v6-0-d577b2371b3c@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Zhang Lixu <lixu.zhang@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789814199; l=2481;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=XJmRzPXaqhKqM4yIeSm5h1wY7VWEZl4o+Whwft4tGS0=;
 b=BXwiz67+9jDaGglzVLl6dzedMzSitLjFkaJLSbzCGi14P0Mq8uRfM/tYppwyWbZ+pRWDTPMyE
 oXr1WVgC4SoBM8BC2AzoN6DRhnb1C2quXz3Tfwz1bST/7lSFkZo19mx
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hid_sensor_setup_trigger() is common API used for the HID IIO drivers,
prepare devm API devm_hid_sensor_setup_trigger() to acquire resource
during setup and release using device managed framework during drivers
fail, unbind or remove path.

Register action with devm_add_action_or_reset() to release resource with
devres framework.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Tested-by: Zhang Lixu <lixu.zhang@intel.com>
---
 drivers/iio/common/hid-sensors/hid-sensor-trigger.c | 18 ++++++++++++++++++
 drivers/iio/common/hid-sensors/hid-sensor-trigger.h |  2 ++
 2 files changed, 20 insertions(+)

diff --git a/drivers/iio/common/hid-sensors/hid-sensor-trigger.c b/drivers/iio/common/hid-sensors/hid-sensor-trigger.c
index 6e6adc501602..df6c07d6a6b7 100644
--- a/drivers/iio/common/hid-sensors/hid-sensor-trigger.c
+++ b/drivers/iio/common/hid-sensors/hid-sensor-trigger.c
@@ -301,6 +301,24 @@ int hid_sensor_setup_trigger(struct iio_dev *indio_dev, const char *name,
 }
 EXPORT_SYMBOL_NS(hid_sensor_setup_trigger, "IIO_HID");
 
+static void hid_sensor_remove_trigger_action(void *attrb)
+{
+	hid_sensor_remove_trigger(attrb);
+}
+
+int devm_hid_sensor_setup_trigger(struct device *dev, struct iio_dev *indio_dev,
+				  const char *name, struct hid_sensor_common *attrb)
+{
+	int ret;
+
+	ret = hid_sensor_setup_trigger(indio_dev, name, attrb);
+	if (ret)
+		return ret;
+
+	return devm_add_action_or_reset(dev, hid_sensor_remove_trigger_action, attrb);
+}
+EXPORT_SYMBOL_NS(devm_hid_sensor_setup_trigger, "IIO_HID");
+
 static int __maybe_unused hid_sensor_suspend(struct device *dev)
 {
 	struct iio_dev *indio_dev = dev_get_drvdata(dev);
diff --git a/drivers/iio/common/hid-sensors/hid-sensor-trigger.h b/drivers/iio/common/hid-sensors/hid-sensor-trigger.h
index ee17d5cc2437..c4b901ca4879 100644
--- a/drivers/iio/common/hid-sensors/hid-sensor-trigger.h
+++ b/drivers/iio/common/hid-sensors/hid-sensor-trigger.h
@@ -17,6 +17,8 @@ extern const struct dev_pm_ops hid_sensor_pm_ops;
 int hid_sensor_setup_trigger(struct iio_dev *indio_dev, const char *name,
 			     struct hid_sensor_common *attrb);
 void hid_sensor_remove_trigger(struct hid_sensor_common *attrb);
+int devm_hid_sensor_setup_trigger(struct device *dev, struct iio_dev *indio_dev,
+				  const char *name, struct hid_sensor_common *attrb);
 int hid_sensor_power_state(struct hid_sensor_common *st, bool state);
 
 #endif

-- 
2.34.1

