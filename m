From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 24 Nov 2026 11:04:44 +0800
Subject: [PATCH v2 7/9] media: i2c: it6625: capture compressed and HBR
 audio, not just LPCM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-upstream-it6625-alsa-i2s-v2-7-a154685f6989@ite.com.tw>
References: <20261124-upstream-it6625-alsa-i2s-v2-0-a154685f6989@ite.com.tw>
In-Reply-To: <20261124-upstream-it6625-alsa-i2s-v2-0-a154685f6989@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Brown <broonie@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, linux-sound@vger.kernel.org, 
 linux-api@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795489507; l=9188;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=vfR3wi4Sj1lgyTacMXk/A4Np+NZCoiTxtEXqzw0T+4M=;
 b=t8K2v2/jH0kt0GseN/BD2sfsEl+Uq44WEFLpZL9V3xx9Hme8s2uEMj+EjydapPwnW/oaGwkBU
 j9XFq4CpwueDnCaRpBtOoF0/ibPJGbdKZF3s/f8oFpPJTHjBHNPGJkq
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

Report the stream's type through the standard V4L2_CID_DV_RX_AUDIO_TYPE
control, so that userspace can tell LPCM, compressed, HBR and one-bit
streams apart without parsing the audio InfoFrame.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 109 ++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 93 insertions(+), 16 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 4a6ab00f04013b874e9af13f26e88f90fcbc3989..72ca1d4ecdc932609f1a38129bfa1e188a024ddf 100644
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
@@ -327,6 +333,7 @@ struct it6625 {
 	struct v4l2_ctrl *ctrl_5v_detect;
 	struct v4l2_ctrl *ctrl_audio_sampling_rate;
 	struct v4l2_ctrl *ctrl_audio_present;
+	struct v4l2_ctrl *ctrl_audio_type;
 	struct v4l2_ctrl *ctrl_link_freq;
 
 	struct delayed_work hpd_delayed_work;
@@ -1065,6 +1072,14 @@ static void it6625_audio_refresh(struct it6625 *it6625)
 	spin_unlock_irqrestore(&it6625->audio_lock, flags);
 }
 
+/* AUD_TYPE (2 bits) to V4L2_CID_DV_RX_AUDIO_TYPE */
+static const u8 it6625_audio_type_to_v4l2[] = {
+	[AUD_TYPE_LPCM] = V4L2_DV_RX_AUDIO_TYPE_LPCM,
+	[AUD_TYPE_NLPCM] = V4L2_DV_RX_AUDIO_TYPE_IEC61937,
+	[AUD_TYPE_HBR] = V4L2_DV_RX_AUDIO_TYPE_HBR,
+	[AUD_TYPE_DSD] = V4L2_DV_RX_AUDIO_TYPE_ONE_BIT,
+};
+
 /*
  * Selecting the published sample and writing both controls happen under
  * the control handler lock, so a stale sample never overwrites a newer one.
@@ -1086,6 +1101,9 @@ static int it6625_audio_update_ctrls(struct it6625 *it6625)
 	if (!ret)
 		ret = __v4l2_ctrl_s_ctrl(it6625->ctrl_audio_present,
 					 info.present);
+	if (!ret)
+		ret = __v4l2_ctrl_s_ctrl(it6625->ctrl_audio_type,
+					 it6625_audio_type_to_v4l2[info.stream.type]);
 
 	v4l2_ctrl_unlock(it6625->ctrl_audio_present);
 
@@ -2138,7 +2156,7 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 	bool cphy_3trio = it6625->bus_type == V4L2_MBUS_CSI2_CPHY &&
 			   it6625->csi_lanes == 3;
 
-	v4l2_ctrl_handler_init(hdl, 4);
+	v4l2_ctrl_handler_init(hdl, 5);
 
 	it6625->ctrl_5v_detect =
 		v4l2_ctrl_new_std(hdl, NULL, V4L2_CID_DV_RX_POWER_PRESENT,
@@ -2150,6 +2168,10 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 				     NULL);
 	it6625->ctrl_audio_present =
 		v4l2_ctrl_new_custom(hdl, &it6625_ctrl_audio_present, NULL);
+	it6625->ctrl_audio_type =
+		v4l2_ctrl_new_std_menu(hdl, NULL, V4L2_CID_DV_RX_AUDIO_TYPE,
+				       V4L2_DV_RX_AUDIO_TYPE_ONE_BIT, 0,
+				       V4L2_DV_RX_AUDIO_TYPE_LPCM);
 	it6625->ctrl_link_freq =
 		v4l2_ctrl_new_int_menu(hdl, NULL, V4L2_CID_LINK_FREQ, 0, 0,
 				       cphy_3trio ? it6626_cphy_3trio_link_freq :
@@ -2193,26 +2215,74 @@ static unsigned int it6625_audio_max_channels(const struct it6625 *it6625)
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
@@ -2288,8 +2358,9 @@ static int it6625_dai_startup(struct snd_pcm_substream *substream,
 	struct it6625 *it6625 = dai_to_6625(dai);
 	struct snd_pcm_runtime *runtime = substream->runtime;
 	struct it6625_audio_info info;
+	unsigned int channels;
 	unsigned long flags;
-	u32 gen;
+	u32 gen, rate;
 	int ret;
 
 	it6625_s_ctrl_audio(&it6625->sd);
@@ -2305,13 +2376,16 @@ static int it6625_dai_startup(struct snd_pcm_substream *substream,
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
 
@@ -2389,18 +2463,21 @@ static int it6625_dai_hw_params(struct snd_pcm_substream *substream,
 				struct snd_soc_dai *dai)
 {
 	struct it6625 *it6625 = dai_to_6625(dai);
-	const struct it6625_audio_stream *s;
+	unsigned int channels;
 	unsigned long flags;
+	u32 rate;
 	int ret;
 
 	it6625_s_ctrl_audio(&it6625->sd);
 
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

-- 
2.34.1

