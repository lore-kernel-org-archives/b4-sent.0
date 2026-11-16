From: Marc Herrero <marcht@proton.me>
Date: Mon, 16 Nov 2026 20:16:29 +0000
Subject: [PATCH v2] ASoC: qcom: audioreach: apply volume changes to a
 running graph
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-q6apm-vol-live-v2-1-fbeba4402984@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WMQQ7CIBBFr9LM2jFCFK0r72G6KDC1k7RAoSGah
 ruL3ft37yfvbZAoMiW4NxtEypzYuwry0IAZe/ciZFsZ5EkqUYeL6sOM2U84cSa0SmthNZmraaF
 KIdLA7z347CqPnFYfP3s/i9/7N5UFCtR0uxAN6twa8QjRr94dZ4KulPIF6Y/zRKwAAAA=
X-Change-ID: 20261111-q6apm-vol-live-d6bb1dbec7c9
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Marc Herrero <marcht@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794860189; l=5278;
 i=marcht@proton.me; s=20261111; h=from:subject:message-id;
 bh=mp2MbI2XiexMCnav2onYjsf+zW4C1sDOoQtZdybVDJk=;
 b=uWiabstwfrwXapwCEIJ2z2qJ6Bro5hEqxGWwLMW3uDhCYHmT2E99Vw3EjNByte2HbhREeY3Dz
 KVuNWySWd8gAvHKEH8VPFKD/x3rxY0eECoB45g/r+eDSsjvYBQR21K0
X-Developer-Key: i=marcht@proton.me; a=ed25519;
 pk=pIPy6L+INgiuJt7L7umVilPgpzy/Ni3QS77ToLj/H9c=
X-Endpoint-Received: by B4 Relay for marcht@proton.me/20261111 with auth_id=1490
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

audioreach_put_vol_ctrl_audio_mixer() only stores the new gain in the
module. The gain reaches the DSP from audioreach_pga_event() on
SND_SOC_DAPM_POST_PMU, that is when a stream starts, so changing the
"<stream> Playback Volume" control while playing has no effect until the
next stream.

On QCS6490 (Radxa Dragon Q6A) shairport-sync uses this control as its
hardware volume: the volume set when an AirPlay session starts is
applied, but every later change from the phone is ignored.

Send the gain to the DSP right away when the widget is powered and the
graph holding the volume module has been started, since the DSP rejects
the parameter before that. Otherwise only store it, and the PGA event
applies it at power up as before. Hold the DAPM lock so the power state
cannot change between the check and the update, keep the old gain and
return the error if the DSP does not take the new one, and report no
change when the value is the same.

Fixes: 36ad9bf1d93d ("ASoC: qdsp6: audioreach: add topology support")
Cc: stable@vger.kernel.org
Signed-off-by: Marc Herrero <marcht@proton.me>
---
Found on the Radxa Dragon Q6A together with the two fixes in
"[PATCH v2 0/2] ASoC: qcom: audioreach: fix S24_LE playback and route
mixer disconnects". This one is independent of them.

Tested on 7.2.9: with the patch, moving the AirPlay volume while
playing changes the output immediately; without it nothing changes
until the next stream. Builds on asoc/for-next.
---
Changes in v2:
- Only send the gain when the graph holding the volume module has been
  started, since the DSP rejects it before that (Srini). Add
  q6apm_is_graph_started() for this.
- Take the DAPM lock so the widget power state cannot change between
  the check and the update (Mark).
- Return the error and keep the old gain if the DSP does not take the
  new one, so writing the same value again retries (Sashiko).
- Link to v1: https://lore.kernel.org/r/20261111-q6apm-vol-live-v1-1-be85eef649c1@proton.me
---
 sound/soc/qcom/qdsp6/q6apm.c    | 13 +++++++++++++
 sound/soc/qcom/qdsp6/q6apm.h    |  1 +
 sound/soc/qcom/qdsp6/topology.c | 26 ++++++++++++++++++++++++--
 3 files changed, 38 insertions(+), 2 deletions(-)

diff --git a/sound/soc/qcom/qdsp6/q6apm.c b/sound/soc/qcom/qdsp6/q6apm.c
index 8e3314a2738c..034d42edde22 100644
--- a/sound/soc/qcom/qdsp6/q6apm.c
+++ b/sound/soc/qcom/qdsp6/q6apm.c
@@ -839,6 +839,19 @@ int q6apm_graph_stop(struct q6apm_graph *graph)
 }
 EXPORT_SYMBOL_GPL(q6apm_graph_stop);
 
+bool q6apm_is_graph_started(struct q6apm *apm, uint32_t graph_id)
+{
+	struct audioreach_graph *graph;
+	bool started;
+
+	mutex_lock(&apm->lock);
+	graph = idr_find(&apm->graph_idr, graph_id);
+	started = graph && graph->start_count > 0;
+	mutex_unlock(&apm->lock);
+
+	return started;
+}
+
 int q6apm_graph_flush(struct q6apm_graph *graph)
 {
 	return audioreach_graph_mgmt_cmd(graph->ar_graph, APM_CMD_GRAPH_FLUSH);
diff --git a/sound/soc/qcom/qdsp6/q6apm.h b/sound/soc/qcom/qdsp6/q6apm.h
index 9092359ccf90..b84ccbee4926 100644
--- a/sound/soc/qcom/qdsp6/q6apm.h
+++ b/sound/soc/qcom/qdsp6/q6apm.h
@@ -120,6 +120,7 @@ int q6apm_graph_prepare(struct q6apm_graph *graph);
 int q6apm_graph_start(struct q6apm_graph *graph);
 int q6apm_graph_stop(struct q6apm_graph *graph);
 int q6apm_graph_flush(struct q6apm_graph *graph);
+bool q6apm_is_graph_started(struct q6apm *apm, uint32_t graph_id);
 
 /* Media Format */
 int q6apm_graph_media_format_pcm(struct q6apm_graph *graph,
diff --git a/sound/soc/qcom/qdsp6/topology.c b/sound/soc/qcom/qdsp6/topology.c
index 612d8f03e6e9..956f8e9e6a76 100644
--- a/sound/soc/qcom/qdsp6/topology.c
+++ b/sound/soc/qcom/qdsp6/topology.c
@@ -1322,11 +1322,33 @@ static int audioreach_put_vol_ctrl_audio_mixer(struct snd_kcontrol *kcontrol,
 					       struct snd_ctl_elem_value *ucontrol)
 {
 	struct snd_soc_dapm_widget *dw = snd_soc_dapm_kcontrol_to_widget(kcontrol);
+	struct snd_soc_component *c = snd_soc_dapm_to_component(dw->dapm);
 	struct audioreach_module *mod = dw->dobj.private;
+	struct q6apm *apm = dev_get_drvdata(c->dev);
+	long gain = ucontrol->value.integer.value[0];
+	int ret = 0;
 
-	mod->gain = ucontrol->value.integer.value[0];
+	/*
+	 * The PGA event applies the gain when the widget powers up. Hold the
+	 * DAPM lock so the power state cannot change under us: either the
+	 * event sees the new gain or it is sent here. The DSP only accepts
+	 * the parameter once the graph holding the module has been started.
+	 * Keep the old gain if the DSP did not take the new one, so that
+	 * writing the same value again retries.
+	 */
+	snd_soc_dapm_mutex_lock(dw->dapm);
+	if (mod->gain != gain) {
+		if (dw->power &&
+		    q6apm_is_graph_started(apm, mod->container->sub_graph->info->id))
+			ret = audioreach_gain_set_vol_ctrl(apm, mod, gain);
+		if (!ret) {
+			mod->gain = gain;
+			ret = 1;
+		}
+	}
+	snd_soc_dapm_mutex_unlock(dw->dapm);
 
-	return 1;
+	return ret;
 }
 
 static int audioreach_control_load_mix(struct snd_soc_component *scomp,

---
base-commit: cde5523c75f1320a55ac1d55a717ccbb566557f0
change-id: 20261111-q6apm-vol-live-d6bb1dbec7c9

Best regards,
-- 
Marc Herrero <marcht@proton.me>

