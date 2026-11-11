From: Marc Herrero <marcht@proton.me>
Date: Wed, 11 Nov 2026 13:49:27 +0000
Subject: [PATCH] ASoC: qcom: audioreach: apply volume changes to a running
 graph
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-q6apm-vol-live-v1-1-be85eef649c1@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MywqAIBAAfyX23EJ6MOpXooOPrRbMSkEC8d+T5
 jaHmQKJIlOCuSsQKXPiKzQRfQf20GEnZNcc5CCVaOCj9H1ivjx6zoROGSOcITvaCVp0R9r4/Yf
 LWusHTawBiGAAAAA=
X-Change-ID: 20261111-q6apm-vol-live-d6bb1dbec7c9
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Marc Herrero <marcht@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794404968; l=2295;
 i=marcht@proton.me; s=20261111; h=from:subject:message-id;
 bh=SqVgjL7+4cci4LPqvCK4Yw6wIkE/kOA+SDqD9jR9pW8=;
 b=FX1Y+Wi7BB5DpHA+0W6yE2XKgDCznVqlJos0UpJ8hstQWnTb3zNutOendQ72+lQoI638F5yi4
 7XppBorHE+kCr74otdQVCgfAsNs5c2orZsVM06hNcGbVazYVy6NqYr/
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

Send the gain to the DSP right away when the widget is powered, and
report no change when the value is the same.

Fixes: 36ad9bf1d93d ("ASoC: qdsp6: audioreach: add topology support")
Cc: stable@vger.kernel.org
Signed-off-by: Marc Herrero <marcht@proton.me>
---
Found on the Radxa Dragon Q6A together with the two fixes in
"[PATCH 0/2] ASoC: qcom: audioreach: fix S24_LE playback and route mixer
disconnects", sent earlier today. This one is independent of them.

Tested on 7.2.9: with the patch, moving the AirPlay volume while
playing changes the output immediately; without it nothing changes
until the next stream. Builds on asoc/for-next.
---
 sound/soc/qcom/qdsp6/topology.c | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/sound/soc/qcom/qdsp6/topology.c b/sound/soc/qcom/qdsp6/topology.c
index 612d8f03e6e9..5b3378fd29fc 100644
--- a/sound/soc/qcom/qdsp6/topology.c
+++ b/sound/soc/qcom/qdsp6/topology.c
@@ -1323,8 +1323,19 @@ static int audioreach_put_vol_ctrl_audio_mixer(struct snd_kcontrol *kcontrol,
 {
 	struct snd_soc_dapm_widget *dw = snd_soc_dapm_kcontrol_to_widget(kcontrol);
 	struct audioreach_module *mod = dw->dobj.private;
+	long gain = ucontrol->value.integer.value[0];
 
-	mod->gain = ucontrol->value.integer.value[0];
+	if (mod->gain == gain)
+		return 0;
+
+	mod->gain = gain;
+
+	/* The PGA event only applies the gain when the widget powers up */
+	if (dw->power) {
+		struct snd_soc_component *c = snd_soc_dapm_to_component(dw->dapm);
+
+		audioreach_gain_set_vol_ctrl(dev_get_drvdata(c->dev), mod, gain);
+	}
 
 	return 1;
 }

---
base-commit: cde5523c75f1320a55ac1d55a717ccbb566557f0
change-id: 20261111-q6apm-vol-live-d6bb1dbec7c9

Best regards,
-- 
Marc Herrero <marcht@proton.me>

