From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 03 Nov 2026 14:50:21 +0800
Subject: [PATCH 3/5] media: i2c: it6625: decode audio status fields with
 FIELD_GET()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-upstream-it6625-alsa-i2s-v1-3-bb91e2879b01@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793688630; l=8899;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=IjKKXFMyLQULTP1bFcFOJVxe44X7oyg/efvYZrDP7uw=;
 b=d/wUmtmPN+ASmm2viBdXvf54UIuwAZ0MCzpsxQAMVXLWGyQ/P3J+gnK6ZWsoUaqni7Z+mFMPf
 pbHz/cvK9M6BdbrofujBiBHokUoLmWFDYOytMN/O0CVUSdM4rB4vEOT
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The sampling-rate control compares the whole HDMI_AUDIO_INFO1 byte
against the AUD_FS code table, although AUD_FS occupies only bits
[5:0]. Any set upper bit makes every rate read back as 0.

Describe the audio registers with GENMASK() fields and decode them with
FIELD_GET(). Collect the audio status in one helper that runs under
it6625_lock: it reads RX_STATUS once, for both the video-stable and the
audio-present bits, and reads the read-only stream description in
0x6B-0x6E as a single 4-byte transfer only while audio is present. Both
audio controls are then fed from that one sample.

Drop the 0x6E alignment/delay/polarity/shift defines; they were unused,
and the audio output framing is fixed by the firmware.

Apart from masking AUD_FS, the controls behave as before: the rate
reads 0 when there is no stable signal, no audio, an unknown code or a
read error, and the present control follows the audio-present bit.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 206 +++++++++++++++++++++++++++++----------------
 1 file changed, 132 insertions(+), 74 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index b74df9dbf8c2cab7461c69bc0f926141ed7a506c..6f12a0e7601784e5b4ce2b395ad58a0dee335f27 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -83,25 +83,34 @@ MODULE_PARM_DESC(debug, "debug level (0-3)");
 #define REG_HDMI_VIDEO_INFO 0x6A
 #define B_COLOR_MODE  BIT(0)
 #define B_COLOR_DEPTH  BIT(4)
+/*
+ * 0x6B-0x6E describe the decoded HDMI audio stream that the firmware passes
+ * through to the audio output. They are read-only and only meaningful while
+ * REG_RX_STATUS reports audio present.
+ */
 #define REG_HDMI_AUDIO_INFO1 0x6B
-#define B_AUD_FS  BIT(0)
+#define M_AUD_FS  GENMASK(5, 0)
 
 #define REG_HDMI_AUDIO_INFO2 0x6C
-#define B_AUD_CH  BIT(0)
-#define B_AUD_WL  BIT(4)
+#define M_AUD_CH  GENMASK(3, 0)
+#define M_AUD_WL  GENMASK(7, 4)
 
 #define REG_HDMI_AUDIO_INFO3 0x6D
-#define B_AUD_TYPE  BIT(0)
+#define M_AUD_TYPE  GENMASK(1, 0)
+#define AUD_TYPE_LPCM 0
 #define B_AUD_MS  BIT(2)
 #define B_AUD_3D  BIT(3)
 
 #define REG_AUDIO_FMT 0x6E
-#define B_I2S_WL  BIT(0)
-#define B_I2S_ALN BIT(2)
-#define B_I2S_DLY BIT(3)
-#define B_I2S_LR  BIT(4)
-#define B_I2S_SFT BIT(5)
-#define B_AUD_OUT_IF  BIT(6)
+#define M_I2S_WL  GENMASK(1, 0)
+#define I2S_WL_16BIT 0
+#define I2S_WL_18BIT 1
+#define I2S_WL_20BIT 2
+#define I2S_WL_24BIT 3
+#define M_AUD_OUT_IF  GENMASK(7, 6)
+#define AUD_OUT_IF_I2S 0
+
+#define AUDIO_INFO_LEN 4
 
 #define REG_IF_LATCH_HB 0x6F
 #define REG_IF_DATA 0x70
@@ -249,6 +258,28 @@ enum it6625_chip_type {
 	IT6626_CHIP = 1,
 };
 
+/* decoded 0x6B-0x6E: the HDMI audio stream passed through to the output */
+struct it6625_audio_stream {
+	u8 fs_code;
+	u8 channels;
+	u8 type;
+	bool multi_stream;
+	bool is_3d;
+	u8 i2s_wl;
+	u8 out_if;
+};
+
+struct it6625_audio_info {
+	/* false if any status read failed */
+	bool read_ok;
+	/* REG_RX_STATUS */
+	bool vid_stable;
+	bool present;
+	bool avmute;
+	/* only refreshed while present */
+	struct it6625_audio_stream stream;
+};
+
 struct it6625 {
 	struct device *dev;
 	struct i2c_client *i2c_client;
@@ -584,61 +615,94 @@ static inline bool no_signal(struct it6625 *it6625)
 	return val < 0 ? true : !(val & B_RX_STABLE);
 }
 
-static inline bool audio_present(struct it6625 *it6625)
+static const struct it6625_audio_rate {
+	u8 fs_code;
+	u32 rate;
+} it6625_audio_rates[] = {
+	{ AUD32K,    32000 },
+	{ AUD44K,    44100 },
+	{ AUD48K,    48000 },
+	{ AUD64K,    64000 },
+	{ AUD88K,    88200 },
+	{ AUD96K,    96000 },
+
+	{ AUD128K,  128000 },
+	{ AUD176K,  176400 },
+	{ AUD192K,  192000 },
+	{ AUD256K,  256000 },
+	{ AUD352K,  352800 },
+	{ AUD384K,  384000 },
+
+	{ AUD512K,  512000 },
+	{ AUD705K,  705600 },
+	{ AUD768K,  768000 },
+	{ AUD1024K, 1024000 },
+	{ AUD1411K, 1411200 },
+	{ AUD1536K, 1536000 },
+};
+
+/* returns 0 for an unknown sampling-frequency code */
+static u32 it6625_audio_fs_to_rate(u8 fs_code)
+{
+	for (unsigned int i = 0; i < ARRAY_SIZE(it6625_audio_rates); i++) {
+		if (it6625_audio_rates[i].fs_code == fs_code)
+			return it6625_audio_rates[i].rate;
+	}
+
+	return 0;
+}
+
+/*
+ * Sample the audio status. REG_RX_STATUS is always read; the stream
+ * description in 0x6B-0x6E is only read while audio is present, otherwise
+ * info->stream is left untouched. read_ok is false if any read failed.
+ */
+static void it6625_read_audio_info(struct it6625 *it6625,
+				   struct it6625_audio_info *info)
 {
+	u8 buf[AUDIO_INFO_LEN];
 	int val;
 
-	val = it6625_read_byte(it6625, REG_RX_STATUS);
-	return val < 0 ? false : val & B_RX_AUD_ON;
-}
-
-static int get_audio_sampling_rate(struct it6625 *it6625)
-{
-	static const struct fs_id_map {
-		u8 fs_id;
-		u32 freq;
-	} s_fsid_map[] = {
-		{ AUD32K,    32000 },
-		{ AUD44K,    44100 },
-		{ AUD48K,    48000 },
-		{ AUD64K,    64000 },
-		{ AUD88K,    88200 },
-		{ AUD96K,    96000 },
-
-		{ AUD128K,  128000 },
-		{ AUD176K,  176400 },
-		{ AUD192K,  192000 },
-		{ AUD256K,  256000 },
-		{ AUD352K,  352800 },
-		{ AUD384K,  384000 },
-
-		{ AUD512K,  512000 },
-		{ AUD705K,  705600 },
-		{ AUD768K,  768000 },
-		{ AUD1024K, 1024000 },
-		{ AUD1411K, 1411200 },
-		{ AUD1536K, 1536000 },
-	};
-	int fs_id;
-	int i, freq = 0;
+	lockdep_assert_held(&it6625->it6625_lock);
 
-	if (no_signal(it6625) || !audio_present(it6625))
-		return 0;
+	val = it6625_read_byte(it6625, REG_RX_STATUS);
+	if (val < 0) {
+		info->read_ok = false;
+		info->vid_stable = false;
+		info->present = false;
+		info->avmute = false;
+		return;
+	}
 
-	guard(mutex)(&it6625->it6625_lock);
+	info->read_ok = true;
+	info->vid_stable = val & B_RX_STABLE;
+	info->present = val & B_RX_AUD_ON;
+	info->avmute = val & B_RX_AVMUTE;
 
-	fs_id = it6625_read_byte(it6625, REG_HDMI_AUDIO_INFO1);
-	if (fs_id < 0)
-		return 0;
+	if (!info->present)
+		return;
 
-	for (i = 0; i < ARRAY_SIZE(s_fsid_map); i++) {
-		if (s_fsid_map[i].fs_id == fs_id) {
-			freq = s_fsid_map[i].freq;
-			break;
-		}
+	if (it6625_read_bytes(it6625, REG_HDMI_AUDIO_INFO1, buf, sizeof(buf))) {
+		info->read_ok = false;
+		return;
 	}
 
-	return freq;
+	info->stream.fs_code = FIELD_GET(M_AUD_FS, buf[0]);
+	info->stream.channels = FIELD_GET(M_AUD_CH, buf[1]);
+	info->stream.type = FIELD_GET(M_AUD_TYPE, buf[2]);
+	info->stream.multi_stream = buf[2] & B_AUD_MS;
+	info->stream.is_3d = buf[2] & B_AUD_3D;
+	info->stream.i2s_wl = FIELD_GET(M_I2S_WL, buf[3]);
+	info->stream.out_if = FIELD_GET(M_AUD_OUT_IF, buf[3]);
+}
+
+/* sampling rate for the V4L2 control: 0 means unavailable */
+static u32 it6625_audio_info_rate(const struct it6625_audio_info *info)
+{
+	if (!info->read_ok || !info->vid_stable || !info->present)
+		return 0;
+
+	return it6625_audio_fs_to_rate(info->stream.fs_code);
 }
 
 static u64 it6625_get_pclk(struct it6625 *it6625)
@@ -888,20 +952,21 @@ static int it6625_s_ctrl_detect_hdmi_5v(struct v4l2_subdev *sd)
 				hdmi_5v_power_present(it6625));
 }
 
-static int it6625_s_ctrl_audio_sampling_rate(struct v4l2_subdev *sd)
+static int it6625_s_ctrl_audio(struct v4l2_subdev *sd)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
+	struct it6625_audio_info info = {};
+	int ret;
 
-	return v4l2_ctrl_s_ctrl(it6625->ctrl_audio_sampling_rate,
-				get_audio_sampling_rate(it6625));
-}
+	scoped_guard(mutex, &it6625->it6625_lock)
+		it6625_read_audio_info(it6625, &info);
 
-static int it6625_s_ctrl_audio_present(struct v4l2_subdev *sd)
-{
-	struct it6625 *it6625 = sd_to_6625(sd);
+	ret = v4l2_ctrl_s_ctrl(it6625->ctrl_audio_sampling_rate,
+			       it6625_audio_info_rate(&info));
+	if (ret)
+		return ret;
 
-	return v4l2_ctrl_s_ctrl(it6625->ctrl_audio_present,
-				audio_present(it6625));
+	return v4l2_ctrl_s_ctrl(it6625->ctrl_audio_present, info.present);
 }
 
 static int it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
@@ -912,11 +977,7 @@ static int it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
 	if (ret)
 		return ret;
 
-	ret = it6625_s_ctrl_audio_sampling_rate(sd);
-	if (ret)
-		return ret;
-
-	return it6625_s_ctrl_audio_present(sd);
+	return it6625_s_ctrl_audio(sd);
 }
 
 static int it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
@@ -1165,10 +1226,7 @@ static void it6625_irq_format_change(struct it6625 *it6625)
 
 static void it6625_irq_hdmi_audio_change(struct it6625 *it6625)
 {
-	struct v4l2_subdev *sd = &it6625->sd;
-
-	it6625_s_ctrl_audio_sampling_rate(sd);
-	it6625_s_ctrl_audio_present(sd);
+	it6625_s_ctrl_audio(&it6625->sd);
 }
 
 static void it6625_get_timings(struct it6625 *it6625,

-- 
2.34.1

