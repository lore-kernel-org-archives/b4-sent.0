From: Robin Snyders <robin@snyders.xyz>
Date: Tue, 11 Aug 2026 22:30:19 +0200
Subject: [PATCH] ASoC: q6afe-dai: make DISPLAY_PORT_RX a playback widget
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-submit-q6afe-display-port-v1-1-3bc8f2f38bdf@snyders.xyz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqDMBBA0avIrB1IImjsVcRFGic6YDVm0tIi3
 r3B5Vv8f4JQYhJ4VCck+rDwvhXougK/uG0m5KkYjDKtslqjvJ8vzni0LhBOLHF1P4x7yuh6720
 TOmVsA6WPiQJ/7/cwXtcfgRZFEWsAAAA=
X-Change-ID: 20260811-submit-q6afe-display-port-a9cc83f70283
To: Mark Brown <broonie@kernel.org>
Cc: Srinivas Kandagatla <srini@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, 
 Mohammad Rafi Shaik <mohammad.rafi.shaik@oss.qualcomm.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Takashi Iwai <tiwai@suse.com>, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-sound@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 Robin Snyders <robin@snyders.xyz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786480230; l=1488;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=ysCl82UHZPMn2kZSyN9OZ4adN2czfiNR23FtgwOeyOY=;
 b=Lwg5vZVhKYn9am5sgQ5j+a1vgWVIlwtz7NY8vNJJ+PAB7FjBSn+eXHaetXgMh1mUnBNvN8iwK
 Y5/n6vUYSxGBATxf9pIDK5gCGxC8GmjAq+todqOhxGS0zwnlOtZJUJm
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DISPLAY_PORT_RX is a receive port, so audio flows into it from a front end
and out to the display. Every other receive port in this file is declared
with SND_SOC_DAPM_AIF_IN, while transmit ports use SND_SOC_DAPM_AIF_OUT.

Declaring DISPLAY_PORT_RX as an output reverses the DAPM graph around it
and prevents a playback path from powering the port. Starting a stream
then leaves the AFE port stopped.

Declare it as an input like the other receive ports. Also pass NULL for
the stream name instead of the string "NULL".

Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
 sound/soc/qcom/qdsp6/q6afe-dai.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/qcom/qdsp6/q6afe-dai.c b/sound/soc/qcom/qdsp6/q6afe-dai.c
index 920345609d2c..f98ff598c072 100644
--- a/sound/soc/qcom/qdsp6/q6afe-dai.c
+++ b/sound/soc/qcom/qdsp6/q6afe-dai.c
@@ -980,7 +980,7 @@ static const struct snd_soc_dapm_widget q6afe_dai_widgets[] = {
 						0, SND_SOC_NOPM, 0, 0),
 	SND_SOC_DAPM_AIF_OUT("QUIN_TDM_TX_7", NULL,
 						0, SND_SOC_NOPM, 0, 0),
-	SND_SOC_DAPM_AIF_OUT("DISPLAY_PORT_RX", "NULL", 0, SND_SOC_NOPM, 0, 0),
+	SND_SOC_DAPM_AIF_IN("DISPLAY_PORT_RX", NULL, 0, SND_SOC_NOPM, 0, 0),
 
 	SND_SOC_DAPM_AIF_IN("WSA_CODEC_DMA_RX_0", "NULL",
 		0, SND_SOC_NOPM, 0, 0),

---
base-commit: 3d08ff75a47a3e7e2ab45a3bcab6723b4d906422
change-id: 20260811-submit-q6afe-display-port-a9cc83f70283

Best regards,
-- 
Robin Snyders <robin@snyders.xyz>

