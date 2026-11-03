From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 03 Nov 2026 14:50:23 +0800
Subject: [PATCH 5/5] media: i2c: it6625: capture compressed and HBR audio,
 not just LPCM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-upstream-it6625-alsa-i2s-v1-5-bb91e2879b01@ite.com.tw>
References: <20261103-upstream-it6625-alsa-i2s-v1-0-bb91e2879b01@ite.com.tw>
In-Reply-To: <20261103-upstream-it6625-alsa-i2s-v1-0-bb91e2879b01@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Brown <broonie@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, linux-sound@vger.kernel.org, 
 linux-api@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793688630; l=12769;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=wCAmb2xCM57osQBwFBWEBx5wH5tevGlbpI6pt8N+xBE=;
 b=qfTfif80G70u0ulUdBpENorUL3gUtuoSyn5+E76hkYCjFGtGRuOSFTA3M7I+f4gq+TZz6Cwxa
 S7yZYpO4d7QC+Oe9PDGW4DRGb5LOq14/O+oqlgTqCQQ6hRvyTRFUKPS
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The capture DAI accepts only LPCM. The bridge also outputs compressed
IEC 61937 streams (AC-3, DTS, ...) and high bit rate (HBR) streams
(Dolby TrueHD/MAT, DTS-HD Master Audio) on the same I2S interface, but
these are rejected.

Add it6625_audio_xport(), which derives the I2S frame rate and slot
count from the stream's coding type and sampling rate. LPCM is
unchanged. A compressed stream is carried in 2 slots at its own
sampling rate, except at the HBR rates of 768 kHz and 705.6 kHz, where
one IEC 61937 stream is spread over 8 slots on 4 data lines at a quarter
of that rate. The bridge firmware also reports the HBR coding type for
some compressed streams at ordinary rates, such as 48 kHz DTS, so the
sampling rate, not the coding type, selects the layout. A compressed
stream at 768 kHz or 705.6 kHz is rejected when fewer than 4 data lines
are connected.

Use the derived rate and channel count in the eligibility check, the
startup constraints and the hw_params comparison. DSD is still
rejected. The driver does not parse the compressed data: userspace
receives the IEC 61937 words as they are.

Add a read-only "Audio Type" menu control, V4L2_CID_IT6625_AUDIO_TYPE,
so that userspace can tell LPCM, compressed, HBR and DSD streams apart
without parsing the audio InfoFrame, and document it.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 .../userspace-api/media/drivers/it6625.rst         |  30 ++++++
 drivers/media/i2c/it6625.c                         | 118 ++++++++++++++++++---
 include/uapi/linux/it6625.h                        |  25 +++++
 3 files changed, 157 insertions(+), 16 deletions(-)

diff --git a/Documentation/userspace-api/media/drivers/it6625.rst b/Documentation/userspace-api/media/drivers/it6625.rst
index efd970e8124979abffb6f9ba3ea1e1bc193820b3..1c4d319f88946ef79e0d847ba0f8adf5b2132210 100644
--- a/Documentation/userspace-api/media/drivers/it6625.rst
+++ b/Documentation/userspace-api/media/drivers/it6625.rst
@@ -16,3 +16,33 @@ them are read-only and describe the audio of the HDMI input.
 ``V4L2_CID_IT6625_AUDIO_PRESENT (boolean)``
 -------------------------------------------
     Whether the bridge currently receives HDMI audio.
+
+``V4L2_CID_IT6625_AUDIO_TYPE (menu)``
+-------------------------------------
+    The coding type of the HDMI audio stream, as last read successfully from
+    the bridge. The value is kept when audio goes away or reading the audio
+    status fails, so it describes the current stream only while
+    ``V4L2_CID_IT6625_AUDIO_PRESENT`` is set and
+    ``V4L2_CID_IT6625_AUDIO_SAMPLING_RATE`` is not 0.
+
+.. flat-table::
+    :header-rows:  0
+    :stub-columns: 0
+    :widths:       1 4
+
+    * - ``V4L2_IT6625_AUDIO_TYPE_LPCM``
+      - Linear PCM.
+    * - ``V4L2_IT6625_AUDIO_TYPE_NLPCM``
+      - Compressed audio in IEC 61937 format.
+    * - ``V4L2_IT6625_AUDIO_TYPE_HBR``
+      - High bit rate compressed audio in IEC 61937 format. The bridge also
+        reports this type for some compressed streams at ordinary sampling
+        rates.
+    * - ``V4L2_IT6625_AUDIO_TYPE_DSD``
+      - One-bit audio. It cannot be captured.
+
+Compressed and high bit rate streams are captured as raw IEC 61937 data. The
+capture layout follows the sampling rate, not the coding type: at 768 kHz and
+705.6 kHz the stream is captured as 8 channels at a quarter of that rate,
+which needs 4 connected I2S data lines; at other rates it is captured as 2
+channels at the sampling rate.
diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index f1bd42ad15eda1a2bd22dac00ba11a5b1c790e71..f9cd15dc24960cf2caf98576ecccd3f803dbfd86 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -101,6 +101,9 @@ MODULE_PARM_DESC(debug, "debug level (0-3)");
 #define REG_HDMI_AUDIO_INFO3 0x6D
 #define M_AUD_TYPE  GENMASK(1, 0)
 #define AUD_TYPE_LPCM 0
+#define AUD_TYPE_NLPCM 1
+#define AUD_TYPE_HBR 2
+#define AUD_TYPE_DSD 3
 #define B_AUD_MS  BIT(2)
 #define B_AUD_3D  BIT(3)
 
@@ -119,6 +122,9 @@ MODULE_PARM_DESC(debug, "debug level (0-3)");
 #define IT6625_AUDIO_MAX_LANES 8
 #define IT6625_AUDIO_MAX_CHANNELS 8
 #define IT6625_AUDIO_MAX_RATE 192000
+/* HBR: one IEC 61937 stream spread over 4 lanes (8 slots) per frame */
+#define IT6625_AUDIO_HBR_LANES 4
+#define IT6625_AUDIO_HBR_CHANNELS 8
 /* status re-check period while a capture stream is open */
 #define IT6625_AUDIO_REFRESH_MS 200
 /* re-checks after an event that left present audio without a valid rate */
@@ -322,6 +328,7 @@ struct it6625 {
 	struct v4l2_ctrl *ctrl_5v_detect;
 	struct v4l2_ctrl *ctrl_audio_sampling_rate;
 	struct v4l2_ctrl *ctrl_audio_present;
+	struct v4l2_ctrl *ctrl_audio_type;
 	struct v4l2_ctrl *ctrl_link_freq;
 
 	struct delayed_work hpd_delayed_work;
@@ -1069,6 +1076,9 @@ static int it6625_audio_update_ctrls(struct it6625 *it6625)
 	if (!ret)
 		ret = __v4l2_ctrl_s_ctrl(it6625->ctrl_audio_present,
 					 info.present);
+	if (!ret)
+		ret = __v4l2_ctrl_s_ctrl(it6625->ctrl_audio_type,
+					 info.stream.type);
 
 	v4l2_ctrl_unlock(it6625->ctrl_audio_present);
 
@@ -2124,6 +2134,25 @@ static const struct v4l2_ctrl_config it6625_ctrl_audio_present = {
 	.flags = V4L2_CTRL_FLAG_READ_ONLY,
 };
 
+static const char * const it6625_audio_type_menu[] = {
+	[V4L2_IT6625_AUDIO_TYPE_LPCM] = "LPCM",
+	[V4L2_IT6625_AUDIO_TYPE_NLPCM] = "NLPCM",
+	[V4L2_IT6625_AUDIO_TYPE_HBR] = "HBR",
+	[V4L2_IT6625_AUDIO_TYPE_DSD] = "DSD",
+	NULL,
+};
+
+static const struct v4l2_ctrl_config it6625_ctrl_audio_type = {
+	.id = V4L2_CID_IT6625_AUDIO_TYPE,
+	.name = "Audio Type",
+	.type = V4L2_CTRL_TYPE_MENU,
+	.min = V4L2_IT6625_AUDIO_TYPE_LPCM,
+	.max = V4L2_IT6625_AUDIO_TYPE_DSD,
+	.def = V4L2_IT6625_AUDIO_TYPE_LPCM,
+	.qmenu = it6625_audio_type_menu,
+	.flags = V4L2_CTRL_FLAG_READ_ONLY,
+};
+
 static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
@@ -2131,7 +2160,7 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 	bool cphy_3trio = it6625->bus_type == V4L2_MBUS_CSI2_CPHY &&
 			   it6625->csi_lanes == 3;
 
-	v4l2_ctrl_handler_init(hdl, 4);
+	v4l2_ctrl_handler_init(hdl, 5);
 
 	it6625->ctrl_5v_detect =
 		v4l2_ctrl_new_std(hdl, NULL, V4L2_CID_DV_RX_POWER_PRESENT,
@@ -2143,6 +2172,8 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 				     NULL);
 	it6625->ctrl_audio_present =
 		v4l2_ctrl_new_custom(hdl, &it6625_ctrl_audio_present, NULL);
+	it6625->ctrl_audio_type =
+		v4l2_ctrl_new_custom(hdl, &it6625_ctrl_audio_type, NULL);
 	it6625->ctrl_link_freq =
 		v4l2_ctrl_new_int_menu(hdl, NULL, V4L2_CID_LINK_FREQ, 0, 0,
 				       cphy_3trio ? it6626_cphy_3trio_link_freq :
@@ -2186,26 +2217,74 @@ static unsigned int it6625_audio_max_channels(const struct it6625 *it6625)
 	return min(2U * it6625->audio_lanes, IT6625_AUDIO_MAX_CHANNELS);
 }
 
+/*
+ * I2S frame rate and slot count that carry this stream. Pure, callable in
+ * atomic context; returns -ENODEV for a stream the I2S output can't carry.
+ *
+ * LPCM goes out as is. A compressed IEC 61937 stream at up to 192 kHz
+ * takes 2 slots at its own sampling rate, whatever channel count the
+ * source signals. An HBR stream (AUD_FS 768 or 705.6 kHz) is one IEC 61937
+ * stream at 4x the frame rate spread over 4 lanes: 8 slots at a quarter of
+ * that rate.
+ *
+ * The firmware doesn't keep AUD_TYPE to its documented meaning: it reports
+ * HBR for a plain 48 kHz DTS stream too. So the rate, not NLPCM vs. HBR,
+ * selects the layout of a compressed stream.
+ */
+static int it6625_audio_xport(const struct it6625 *it6625,
+			      const struct it6625_audio_stream *s,
+			      u32 *rate, unsigned int *channels)
+{
+	u32 fs = it6625_audio_fs_to_rate(s->fs_code);
+
+	if (!fs)
+		return -ENODEV;
+
+	switch (s->type) {
+	case AUD_TYPE_LPCM:
+		*rate = fs;
+		*channels = s->channels;
+		break;
+	case AUD_TYPE_NLPCM:
+	case AUD_TYPE_HBR:
+		if (fs == 768000 || fs == 705600) {
+			*rate = fs / IT6625_AUDIO_HBR_LANES;
+			*channels = IT6625_AUDIO_HBR_CHANNELS;
+		} else {
+			*rate = fs;
+			*channels = 2;
+		}
+		break;
+	default:
+		return -ENODEV;
+	}
+
+	if (*rate > IT6625_AUDIO_MAX_RATE)
+		return -ENODEV;
+
+	if (*channels < 2 || *channels % 2 ||
+	    *channels > it6625_audio_max_channels(it6625))
+		return -ENODEV;
+
+	return 0;
+}
+
 /* can this audio status be captured? Pure check, callable in atomic context. */
 static int it6625_audio_check(const struct it6625 *it6625,
 			      const struct it6625_audio_info *info)
 {
 	const struct it6625_audio_stream *s = &info->stream;
-	u32 rate = it6625_audio_fs_to_rate(s->fs_code);
+	unsigned int channels;
+	u32 rate;
 
 	if (!info->read_ok || !info->vid_stable || !info->present ||
 	    info->avmute)
 		return -ENODEV;
 
-	if (s->out_if != AUD_OUT_IF_I2S || s->type != AUD_TYPE_LPCM ||
-	    s->multi_stream || s->is_3d)
-		return -ENODEV;
-
-	if (!rate || rate > IT6625_AUDIO_MAX_RATE)
+	if (s->out_if != AUD_OUT_IF_I2S || s->multi_stream || s->is_3d)
 		return -ENODEV;
 
-	if (s->channels < 2 || s->channels % 2 ||
-	    s->channels > it6625_audio_max_channels(it6625))
+	if (it6625_audio_xport(it6625, s, &rate, &channels))
 		return -ENODEV;
 
 	if (!it6625_audio_wl_bits(s->i2s_wl))
@@ -2281,8 +2360,9 @@ static int it6625_dai_startup(struct snd_pcm_substream *substream,
 	struct it6625 *it6625 = dai_to_6625(dai);
 	struct snd_pcm_runtime *runtime = substream->runtime;
 	struct it6625_audio_info info;
+	unsigned int channels;
 	unsigned long flags;
-	u32 gen;
+	u32 gen, rate;
 	int ret;
 
 	it6625_audio_refresh(it6625);
@@ -2298,13 +2378,16 @@ static int it6625_dai_startup(struct snd_pcm_substream *substream,
 	if (ret)
 		return ret;
 
+	/* the check above passed, so this can't fail */
+	it6625_audio_xport(it6625, &info.stream, &rate, &channels);
+
 	ret = snd_pcm_hw_constraint_single(runtime, SNDRV_PCM_HW_PARAM_RATE,
-					   it6625_audio_fs_to_rate(info.stream.fs_code));
+					   rate);
 	if (ret < 0)
 		return ret;
 
 	ret = snd_pcm_hw_constraint_single(runtime, SNDRV_PCM_HW_PARAM_CHANNELS,
-					   info.stream.channels);
+					   channels);
 	if (ret < 0)
 		return ret;
 
@@ -2378,18 +2461,21 @@ static int it6625_dai_hw_params(struct snd_pcm_substream *substream,
 				struct snd_soc_dai *dai)
 {
 	struct it6625 *it6625 = dai_to_6625(dai);
-	const struct it6625_audio_stream *s;
+	unsigned int channels;
 	unsigned long flags;
+	u32 rate;
 	int ret;
 
 	it6625_audio_refresh(it6625);
 
 	spin_lock_irqsave(&it6625->audio_lock, flags);
 	ret = it6625_audio_validate_locked(it6625);
-	s = &it6625->audio_accepted;
+	if (!ret)
+		ret = it6625_audio_xport(it6625, &it6625->audio_accepted,
+					 &rate, &channels);
 	if (!ret &&
-	    (params_rate(params) != it6625_audio_fs_to_rate(s->fs_code) ||
-	     params_channels(params) != s->channels ||
+	    (params_rate(params) != rate ||
+	     params_channels(params) != channels ||
 	     params_format(params) != SNDRV_PCM_FORMAT_S32_LE))
 		ret = -EINVAL;
 	spin_unlock_irqrestore(&it6625->audio_lock, flags);
diff --git a/include/uapi/linux/it6625.h b/include/uapi/linux/it6625.h
index a895658aaf6a80d3fb624cdece33c5135161c72d..9ab85378ac77d1e06bc87964c1066d35ad177c15 100644
--- a/include/uapi/linux/it6625.h
+++ b/include/uapi/linux/it6625.h
@@ -22,4 +22,29 @@
  */
 #define V4L2_CID_IT6625_AUDIO_PRESENT		(V4L2_CID_USER_IT6625_BASE + 1)
 
+/*
+ * Coding type of the HDMI audio stream, as last successfully read from the
+ * bridge. Read-only menu. It is kept, not cleared, when audio goes away or
+ * a status read fails, so it describes the current stream only while
+ * V4L2_CID_IT6625_AUDIO_PRESENT is set and
+ * V4L2_CID_IT6625_AUDIO_SAMPLING_RATE is non-zero.
+ *
+ * LPCM:  linear PCM, captured as is.
+ * NLPCM, HBR: IEC 61937 compressed stream, as reported by the bridge
+ *        firmware (which also reports HBR for plain 48 kHz DTS). The
+ *        capture layout follows V4L2_CID_IT6625_AUDIO_SAMPLING_RATE: at
+ *        768/705.6 kHz (TrueHD/MAT, DTS-HD MA) 8 channels on 4 I2S lanes
+ *        at a quarter of that rate, otherwise (AC-3, DTS, ...) 2 channels
+ *        at that rate.
+ * DSD:   one-bit audio; not capturable.
+ */
+#define V4L2_CID_IT6625_AUDIO_TYPE		(V4L2_CID_USER_IT6625_BASE + 2)
+
+enum v4l2_it6625_audio_type {
+	V4L2_IT6625_AUDIO_TYPE_LPCM = 0,
+	V4L2_IT6625_AUDIO_TYPE_NLPCM = 1,
+	V4L2_IT6625_AUDIO_TYPE_HBR = 2,
+	V4L2_IT6625_AUDIO_TYPE_DSD = 3,
+};
+
 #endif /* _UAPI_LINUX_IT6625_H */

-- 
2.34.1

