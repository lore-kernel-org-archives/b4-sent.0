From: Marc Herrero <marcht@proton.me>
Date: Wed, 11 Nov 2026 10:54:18 +0000
Subject: [PATCH 2/2] ASoC: qcom: audioreach: only disconnect the route a
 mixer control owns
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-q6apm-fixes-v1-2-1beb5702b372@proton.me>
References: <20261111-q6apm-fixes-v1-0-1beb5702b372@proton.me>
In-Reply-To: <20261111-q6apm-fixes-v1-0-1beb5702b372@proton.me>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Marc Herrero <marcht@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794394460; l=2173;
 i=marcht@proton.me; s=20261111; h=from:subject:message-id;
 bh=uwHreXeheF+PY4xZ0ZasSUnOSnlXrONYE6C8uZecUBM=;
 b=bLkWe0qoIIXe4vR/PnbDWg1bBcDb3ZcqkOH4+4smFjsy+J+H3bp+7RMSHR6hsb0g8jz20cm6Y
 IZlTr6OAuUaBpTR2JKIdOEDdty12wfeTZAMyPw/715ULBSQFkVIhSYd
X-Developer-Key: i=marcht@proton.me; a=ed25519;
 pk=pIPy6L+INgiuJt7L7umVilPgpzy/Ni3QS77ToLj/H9c=
X-Endpoint-Received: by B4 Relay for marcht@proton.me/20261111 with auth_id=1490
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each AudioReach virtual mixer route control ("<BE> Audio Mixer <FE>")
connects a front-end stream graph to a back-end device graph by storing
the source module in the device graph's audioreach_graph_info. Writing 0
to any of these controls clears that link unconditionally, even when the
device graph is connected to a different front end.

When two front ends can feed the same back end the result therefore
depends on write order. On QCS6490 (Radxa Dragon Q6A):

 - alsactl restore writes 'DISPLAY_PORT_RX_0 Audio Mixer MultiMedia2' = 1
   and then 'DISPLAY_PORT_RX_0 Audio Mixer MultiMedia1' = 0, which leaves
   DisplayPort disconnected although the saved state has it connected;
 - the UCM HDMI enable sequence writes
   'RX_CODEC_DMA_RX_0 Audio Mixer MultiMedia2' = 0, which disconnects
   MultiMedia1 from the headphones. A PCM started on MultiMedia1 after
   that never advances (hw_ptr stays at 0).

Only drop the link when it belongs to the control being cleared, that is
when audioreach_is_vmixer_connected() reports it as connected. Writing 0
to a control that is not the active route becomes a no-op, which matches
what its get() callback already returns.

Fixes: e4977b91cff8 ("ASoC: qdsp6: audioreach: Simplify handing FE and BE graph connections")
Cc: stable@vger.kernel.org
Signed-off-by: Marc Herrero <marcht@proton.me>
---
 sound/soc/qcom/qdsp6/topology.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/qcom/qdsp6/topology.c b/sound/soc/qcom/qdsp6/topology.c
index 612d8f03e6e9..e92408e09bac 100644
--- a/sound/soc/qcom/qdsp6/topology.c
+++ b/sound/soc/qcom/qdsp6/topology.c
@@ -1300,7 +1300,7 @@ static int audioreach_put_audio_mixer(struct snd_kcontrol *kcontrol,
 	if (ucontrol->value.integer.value[0]) {
 		audioreach_connect_sub_graphs(data, scontrol, dapm_scontrol, true);
 		snd_soc_dapm_mixer_update_power(dapm, kcontrol, 1, NULL);
-	} else {
+	} else if (audioreach_is_vmixer_connected(data, scontrol, dapm_scontrol)) {
 		audioreach_connect_sub_graphs(data, scontrol, dapm_scontrol, false);
 		snd_soc_dapm_mixer_update_power(dapm, kcontrol, 0, NULL);
 	}

-- 
2.53.0

