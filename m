From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:35 +0800
Subject: [PATCH 20/21] media: i2c: it6625: use centrally managed active
 state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-20-78d72d7886a5@ite.com.tw>
References: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
In-Reply-To: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=17656;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=Od5HPgJWNyxL2zm0GyyKeYfcet7/wwxFCUyEQT7ygdI=;
 b=U9Cmn0qvvBsVpAgvc4As2lO7laWc4GfkWk8MdCMozf9qZFf3v9x8K+0rtOsXEZU9z9I1psOpM
 JBZaPxCmPjOD4QOj1lKIK5ivdZMARbSnKrzzvPhaB69GtiLNHN+iyKG
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adopt the subdev active-state model instead of a private driver mutex
and driver-local format fields:

 - Share it6625_lock as both sd->state_lock and sd->ctrl_handler->lock
   (set hdl->lock right after v4l2_ctrl_handler_init(), which resets
   it, and before any control is created), matching the documented
   model in Documentation/driver-api/media/v4l2-subdev.rst. Call
   v4l2_subdev_init_finalize() after media_entity_pads_init() and
   before any code that touches active state, always before
   v4l2_async_register_subdev().

 - Remove csi_format/mbus_fmt_code from struct it6625 and store the
   complete format -- code, colorspace, and width/height/field derived
   from the configured DV timings -- in the pad format of each
   v4l2_subdev_state instead. it6625_set_fmt() now operates directly
   on the state the core hands it (already locked, and for ACTIVE
   already sd->active_state) instead of taking it6625_lock itself.
   it6625_get_fmt() is deleted; .get_fmt is now the core's
   v4l2_subdev_get_fmt(). it6625_init_state() seeds a state from the
   current active format when one exists (later TRY-state allocation)
   or from driver defaults when it doesn't (the very first, pre-
   assignment call that becomes the active state itself).

 - Keep it6625->timings as driver-private DV-timings state, but project
   its width/height/field onto the active pad format every time it
   changes (it6625_update_timings_if_changed(), it6625_clear_timings())
   so VIDIOC_SUBDEV_G_FMT stays consistent with
   VIDIOC_SUBDEV_G_DV_TIMINGS. it6625_initial_setup() and
   it6625_log_status() now read the media-bus code from the locked
   active format instead of the removed fields.

 - Make ACTIVE .set_fmt() transactional: return -EBUSY while streaming,
   and commit the new code/colorspace to active state only after the
   MIPI register writes that implement it actually succeed. This
   requires it6625_enable_stream_locked(), it6625_enable_stream(), and
   it6625_set_mipi_config_locked() to return int and propagate the
   first register/config-update failure; all existing callers are
   updated.

Every it6625_lock acquisition site was re-audited against the core's
actual locking contract (which ioctls the core state-locks, what
v4l2_ctrl_handler_init()/_free() and v4l2_subdev_cleanup() actually
touch) to confirm none of the driver's own lock-taking helpers are
reachable from a path where the core already holds it6625_lock, and
that init/teardown ordering keeps hdl->lock valid whenever
v4l2_ctrl_handler_free() runs. The full trace is recorded in
it6625-follow-up-patch/patch19-lock-audit.md (not part of this commit)
for review -- it is static analysis only, since no IT6625/IT6626
hardware is available here to exercise this with lockdep enabled.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 220 ++++++++++++++++++++++++++++-----------------
 1 file changed, 138 insertions(+), 82 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index ec6aaa878471ff210264a35e4aa66dfb1e63ed3b..550eb95c6f74a81fc11cc055b4590159ac50e969 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -255,7 +255,15 @@ struct it6625 {
 	struct regmap *it6625_regmap;
 	enum it6625_chip_type chip_type;
 
-	/* protects concurrent access to the chip's registers and state */
+	/*
+	 * Protects concurrent access to the chip's registers and state.
+	 * Also shared as sd.state_lock and hdl.lock (see
+	 * Documentation/driver-api/media/v4l2-subdev.rst), so the V4L2
+	 * core already holds it across .get_fmt/.set_fmt/.enable_streams/
+	 * .disable_streams and control updates -- callers reached only
+	 * through those paths must use the *_locked() helpers instead of
+	 * taking it again.
+	 */
 	struct mutex it6625_lock;
 	/* serializes the complete VIDIOC_S_EDID sequence against itself */
 	struct mutex edid_lock;
@@ -291,8 +299,6 @@ struct it6625 {
 	u8 csi_lanes;
 	u8 port_num;
 	enum v4l2_mbus_type bus_type;
-	u8 csi_format;
-	u32 mbus_fmt_code;
 	/* number of EDID blocks currently loaded, protected by edid_lock */
 	u8 edid_blocks;
 
@@ -911,10 +917,11 @@ static int it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
 	return it6625_s_ctrl_audio_present(sd);
 }
 
-static void it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
+static int it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
 {
 	struct v4l2_subdev *sd = &it6625->sd;
 	int val;
+	int err;
 
 	lockdep_assert_held(&it6625->it6625_lock);
 
@@ -922,27 +929,34 @@ static void it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
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
@@ -957,10 +971,18 @@ static inline unsigned int fps_from_bt_timings(const struct v4l2_bt_timings *t)
 
 static void it6625_initial_setup(struct it6625 *it6625)
 {
+	struct v4l2_subdev *sd = &it6625->sd;
+	struct v4l2_mbus_framefmt *fmt;
+	int idx;
 	int val = 0;
 
 	guard(mutex)(&it6625->it6625_lock);
 
+	fmt = v4l2_subdev_state_get_format(v4l2_subdev_get_locked_active_state(sd), 0);
+	idx = it6625_csi_mbus_code_idx(fmt->code);
+	if (idx < 0)
+		idx = 0;
+
 	/*
 	 * REG_MIPI_CFG[0:2] lane count field: 1 lane -> 0, 2 lanes -> 1,
 	 * 3 lanes (C-PHY only) -> 3, 4 lanes (D-PHY only) -> 3.
@@ -984,7 +1006,7 @@ static void it6625_initial_setup(struct it6625 *it6625)
 		val |= FIELD_PREP(B_MIPI_SPLIT, 1);
 
 	it6625_write_byte(it6625, REG_MIPI_CFG, val);
-	it6625_write_byte(it6625, REG_MIPI_DATA_TYPE, it6625->csi_format);
+	it6625_write_byte(it6625, REG_MIPI_DATA_TYPE, it6625_formats[idx].csi_format);
 	it6625_write_byte(it6625, REG_MIPI_CONTROL, 0x00);
 	it6625_write_byte(it6625, REG_RX_CFG, 0x00);
 
@@ -1140,10 +1162,29 @@ static void it6625_get_timings(struct it6625 *it6625,
 	*timings = it6625->timings;
 }
 
+/*
+ * Project a DV-timings struct's width/height/field onto an active pad
+ * format. Caller must hold it6625_lock (== the active state's lock).
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
+	struct v4l2_subdev *sd = &it6625->sd;
+	struct v4l2_mbus_framefmt *fmt;
+
 	guard(mutex)(&it6625->it6625_lock);
 	memset(&it6625->timings, 0, sizeof(it6625->timings));
+
+	fmt = v4l2_subdev_state_get_format(v4l2_subdev_get_locked_active_state(sd), 0);
+	it6625_fill_timings_format(&it6625->timings, fmt);
 }
 
 static void it6625_irq_hdmi_5v_change(struct it6625 *it6625)
@@ -1362,7 +1403,10 @@ static int it6625_log_status(struct v4l2_subdev *sd)
 
 	/* snapshot together so the reported pair was actually configured together */
 	scoped_guard(mutex, &it6625->it6625_lock) {
-		mbus_fmt_code = it6625->mbus_fmt_code;
+		struct v4l2_mbus_framefmt *fmt =
+			v4l2_subdev_state_get_format(v4l2_subdev_get_locked_active_state(sd), 0);
+
+		mbus_fmt_code = fmt->code;
 		bt = it6625->timings.bt;
 	}
 
@@ -1415,6 +1459,9 @@ static int
 it6625_update_timings_if_changed(struct it6625 *it6625,
 				 const struct v4l2_dv_timings *timings)
 {
+	struct v4l2_subdev *sd = &it6625->sd;
+	struct v4l2_mbus_framefmt *fmt;
+
 	guard(mutex)(&it6625->it6625_lock);
 
 	if (v4l2_match_dv_timings(&it6625->timings, timings, 0, false))
@@ -1425,6 +1472,9 @@ it6625_update_timings_if_changed(struct it6625 *it6625,
 
 	it6625->timings = *timings;
 
+	fmt = v4l2_subdev_state_get_format(v4l2_subdev_get_locked_active_state(sd), 0);
+	it6625_fill_timings_format(&it6625->timings, fmt);
+
 	return 1;
 }
 
@@ -1457,8 +1507,7 @@ static int it6625_s_stream(struct v4l2_subdev *sd, int enable)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
 
-	it6625_enable_stream(it6625, enable);
-	return 0;
+	return it6625_enable_stream(it6625, enable);
 }
 
 static int it6625_enum_mbus_code(struct v4l2_subdev *sd,
@@ -1586,84 +1635,56 @@ static inline u32 format_to_colorspace(u8 csi_format)
 	}
 }
 
-static int it6625_get_fmt(struct v4l2_subdev *sd,
-			  struct v4l2_subdev_state *sd_state,
-			  struct v4l2_subdev_format *format)
-{
-	struct it6625 *it6625 = sd_to_6625(sd);
-	struct v4l2_dv_timings timings;
-
-	if (format->pad != 0)
-		return -EINVAL;
-
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
-	}
-
-	return 0;
-}
-
 static int it6625_set_fmt(struct v4l2_subdev *sd,
 			  struct v4l2_subdev_state *sd_state,
 			  struct v4l2_subdev_format *format)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
-	u32 mbus_fmt_code = format->format.code;
+	struct v4l2_mbus_framefmt *fmt;
+	u32 colorspace;
+	int idx;
 	int ret;
 
-	ret = it6625_get_fmt(sd, sd_state, format);
-	format->format.code = mbus_fmt_code;
-
-	if (ret)
-		return ret;
-
-	ret = it6625_csi_mbus_code_idx(mbus_fmt_code);
+	if (format->pad != 0)
+		return -EINVAL;
 
-	if (ret < 0) {
+	idx = it6625_csi_mbus_code_idx(format->format.code);
+	if (idx < 0) {
 		v4l2_dbg(1, debug, sd,
 			 "%s: unsupported format code 0x%x, falling back to default",
-			 __func__, mbus_fmt_code);
-		ret = 0;
-		mbus_fmt_code = it6625_formats[ret].mbus_fmt_code;
-		format->format.code = mbus_fmt_code;
+			 __func__, format->format.code);
+		idx = 0;
 	}
 
-	if (format->which == V4L2_SUBDEV_FORMAT_TRY) {
-		struct v4l2_mbus_framefmt *fmt;
+	colorspace = format_to_colorspace(it6625_formats[idx].csi_format);
 
-		fmt = v4l2_subdev_state_get_format(sd_state, format->pad);
-		fmt->code = format->format.code;
-		fmt->colorspace = format_to_colorspace(it6625_formats[ret].csi_format);
-		format->format.colorspace = fmt->colorspace;
+	/* fmt already carries this state's width/height/field; leave them alone */
+	fmt = v4l2_subdev_state_get_format(sd_state, format->pad);
+
+	if (format->which == V4L2_SUBDEV_FORMAT_TRY) {
+		fmt->code = it6625_formats[idx].mbus_fmt_code;
+		fmt->colorspace = colorspace;
+		format->format = *fmt;
 		v4l2_dbg(1, debug, sd, "%s: try format code = 0x%x",
 			 __func__, format->format.code);
 		return 0;
 	}
 
-	scoped_guard(mutex, &it6625->it6625_lock) {
-		it6625->csi_format = it6625_formats[ret].csi_format;
-		it6625->mbus_fmt_code = format->format.code;
-		it6625_enable_stream_locked(it6625, false);
-		it6625_set_mipi_config_locked(it6625, it6625->csi_format);
-	}
+	if (v4l2_subdev_is_streaming(sd))
+		return -EBUSY;
 
-	format->format.colorspace = format_to_colorspace(it6625_formats[ret].csi_format);
+	ret = it6625_enable_stream_locked(it6625, false);
+	if (ret)
+		return ret;
+
+	ret = it6625_set_mipi_config_locked(it6625, it6625_formats[idx].csi_format);
+	if (ret)
+		return ret;
+
+	/* commit to active state only after hardware programming succeeded */
+	fmt->code = it6625_formats[idx].mbus_fmt_code;
+	fmt->colorspace = colorspace;
+	format->format = *fmt;
 
 	return 0;
 }
@@ -1780,7 +1801,7 @@ static const struct v4l2_subdev_video_ops it6625_video_ops = {
 static const struct v4l2_subdev_pad_ops it6625_pad_ops = {
 	.enum_mbus_code = it6625_enum_mbus_code,
 	.set_fmt = it6625_set_fmt,
-	.get_fmt = it6625_get_fmt,
+	.get_fmt = v4l2_subdev_get_fmt,
 	.get_edid = it6625_g_edid,
 	.set_edid = it6625_s_edid,
 	.enum_dv_timings = it6625_enum_dv_timings,
@@ -1800,8 +1821,26 @@ static const struct v4l2_subdev_ops it6625_ops = {
 static int it6625_init_state(struct v4l2_subdev *sd,
 			     struct v4l2_subdev_state *sd_state)
 {
+	struct it6625 *it6625 = sd_to_6625(sd);
+	struct v4l2_subdev_state *active = v4l2_subdev_get_locked_active_state(sd);
 	struct v4l2_mbus_framefmt *fmt = v4l2_subdev_state_get_format(sd_state, 0);
 
+	/*
+	 * The very first call initializes what becomes sd->active_state
+	 * itself, before it's assigned -- active is NULL then, and this
+	 * state gets the driver's own defaults. Every later call (opening
+	 * a new file handle) initializes a fresh TRY state while the
+	 * active state already exists and is locked by the same mutex
+	 * (state->lock is assigned before init_state() runs), so seed it
+	 * from the current active format instead of reverting to boot
+	 * defaults.
+	 */
+	if (active) {
+		*fmt = *v4l2_subdev_state_get_format(active, 0);
+		return 0;
+	}
+
+	it6625_fill_timings_format(&it6625->timings, fmt);
 	fmt->code = it6625_formats[0].mbus_fmt_code;
 	fmt->colorspace = format_to_colorspace(it6625_formats[0].csi_format);
 
@@ -1842,6 +1881,8 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 			   it6625->csi_lanes == 3;
 
 	v4l2_ctrl_handler_init(hdl, 4);
+	hdl->lock = &it6625->it6625_lock;
+
 	it6625->ctrl_5v_detect =
 		v4l2_ctrl_new_std(hdl, NULL, V4L2_CID_DV_RX_POWER_PRESENT,
 				  0, 1, 0, 0);
@@ -2050,8 +2091,6 @@ static void it6625_init_data(struct it6625 *it6625)
 	static struct v4l2_dv_timings default_timing =
 			V4L2_DV_BT_CEA_1920X1080P60;
 
-	it6625->csi_format = it6625_formats[0].csi_format;
-	it6625->mbus_fmt_code = it6625_formats[0].mbus_fmt_code;
 	it6625->timings = default_timing;
 	/* firmware ships with a verified 2-block default EDID in EDID RAM */
 	it6625->edid_blocks = 2;
@@ -2246,9 +2285,16 @@ static int it6625_probe(struct i2c_client *client)
 		goto err_clean_work_queues;
 	}
 
+	sd->state_lock = &it6625->it6625_lock;
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
@@ -2259,7 +2305,7 @@ static int it6625_probe(struct i2c_client *client)
 	if (IS_ERR(it6625->cec_adap)) {
 		err = PTR_ERR(it6625->cec_adap);
 		dev_err(it6625->dev, "%s %d", __func__, __LINE__);
-		goto err_clean_hdl;
+		goto err_clean_state;
 	}
 
 	err = cec_register_adapter(it6625->cec_adap, &client->dev);
@@ -2267,7 +2313,7 @@ static int it6625_probe(struct i2c_client *client)
 		dev_err(it6625->dev, "%s: failed to register the cec device", __func__);
 		cec_delete_adapter(it6625->cec_adap);
 		it6625->cec_adap = NULL;
-		goto err_clean_hdl;
+		goto err_clean_state;
 	}
 
 	it6625_debugfs_init(it6625, client);
@@ -2294,6 +2340,8 @@ static int it6625_probe(struct i2c_client *client)
 	v4l2_debugfs_if_free(it6625->infoframes);
 	debugfs_remove_recursive(it6625->debugfs_dir);
 	cec_unregister_adapter(it6625->cec_adap);
+err_clean_state:
+	v4l2_subdev_cleanup(sd);
 err_clean_hdl:
 	media_entity_cleanup(&sd->entity);
 	v4l2_ctrl_handler_free(&it6625->hdl);
@@ -2330,12 +2378,20 @@ static void it6625_remove(struct i2c_client *client)
 
 	debugfs_remove_recursive(it6625->debugfs_dir);
 	cec_unregister_adapter(it6625->cec_adap);
+
+	/*
+	 * v4l2_subdev_cleanup()/v4l2_ctrl_handler_free() take it6625_lock
+	 * (shared as state_lock/hdl.lock), so they must run before it's
+	 * destroyed.
+	 */
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

