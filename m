From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Tue, 07 Jul 2026 00:29:43 +0530
Subject: [PATCH v3 1/2] iio: hid-sensors: align function parenthesis for
 readability
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260707-15-jun-hid-iio-alignment-v3-1-8791574ad0fe@gmail.com>
References: <20260707-15-jun-hid-iio-alignment-v3-0-8791574ad0fe@gmail.com>
In-Reply-To: <20260707-15-jun-hid-iio-alignment-v3-0-8791574ad0fe@gmail.com>
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783364398; l=50117;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=6oWcpzCDTyTilr+08qrpIt5rAVdVI5vJfxBR1tXZqOI=;
 b=6KyqX8eF/kFVzEbYSsKtTypvgKbND8vHV+KuMulF5+JM91xOynb+evGKZUHRsN0iurh01PDhE
 ONMt1eHvtZMAYIcUSRYxIAdDkNdA1wXQqNAI0VOA7emN3BOk9XP8II5
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adjust alignment of parentheses across HID sensor IIO drivers to
improve readability and maintain consistency with kernel coding style.

While updating the formatting, group related arguments consistently in
multi-line function signatures where appropriate.

No functional change intended.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/accel/hid-sensor-accel-3d.c            | 46 ++++++-------
 .../iio/common/hid-sensors/hid-sensor-attributes.c | 80 +++++++++++-----------
 .../iio/common/hid-sensors/hid-sensor-trigger.c    |  2 +-
 .../iio/common/hid-sensors/hid-sensor-trigger.h    |  2 +-
 drivers/iio/gyro/hid-sensor-gyro-3d.c              | 35 ++++------
 drivers/iio/humidity/hid-sensor-humidity.c         | 33 ++++-----
 drivers/iio/light/hid-sensor-als.c                 | 32 ++++-----
 drivers/iio/light/hid-sensor-prox.c                | 29 ++++----
 drivers/iio/magnetometer/hid-sensor-magn-3d.c      | 49 ++++++-------
 drivers/iio/orientation/hid-sensor-incl-3d.c       | 31 ++++-----
 drivers/iio/orientation/hid-sensor-rotation.c      | 24 +++----
 .../iio/position/hid-sensor-custom-intel-hinge.c   | 13 ++--
 drivers/iio/pressure/hid-sensor-press.c            | 35 ++++------
 drivers/iio/temperature/hid-sensor-temperature.c   | 30 ++++----
 14 files changed, 202 insertions(+), 239 deletions(-)

diff --git a/drivers/iio/accel/hid-sensor-accel-3d.c b/drivers/iio/accel/hid-sensor-accel-3d.c
index 12481cfe9800..3986a0bdaf44 100644
--- a/drivers/iio/accel/hid-sensor-accel-3d.c
+++ b/drivers/iio/accel/hid-sensor-accel-3d.c
@@ -122,9 +122,8 @@ static const struct iio_chan_spec gravity_channels[] = {
 
 /* Channel read_raw handler */
 static int accel_3d_read_raw(struct iio_dev *indio_dev,
-			      struct iio_chan_spec const *chan,
-			      int *val, int *val2,
-			      long mask)
+			     struct iio_chan_spec const *chan,
+			     int *val, int *val2, long mask)
 {
 	struct accel_3d_state *accel_state = iio_priv(indio_dev);
 	int report_id = -1;
@@ -151,7 +150,7 @@ static int accel_3d_read_raw(struct iio_dev *indio_dev,
 		else {
 			*val = 0;
 			hid_sensor_power_state(&accel_state->common_attributes,
-						 false);
+					       false);
 			return -EINVAL;
 		}
 		hid_sensor_power_state(&accel_state->common_attributes, false);
@@ -184,10 +183,8 @@ static int accel_3d_read_raw(struct iio_dev *indio_dev,
 
 /* Channel write_raw handler */
 static int accel_3d_write_raw(struct iio_dev *indio_dev,
-			       struct iio_chan_spec const *chan,
-			       int val,
-			       int val2,
-			       long mask)
+			      struct iio_chan_spec const *chan,
+			      int val, int val2, long mask)
 {
 	struct accel_3d_state *accel_state = iio_priv(indio_dev);
 	int ret = 0;
@@ -223,8 +220,7 @@ static void hid_sensor_push_data(struct iio_dev *indio_dev, void *data,
 
 /* Callback handler to send event after all samples are received and captured */
 static int accel_3d_proc_event(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				void *priv)
+			       u32 usage_id, void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct accel_3d_state *accel_state = iio_priv(indio_dev);
@@ -247,9 +243,9 @@ static int accel_3d_proc_event(struct hid_sensor_hub_device *hsdev,
 
 /* Capture samples in local storage */
 static int accel_3d_capture_sample(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				size_t raw_len, char *raw_data,
-				void *priv)
+				   u32 usage_id,
+				   size_t raw_len, char *raw_data,
+				   void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct accel_3d_state *accel_state = iio_priv(indio_dev);
@@ -281,10 +277,10 @@ static int accel_3d_capture_sample(struct hid_sensor_hub_device *hsdev,
 
 /* Parse report which is specific to an usage id*/
 static int accel_3d_parse_report(struct platform_device *pdev,
-				struct hid_sensor_hub_device *hsdev,
-				struct iio_chan_spec *channels,
-				u32 usage_id,
-				struct accel_3d_state *st)
+				 struct hid_sensor_hub_device *hsdev,
+				 struct iio_chan_spec *channels,
+				 u32 usage_id,
+				 struct accel_3d_state *st)
 {
 	int ret;
 
@@ -303,10 +299,10 @@ static int accel_3d_parse_report(struct platform_device *pdev,
 		};
 	}
 	dev_dbg(&pdev->dev, "accel_3d %x:%x, %x:%x, %x:%x\n",
-			st->accel[0].index,
-			st->accel[0].report_id,
-			st->accel[1].index, st->accel[1].report_id,
-			st->accel[2].index, st->accel[2].report_id);
+		st->accel[0].index,
+		st->accel[0].report_id,
+		st->accel[1].index, st->accel[1].report_id,
+		st->accel[2].index, st->accel[2].report_id);
 
 	st->scale_precision = hid_sensor_format_scale(
 				hsdev->usage,
@@ -366,8 +362,8 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 		return -ENOMEM;
 	}
 	ret = accel_3d_parse_report(pdev, hsdev,
-				(struct iio_chan_spec *)indio_dev->channels,
-				hsdev->usage, accel_state);
+				    (struct iio_chan_spec *)indio_dev->channels,
+				    hsdev->usage, accel_state);
 	if (ret) {
 		dev_err(&pdev->dev, "failed to setup attributes\n");
 		return ret;
@@ -380,7 +376,7 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 	atomic_set(&accel_state->common_attributes.data_ready, 0);
 
 	ret = hid_sensor_setup_trigger(indio_dev, name,
-					&accel_state->common_attributes);
+				       &accel_state->common_attributes);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "trigger setup failed\n");
 		return ret;
@@ -390,7 +386,7 @@ static int hid_accel_3d_probe(struct platform_device *pdev)
 	accel_state->callbacks.capture_sample = accel_3d_capture_sample;
 	accel_state->callbacks.pdev = pdev;
 	ret = sensor_hub_register_callback(hsdev, hsdev->usage,
-					&accel_state->callbacks);
+					   &accel_state->callbacks);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "callback reg failed\n");
 		goto error_remove_trigger;
diff --git a/drivers/iio/common/hid-sensors/hid-sensor-attributes.c b/drivers/iio/common/hid-sensors/hid-sensor-attributes.c
index 2f0a1ea42f48..9e7c26e37880 100644
--- a/drivers/iio/common/hid-sensors/hid-sensor-attributes.c
+++ b/drivers/iio/common/hid-sensors/hid-sensor-attributes.c
@@ -72,8 +72,7 @@ static const struct {
 	{HID_USAGE_SENSOR_HUMAN_ATTENTION, 0, 1, 0},
 };
 
-static void simple_div(int dividend, int divisor, int *whole,
-				int *micro_frac)
+static void simple_div(int dividend, int divisor, int *whole, int *micro_frac)
 {
 	int rem;
 	int exp = 0;
@@ -111,7 +110,7 @@ for 10^-2.
 Negative numbers are 2's complement
 */
 static void convert_from_vtf_format(u32 value, int size, int exp,
-					int *val1, int *val2)
+				    int *val1, int *val2)
 {
 	int sign = 1;
 
@@ -176,7 +175,7 @@ s32 hid_sensor_read_poll_value(struct hid_sensor_common *st)
 EXPORT_SYMBOL_NS(hid_sensor_read_poll_value, "IIO_HID_ATTRIBUTES");
 
 int hid_sensor_read_samp_freq_value(struct hid_sensor_common *st,
-				int *val1, int *val2)
+				    int *val1, int *val2)
 {
 	s32 value;
 	int ret;
@@ -203,7 +202,7 @@ int hid_sensor_read_samp_freq_value(struct hid_sensor_common *st,
 EXPORT_SYMBOL_NS(hid_sensor_read_samp_freq_value, "IIO_HID");
 
 int hid_sensor_write_samp_freq_value(struct hid_sensor_common *st,
-				int val1, int val2)
+				     int val1, int val2)
 {
 	s32 value;
 	int ret;
@@ -238,15 +237,15 @@ int hid_sensor_write_samp_freq_value(struct hid_sensor_common *st,
 EXPORT_SYMBOL_NS(hid_sensor_write_samp_freq_value, "IIO_HID");
 
 int hid_sensor_read_raw_hyst_value(struct hid_sensor_common *st,
-				int *val1, int *val2)
+				   int *val1, int *val2)
 {
 	s32 value;
 	int ret;
 
 	ret = sensor_hub_get_feature(st->hsdev,
 				     st->sensitivity.report_id,
-				     st->sensitivity.index, sizeof(value),
-				     &value);
+				     st->sensitivity.index,
+				     sizeof(value), &value);
 	if (ret < 0 || value < 0) {
 		*val1 = *val2 = 0;
 		return -EINVAL;
@@ -268,8 +267,8 @@ int hid_sensor_read_raw_hyst_rel_value(struct hid_sensor_common *st, int *val1,
 
 	ret = sensor_hub_get_feature(st->hsdev,
 				     st->sensitivity_rel.report_id,
-				     st->sensitivity_rel.index, sizeof(value),
-				     &value);
+				     st->sensitivity_rel.index,
+				     sizeof(value), &value);
 	if (ret < 0 || value < 0) {
 		*val1 = *val2 = 0;
 		return -EINVAL;
@@ -283,7 +282,7 @@ int hid_sensor_read_raw_hyst_rel_value(struct hid_sensor_common *st, int *val1,
 EXPORT_SYMBOL_NS(hid_sensor_read_raw_hyst_rel_value, "IIO_HID");
 
 int hid_sensor_write_raw_hyst_value(struct hid_sensor_common *st,
-					int val1, int val2)
+				    int val1, int val2)
 {
 	s32 value;
 	int ret;
@@ -292,8 +291,8 @@ int hid_sensor_write_raw_hyst_value(struct hid_sensor_common *st,
 		return -EINVAL;
 
 	value = convert_to_vtf_format(st->sensitivity.size,
-				st->sensitivity.unit_expo,
-				val1, val2);
+				      st->sensitivity.unit_expo,
+				      val1, val2);
 	ret = sensor_hub_set_feature(st->hsdev, st->sensitivity.report_id,
 				     st->sensitivity.index, sizeof(value),
 				     &value);
@@ -302,8 +301,8 @@ int hid_sensor_write_raw_hyst_value(struct hid_sensor_common *st,
 
 	ret = sensor_hub_get_feature(st->hsdev,
 				     st->sensitivity.report_id,
-				     st->sensitivity.index, sizeof(value),
-				     &value);
+				     st->sensitivity.index,
+				     sizeof(value), &value);
 	if (ret < 0 || value < 0)
 		return -EINVAL;
 
@@ -323,8 +322,8 @@ int hid_sensor_write_raw_hyst_rel_value(struct hid_sensor_common *st,
 		return -EINVAL;
 
 	value = convert_to_vtf_format(st->sensitivity_rel.size,
-				st->sensitivity_rel.unit_expo,
-				val1, val2);
+				      st->sensitivity_rel.unit_expo,
+				      val1, val2);
 	ret = sensor_hub_set_feature(st->hsdev, st->sensitivity_rel.report_id,
 				     st->sensitivity_rel.index, sizeof(value),
 				     &value);
@@ -333,8 +332,8 @@ int hid_sensor_write_raw_hyst_rel_value(struct hid_sensor_common *st,
 
 	ret = sensor_hub_get_feature(st->hsdev,
 				     st->sensitivity_rel.report_id,
-				     st->sensitivity_rel.index, sizeof(value),
-				     &value);
+				     st->sensitivity_rel.index,
+				     sizeof(value), &value);
 	if (ret < 0 || value < 0)
 		return -EINVAL;
 
@@ -355,8 +354,8 @@ EXPORT_SYMBOL_NS(hid_sensor_write_raw_hyst_rel_value, "IIO_HID");
  * 1.001745329 ->exp:4-> val0[10017]val1[453290000]
  * 9.806650000 ->exp:-2-> val0[0]val1[98066500]
  */
-static void adjust_exponent_nano(int *val0, int *val1, int scale0,
-				  int scale1, int exp)
+static void adjust_exponent_nano(int *val0, int *val1,
+				 int scale0, int scale1, int exp)
 {
 	int divisor;
 	int i;
@@ -403,8 +402,8 @@ static void adjust_exponent_nano(int *val0, int *val1, int scale0,
 }
 
 int hid_sensor_format_scale(u32 usage_id,
-			struct hid_sensor_hub_attribute_info *attr_info,
-			int *val0, int *val1)
+			    struct hid_sensor_hub_attribute_info *attr_info,
+			    int *val0, int *val1)
 {
 	int i;
 	int exp;
@@ -414,12 +413,11 @@ int hid_sensor_format_scale(u32 usage_id,
 
 	for (i = 0; i < ARRAY_SIZE(unit_conversion); ++i) {
 		if (unit_conversion[i].usage_id == usage_id &&
-			unit_conversion[i].unit == attr_info->units) {
-			exp  = hid_sensor_convert_exponent(
-						attr_info->unit_expo);
+		    unit_conversion[i].unit == attr_info->units) {
+			exp  = hid_sensor_convert_exponent(attr_info->unit_expo);
 			adjust_exponent_nano(val0, val1,
-					unit_conversion[i].scale_val0,
-					unit_conversion[i].scale_val1, exp);
+					     unit_conversion[i].scale_val0,
+					     unit_conversion[i].scale_val1, exp);
 			break;
 		}
 	}
@@ -437,8 +435,8 @@ EXPORT_SYMBOL_NS(hid_sensor_convert_timestamp, "IIO_HID");
 
 static
 int hid_sensor_get_reporting_interval(struct hid_sensor_hub_device *hsdev,
-					u32 usage_id,
-					struct hid_sensor_common *st)
+				      u32 usage_id,
+				      struct hid_sensor_common *st)
 {
 	sensor_hub_input_get_attribute_info(hsdev,
 					HID_FEATURE_REPORT, usage_id,
@@ -472,9 +470,10 @@ int hid_sensor_get_report_latency(struct hid_sensor_common *st)
 	int ret;
 	int value;
 
-	ret = sensor_hub_get_feature(st->hsdev, st->report_latency.report_id,
-				     st->report_latency.index, sizeof(value),
-				     &value);
+	ret = sensor_hub_get_feature(st->hsdev,
+				     st->report_latency.report_id,
+				     st->report_latency.index,
+				     sizeof(value), &value);
 	if (ret < 0)
 		return ret;
 
@@ -497,10 +496,10 @@ bool hid_sensor_batch_mode_supported(struct hid_sensor_common *st)
 EXPORT_SYMBOL_NS(hid_sensor_batch_mode_supported, "IIO_HID_ATTRIBUTES");
 
 int hid_sensor_parse_common_attributes(struct hid_sensor_hub_device *hsdev,
-					u32 usage_id,
-					struct hid_sensor_common *st,
-					const u32 *sensitivity_addresses,
-					u32 sensitivity_addresses_len)
+				       u32 usage_id,
+				       struct hid_sensor_common *st,
+				       const u32 *sensitivity_addresses,
+				       u32 sensitivity_addresses_len)
 {
 
 	struct hid_sensor_hub_attribute_info timestamp;
@@ -526,7 +525,7 @@ int hid_sensor_parse_common_attributes(struct hid_sensor_hub_device *hsdev,
 	sensor_hub_input_get_attribute_info(hsdev,
 			HID_FEATURE_REPORT, usage_id,
 			HID_USAGE_SENSOR_PROP_SENSITIVITY_ABS,
-			 &st->sensitivity);
+			&st->sensitivity);
 
 	sensor_hub_input_get_attribute_info(hsdev,
 			HID_FEATURE_REPORT, usage_id,
@@ -577,8 +576,9 @@ int hid_sensor_parse_common_attributes(struct hid_sensor_hub_device *hsdev,
 		timestamp.index, timestamp.report_id);
 
 	ret = sensor_hub_get_feature(hsdev,
-				st->power_state.report_id,
-				st->power_state.index, sizeof(value), &value);
+				     st->power_state.report_id,
+				     st->power_state.index,
+				     sizeof(value), &value);
 	if (ret < 0)
 		return ret;
 	if (value < 0)
diff --git a/drivers/iio/common/hid-sensors/hid-sensor-trigger.c b/drivers/iio/common/hid-sensors/hid-sensor-trigger.c
index c8ccf96f3d03..fffaebe8c7f0 100644
--- a/drivers/iio/common/hid-sensors/hid-sensor-trigger.c
+++ b/drivers/iio/common/hid-sensors/hid-sensor-trigger.c
@@ -233,7 +233,7 @@ void hid_sensor_remove_trigger(struct iio_dev *indio_dev,
 EXPORT_SYMBOL_NS(hid_sensor_remove_trigger, "IIO_HID");
 
 int hid_sensor_setup_trigger(struct iio_dev *indio_dev, const char *name,
-				struct hid_sensor_common *attrb)
+			     struct hid_sensor_common *attrb)
 {
 	const struct iio_dev_attr **fifo_attrs;
 	int ret;
diff --git a/drivers/iio/common/hid-sensors/hid-sensor-trigger.h b/drivers/iio/common/hid-sensors/hid-sensor-trigger.h
index f94fca4f1edf..589de858e369 100644
--- a/drivers/iio/common/hid-sensors/hid-sensor-trigger.h
+++ b/drivers/iio/common/hid-sensors/hid-sensor-trigger.h
@@ -15,7 +15,7 @@ struct iio_dev;
 extern const struct dev_pm_ops hid_sensor_pm_ops;
 
 int hid_sensor_setup_trigger(struct iio_dev *indio_dev, const char *name,
-				struct hid_sensor_common *attrb);
+			     struct hid_sensor_common *attrb);
 void hid_sensor_remove_trigger(struct iio_dev *indio_dev,
 			       struct hid_sensor_common *attrb);
 int hid_sensor_power_state(struct hid_sensor_common *st, bool state);
diff --git a/drivers/iio/gyro/hid-sensor-gyro-3d.c b/drivers/iio/gyro/hid-sensor-gyro-3d.c
index c8130b488f10..34ab18fffc31 100644
--- a/drivers/iio/gyro/hid-sensor-gyro-3d.c
+++ b/drivers/iio/gyro/hid-sensor-gyro-3d.c
@@ -85,9 +85,8 @@ static const struct iio_chan_spec gyro_3d_channels[] = {
 
 /* Channel read_raw handler */
 static int gyro_3d_read_raw(struct iio_dev *indio_dev,
-			      struct iio_chan_spec const *chan,
-			      int *val, int *val2,
-			      long mask)
+			    struct iio_chan_spec const *chan,
+			    int *val, int *val2, long mask)
 {
 	struct gyro_3d_state *gyro_state = iio_priv(indio_dev);
 	int report_id = -1;
@@ -112,8 +111,7 @@ static int gyro_3d_read_raw(struct iio_dev *indio_dev,
 					min < 0);
 		else {
 			*val = 0;
-			hid_sensor_power_state(&gyro_state->common_attributes,
-						false);
+			hid_sensor_power_state(&gyro_state->common_attributes, false);
 			return -EINVAL;
 		}
 		hid_sensor_power_state(&gyro_state->common_attributes, false);
@@ -146,10 +144,8 @@ static int gyro_3d_read_raw(struct iio_dev *indio_dev,
 
 /* Channel write_raw handler */
 static int gyro_3d_write_raw(struct iio_dev *indio_dev,
-			       struct iio_chan_spec const *chan,
-			       int val,
-			       int val2,
-			       long mask)
+			     struct iio_chan_spec const *chan,
+			     int val, int val2, long mask)
 {
 	struct gyro_3d_state *gyro_state = iio_priv(indio_dev);
 	int ret = 0;
@@ -177,8 +173,7 @@ static const struct iio_info gyro_3d_info = {
 
 /* Callback handler to send event after all samples are received and captured */
 static int gyro_3d_proc_event(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				void *priv)
+			      u32 usage_id, void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct gyro_3d_state *gyro_state = iio_priv(indio_dev);
@@ -199,9 +194,9 @@ static int gyro_3d_proc_event(struct hid_sensor_hub_device *hsdev,
 
 /* Capture samples in local storage */
 static int gyro_3d_capture_sample(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				size_t raw_len, char *raw_data,
-				void *priv)
+				  u32 usage_id,
+				  size_t raw_len, char *raw_data,
+				  void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct gyro_3d_state *gyro_state = iio_priv(indio_dev);
@@ -254,10 +249,10 @@ static int gyro_3d_parse_report(struct platform_device *pdev,
 		};
 	}
 	dev_dbg(&pdev->dev, "gyro_3d %x:%x, %x:%x, %x:%x\n",
-			st->gyro[0].index,
-			st->gyro[0].report_id,
-			st->gyro[1].index, st->gyro[1].report_id,
-			st->gyro[2].index, st->gyro[2].report_id);
+		st->gyro[0].index,
+		st->gyro[0].report_id,
+		st->gyro[1].index, st->gyro[1].report_id,
+		st->gyro[2].index, st->gyro[2].report_id);
 
 	st->scale_precision = hid_sensor_format_scale(
 				HID_USAGE_SENSOR_GYRO_3D,
@@ -318,7 +313,7 @@ static int hid_gyro_3d_probe(struct platform_device *pdev)
 	atomic_set(&gyro_state->common_attributes.data_ready, 0);
 
 	ret = hid_sensor_setup_trigger(indio_dev, name,
-					&gyro_state->common_attributes);
+				       &gyro_state->common_attributes);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "trigger setup failed\n");
 		return ret;
@@ -328,7 +323,7 @@ static int hid_gyro_3d_probe(struct platform_device *pdev)
 	gyro_state->callbacks.capture_sample = gyro_3d_capture_sample;
 	gyro_state->callbacks.pdev = pdev;
 	ret = sensor_hub_register_callback(hsdev, HID_USAGE_SENSOR_GYRO_3D,
-					&gyro_state->callbacks);
+					   &gyro_state->callbacks);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "callback reg failed\n");
 		goto error_remove_trigger;
diff --git a/drivers/iio/humidity/hid-sensor-humidity.c b/drivers/iio/humidity/hid-sensor-humidity.c
index 1d4612a471db..4338147e3641 100644
--- a/drivers/iio/humidity/hid-sensor-humidity.c
+++ b/drivers/iio/humidity/hid-sensor-humidity.c
@@ -45,7 +45,7 @@ static const struct iio_chan_spec humidity_channels[] = {
 
 /* Adjust channel real bits based on report descriptor */
 static void humidity_adjust_channel_bit_mask(struct iio_chan_spec *channels,
-					int channel, int size)
+					     int channel, int size)
 {
 	channels[channel].scan_type.sign = 's';
 	/* Real storage bits will change based on the report desc. */
@@ -55,8 +55,8 @@ static void humidity_adjust_channel_bit_mask(struct iio_chan_spec *channels,
 }
 
 static int humidity_read_raw(struct iio_dev *indio_dev,
-				struct iio_chan_spec const *chan,
-				int *val, int *val2, long mask)
+			     struct iio_chan_spec const *chan,
+			     int *val, int *val2, long mask)
 {
 	struct hid_humidity_state *humid_st = iio_priv(indio_dev);
 
@@ -101,8 +101,8 @@ static int humidity_read_raw(struct iio_dev *indio_dev,
 }
 
 static int humidity_write_raw(struct iio_dev *indio_dev,
-				struct iio_chan_spec const *chan,
-				int val, int val2, long mask)
+			      struct iio_chan_spec const *chan,
+			      int val, int val2, long mask)
 {
 	struct hid_humidity_state *humid_st = iio_priv(indio_dev);
 
@@ -127,7 +127,7 @@ static const struct iio_info humidity_info = {
 
 /* Callback handler to send event after all samples are received and captured */
 static int humidity_proc_event(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id, void *pdev)
+			       u32 usage_id, void *pdev)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(pdev);
 	struct hid_humidity_state *humid_st = iio_priv(indio_dev);
@@ -141,8 +141,9 @@ static int humidity_proc_event(struct hid_sensor_hub_device *hsdev,
 
 /* Capture samples in local storage */
 static int humidity_capture_sample(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id, size_t raw_len,
-				char *raw_data, void *pdev)
+				   u32 usage_id,
+				   size_t raw_len, char *raw_data,
+				   void *pdev)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(pdev);
 	struct hid_humidity_state *humid_st = iio_priv(indio_dev);
@@ -159,10 +160,10 @@ static int humidity_capture_sample(struct hid_sensor_hub_device *hsdev,
 
 /* Parse report which is specific to an usage id */
 static int humidity_parse_report(struct platform_device *pdev,
-				struct hid_sensor_hub_device *hsdev,
-				struct iio_chan_spec *channels,
-				u32 usage_id,
-				struct hid_humidity_state *st)
+				 struct hid_sensor_hub_device *hsdev,
+				 struct iio_chan_spec *channels,
+				 u32 usage_id,
+				 struct hid_humidity_state *st)
 {
 	int ret;
 
@@ -216,12 +217,12 @@ static int hid_humidity_probe(struct platform_device *pdev)
 		return ret;
 
 	humid_chans = devm_kmemdup(&pdev->dev, humidity_channels,
-					sizeof(humidity_channels), GFP_KERNEL);
+				   sizeof(humidity_channels), GFP_KERNEL);
 	if (!humid_chans)
 		return -ENOMEM;
 
 	ret = humidity_parse_report(pdev, hsdev, humid_chans,
-				HID_USAGE_SENSOR_HUMIDITY, humid_st);
+				    HID_USAGE_SENSOR_HUMIDITY, humid_st);
 	if (ret)
 		return ret;
 
@@ -234,7 +235,7 @@ static int hid_humidity_probe(struct platform_device *pdev)
 	atomic_set(&humid_st->common_attributes.data_ready, 0);
 
 	ret = hid_sensor_setup_trigger(indio_dev, name,
-				&humid_st->common_attributes);
+				       &humid_st->common_attributes);
 	if (ret)
 		return ret;
 
@@ -242,7 +243,7 @@ static int hid_humidity_probe(struct platform_device *pdev)
 
 	humidity_callbacks.pdev = pdev;
 	ret = sensor_hub_register_callback(hsdev, HID_USAGE_SENSOR_HUMIDITY,
-					&humidity_callbacks);
+					   &humidity_callbacks);
 	if (ret)
 		goto error_remove_trigger;
 
diff --git a/drivers/iio/light/hid-sensor-als.c b/drivers/iio/light/hid-sensor-als.c
index 823bb56b9873..666788285255 100644
--- a/drivers/iio/light/hid-sensor-als.c
+++ b/drivers/iio/light/hid-sensor-als.c
@@ -120,9 +120,8 @@ static const struct iio_chan_spec als_channels[] = {
 
 /* Channel read_raw handler */
 static int als_read_raw(struct iio_dev *indio_dev,
-			      struct iio_chan_spec const *chan,
-			      int *val, int *val2,
-			      long mask)
+			struct iio_chan_spec const *chan,
+			int *val, int *val2, long mask)
 {
 	struct als_state *als_state = iio_priv(indio_dev);
 	struct hid_sensor_hub_device *hsdev = als_state->common_attributes.hsdev;
@@ -163,12 +162,12 @@ static int als_read_raw(struct iio_dev *indio_dev,
 		}
 		if (report_id >= 0) {
 			hid_sensor_power_state(&als_state->common_attributes,
-						true);
+					       true);
 			*val = sensor_hub_input_attr_get_raw_value(
 					hsdev, hsdev->usage, address, report_id,
 					SENSOR_HUB_SYNC, min < 0);
 			hid_sensor_power_state(&als_state->common_attributes,
-						false);
+					       false);
 		} else {
 			*val = 0;
 			return -EINVAL;
@@ -206,10 +205,8 @@ static int als_read_raw(struct iio_dev *indio_dev,
 
 /* Channel write_raw handler */
 static int als_write_raw(struct iio_dev *indio_dev,
-			       struct iio_chan_spec const *chan,
-			       int val,
-			       int val2,
-			       long mask)
+			 struct iio_chan_spec const *chan,
+			 int val, int val2, long mask)
 {
 	struct als_state *als_state = iio_priv(indio_dev);
 	int ret = 0;
@@ -241,8 +238,7 @@ static const struct iio_info als_info = {
 
 /* Callback handler to send event after all samples are received and captured */
 static int als_proc_event(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				void *priv)
+			  u32 usage_id, void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct als_state *als_state = iio_priv(indio_dev);
@@ -263,9 +259,9 @@ static int als_proc_event(struct hid_sensor_hub_device *hsdev,
 
 /* Capture samples in local storage */
 static int als_capture_sample(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				size_t raw_len, char *raw_data,
-				void *priv)
+			      u32 usage_id,
+			      size_t raw_len, char *raw_data,
+			      void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct als_state *als_state = iio_priv(indio_dev);
@@ -304,9 +300,9 @@ static int als_capture_sample(struct hid_sensor_hub_device *hsdev,
 
 /* Parse report which is specific to an usage id*/
 static int als_parse_report(struct platform_device *pdev,
-				struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				struct als_state *st)
+			    struct hid_sensor_hub_device *hsdev,
+			    u32 usage_id,
+			    struct als_state *st)
 {
 	struct iio_chan_spec *channels;
 	int ret, index = 0;
@@ -400,7 +396,7 @@ static int hid_als_probe(struct platform_device *pdev)
 	atomic_set(&als_state->common_attributes.data_ready, 0);
 
 	ret = hid_sensor_setup_trigger(indio_dev, name,
-				&als_state->common_attributes);
+				       &als_state->common_attributes);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "trigger setup failed\n");
 		return ret;
diff --git a/drivers/iio/light/hid-sensor-prox.c b/drivers/iio/light/hid-sensor-prox.c
index 11609dc4c5dc..7541947f931c 100644
--- a/drivers/iio/light/hid-sensor-prox.c
+++ b/drivers/iio/light/hid-sensor-prox.c
@@ -70,9 +70,8 @@ static const struct iio_chan_spec prox_channels[] = {
 
 /* Channel read_raw handler */
 static int prox_read_raw(struct iio_dev *indio_dev,
-			      struct iio_chan_spec const *chan,
-			      int *val, int *val2,
-			      long mask)
+			 struct iio_chan_spec const *chan,
+			 int *val, int *val2, long mask)
 {
 	struct prox_state *prox_state = iio_priv(indio_dev);
 	struct hid_sensor_hub_device *hsdev;
@@ -135,10 +134,8 @@ static int prox_read_raw(struct iio_dev *indio_dev,
 
 /* Channel write_raw handler */
 static int prox_write_raw(struct iio_dev *indio_dev,
-			       struct iio_chan_spec const *chan,
-			       int val,
-			       int val2,
-			       long mask)
+			  struct iio_chan_spec const *chan,
+			  int val, int val2, long mask)
 {
 	struct prox_state *prox_state = iio_priv(indio_dev);
 	int ret = 0;
@@ -166,8 +163,7 @@ static const struct iio_info prox_info = {
 
 /* Callback handler to send event after all samples are received and captured */
 static int prox_proc_event(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				void *priv)
+			   u32 usage_id, void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct prox_state *prox_state = iio_priv(indio_dev);
@@ -183,9 +179,9 @@ static int prox_proc_event(struct hid_sensor_hub_device *hsdev,
 
 /* Capture samples in local storage */
 static int prox_capture_sample(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				size_t raw_len, char *raw_data,
-				void *priv)
+			       u32 usage_id,
+			       size_t raw_len, char *raw_data,
+			       void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct prox_state *prox_state = iio_priv(indio_dev);
@@ -218,8 +214,8 @@ static int prox_capture_sample(struct hid_sensor_hub_device *hsdev,
 
 /* Parse report which is specific to an usage id*/
 static int prox_parse_report(struct platform_device *pdev,
-				struct hid_sensor_hub_device *hsdev,
-				struct prox_state *st)
+			     struct hid_sensor_hub_device *hsdev,
+			     struct prox_state *st)
 {
 	struct iio_chan_spec *channels = st->channels;
 	int index = 0;
@@ -271,8 +267,7 @@ static int hid_prox_probe(struct platform_device *pdev)
 	struct iio_dev *indio_dev;
 	struct prox_state *prox_state;
 
-	indio_dev = devm_iio_device_alloc(&pdev->dev,
-				sizeof(struct prox_state));
+	indio_dev = devm_iio_device_alloc(&pdev->dev, sizeof(struct prox_state));
 	if (!indio_dev)
 		return -ENOMEM;
 	platform_set_drvdata(pdev, indio_dev);
@@ -306,7 +301,7 @@ static int hid_prox_probe(struct platform_device *pdev)
 	atomic_set(&prox_state->common_attributes.data_ready, 0);
 
 	ret = hid_sensor_setup_trigger(indio_dev, name,
-				&prox_state->common_attributes);
+				       &prox_state->common_attributes);
 	if (ret) {
 		dev_err(&pdev->dev, "trigger setup failed\n");
 		return ret;
diff --git a/drivers/iio/magnetometer/hid-sensor-magn-3d.c b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
index acae77273bd5..6c95ce84067d 100644
--- a/drivers/iio/magnetometer/hid-sensor-magn-3d.c
+++ b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
@@ -135,9 +135,8 @@ static const struct iio_chan_spec magn_3d_channels[] = {
 
 /* Channel read_raw handler */
 static int magn_3d_read_raw(struct iio_dev *indio_dev,
-			      struct iio_chan_spec const *chan,
-			      int *val, int *val2,
-			      long mask)
+			    struct iio_chan_spec const *chan,
+			    int *val, int *val2, long mask)
 {
 	struct magn_3d_state *magn_state = iio_priv(indio_dev);
 	int report_id = -1;
@@ -167,8 +166,7 @@ static int magn_3d_read_raw(struct iio_dev *indio_dev,
 				false);
 			return -EINVAL;
 		}
-		hid_sensor_power_state(&magn_state->magn_flux_attributes,
-					false);
+		hid_sensor_power_state(&magn_state->magn_flux_attributes, false);
 		ret_type = IIO_VAL_INT;
 		break;
 	case IIO_CHAN_INFO_SCALE:
@@ -229,10 +227,8 @@ static int magn_3d_read_raw(struct iio_dev *indio_dev,
 
 /* Channel write_raw handler */
 static int magn_3d_write_raw(struct iio_dev *indio_dev,
-			       struct iio_chan_spec const *chan,
-			       int val,
-			       int val2,
-			       long mask)
+			     struct iio_chan_spec const *chan,
+			     int val, int val2, long mask)
 {
 	struct magn_3d_state *magn_state = iio_priv(indio_dev);
 	int ret = 0;
@@ -270,8 +266,7 @@ static const struct iio_info magn_3d_info = {
 
 /* Callback handler to send event after all samples are received and captured */
 static int magn_3d_proc_event(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				void *priv)
+			      u32 usage_id, void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct magn_3d_state *magn_state = iio_priv(indio_dev);
@@ -292,9 +287,9 @@ static int magn_3d_proc_event(struct hid_sensor_hub_device *hsdev,
 
 /* Capture samples in local storage */
 static int magn_3d_capture_sample(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				size_t raw_len, char *raw_data,
-				void *priv)
+				  u32 usage_id,
+				  size_t raw_len, char *raw_data,
+				  void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct magn_3d_state *magn_state = iio_priv(indio_dev);
@@ -368,18 +363,17 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 		return  -EINVAL;
 	}
 
-	dev_dbg(&pdev->dev, "magn_3d Found %d usage attributes\n",
-			attr_count);
+	dev_dbg(&pdev->dev, "magn_3d Found %d usage attributes\n", attr_count);
 	dev_dbg(&pdev->dev, "magn_3d X: %x:%x Y: %x:%x Z: %x:%x\n",
-			st->magn[0].index,
-			st->magn[0].report_id,
-			st->magn[1].index, st->magn[1].report_id,
-			st->magn[2].index, st->magn[2].report_id);
+		st->magn[0].index,
+		st->magn[0].report_id,
+		st->magn[1].index, st->magn[1].report_id,
+		st->magn[2].index, st->magn[2].report_id);
 
 	/* Setup IIO channel array */
 	_channels = devm_kcalloc(&pdev->dev, attr_count,
-				sizeof(struct iio_chan_spec),
-				GFP_KERNEL);
+				 sizeof(struct iio_chan_spec),
+				 GFP_KERNEL);
 	if (!_channels) {
 		dev_err(&pdev->dev,
 			"failed to allocate space for iio channels\n");
@@ -426,8 +420,7 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 
 	*channels = _channels;
 
-	dev_dbg(&pdev->dev, "magn_3d Setup %d IIO channels\n",
-			*chan_count);
+	dev_dbg(&pdev->dev, "magn_3d Setup %d IIO channels\n", *chan_count);
 
 	st->magn_flux_attr.scale_precision = hid_sensor_format_scale(
 				HID_USAGE_SENSOR_COMPASS_3D,
@@ -491,8 +484,8 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 	magn_state->rot_attributes.sensitivity.index = -1;
 
 	ret = magn_3d_parse_report(pdev, hsdev,
-				&channels, &chan_count,
-				HID_USAGE_SENSOR_COMPASS_3D, magn_state);
+				   &channels, &chan_count,
+				   HID_USAGE_SENSOR_COMPASS_3D, magn_state);
 	if (ret) {
 		dev_err(&pdev->dev, "failed to parse report\n");
 		return ret;
@@ -507,7 +500,7 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 	atomic_set(&magn_state->magn_flux_attributes.data_ready, 0);
 
 	ret = hid_sensor_setup_trigger(indio_dev, name,
-					&magn_state->magn_flux_attributes);
+				       &magn_state->magn_flux_attributes);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "trigger setup failed\n");
 		return ret;
@@ -517,7 +510,7 @@ static int hid_magn_3d_probe(struct platform_device *pdev)
 	magn_state->callbacks.capture_sample = magn_3d_capture_sample;
 	magn_state->callbacks.pdev = pdev;
 	ret = sensor_hub_register_callback(hsdev, HID_USAGE_SENSOR_COMPASS_3D,
-					&magn_state->callbacks);
+					   &magn_state->callbacks);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "callback reg failed\n");
 		goto error_remove_trigger;
diff --git a/drivers/iio/orientation/hid-sensor-incl-3d.c b/drivers/iio/orientation/hid-sensor-incl-3d.c
index 5696e4ef3633..05c75e7246af 100644
--- a/drivers/iio/orientation/hid-sensor-incl-3d.c
+++ b/drivers/iio/orientation/hid-sensor-incl-3d.c
@@ -86,8 +86,7 @@ static const struct iio_chan_spec incl_3d_channels[] = {
 };
 
 /* Adjust channel real bits based on report descriptor */
-static void incl_3d_adjust_channel_bit_mask(struct iio_chan_spec *chan,
-						int size)
+static void incl_3d_adjust_channel_bit_mask(struct iio_chan_spec *chan, int size)
 {
 	chan->scan_type.sign = 's';
 	/* Real storage bits will change based on the report desc. */
@@ -98,9 +97,8 @@ static void incl_3d_adjust_channel_bit_mask(struct iio_chan_spec *chan,
 
 /* Channel read_raw handler */
 static int incl_3d_read_raw(struct iio_dev *indio_dev,
-			      struct iio_chan_spec const *chan,
-			      int *val, int *val2,
-			      long mask)
+			    struct iio_chan_spec const *chan,
+			    int *val, int *val2, long mask)
 {
 	struct incl_3d_state *incl_state = iio_priv(indio_dev);
 	int report_id = -1;
@@ -125,7 +123,7 @@ static int incl_3d_read_raw(struct iio_dev *indio_dev,
 				min < 0);
 		else {
 			hid_sensor_power_state(&incl_state->common_attributes,
-						false);
+					       false);
 			return -EINVAL;
 		}
 		hid_sensor_power_state(&incl_state->common_attributes, false);
@@ -158,10 +156,8 @@ static int incl_3d_read_raw(struct iio_dev *indio_dev,
 
 /* Channel write_raw handler */
 static int incl_3d_write_raw(struct iio_dev *indio_dev,
-			       struct iio_chan_spec const *chan,
-			       int val,
-			       int val2,
-			       long mask)
+			     struct iio_chan_spec const *chan,
+			     int val, int val2, long mask)
 {
 	struct incl_3d_state *incl_state = iio_priv(indio_dev);
 	int ret;
@@ -189,8 +185,7 @@ static const struct iio_info incl_3d_info = {
 
 /* Callback handler to send event after all samples are received and captured */
 static int incl_3d_proc_event(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				void *priv)
+			      u32 usage_id, void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct incl_3d_state *incl_state = iio_priv(indio_dev);
@@ -212,9 +207,9 @@ static int incl_3d_proc_event(struct hid_sensor_hub_device *hsdev,
 
 /* Capture samples in local storage */
 static int incl_3d_capture_sample(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				size_t raw_len, char *raw_data,
-				void *priv)
+				  u32 usage_id,
+				  size_t raw_len, char *raw_data,
+				  void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct incl_3d_state *incl_state = iio_priv(indio_dev);
@@ -350,7 +345,7 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 	atomic_set(&incl_state->common_attributes.data_ready, 0);
 
 	ret = hid_sensor_setup_trigger(indio_dev, name,
-					&incl_state->common_attributes);
+				       &incl_state->common_attributes);
 	if (ret) {
 		dev_err(&pdev->dev, "trigger setup failed\n");
 		return ret;
@@ -360,8 +355,8 @@ static int hid_incl_3d_probe(struct platform_device *pdev)
 	incl_state->callbacks.capture_sample = incl_3d_capture_sample;
 	incl_state->callbacks.pdev = pdev;
 	ret = sensor_hub_register_callback(hsdev,
-					HID_USAGE_SENSOR_INCLINOMETER_3D,
-					&incl_state->callbacks);
+					   HID_USAGE_SENSOR_INCLINOMETER_3D,
+					   &incl_state->callbacks);
 	if (ret) {
 		dev_err(&pdev->dev, "callback reg failed\n");
 		goto error_remove_trigger;
diff --git a/drivers/iio/orientation/hid-sensor-rotation.c b/drivers/iio/orientation/hid-sensor-rotation.c
index 6773bb0ec204..bd918feb3617 100644
--- a/drivers/iio/orientation/hid-sensor-rotation.c
+++ b/drivers/iio/orientation/hid-sensor-rotation.c
@@ -81,9 +81,8 @@ static const struct iio_chan_spec dev_rot_channels[] = {
 
 /* Channel read_raw handler */
 static int dev_rot_read_raw(struct iio_dev *indio_dev,
-				struct iio_chan_spec const *chan,
-				int size, int *vals, int *val_len,
-				long mask)
+			    struct iio_chan_spec const *chan,
+			    int size, int *vals, int *val_len, long mask)
 {
 	struct dev_rot_state *rot_state = iio_priv(indio_dev);
 	int ret_type;
@@ -129,10 +128,8 @@ static int dev_rot_read_raw(struct iio_dev *indio_dev,
 
 /* Channel write_raw handler */
 static int dev_rot_write_raw(struct iio_dev *indio_dev,
-			       struct iio_chan_spec const *chan,
-			       int val,
-			       int val2,
-			       long mask)
+			     struct iio_chan_spec const *chan,
+			     int val, int val2, long mask)
 {
 	struct dev_rot_state *rot_state = iio_priv(indio_dev);
 	int ret;
@@ -176,8 +173,7 @@ static const struct iio_info dev_rot_info = {
 
 /* Callback handler to send event after all samples are received and captured */
 static int dev_rot_proc_event(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				void *priv)
+			      u32 usage_id, void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct dev_rot_state *rot_state = iio_priv(indio_dev);
@@ -209,9 +205,9 @@ static int dev_rot_proc_event(struct hid_sensor_hub_device *hsdev,
 
 /* Capture samples in local storage */
 static int dev_rot_capture_sample(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				size_t raw_len, char *raw_data,
-				void *priv)
+				  u32 usage_id,
+				  size_t raw_len, char *raw_data,
+				  void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct dev_rot_state *rot_state = iio_priv(indio_dev);
@@ -326,7 +322,7 @@ static int hid_dev_rot_probe(struct platform_device *pdev)
 	atomic_set(&rot_state->common_attributes.data_ready, 0);
 
 	ret = hid_sensor_setup_trigger(indio_dev, name,
-					&rot_state->common_attributes);
+				       &rot_state->common_attributes);
 	if (ret) {
 		dev_err(&pdev->dev, "trigger setup failed\n");
 		return ret;
@@ -336,7 +332,7 @@ static int hid_dev_rot_probe(struct platform_device *pdev)
 	rot_state->callbacks.capture_sample = dev_rot_capture_sample;
 	rot_state->callbacks.pdev = pdev;
 	ret = sensor_hub_register_callback(hsdev, hsdev->usage,
-					&rot_state->callbacks);
+					   &rot_state->callbacks);
 	if (ret) {
 		dev_err(&pdev->dev, "callback reg failed\n");
 		goto error_remove_trigger;
diff --git a/drivers/iio/position/hid-sensor-custom-intel-hinge.c b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
index 7d3f4907e083..eb6c59f81c3f 100644
--- a/drivers/iio/position/hid-sensor-custom-intel-hinge.c
+++ b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
@@ -107,8 +107,8 @@ static void hinge_adjust_channel_realbits(struct iio_chan_spec *channels,
 
 /* Channel read_raw handler */
 static int hinge_read_raw(struct iio_dev *indio_dev,
-			  struct iio_chan_spec const *chan, int *val, int *val2,
-			  long mask)
+			  struct iio_chan_spec const *chan,
+			  int *val, int *val2, long mask)
 {
 	struct hinge_state *st = iio_priv(indio_dev);
 	struct hid_sensor_hub_device *hsdev;
@@ -154,8 +154,8 @@ static int hinge_read_raw(struct iio_dev *indio_dev,
 
 /* Channel write_raw handler */
 static int hinge_write_raw(struct iio_dev *indio_dev,
-			   struct iio_chan_spec const *chan, int val, int val2,
-			   long mask)
+			   struct iio_chan_spec const *chan,
+			   int val, int val2, long mask)
 {
 	struct hinge_state *st = iio_priv(indio_dev);
 
@@ -209,8 +209,9 @@ static int hinge_proc_event(struct hid_sensor_hub_device *hsdev,
 
 /* Capture samples in local storage */
 static int hinge_capture_sample(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id, size_t raw_len,
-				char *raw_data, void *priv)
+				u32 usage_id,
+				size_t raw_len, char *raw_data,
+				void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct hinge_state *st = iio_priv(indio_dev);
diff --git a/drivers/iio/pressure/hid-sensor-press.c b/drivers/iio/pressure/hid-sensor-press.c
index 8f81a6d65b9f..c2be2a2eaa1b 100644
--- a/drivers/iio/pressure/hid-sensor-press.c
+++ b/drivers/iio/pressure/hid-sensor-press.c
@@ -56,9 +56,8 @@ static const struct iio_chan_spec press_channels[] = {
 
 /* Channel read_raw handler */
 static int press_read_raw(struct iio_dev *indio_dev,
-			      struct iio_chan_spec const *chan,
-			      int *val, int *val2,
-			      long mask)
+			  struct iio_chan_spec const *chan,
+			  int *val, int *val2, long mask)
 {
 	struct press_state *press_state = iio_priv(indio_dev);
 	int report_id = -1;
@@ -82,7 +81,7 @@ static int press_read_raw(struct iio_dev *indio_dev,
 		}
 		if (report_id >= 0) {
 			hid_sensor_power_state(&press_state->common_attributes,
-						true);
+					       true);
 			*val = sensor_hub_input_attr_get_raw_value(
 				press_state->common_attributes.hsdev,
 				HID_USAGE_SENSOR_PRESSURE, address,
@@ -90,7 +89,7 @@ static int press_read_raw(struct iio_dev *indio_dev,
 				SENSOR_HUB_SYNC,
 				min < 0);
 			hid_sensor_power_state(&press_state->common_attributes,
-						false);
+					       false);
 		} else {
 			*val = 0;
 			return -EINVAL;
@@ -124,10 +123,8 @@ static int press_read_raw(struct iio_dev *indio_dev,
 
 /* Channel write_raw handler */
 static int press_write_raw(struct iio_dev *indio_dev,
-			       struct iio_chan_spec const *chan,
-			       int val,
-			       int val2,
-			       long mask)
+			   struct iio_chan_spec const *chan,
+			   int val, int val2, long mask)
 {
 	struct press_state *press_state = iio_priv(indio_dev);
 	int ret = 0;
@@ -155,8 +152,7 @@ static const struct iio_info press_info = {
 
 /* Callback handler to send event after all samples are received and captured */
 static int press_proc_event(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id,
-				void *priv)
+			    u32 usage_id, void *priv)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(priv);
 	struct press_state *press_state = iio_priv(indio_dev);
@@ -202,10 +198,10 @@ static int press_capture_sample(struct hid_sensor_hub_device *hsdev,
 
 /* Parse report which is specific to an usage id*/
 static int press_parse_report(struct platform_device *pdev,
-				struct hid_sensor_hub_device *hsdev,
-				struct iio_chan_spec *channels,
-				u32 usage_id,
-				struct press_state *st)
+			      struct hid_sensor_hub_device *hsdev,
+			      struct iio_chan_spec *channels,
+			      u32 usage_id,
+			      struct press_state *st)
 {
 	int ret;
 
@@ -222,7 +218,7 @@ static int press_parse_report(struct platform_device *pdev,
 	};
 
 	dev_dbg(&pdev->dev, "press %x:%x\n", st->press_attr.index,
-			st->press_attr.report_id);
+		st->press_attr.report_id);
 
 	st->scale_precision = hid_sensor_format_scale(
 				HID_USAGE_SENSOR_PRESSURE,
@@ -241,8 +237,7 @@ static int hid_press_probe(struct platform_device *pdev)
 	struct iio_dev *indio_dev;
 	struct press_state *press_state;
 
-	indio_dev = devm_iio_device_alloc(&pdev->dev,
-				sizeof(struct press_state));
+	indio_dev = devm_iio_device_alloc(&pdev->dev, sizeof(struct press_state));
 	if (!indio_dev)
 		return -ENOMEM;
 	platform_set_drvdata(pdev, indio_dev);
@@ -285,7 +280,7 @@ static int hid_press_probe(struct platform_device *pdev)
 	atomic_set(&press_state->common_attributes.data_ready, 0);
 
 	ret = hid_sensor_setup_trigger(indio_dev, name,
-				&press_state->common_attributes);
+				       &press_state->common_attributes);
 	if (ret) {
 		dev_err(&pdev->dev, "trigger setup failed\n");
 		return ret;
@@ -295,7 +290,7 @@ static int hid_press_probe(struct platform_device *pdev)
 	press_state->callbacks.capture_sample = press_capture_sample;
 	press_state->callbacks.pdev = pdev;
 	ret = sensor_hub_register_callback(hsdev, HID_USAGE_SENSOR_PRESSURE,
-					&press_state->callbacks);
+					   &press_state->callbacks);
 	if (ret < 0) {
 		dev_err(&pdev->dev, "callback reg failed\n");
 		goto error_remove_trigger;
diff --git a/drivers/iio/temperature/hid-sensor-temperature.c b/drivers/iio/temperature/hid-sensor-temperature.c
index d3bc13b4258e..f4a09d941d31 100644
--- a/drivers/iio/temperature/hid-sensor-temperature.c
+++ b/drivers/iio/temperature/hid-sensor-temperature.c
@@ -45,7 +45,7 @@ static const struct iio_chan_spec temperature_channels[] = {
 
 /* Adjust channel real bits based on report descriptor */
 static void temperature_adjust_channel_bit_mask(struct iio_chan_spec *channels,
-					int channel, int size)
+						int channel, int size)
 {
 	channels[channel].scan_type.sign = 's';
 	/* Real storage bits will change based on the report desc. */
@@ -101,8 +101,8 @@ static int temperature_read_raw(struct iio_dev *indio_dev,
 }
 
 static int temperature_write_raw(struct iio_dev *indio_dev,
-				struct iio_chan_spec const *chan,
-				int val, int val2, long mask)
+				 struct iio_chan_spec const *chan,
+				 int val, int val2, long mask)
 {
 	struct temperature_state *temp_st = iio_priv(indio_dev);
 
@@ -125,7 +125,7 @@ static const struct iio_info temperature_info = {
 
 /* Callback handler to send event after all samples are received and captured */
 static int temperature_proc_event(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id, void *pdev)
+				  u32 usage_id, void *pdev)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(pdev);
 	struct temperature_state *temp_st = iio_priv(indio_dev);
@@ -140,8 +140,9 @@ static int temperature_proc_event(struct hid_sensor_hub_device *hsdev,
 
 /* Capture samples in local storage */
 static int temperature_capture_sample(struct hid_sensor_hub_device *hsdev,
-				u32 usage_id, size_t raw_len,
-				char *raw_data, void *pdev)
+				      u32 usage_id,
+				      size_t raw_len, char *raw_data,
+				      void *pdev)
 {
 	struct iio_dev *indio_dev = platform_get_drvdata(pdev);
 	struct temperature_state *temp_st = iio_priv(indio_dev);
@@ -157,10 +158,10 @@ static int temperature_capture_sample(struct hid_sensor_hub_device *hsdev,
 
 /* Parse report which is specific to an usage id*/
 static int temperature_parse_report(struct platform_device *pdev,
-				struct hid_sensor_hub_device *hsdev,
-				struct iio_chan_spec *channels,
-				u32 usage_id,
-				struct temperature_state *st)
+				    struct hid_sensor_hub_device *hsdev,
+				    struct iio_chan_spec *channels,
+				    u32 usage_id,
+				    struct temperature_state *st)
 {
 	int ret;
 
@@ -171,8 +172,7 @@ static int temperature_parse_report(struct platform_device *pdev,
 	if (ret < 0)
 		return ret;
 
-	temperature_adjust_channel_bit_mask(channels, 0,
-					st->temperature_attr.size);
+	temperature_adjust_channel_bit_mask(channels, 0, st->temperature_attr.size);
 
 	st->scale_precision = hid_sensor_format_scale(
 				HID_USAGE_SENSOR_TEMPERATURE,
@@ -219,7 +219,7 @@ static int hid_temperature_probe(struct platform_device *pdev)
 		return -ENOMEM;
 
 	ret = temperature_parse_report(pdev, hsdev, temp_chans,
-				HID_USAGE_SENSOR_TEMPERATURE, temp_st);
+				       HID_USAGE_SENSOR_TEMPERATURE, temp_st);
 	if (ret)
 		return ret;
 
@@ -232,7 +232,7 @@ static int hid_temperature_probe(struct platform_device *pdev)
 	atomic_set(&temp_st->common_attributes.data_ready, 0);
 
 	ret = hid_sensor_setup_trigger(indio_dev, name,
-				&temp_st->common_attributes);
+				       &temp_st->common_attributes);
 	if (ret)
 		return ret;
 
@@ -240,7 +240,7 @@ static int hid_temperature_probe(struct platform_device *pdev)
 
 	temperature_callbacks.pdev = pdev;
 	ret = sensor_hub_register_callback(hsdev, HID_USAGE_SENSOR_TEMPERATURE,
-					&temperature_callbacks);
+					   &temperature_callbacks);
 	if (ret)
 		goto error_remove_trigger;
 

-- 
2.34.1

