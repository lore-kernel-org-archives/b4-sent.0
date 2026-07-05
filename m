From: David Heidelberg <david@ixit.cz>
Date: Sun, 05 Jul 2026 22:06:52 +0200
Subject: [PATCH RFC 2/6] ASoC: qcom: sdm845: use DSP_A format for TDM codec
 DAIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-pixel3-audio-v1-2-3b66f33859f1@ixit.cz>
References: <20260705-pixel3-audio-v1-0-3b66f33859f1@ixit.cz>
In-Reply-To: <20260705-pixel3-audio-v1-0-3b66f33859f1@ixit.cz>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1269; i=david@ixit.cz;
 h=from:subject:message-id; bh=vLuqZQgNHynl7n+YwN094veUqydvvq72pur4s+x3Vjc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqSrmMxsJh2TZYCYImKM3dHEGZnqqVMKQa7xm8k
 +EsJXe5/e6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCakq5jAAKCRBgAj/E00kg
 cu5YD/9coSUo9sEfrRl7BuTXjjUjyo6d/q5YE4/AdR/0f6I/p12/Wu4dXZhbe9w+mrshAkgLJXo
 1P/2j+q8YGWgjNrAyMTu2D6pYZm85898pKeMy/sAFbUiHgDdBPKLR/8Q0PMEOS2rUx3VMxS9JIn
 d16yKluhPGQiHd72gamG+RWfd1N3UPFsAjWm8MzvQGnUtYfK5x1lSaZoG7BDbFV+N457ERUW7Mw
 zl8AdJpczy5AGWpuNJMHrqIQnwGOUPL1VbssZpG3HpAQrvSj5Ha4U3jadxlbwkN1v/li7vKSJ9J
 YxnTC3XprGquEKFQpvDkQ9W2LcGxlBAtrTKnKuC/MegNX3T4elKbCkimBnkx6qRWSu9b1eIkJo6
 u9/Wpq9dPnk10zeztrs8XUMy78W8DHSr606PtgOqEjXLSzQSAqL6pwZTuNJLtso/frI86YynhMg
 gELUdhO6eVPOl5GuqTk2zycaheo9FCdX4q+68vul2emYgGdBpOJqRJ6ZiNIwVoJ0ZfWtMNmyxBf
 Zh8BRQJMxYM8Jl4yCiM6547ZK2ml9LLL+78nqesjNUvlZk6g4Fokp7EcQZAHtmZI6q1M8WzxguK
 O5hQtVBA3/F651ePhYjeOzLMMZ6LNVQhJrqIzvGEeGVAg0TbvfgihXVZH7kkpnYIGThP1LolLMF
 oDNsiDG1ycIoOQw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Before the DSP_B only worked because the only close-to-mainline consumer
cs35l36 codec was patched to map both DSP_A and DSP_B to the same
hardware register value (asp_fmt = 0), which is inherently DSP_A timing.
Use the right codec (DSP_A) which works as expected.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 sound/soc/qcom/sdm845.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/qcom/sdm845.c b/sound/soc/qcom/sdm845.c
index edd2cc7a1c74f..9de3282bda4be 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -380,17 +380,17 @@ static int sdm845_snd_startup(struct snd_pcm_substream *substream)
 	case QUATERNARY_TDM_RX_0:
 	case QUATERNARY_TDM_TX_0:
 		if (++(data->quat_tdm_clk_count) == 1) {
 			snd_soc_dai_set_sysclk(cpu_dai,
 				Q6AFE_LPASS_CLK_ID_QUAD_TDM_IBIT,
 				TDM_BCLK_RATE, SNDRV_PCM_STREAM_PLAYBACK);
 		}
 
-		codec_dai_fmt |= SND_SOC_DAIFMT_IB_NF | SND_SOC_DAIFMT_DSP_B;
+		codec_dai_fmt |= SND_SOC_DAIFMT_IB_NF | SND_SOC_DAIFMT_DSP_A;
 
 		for_each_rtd_codec_dais(rtd, j, codec_dai) {
 
 			if (!strcmp(codec_dai->component->name_prefix,
 				    "Left")) {
 				ret = snd_soc_dai_set_fmt(
 						codec_dai, codec_dai_fmt);
 				if (ret < 0) {

-- 
2.53.0

