From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 30 Sep 2026 14:41:38 +0800
Subject: [PATCH v2 20/21] media: i2c: it6625: use centrally managed active
 state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-upstream-it6625-follow-up-patch-v2-20-e353f887e7fa@ite.com.tw>
References: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
In-Reply-To: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790750567; l=15946;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=V/ot2kS9wT5pQbVWfx+lz9NvNTURFAa/RTY5/+f5RWY=;
 b=eGesXj3I1eY4LeIl4eX5EQoecjOhVjkUvdUyqp1895cHU+3WTnspRhRQHnXEFtQOF9vaR1Qiz
 aAgXXE2XeerAMAv+AbHrS91Eu22OUJyhWAMi66aL9tLeJ9jYcfIasuE
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Store the negotiated media-bus format in the V4L2 subdev state instead
of duplicating it in driver-private fields. This keeps ACTIVE and TRY
formats under the framework's state management and keeps the active
format synchronized with the configured DV timings.

Use the control handler's lock as the subdev state lock. Keep
it6625_lock independent for MCU transactions.

Initialize every state from the current DV timings and default format
index, use the core get_fmt implementation, and update the active format
whenever the configured timings change.

Make ACTIVE set_fmt reject changes while streaming and commit the new
format only after hardware programming succeeds. TRY changes remain
state-only and do not program hardware.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 234 +++++++++++++++++++++++++++------------------
 1 file changed, 142 insertions(+), 92 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index c3361727311d1ebbed072d9e7d25967231121cf5..1127d050d82522e202f042832e3772fd88e63ca9 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -255,7 +255,7 @@ struct it6625 {
 	struct regmap *it6625_regmap;
 	enum it6625_chip_type chip_type;
 
-	/* protects concurrent access to the chip's registers and state */
+	/* Serializes MCU transactions. */
 	struct mutex it6625_lock;
 	/* serializes the complete VIDIOC_S_EDID sequence against itself */
 	struct mutex edid_lock;
@@ -291,8 +291,6 @@ struct it6625 {
 	u8 csi_lanes;
 	u8 port_num;
 	enum v4l2_mbus_type bus_type;
-	u8 csi_format;
-	u32 mbus_fmt_code;
 	/* number of EDID blocks currently loaded, protected by edid_lock */
 	u8 edid_blocks;
 
@@ -918,10 +916,11 @@ static int it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
 	return it6625_s_ctrl_audio_present(sd);
 }
 
-static void it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
+static int it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
 {
 	struct v4l2_subdev *sd = &it6625->sd;
 	int val;
+	int err;
 
 	lockdep_assert_held(&it6625->it6625_lock);
 
@@ -929,27 +928,34 @@ static void it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
 		 __func__, enable ? "en" : "dis");
 
 	val = enable ? B_MIPI_OUTPUT : 0;
-	it6625_set_bits(it6625, REG_MIPI_CONTROL, B_MIPI_OUTPUT, val);
-	it6625_update_config(it6625);
+	err = it6625_set_bits(it6625, REG_MIPI_CONTROL, B_MIPI_OUTPUT, val);
+	if (err < 0)
+		return err;
+
+	return it6625_update_config(it6625);
 }
 
-static void it6625_enable_stream(struct it6625 *it6625, bool enable)
+static int it6625_enable_stream(struct it6625 *it6625, bool enable)
 {
 	guard(mutex)(&it6625->it6625_lock);
-	it6625_enable_stream_locked(it6625, enable);
+	return it6625_enable_stream_locked(it6625, enable);
 }
 
-static void it6625_set_mipi_config_locked(struct it6625 *it6625, u32 cfg_val)
+static int it6625_set_mipi_config_locked(struct it6625 *it6625, u32 cfg_val)
 {
 	u8 mipi_data_type;
+	int err;
 
 	lockdep_assert_held(&it6625->it6625_lock);
 
 	dev_dbg(it6625->dev, "mipi_data_type = 0x%x", cfg_val);
 
 	mipi_data_type = cfg_val & 0xFF;
-	it6625_write_byte(it6625, REG_MIPI_DATA_TYPE, mipi_data_type);
-	it6625_update_config(it6625);
+	err = it6625_write_byte(it6625, REG_MIPI_DATA_TYPE, mipi_data_type);
+	if (err < 0)
+		return err;
+
+	return it6625_update_config(it6625);
 }
 
 static inline unsigned int fps_from_bt_timings(const struct v4l2_bt_timings *t)
@@ -964,9 +970,20 @@ static inline unsigned int fps_from_bt_timings(const struct v4l2_bt_timings *t)
 
 static int it6625_initial_setup(struct it6625 *it6625)
 {
+	struct v4l2_subdev *sd = &it6625->sd;
+	struct v4l2_subdev_state *state;
+	struct v4l2_mbus_framefmt *fmt;
+	int idx;
 	int val = 0;
 	int err;
 
+	state = v4l2_subdev_lock_and_get_active_state(sd);
+	fmt = v4l2_subdev_state_get_format(state, 0);
+	idx = it6625_csi_mbus_code_idx(fmt->code);
+	if (idx < 0)
+		idx = 0;
+	v4l2_subdev_unlock_state(state);
+
 	guard(mutex)(&it6625->it6625_lock);
 
 	/*
@@ -995,7 +1012,8 @@ static int it6625_initial_setup(struct it6625 *it6625)
 	if (err)
 		return err;
 
-	err = it6625_write_byte(it6625, REG_MIPI_DATA_TYPE, it6625->csi_format);
+	err = it6625_write_byte(it6625, REG_MIPI_DATA_TYPE,
+				it6625_formats[idx].csi_format);
 	if (err)
 		return err;
 
@@ -1163,10 +1181,32 @@ static void it6625_get_timings(struct it6625 *it6625,
 	*timings = it6625->timings;
 }
 
+/*
+ * Project a DV-timings struct's width/height/field onto a pad format.
+ * Caller must hold it6625_lock and, separately, whichever subdev
+ * state fmt belongs to.
+ */
+static void it6625_fill_timings_format(const struct v4l2_dv_timings *timings,
+				       struct v4l2_mbus_framefmt *fmt)
+{
+	fmt->width = timings->bt.width;
+	fmt->height = timings->bt.height;
+	fmt->field = timings->bt.interlaced == V4L2_DV_INTERLACED ?
+		     V4L2_FIELD_INTERLACED : V4L2_FIELD_NONE;
+}
+
 static void it6625_clear_timings(struct it6625 *it6625)
 {
-	guard(mutex)(&it6625->it6625_lock);
-	memset(&it6625->timings, 0, sizeof(it6625->timings));
+	struct v4l2_subdev *sd = &it6625->sd;
+	struct v4l2_subdev_state *state = v4l2_subdev_lock_and_get_active_state(sd);
+	struct v4l2_mbus_framefmt *fmt = v4l2_subdev_state_get_format(state, 0);
+
+	scoped_guard(mutex, &it6625->it6625_lock) {
+		memset(&it6625->timings, 0, sizeof(it6625->timings));
+		it6625_fill_timings_format(&it6625->timings, fmt);
+	}
+
+	v4l2_subdev_unlock_state(state);
 }
 
 static void it6625_irq_hdmi_5v_change(struct it6625 *it6625)
@@ -1369,6 +1409,7 @@ static void it6625_polling_work(struct work_struct *work)
 static int it6625_log_status(struct v4l2_subdev *sd)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
+	struct v4l2_subdev_state *state;
 	struct v4l2_dv_timings timings, configured_timings;
 	struct v4l2_bt_timings bt;
 	u32 mbus_fmt_code;
@@ -1383,11 +1424,17 @@ static int it6625_log_status(struct v4l2_subdev *sd)
 	v4l2_print_dv_timings(sd->name, "Configured format: ",
 			      &configured_timings, true);
 
-	/* snapshot together so the reported pair was actually configured together */
+	/*
+	 * VIDIOC_LOG_STATUS isn't core-locked, so take both locks
+	 * ourselves; snapshot together so the reported pair was
+	 * actually configured together.
+	 */
+	state = v4l2_subdev_lock_and_get_active_state(sd);
 	scoped_guard(mutex, &it6625->it6625_lock) {
-		mbus_fmt_code = it6625->mbus_fmt_code;
+		mbus_fmt_code = v4l2_subdev_state_get_format(state, 0)->code;
 		bt = it6625->timings.bt;
 	}
+	v4l2_subdev_unlock_state(state);
 
 	v4l2_info(sd, "CSI format: %#x @ %uHz", mbus_fmt_code, fps_from_bt_timings(&bt));
 
@@ -1438,17 +1485,32 @@ static int
 it6625_update_timings_if_changed(struct it6625 *it6625,
 				 const struct v4l2_dv_timings *timings)
 {
-	guard(mutex)(&it6625->it6625_lock);
+	struct v4l2_subdev *sd = &it6625->sd;
+	struct v4l2_subdev_state *state;
+	struct v4l2_mbus_framefmt *fmt;
+	int ret;
 
-	if (v4l2_match_dv_timings(&it6625->timings, timings, 0, false))
-		return 0;
+	/* .s_dv_timings isn't core-locked, so take both locks ourselves */
+	state = v4l2_subdev_lock_and_get_active_state(sd);
+	fmt = v4l2_subdev_state_get_format(state, 0);
 
-	if (!v4l2_valid_dv_timings(timings, it6625_get_timings_cap(it6625), NULL, NULL))
-		return -ERANGE;
+	scoped_guard(mutex, &it6625->it6625_lock) {
+		if (v4l2_match_dv_timings(&it6625->timings, timings, 0, false)) {
+			ret = 0;
+		} else if (!v4l2_valid_dv_timings(timings,
+						  it6625_get_timings_cap(it6625),
+						  NULL, NULL)) {
+			ret = -ERANGE;
+		} else {
+			it6625->timings = *timings;
+			it6625_fill_timings_format(&it6625->timings, fmt);
+			ret = 1;
+		}
+	}
 
-	it6625->timings = *timings;
+	v4l2_subdev_unlock_state(state);
 
-	return 1;
+	return ret;
 }
 
 static int it6625_enum_dv_timings(struct v4l2_subdev *sd,
@@ -1480,8 +1542,7 @@ static int it6625_s_stream(struct v4l2_subdev *sd, int enable)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
 
-	it6625_enable_stream(it6625, enable);
-	return 0;
+	return it6625_enable_stream(it6625, enable);
 }
 
 static int it6625_enum_mbus_code(struct v4l2_subdev *sd,
@@ -1609,85 +1670,59 @@ static inline u32 format_to_colorspace(u8 csi_format)
 	}
 }
 
-static int it6625_get_fmt(struct v4l2_subdev *sd,
+static int it6625_set_fmt(struct v4l2_subdev *sd,
+			  const struct v4l2_subdev_client_info *ci,
 			  struct v4l2_subdev_state *sd_state,
 			  struct v4l2_subdev_format *format)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
-	struct v4l2_dv_timings timings;
+	struct v4l2_mbus_framefmt *fmt;
+	u8 csi_format;
+	int idx;
+	int ret;
 
 	if (format->pad != 0)
 		return -EINVAL;
 
-	it6625_get_timings(it6625, &timings);
-	format->format.width = timings.bt.width;
-	format->format.height = timings.bt.height;
-	format->format.field = timings.bt.interlaced == V4L2_DV_INTERLACED ?
-			       V4L2_FIELD_INTERLACED : V4L2_FIELD_NONE;
-
-	if (format->which == V4L2_SUBDEV_FORMAT_TRY) {
-		struct v4l2_mbus_framefmt *fmt;
-
-		fmt = v4l2_subdev_state_get_format(sd_state, format->pad);
-		format->format.code = fmt->code;
-		format->format.colorspace = fmt->colorspace;
-	} else {
-		scoped_guard(mutex, &it6625->it6625_lock) {
-			format->format.colorspace =
-				format_to_colorspace(it6625->csi_format);
-			format->format.code = it6625->mbus_fmt_code;
-		}
+	idx = it6625_csi_mbus_code_idx(format->format.code);
+	if (idx < 0) {
+		v4l2_dbg(1, debug, sd,
+			 "%s: unsupported format code 0x%x, falling back to default",
+			 __func__, format->format.code);
+		idx = 0;
 	}
 
-	return 0;
-}
+	csi_format = it6625_formats[idx].csi_format;
 
-static int it6625_set_fmt(struct v4l2_subdev *sd,
-			  const struct v4l2_subdev_client_info *ci,
-			  struct v4l2_subdev_state *sd_state,
-			  struct v4l2_subdev_format *format)
-{
-	struct it6625 *it6625 = sd_to_6625(sd);
-	u32 mbus_fmt_code = format->format.code;
-	int ret;
+	/* fmt already carries width/height/field for this state; leave alone */
+	fmt = v4l2_subdev_state_get_format(sd_state, format->pad);
 
-	ret = it6625_get_fmt(sd, sd_state, format);
-	format->format.code = mbus_fmt_code;
+	if (format->which == V4L2_SUBDEV_FORMAT_ACTIVE) {
+		if (v4l2_subdev_is_streaming(sd))
+			return -EBUSY;
 
-	if (ret)
-		return ret;
+		guard(mutex)(&it6625->it6625_lock);
 
-	ret = it6625_csi_mbus_code_idx(mbus_fmt_code);
+		ret = it6625_enable_stream_locked(it6625, false);
+		if (ret)
+			return ret;
 
-	if (ret < 0) {
-		v4l2_dbg(1, debug, sd,
-			 "%s: unsupported format code 0x%x, falling back to default",
-			 __func__, mbus_fmt_code);
-		ret = 0;
-		mbus_fmt_code = it6625_formats[ret].mbus_fmt_code;
-		format->format.code = mbus_fmt_code;
+		ret = it6625_set_mipi_config_locked(it6625, csi_format);
+		if (ret)
+			return ret;
 	}
 
-	if (format->which == V4L2_SUBDEV_FORMAT_TRY) {
-		struct v4l2_mbus_framefmt *fmt;
+	/*
+	 * TRY: commit unconditionally. ACTIVE: commit only after the
+	 * hardware programming above actually succeeded.
+	 */
+	fmt->code = it6625_formats[idx].mbus_fmt_code;
+	fmt->colorspace = format_to_colorspace(csi_format);
+	format->format = *fmt;
 
-		fmt = v4l2_subdev_state_get_format(sd_state, format->pad);
-		fmt->code = format->format.code;
-		fmt->colorspace = format_to_colorspace(it6625_formats[ret].csi_format);
-		format->format.colorspace = fmt->colorspace;
+	if (format->which == V4L2_SUBDEV_FORMAT_TRY)
 		v4l2_dbg(1, debug, sd, "%s: try format code = 0x%x",
 			 __func__, format->format.code);
-		return 0;
-	}
-
-	scoped_guard(mutex, &it6625->it6625_lock) {
-		it6625->csi_format = it6625_formats[ret].csi_format;
-		it6625->mbus_fmt_code = format->format.code;
-		it6625_enable_stream_locked(it6625, false);
-		it6625_set_mipi_config_locked(it6625, it6625->csi_format);
-	}
-
-	format->format.colorspace = format_to_colorspace(it6625_formats[ret].csi_format);
 
 	return 0;
 }
@@ -1804,7 +1839,7 @@ static const struct v4l2_subdev_video_ops it6625_video_ops = {
 static const struct v4l2_subdev_pad_ops it6625_pad_ops = {
 	.enum_mbus_code = it6625_enum_mbus_code,
 	.set_fmt = it6625_set_fmt,
-	.get_fmt = it6625_get_fmt,
+	.get_fmt = v4l2_subdev_get_fmt,
 	.get_edid = it6625_g_edid,
 	.set_edid = it6625_s_edid,
 	.enum_dv_timings = it6625_enum_dv_timings,
@@ -1824,8 +1859,12 @@ static const struct v4l2_subdev_ops it6625_ops = {
 static int it6625_init_state(struct v4l2_subdev *sd,
 			     struct v4l2_subdev_state *sd_state)
 {
+	struct it6625 *it6625 = sd_to_6625(sd);
 	struct v4l2_mbus_framefmt *fmt = v4l2_subdev_state_get_format(sd_state, 0);
 
+	scoped_guard(mutex, &it6625->it6625_lock)
+		it6625_fill_timings_format(&it6625->timings, fmt);
+
 	fmt->code = it6625_formats[0].mbus_fmt_code;
 	fmt->colorspace = format_to_colorspace(it6625_formats[0].csi_format);
 
@@ -1866,6 +1905,7 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 			   it6625->csi_lanes == 3;
 
 	v4l2_ctrl_handler_init(hdl, 4);
+
 	it6625->ctrl_5v_detect =
 		v4l2_ctrl_new_std(hdl, NULL, V4L2_CID_DV_RX_POWER_PRESENT,
 				  0, 1, 0, 0);
@@ -2074,8 +2114,6 @@ static void it6625_init_data(struct it6625 *it6625)
 	static struct v4l2_dv_timings default_timing =
 			V4L2_DV_BT_CEA_1920X1080P60;
 
-	it6625->csi_format = it6625_formats[0].csi_format;
-	it6625->mbus_fmt_code = it6625_formats[0].mbus_fmt_code;
 	it6625->timings = default_timing;
 	/* firmware ships with a verified 2-block default EDID in EDID RAM */
 	it6625->edid_blocks = 2;
@@ -2267,9 +2305,16 @@ static int it6625_probe(struct i2c_client *client)
 		goto err_clean_ctrl_handler;
 	}
 
+	sd->state_lock = sd->ctrl_handler->lock;
+	err = v4l2_subdev_init_finalize(sd);
+	if (err) {
+		dev_err(it6625->dev, "%s %d err=%d", __func__, __LINE__, err);
+		goto err_clean_hdl;
+	}
+
 	err = v4l2_ctrl_handler_setup(sd->ctrl_handler);
 	if (err)
-		goto err_clean_hdl;
+		goto err_clean_state;
 
 	it6625->cec_adap = cec_allocate_adapter(&it6625_cec_adap_ops,
 						it6625, dev_name(it6625->dev),
@@ -2280,7 +2325,7 @@ static int it6625_probe(struct i2c_client *client)
 	if (IS_ERR(it6625->cec_adap)) {
 		err = PTR_ERR(it6625->cec_adap);
 		dev_err(it6625->dev, "%s %d", __func__, __LINE__);
-		goto err_clean_hdl;
+		goto err_clean_state;
 	}
 
 	err = cec_register_adapter(it6625->cec_adap, &client->dev);
@@ -2288,7 +2333,7 @@ static int it6625_probe(struct i2c_client *client)
 		dev_err(it6625->dev, "%s: failed to register the cec device", __func__);
 		cec_delete_adapter(it6625->cec_adap);
 		it6625->cec_adap = NULL;
-		goto err_clean_hdl;
+		goto err_clean_state;
 	}
 
 	it6625_debugfs_init(it6625, client);
@@ -2322,6 +2367,8 @@ static int it6625_probe(struct i2c_client *client)
 	v4l2_debugfs_if_free(it6625->infoframes);
 	debugfs_remove_recursive(it6625->debugfs_dir);
 	cec_unregister_adapter(it6625->cec_adap);
+err_clean_state:
+	v4l2_subdev_cleanup(sd);
 err_clean_hdl:
 	media_entity_cleanup(&sd->entity);
 err_clean_ctrl_handler:
@@ -2359,12 +2406,15 @@ static void it6625_remove(struct i2c_client *client)
 
 	debugfs_remove_recursive(it6625->debugfs_dir);
 	cec_unregister_adapter(it6625->cec_adap);
+
+	v4l2_subdev_cleanup(sd);
+	media_entity_cleanup(&sd->entity);
+	v4l2_ctrl_handler_free(&it6625->hdl);
+
 	mutex_destroy(&it6625->it6625_lock);
 	mutex_destroy(&it6625->edid_lock);
 	mutex_destroy(&it6625->if_read_lock);
 	mutex_destroy(&it6625->if_state_lock);
-	media_entity_cleanup(&sd->entity);
-	v4l2_ctrl_handler_free(&it6625->hdl);
 }
 
 static const struct i2c_device_id it6625_id[] = {

-- 
2.34.1

