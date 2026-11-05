From: Rafael Gago <rafael.gago@gmail.com>
Date: Thu, 05 Nov 2026 10:22:50 +0100
Subject: [PATCH v2] ALSA: hdsp: allow sample rate changes from hw_params
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-hdsp-sound-v2-1-458a3cfafbcd@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOlK7GoC/22Nyw6CMBBFf4XM2poOD4Ou/A/DosAUxgglHSAa0
 n+34NblSc49dwMhzyRwSzbwtLKwGyOkpwSa3owdKW4jQ6rTC6JG1bcyKXHL2Cq0how2uS0zC3E
 webL8PmKP6sey1E9q5r2wGz3L7PzneFtx9/6GV1SobHa1WBa51nVx7wbDr3PjBqhCCF9r3eRBt
 gAAAA==
X-Change-ID: 20261101-hdsp-sound-1faea0a4f83f
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Rafael Gago <rafael.gago@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793870570; l=10489;
 i=rafael.gago@gmail.com; s=20261101; h=from:subject:message-id;
 bh=OOWPJ/eSblWXsSIk6JfbzjefJM/GPmbbYxIxkfdiAtg=;
 b=710SdVIHK9D8Y1UsQ45/F0EQTANQvfEB2gJ0XIpd3XvP8Xn25vOFrVXWHqFkwQ8SNL9Xhvalq
 kXQiN6VCLlhBktBWFGs4qG7yUrbYj97o/wQ5DXPdJfxjao5zZjMLhUx
X-Developer-Key: i=rafael.gago@gmail.com; a=ed25519;
 pk=1shUAtvt9i3ykuhyO1aVre9o4Lqma7slUO2FA0HsOmE=
X-Endpoint-Received: by B4 Relay for rafael.gago@gmail.com/20261101 with auth_id=1375
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hdsp_set_rate() refuses to switch between single, double and quad
speed whenever capture_pid or playback_pid is set. Both are set in the
PCM open callbacks, so the substream that asks for the new rate in
hw_params always blocks itself:

  cannot change speed mode (capture PID = -1, playback PID = 4242)

As a result no application can move an HDSP from 48 kHz to 96 kHz (or
to 192 kHz on the H9632) through the normal ALSA API. Rate changes
within one speed mode work, and a speed mode change only works through
the "Sample Clock Source" control while no PCM is open, which is what
users have to script around today.

The restriction exists because a speed mode change moves the channels
to other DMA buffer slots (hdsp->channel_map) and changes the channel
count, which must not happen under a substream that was already set up
with the old layout. The substream calling hw_params is about to be set
up anyway, so it is not such a substream.

Pass the requesting substream to hdsp_set_rate() in place of the
called_internally flag, and from hw_params only refuse the speed mode
change if the other direction has hw_params of its own. A substream of
another process is still turned away by the existing check in
snd_hdsp_hw_params(), and requests from the controls and from card
initialization (substream == NULL) keep the old rule of no open
substreams at all.

A duplex client therefore opens both directions, sets hw_params on the
first one (which may change the speed mode) and then on the second one
at the same rate. To change the speed mode later it has to hw_free or
close the other direction first.

Which directions have hw_params is tracked in a new setup_streams mask
under hdsp->lock: hw_params sets the bit, and a new hw_free callback
and close clear it. The other substream's runtime state cannot be used
for this, because the PCM core only moves it to SETUP after the driver's
hw_params has returned and dropped hdsp->lock. Two threads calling
hw_params on the two directions at once could then both change the
speed mode.

Tested on an HDSP 9632 (v7.0 based kernel, same hdsp.c as v7.0) with
aplay/arecord -M on hw:DSP: one stream moves the clock between 44.1k,
48k, 88.2k, 96k and 192k in both directions; alsaloop runs duplex in one
process at 48k/12ch, 96k/8ch and 192k/4ch; while another process plays
at 96k, a capture at 96k works and one at 48k or 192k is still refused;
the "Sample Clock Source" control is still refused while a stream is
open. REAPER on raw ALSA now changes the project rate between speed
modes without presetting the clock first. Also built with W=1 on
current mainline without warnings.

Only the HDSP 9632 was available for testing; the Digiface, Multiface,
RPM and 9652 were not. The change is not model specific: the speed
mode switch itself is the same code the "Sample Clock Source" control
already runs on every model, and it still only happens while no stream
is transferring data. The per-model channel counts and channel maps
come from the driver's existing tables.

A Claude AI coding assistant (Claude Code) read the driver, wrote this
change, the changelog and the tests at the request of the submitter,
who reviewed them.

Signed-off-by: Rafael Gago <rafael.gago@gmail.com>
---
Changes in v2:
- Track which directions have hw_params in a setup_streams mask under
  hdsp->lock, set in hw_params and cleared in a new hw_free callback and
  in close, instead of reading the other substream's runtime state. The
  PCM core only sets that to SETUP after hw_params returns, so two
  threads could both change the speed mode (reported by Sashiko).
- Link to v1: https://patch.msgid.link/20261101-hdsp-sound-v1-1-f39f185400b5@gmail.com
---
 sound/pci/rme9652/hdsp.c | 65 ++++++++++++++++++++++++++++++++++++++++++------
 1 file changed, 57 insertions(+), 8 deletions(-)

diff --git a/sound/pci/rme9652/hdsp.c b/sound/pci/rme9652/hdsp.c
index 7dce548b9..c6ddad82d 100644
--- a/sound/pci/rme9652/hdsp.c
+++ b/sound/pci/rme9652/hdsp.c
@@ -478,6 +478,7 @@ struct hdsp {
 
 	pid_t                 capture_pid;
 	pid_t                 playback_pid;
+	unsigned int          setup_streams;  /* 1 << stream after hw_params */
 	int                   running;
 	int                   system_sample_rate;
 	const signed char    *channel_map;
@@ -1095,7 +1096,40 @@ static void hdsp_set_dds_value(struct hdsp *hdsp, int rate)
 	hdsp_write(hdsp, HDSP_freqReg, hdsp->dds_value);
 }
 
-static int hdsp_set_rate(struct hdsp *hdsp, int rate, int called_internally)
+/*
+ * A speed mode change moves the channels to different DMA buffer slots
+ * (hdsp->channel_map) and changes the channel count. It is only safe if
+ * no substream other than the one asking for it (if any) was set up with
+ * the old layout. A substream of another process is already turned away
+ * by snd_hdsp_hw_params().
+ *
+ * hdsp->setup_streams is used rather than the other substream's runtime
+ * state, because the PCM core only moves a substream to SETUP after
+ * snd_hdsp_hw_params() has returned and dropped hdsp->lock. It is read
+ * and updated under hdsp->lock.
+ */
+static bool hdsp_speed_change_blocked(struct hdsp *hdsp,
+				      struct snd_pcm_substream *substream)
+{
+	int other;
+
+	if (!substream)
+		return hdsp->capture_pid >= 0 || hdsp->playback_pid >= 0;
+
+	if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK)
+		other = SNDRV_PCM_STREAM_CAPTURE;
+	else
+		other = SNDRV_PCM_STREAM_PLAYBACK;
+
+	return hdsp->setup_streams & (1 << other);
+}
+
+/*
+ * substream is the stream asking for the rate in hw_params, or NULL for a
+ * request from a control or from card initialization.
+ */
+static int hdsp_set_rate(struct hdsp *hdsp, int rate,
+			 struct snd_pcm_substream *substream)
 {
 	int reject_if_open = 0;
 	int current_rate;
@@ -1107,7 +1141,7 @@ static int hdsp_set_rate(struct hdsp *hdsp, int rate, int called_internally)
 	*/
 
 	if (!(hdsp->control_register & HDSP_ClockModeMaster)) {
-		if (called_internally) {
+		if (!substream) {
 			/* request from ctl or card initialization */
 			dev_err(hdsp->card->dev,
 				"device is not running as a clock master: cannot set sample rate.\n");
@@ -1134,7 +1168,7 @@ static int hdsp_set_rate(struct hdsp *hdsp, int rate, int called_internally)
 	current_rate = hdsp->system_sample_rate;
 
 	/* Changing from a "single speed" to a "double speed" rate is
-	   not allowed if any substreams are open. This is because
+	   not allowed while another substream is set up. This is because
 	   such a change causes a shift in the location of
 	   the DMA buffers and a reduction in the number of available
 	   buffers.
@@ -1196,7 +1230,7 @@ static int hdsp_set_rate(struct hdsp *hdsp, int rate, int called_internally)
 		return -EINVAL;
 	}
 
-	if (reject_if_open && (hdsp->capture_pid >= 0 || hdsp->playback_pid >= 0)) {
+	if (reject_if_open && hdsp_speed_change_blocked(hdsp, substream)) {
 		dev_warn(hdsp->card->dev,
 			 "cannot change speed mode (capture PID = %d, playback PID = %d)\n",
 			    hdsp->capture_pid,
@@ -1939,7 +1973,7 @@ static int hdsp_set_clock_source(struct hdsp *hdsp, int mode)
 	switch (mode) {
 	case HDSP_CLOCK_SOURCE_AUTOSYNC:
 		if (hdsp_external_sample_rate(hdsp) != 0) {
-		    if (!hdsp_set_rate(hdsp, hdsp_external_sample_rate(hdsp), 1)) {
+		    if (!hdsp_set_rate(hdsp, hdsp_external_sample_rate(hdsp), NULL)) {
 			hdsp->control_register &= ~HDSP_ClockModeMaster;
 			hdsp_write(hdsp, HDSP_controlRegister, hdsp->control_register);
 			return 0;
@@ -1978,7 +2012,7 @@ static int hdsp_set_clock_source(struct hdsp *hdsp, int mode)
 	}
 	hdsp->control_register |= HDSP_ClockModeMaster;
 	hdsp_write(hdsp, HDSP_controlRegister, hdsp->control_register);
-	hdsp_set_rate(hdsp, rate, 1);
+	hdsp_set_rate(hdsp, rate, NULL);
 	return 0;
 }
 
@@ -3815,7 +3849,7 @@ static int snd_hdsp_set_defaults(struct hdsp *hdsp)
 	/* set a default rate so that the channel map is set up.
 	 */
 
-	hdsp_set_rate(hdsp, 48000, 1);
+	hdsp_set_rate(hdsp, 48000, NULL);
 
 	return 0;
 }
@@ -4040,6 +4074,7 @@ static int snd_hdsp_hw_params(struct snd_pcm_substream *substream,
 
 		/* We're fine. */
 
+		hdsp->setup_streams |= 1 << substream->stream;
  		return 0;
 
 	}
@@ -4048,7 +4083,7 @@ static int snd_hdsp_hw_params(struct snd_pcm_substream *substream,
 	 */
 
 	if (! hdsp->clock_source_locked) {
-		err = hdsp_set_rate(hdsp, params_rate(params), 0);
+		err = hdsp_set_rate(hdsp, params_rate(params), substream);
 		if (err < 0) {
 			_snd_pcm_hw_param_setempty(params, SNDRV_PCM_HW_PARAM_RATE);
 			return err;
@@ -4061,6 +4096,16 @@ static int snd_hdsp_hw_params(struct snd_pcm_substream *substream,
 		return err;
 	}
 
+	hdsp->setup_streams |= 1 << substream->stream;
+	return 0;
+}
+
+static int snd_hdsp_hw_free(struct snd_pcm_substream *substream)
+{
+	struct hdsp *hdsp = snd_pcm_substream_chip(substream);
+
+	guard(spinlock_irq)(&hdsp->lock);
+	hdsp->setup_streams &= ~(1 << substream->stream);
 	return 0;
 }
 
@@ -4471,6 +4516,7 @@ static int snd_hdsp_playback_release(struct snd_pcm_substream *substream)
 	scoped_guard(spinlock_irq, &hdsp->lock) {
 		hdsp->playback_pid = -1;
 		hdsp->playback_substream = NULL;
+		hdsp->setup_streams &= ~(1 << SNDRV_PCM_STREAM_PLAYBACK);
 	}
 
 	if (RPM != hdsp->io_type) {
@@ -4533,6 +4579,7 @@ static int snd_hdsp_capture_release(struct snd_pcm_substream *substream)
 
 	hdsp->capture_pid = -1;
 	hdsp->capture_substream = NULL;
+	hdsp->setup_streams &= ~(1 << SNDRV_PCM_STREAM_CAPTURE);
 
 	return 0;
 }
@@ -4854,6 +4901,7 @@ static const struct snd_pcm_ops snd_hdsp_playback_ops = {
 	.close =	snd_hdsp_playback_release,
 	.ioctl =	snd_hdsp_ioctl,
 	.hw_params =	snd_hdsp_hw_params,
+	.hw_free =	snd_hdsp_hw_free,
 	.prepare =	snd_hdsp_prepare,
 	.trigger =	snd_hdsp_trigger,
 	.pointer =	snd_hdsp_hw_pointer,
@@ -4866,6 +4914,7 @@ static const struct snd_pcm_ops snd_hdsp_capture_ops = {
 	.close =	snd_hdsp_capture_release,
 	.ioctl =	snd_hdsp_ioctl,
 	.hw_params =	snd_hdsp_hw_params,
+	.hw_free =	snd_hdsp_hw_free,
 	.prepare =	snd_hdsp_prepare,
 	.trigger =	snd_hdsp_trigger,
 	.pointer =	snd_hdsp_hw_pointer,

---
base-commit: 231efd8f68c950ad3b774ff51c6d15fdd0443a5b
change-id: 20261101-hdsp-sound-1faea0a4f83f

Best regards,
--  
Rafael Gago <rafael.gago@gmail.com>

