From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 03 Nov 2026 14:50:22 +0800
Subject: [PATCH 4/5] media: i2c: it6625: add I2S audio capture DAI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-upstream-it6625-alsa-i2s-v1-4-bb91e2879b01@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793688630; l=25772;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=JE71kUEyiv9JA6gtRukjAISwtK6BXBoSoJrfX1VQW00=;
 b=M5NkiR5+dHSgqC+Hi5T8BNMANcoqZm/X7I8knwwNl51+URsBvPTUmelV8Wg1UTIrzRCdzIoa5
 G9eMjHbNYpoB23VhrElhKd565z1BQ9nDg5DQf541gY/pYv0Xv6vixky
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IT6625 and IT6626 decode the HDMI audio stream and pass it through to an
I2S output. The bridge drives the bit and frame clocks and uses standard
I2S framing with 16, 20 or 24 valid bits in 32-bit slots. None of this
is host-configurable: 0x6B-0x6E only report the stream being output.

Register an ASoC component with one capture DAI when the device node has
'#sound-dai-cells'. The DAI accepts only what the bridge currently
outputs: single-stream, non-3D LPCM at 32 kHz to 192 kHz, S32_LE with the
valid bits reported through msbits, and 2 channels per connected I2S
data pin (from 'ite,i2s-data-lanes'), up to 8 channels. startup pins
these values, and hw_params, prepare and the start and resume triggers
check them again against the latest observed status.

The I2S clocks are not guaranteed to keep running at a constant rate
when audio is lost, muted or changes format. Any observed change of the
audio status, and any status read failure, therefore stops a running
capture with an XRUN. A paused stream whose audio changed is still
released, and then stopped with an XRUN: refusing the release would
leave it paused, where a blocking read waits indefinitely. Changes are
observed on the audio-change, video-change, 5V and AV-mute events, and
every 200 ms while a capture stream is open, to catch changes that raise
no event.

The V4L2 audio controls are updated from the same status sample. The
bridge can report audio before the video signal is stable or the
sampling-frequency code is valid, and may raise no further event once
they are. After an event that leaves audio present without a valid rate,
the status is therefore checked again every 200 ms, up to 15 times, also
when no capture stream is open.

The component is registered without devm and unregistered first in
remove. Unregistering waits for open capture streams to be closed, so no
DAI callback can run while the rest of the driver is torn down. Unbind
therefore blocks while a capture stream is held open.

The driver still builds without ASoC: the audio code is compiled out
when SND_SOC is disabled.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/Kconfig  |   1 +
 drivers/media/i2c/it6625.c | 609 +++++++++++++++++++++++++++++++++++++++++++--
 2 files changed, 595 insertions(+), 15 deletions(-)

diff --git a/drivers/media/i2c/Kconfig b/drivers/media/i2c/Kconfig
index 7de2d095c96960070a3eaed859925fc97c0e12ca..6c97bccd6794e9c0821c903d2aa89a48badef482 100644
--- a/drivers/media/i2c/Kconfig
+++ b/drivers/media/i2c/Kconfig
@@ -1354,6 +1354,7 @@ config VIDEO_IT6625
 	tristate "IT6625 HDMI to MIPI CSI bridge"
 	depends on VIDEO_DEV && I2C
 	depends on OF
+	depends on SND_SOC || !SND_SOC
 	select CEC_CORE
 	select HDMI
 	select MEDIA_CONTROLLER
diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 6f12a0e7601784e5b4ce2b395ad58a0dee335f27..f1bd42ad15eda1a2bd22dac00ba11a5b1c790e71 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -30,6 +30,9 @@
 #include <media/v4l2-dv-timings.h>
 #include <media/v4l2-event.h>
 #include <media/v4l2-fwnode.h>
+#include <sound/pcm.h>
+#include <sound/pcm_params.h>
+#include <sound/soc.h>
 #include <uapi/linux/it6625.h>
 
 static int debug;
@@ -112,6 +115,15 @@ MODULE_PARM_DESC(debug, "debug level (0-3)");
 
 #define AUDIO_INFO_LEN 4
 
+/* I2S capture DAI */
+#define IT6625_AUDIO_MAX_LANES 8
+#define IT6625_AUDIO_MAX_CHANNELS 8
+#define IT6625_AUDIO_MAX_RATE 192000
+/* status re-check period while a capture stream is open */
+#define IT6625_AUDIO_REFRESH_MS 200
+/* re-checks after an event that left present audio without a valid rate */
+#define IT6625_AUDIO_SETTLE_POLLS 15
+
 #define REG_IF_LATCH_HB 0x6F
 #define REG_IF_DATA 0x70
 #define REG_EMP_DATA 0xA0
@@ -343,6 +355,35 @@ struct it6625 {
 	int if_snapshot_err;
 	/* set just before complete(), to disambiguate timeout vs. capture */
 	bool if_snapshot_done;
+
+	/*
+	 * ASoC capture DAI state. audio is written with both it6625_lock and
+	 * audio_lock held, so either one is enough to read it. Everything
+	 * else below is protected by audio_lock, which is taken with
+	 * spin_lock_irqsave() because .trigger runs in atomic context. It is
+	 * never held across I2C, V4L2 control, ALSA core or work-sync calls.
+	 */
+	spinlock_t audio_lock;
+	/* last published audio status sample */
+	struct it6625_audio_info audio;
+	/* bumped on any observed audio status change and on read failures */
+	u32 audio_gen;
+	/* the open capture stream, or NULL */
+	struct snd_pcm_substream *audio_substream;
+	/* audio_gen and stream accepted by the open capture stream */
+	u32 audio_accepted_gen;
+	struct it6625_audio_stream audio_accepted;
+	bool audio_running;
+	/* stream shutdown in progress: queue no new work */
+	bool audio_block;
+	/* refresh work runs left to follow a rate that is still settling */
+	unsigned int audio_settle_polls;
+	/* component registered by probe, unregistered first in remove */
+	bool audio_registered;
+	/* number of connected I2S data pins, from ite,i2s-data-lanes */
+	u8 audio_lanes;
+	struct work_struct audio_xrun_work;
+	struct delayed_work audio_refresh_work;
 };
 
 /*
@@ -952,21 +993,132 @@ static int it6625_s_ctrl_detect_hdmi_5v(struct v4l2_subdev *sd)
 				hdmi_5v_power_present(it6625));
 }
 
+static bool it6625_audio_stream_equal(const struct it6625_audio_stream *a,
+				      const struct it6625_audio_stream *b)
+{
+	return a->fs_code == b->fs_code &&
+	       a->channels == b->channels &&
+	       a->type == b->type &&
+	       a->multi_stream == b->multi_stream &&
+	       a->is_3d == b->is_3d &&
+	       a->i2s_wl == b->i2s_wl &&
+	       a->out_if == b->out_if;
+}
+
+/*
+ * Any change of the status bits or of the stream description, and every
+ * read failure, invalidates an accepted capture stream: the I2S clocks are
+ * not guaranteed to keep running at one rate across such a change.
+ */
+static bool it6625_audio_changed(const struct it6625_audio_info *old,
+				 const struct it6625_audio_info *new)
+{
+	return !new->read_ok ||
+	       new->read_ok != old->read_ok ||
+	       new->vid_stable != old->vid_stable ||
+	       new->present != old->present ||
+	       new->avmute != old->avmute ||
+	       !it6625_audio_stream_equal(&new->stream, &old->stream);
+}
+
+/*
+ * Sample the audio status and publish it. The read and the publication
+ * both happen under it6625_lock, so concurrent refreshes cannot publish
+ * out of order.
+ */
+static void it6625_audio_refresh(struct it6625 *it6625)
+{
+	struct it6625_audio_info info;
+	unsigned long flags;
+
+	guard(mutex)(&it6625->it6625_lock);
+
+	/* keep the last stream description if audio is absent */
+	info = it6625->audio;
+	it6625_read_audio_info(it6625, &info);
+
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	if (it6625_audio_changed(&it6625->audio, &info)) {
+		it6625->audio_gen++;
+		if (it6625->audio_substream && it6625->audio_running &&
+		    !it6625->audio_block)
+			queue_work(system_wq, &it6625->audio_xrun_work);
+	}
+	it6625->audio = info;
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+}
+
+/*
+ * Selecting the published sample and writing both controls happen under
+ * the control handler lock, so a stale sample never overwrites a newer one.
+ */
+static int it6625_audio_update_ctrls(struct it6625 *it6625)
+{
+	struct it6625_audio_info info;
+	unsigned long flags;
+	int ret;
+
+	v4l2_ctrl_lock(it6625->ctrl_audio_present);
+
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	info = it6625->audio;
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+
+	ret = __v4l2_ctrl_s_ctrl(it6625->ctrl_audio_sampling_rate,
+				 it6625_audio_info_rate(&info));
+	if (!ret)
+		ret = __v4l2_ctrl_s_ctrl(it6625->ctrl_audio_present,
+					 info.present);
+
+	v4l2_ctrl_unlock(it6625->ctrl_audio_present);
+
+	return ret;
+}
+
 static int it6625_s_ctrl_audio(struct v4l2_subdev *sd)
 {
 	struct it6625 *it6625 = sd_to_6625(sd);
-	struct it6625_audio_info info = {};
+
+	it6625_audio_refresh(it6625);
+
+	return it6625_audio_update_ctrls(it6625);
+}
+
+/* audio is present but its rate is not valid yet. Caller holds audio_lock. */
+static bool it6625_audio_settling(struct it6625 *it6625)
+{
+	lockdep_assert_held(&it6625->audio_lock);
+
+	return it6625->audio.read_ok && it6625->audio.present &&
+	       !it6625_audio_info_rate(&it6625->audio);
+}
+
+/*
+ * Update the audio controls on a status event. The chip can report audio
+ * present before the video is stable or the sampling-frequency code is
+ * valid, and may raise no further interrupt once they settle, so keep
+ * re-checking for a while in that case.
+ */
+static int it6625_audio_event(struct it6625 *it6625)
+{
+	unsigned long flags;
 	int ret;
 
-	scoped_guard(mutex, &it6625->it6625_lock)
-		it6625_read_audio_info(it6625, &info);
+	ret = it6625_s_ctrl_audio(&it6625->sd);
 
-	ret = v4l2_ctrl_s_ctrl(it6625->ctrl_audio_sampling_rate,
-			       it6625_audio_info_rate(&info));
-	if (ret)
-		return ret;
+	/*
+	 * Load the budget and queue the work in one section, so the work
+	 * can't be queued again after it has used up the budget.
+	 */
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	if (it6625_audio_settling(it6625)) {
+		it6625->audio_settle_polls = IT6625_AUDIO_SETTLE_POLLS;
+		schedule_delayed_work(&it6625->audio_refresh_work,
+				      msecs_to_jiffies(IT6625_AUDIO_REFRESH_MS));
+	}
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
 
-	return v4l2_ctrl_s_ctrl(it6625->ctrl_audio_present, info.present);
+	return ret;
 }
 
 static int it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
@@ -977,7 +1129,7 @@ static int it6625_v4l2_sd_ctrl_update(struct v4l2_subdev *sd)
 	if (ret)
 		return ret;
 
-	return it6625_s_ctrl_audio(sd);
+	return it6625_audio_event(sd_to_6625(sd));
 }
 
 static int it6625_enable_stream_locked(struct it6625 *it6625, bool enable)
@@ -1208,6 +1360,9 @@ static void it6625_irq_format_change(struct it6625 *it6625)
 	};
 	int ret;
 
+	/* the audio rate is only valid while the video is stable */
+	it6625_audio_event(it6625);
+
 	if (no_signal(it6625)) {
 		if (sd->devnode)
 			v4l2_subdev_notify_event(sd, &it6625_ev_fmt);
@@ -1226,7 +1381,7 @@ static void it6625_irq_format_change(struct it6625 *it6625)
 
 static void it6625_irq_hdmi_audio_change(struct it6625 *it6625)
 {
-	it6625_s_ctrl_audio(&it6625->sd);
+	it6625_audio_event(it6625);
 }
 
 static void it6625_get_timings(struct it6625 *it6625,
@@ -1314,11 +1469,13 @@ static void it6625_irq_avmute_change(struct it6625 *it6625)
 	u8 avmute;
 
 	val = it6625_read_byte(it6625, REG_RX_STATUS);
-	if (val < 0)
-		return;
+	if (val >= 0) {
+		avmute = (val & B_RX_AVMUTE) ? 1 : 0;
+		v4l2_info(sd, "AVMute change to %d", avmute);
+	}
 
-	avmute = (val & B_RX_AVMUTE) ? 1 : 0;
-	v4l2_info(sd, "AVMute change to %d", avmute);
+	/* AV mute makes the audio unusable for capture */
+	it6625_audio_event(it6625);
 }
 
 static void it6625_dispatch_int_status1(struct it6625 *it6625, int int_sts1)
@@ -2001,6 +2158,369 @@ static int it6625_v4l2_init_controls(struct v4l2_subdev *sd)
 	return 0;
 }
 
+/*
+ * I2S capture DAI. The firmware decodes the HDMI audio stream and passes it
+ * through to the I2S output, which it drives as bit and frame clock
+ * provider: standard I2S framing, 16/20/24-bit data in 32-bit slots. None of
+ * this is configurable, so the DAI only accepts streams matching the
+ * currently observed audio and stops a running capture when that changes.
+ */
+
+/* valid bits per 32-bit slot, 0 if unsupported */
+static unsigned int it6625_audio_wl_bits(u8 i2s_wl)
+{
+	switch (i2s_wl) {
+	case I2S_WL_16BIT:
+		return 16;
+	case I2S_WL_20BIT:
+		return 20;
+	case I2S_WL_24BIT:
+		return 24;
+	default:
+		return 0;
+	}
+}
+
+static unsigned int it6625_audio_max_channels(const struct it6625 *it6625)
+{
+	return min(2U * it6625->audio_lanes, IT6625_AUDIO_MAX_CHANNELS);
+}
+
+/* can this audio status be captured? Pure check, callable in atomic context. */
+static int it6625_audio_check(const struct it6625 *it6625,
+			      const struct it6625_audio_info *info)
+{
+	const struct it6625_audio_stream *s = &info->stream;
+	u32 rate = it6625_audio_fs_to_rate(s->fs_code);
+
+	if (!info->read_ok || !info->vid_stable || !info->present ||
+	    info->avmute)
+		return -ENODEV;
+
+	if (s->out_if != AUD_OUT_IF_I2S || s->type != AUD_TYPE_LPCM ||
+	    s->multi_stream || s->is_3d)
+		return -ENODEV;
+
+	if (!rate || rate > IT6625_AUDIO_MAX_RATE)
+		return -ENODEV;
+
+	if (s->channels < 2 || s->channels % 2 ||
+	    s->channels > it6625_audio_max_channels(it6625))
+		return -ENODEV;
+
+	if (!it6625_audio_wl_bits(s->i2s_wl))
+		return -ENODEV;
+
+	return 0;
+}
+
+/* is the accepted stream still current? Caller holds audio_lock. */
+static int it6625_audio_validate_locked(struct it6625 *it6625)
+{
+	lockdep_assert_held(&it6625->audio_lock);
+
+	if (it6625->audio_gen != it6625->audio_accepted_gen)
+		return -EPIPE;
+
+	return it6625_audio_check(it6625, &it6625->audio);
+}
+
+static void it6625_audio_xrun_work(struct work_struct *work)
+{
+	struct it6625 *it6625 = container_of(work, struct it6625,
+					     audio_xrun_work);
+	struct snd_pcm_substream *substream = NULL;
+	unsigned long flags;
+
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	if (!it6625->audio_block)
+		substream = it6625->audio_substream;
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+
+	/* .shutdown drains this work before the substream goes away */
+	if (IS_ENABLED(CONFIG_SND_SOC) && substream)
+		snd_pcm_stop_xrun(substream);
+}
+
+/*
+ * Catch persistent audio changes that raise no interrupt while a capture
+ * stream is open, and follow a rate that is still settling after an event
+ * for at most IT6625_AUDIO_SETTLE_POLLS runs.
+ */
+static void it6625_audio_refresh_work(struct work_struct *work)
+{
+	struct it6625 *it6625 = container_of(to_delayed_work(work),
+					     struct it6625, audio_refresh_work);
+	unsigned long flags;
+	bool rearm;
+
+	it6625_s_ctrl_audio(&it6625->sd);
+
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	/* every run uses up one re-check of a settle budget */
+	if (it6625->audio_settle_polls)
+		it6625->audio_settle_polls--;
+	rearm = (it6625->audio_substream && !it6625->audio_block) ||
+		(it6625->audio_settle_polls && it6625_audio_settling(it6625));
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+
+	if (rearm)
+		schedule_delayed_work(&it6625->audio_refresh_work,
+				      msecs_to_jiffies(IT6625_AUDIO_REFRESH_MS));
+}
+
+static struct it6625 *dai_to_6625(struct snd_soc_dai *dai)
+{
+	/* the I2C client data is the V4L2 subdev */
+	return sd_to_6625(snd_soc_dai_get_drvdata(dai));
+}
+
+static int it6625_dai_startup(struct snd_pcm_substream *substream,
+			      struct snd_soc_dai *dai)
+{
+	struct it6625 *it6625 = dai_to_6625(dai);
+	struct snd_pcm_runtime *runtime = substream->runtime;
+	struct it6625_audio_info info;
+	unsigned long flags;
+	u32 gen;
+	int ret;
+
+	it6625_audio_refresh(it6625);
+
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	if (it6625->audio_substream || it6625->audio_block)
+		ret = -EBUSY;
+	else
+		ret = it6625_audio_check(it6625, &it6625->audio);
+	info = it6625->audio;
+	gen = it6625->audio_gen;
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+	if (ret)
+		return ret;
+
+	ret = snd_pcm_hw_constraint_single(runtime, SNDRV_PCM_HW_PARAM_RATE,
+					   it6625_audio_fs_to_rate(info.stream.fs_code));
+	if (ret < 0)
+		return ret;
+
+	ret = snd_pcm_hw_constraint_single(runtime, SNDRV_PCM_HW_PARAM_CHANNELS,
+					   info.stream.channels);
+	if (ret < 0)
+		return ret;
+
+	ret = snd_pcm_hw_constraint_mask64(runtime, SNDRV_PCM_HW_PARAM_FORMAT,
+					   SNDRV_PCM_FMTBIT_S32_LE);
+	if (ret < 0)
+		return ret;
+
+	ret = snd_pcm_hw_constraint_msbits(runtime, 0, 32,
+					   it6625_audio_wl_bits(info.stream.i2s_wl));
+	if (ret < 0)
+		return ret;
+
+	/* recheck: the status may have changed while installing constraints */
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	if (it6625->audio_substream || it6625->audio_block)
+		ret = -EBUSY;
+	else if (it6625->audio_gen != gen)
+		ret = -EPIPE;
+	else
+		ret = it6625_audio_check(it6625, &it6625->audio);
+	if (!ret) {
+		it6625->audio_substream = substream;
+		it6625->audio_accepted = info.stream;
+		it6625->audio_accepted_gen = gen;
+		it6625->audio_running = false;
+	}
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+	if (ret)
+		return ret;
+
+	schedule_delayed_work(&it6625->audio_refresh_work,
+			      msecs_to_jiffies(IT6625_AUDIO_REFRESH_MS));
+
+	return 0;
+}
+
+/* also called on rollback after a successful .startup */
+static void it6625_dai_shutdown(struct snd_pcm_substream *substream,
+				struct snd_soc_dai *dai)
+{
+	struct it6625 *it6625 = dai_to_6625(dai);
+	unsigned long flags;
+
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	it6625->audio_block = true;
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+
+	cancel_delayed_work_sync(&it6625->audio_refresh_work);
+	cancel_work_sync(&it6625->audio_xrun_work);
+
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	it6625->audio_substream = NULL;
+	it6625->audio_running = false;
+	it6625->audio_block = false;
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+}
+
+static int it6625_dai_set_fmt(struct snd_soc_dai *dai, unsigned int fmt)
+{
+	if ((fmt & SND_SOC_DAIFMT_CLOCK_PROVIDER_MASK) != SND_SOC_DAIFMT_CBP_CFP ||
+	    (fmt & SND_SOC_DAIFMT_FORMAT_MASK) != SND_SOC_DAIFMT_I2S ||
+	    (fmt & SND_SOC_DAIFMT_INV_MASK) != SND_SOC_DAIFMT_NB_NF)
+		return -EINVAL;
+
+	return 0;
+}
+
+static int it6625_dai_hw_params(struct snd_pcm_substream *substream,
+				struct snd_pcm_hw_params *params,
+				struct snd_soc_dai *dai)
+{
+	struct it6625 *it6625 = dai_to_6625(dai);
+	const struct it6625_audio_stream *s;
+	unsigned long flags;
+	int ret;
+
+	it6625_audio_refresh(it6625);
+
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	ret = it6625_audio_validate_locked(it6625);
+	s = &it6625->audio_accepted;
+	if (!ret &&
+	    (params_rate(params) != it6625_audio_fs_to_rate(s->fs_code) ||
+	     params_channels(params) != s->channels ||
+	     params_format(params) != SNDRV_PCM_FORMAT_S32_LE))
+		ret = -EINVAL;
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+
+	return ret;
+}
+
+static int it6625_dai_prepare(struct snd_pcm_substream *substream,
+			      struct snd_soc_dai *dai)
+{
+	struct it6625 *it6625 = dai_to_6625(dai);
+	unsigned long flags;
+	int ret;
+
+	it6625_audio_refresh(it6625);
+
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	ret = it6625_audio_validate_locked(it6625);
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+
+	return ret;
+}
+
+/*
+ * Atomic: only the published status is consulted. A loss that no refresh
+ * has observed yet is handled by the refresh that observes it.
+ */
+static int it6625_dai_trigger(struct snd_pcm_substream *substream, int cmd,
+			      struct snd_soc_dai *dai)
+{
+	struct it6625 *it6625 = dai_to_6625(dai);
+	unsigned long flags;
+	int ret = 0;
+
+	spin_lock_irqsave(&it6625->audio_lock, flags);
+	switch (cmd) {
+	case SNDRV_PCM_TRIGGER_START:
+	case SNDRV_PCM_TRIGGER_RESUME:
+		ret = it6625_audio_validate_locked(it6625);
+		if (!ret)
+			it6625->audio_running = true;
+		break;
+	case SNDRV_PCM_TRIGGER_PAUSE_RELEASE:
+		/*
+		 * A refused release would leave the stream paused, and a
+		 * blocking read on a paused stream never returns. If the
+		 * stream became stale while paused, release it and stop it
+		 * with an XRUN instead.
+		 */
+		it6625->audio_running = true;
+		if (it6625_audio_validate_locked(it6625) &&
+		    it6625->audio_substream && !it6625->audio_block)
+			queue_work(system_wq, &it6625->audio_xrun_work);
+		break;
+	case SNDRV_PCM_TRIGGER_STOP:
+	case SNDRV_PCM_TRIGGER_SUSPEND:
+	case SNDRV_PCM_TRIGGER_PAUSE_PUSH:
+		it6625->audio_running = false;
+		break;
+	default:
+		ret = -EINVAL;
+		break;
+	}
+	spin_unlock_irqrestore(&it6625->audio_lock, flags);
+
+	return ret;
+}
+
+static const struct snd_soc_dai_ops it6625_dai_ops = {
+	.startup = it6625_dai_startup,
+	.shutdown = it6625_dai_shutdown,
+	.set_fmt = it6625_dai_set_fmt,
+	.hw_params = it6625_dai_hw_params,
+	.prepare = it6625_dai_prepare,
+	.trigger = it6625_dai_trigger,
+};
+
+static struct snd_soc_dai_driver it6625_dai = {
+	.name = "it6625-i2s",
+	.capture = {
+		.stream_name = "Capture",
+		.channels_min = 2,
+		.channels_max = IT6625_AUDIO_MAX_CHANNELS,
+		.rates = SNDRV_PCM_RATE_32000 | SNDRV_PCM_RATE_44100 |
+			 SNDRV_PCM_RATE_48000 | SNDRV_PCM_RATE_64000 |
+			 SNDRV_PCM_RATE_88200 | SNDRV_PCM_RATE_96000 |
+			 SNDRV_PCM_RATE_128000 | SNDRV_PCM_RATE_176400 |
+			 SNDRV_PCM_RATE_192000,
+		.formats = SNDRV_PCM_FMTBIT_S32_LE,
+	},
+	.ops = &it6625_dai_ops,
+};
+
+static const struct snd_soc_component_driver it6625_component = {
+	.name = "it6625",
+	.endianness = 1,
+};
+
+/*
+ * Registered without devm so that remove can unregister it first: that
+ * waits until every open capture stream is closed, so no DAI callback
+ * runs once the driver starts tearing down.
+ */
+static int it6625_audio_register(struct it6625 *it6625)
+{
+	int err;
+
+	if (!IS_ENABLED(CONFIG_SND_SOC) ||
+	    !of_property_present(it6625->dev->of_node, "#sound-dai-cells"))
+		return 0;
+
+	err = snd_soc_register_component(it6625->dev, &it6625_component,
+					 &it6625_dai, 1);
+	if (err)
+		return dev_err_probe(it6625->dev, err,
+				     "failed to register audio DAI");
+
+	it6625->audio_registered = true;
+
+	return 0;
+}
+
+static void it6625_audio_unregister(struct it6625 *it6625)
+{
+	if (IS_ENABLED(CONFIG_SND_SOC) && it6625->audio_registered)
+		snd_soc_unregister_component(it6625->dev);
+
+	disable_delayed_work_sync(&it6625->audio_refresh_work);
+	disable_work_sync(&it6625->audio_xrun_work);
+}
+
 static void it6625_regdump_print(struct seq_file *s, const u8 *reg_buf)
 {
 	seq_puts(s, "     0x00 0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09 0x0A 0x0B 0x0C 0x0D 0x0E 0x0F\n");
@@ -2267,9 +2787,49 @@ static int it6625_parse_endpoint(struct it6625 *it6625)
 	return ret;
 }
 
+static int it6625_parse_audio(struct it6625 *it6625)
+{
+	struct device *dev = it6625->dev;
+	struct device_node *np = dev->of_node;
+	u32 lanes[IT6625_AUDIO_MAX_LANES];
+	int count, ret;
+
+	it6625->audio_lanes = 1;
+
+	if (!of_property_present(np, "ite,i2s-data-lanes"))
+		return 0;
+
+	count = of_property_count_u32_elems(np, "ite,i2s-data-lanes");
+	if (count < 1 || count > IT6625_AUDIO_MAX_LANES)
+		return dev_err_probe(dev, -EINVAL,
+				     "ite,i2s-data-lanes needs 1 to %u entries",
+				     IT6625_AUDIO_MAX_LANES);
+
+	ret = of_property_read_u32_array(np, "ite,i2s-data-lanes", lanes, count);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to read ite,i2s-data-lanes");
+
+	/* channel-pair to data-pin mapping is not supported yet */
+	for (unsigned int i = 0; i < count; i++) {
+		if (lanes[i] != i)
+			return dev_err_probe(dev, -EINVAL,
+					     "ite,i2s-data-lanes must be <0 1 ... n-1>");
+	}
+
+	it6625->audio_lanes = count;
+
+	return 0;
+}
+
 static int it6625_parse_dt(struct it6625 *it6625)
 {
-	return it6625_parse_endpoint(it6625);
+	int ret;
+
+	ret = it6625_parse_endpoint(it6625);
+	if (ret)
+		return ret;
+
+	return it6625_parse_audio(it6625);
 }
 
 static int it6625_check_device(struct it6625 *it6625)
@@ -2342,6 +2902,9 @@ static int it6625_probe(struct i2c_client *client)
 	init_completion(&it6625->if_latched);
 	INIT_DELAYED_WORK(&it6625->hpd_delayed_work, it6625_hpd_delayed_work);
 	INIT_WORK(&it6625->polling_work, it6625_polling_work);
+	spin_lock_init(&it6625->audio_lock);
+	INIT_WORK(&it6625->audio_xrun_work, it6625_audio_xrun_work);
+	INIT_DELAYED_WORK(&it6625->audio_refresh_work, it6625_audio_refresh_work);
 
 	if (client->irq) {
 		err = devm_request_threaded_irq(&client->dev, client->irq,
@@ -2426,6 +2989,13 @@ static int it6625_probe(struct i2c_client *client)
 		goto err_clean_debugfs;
 	}
 
+	/* may bind a waiting sound card, so everything must be set up */
+	err = it6625_audio_register(it6625);
+	if (err) {
+		v4l2_async_unregister_subdev(sd);
+		goto err_clean_debugfs;
+	}
+
 	if (client->irq)
 		enable_irq(client->irq);
 	else
@@ -2434,6 +3004,12 @@ static int it6625_probe(struct i2c_client *client)
 	return 0;
 
 err_clean_debugfs:
+	/*
+	 * Events dispatched by the probe control update or a debugfs reader
+	 * may have queued it. Disable rather than cancel it: a reader still
+	 * running until the debugfs removal below must not queue it again.
+	 */
+	disable_delayed_work_sync(&it6625->audio_refresh_work);
 	v4l2_debugfs_if_free(it6625->infoframes);
 	debugfs_remove_recursive(it6625->debugfs_dir);
 	cec_unregister_adapter(it6625->cec_adap);
@@ -2461,6 +3037,9 @@ static void it6625_remove(struct i2c_client *client)
 	struct v4l2_subdev *sd = i2c_get_clientdata(client);
 	struct it6625 *it6625 = sd_to_6625(sd);
 
+	/* first: waits for open capture streams to close */
+	it6625_audio_unregister(it6625);
+
 	v4l2_debugfs_if_free(it6625->infoframes);
 
 	if (client->irq)

-- 
2.34.1

