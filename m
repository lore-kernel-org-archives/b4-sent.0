From: David Heidelberg <david@ixit.cz>
Date: Fri, 25 Sep 2026 17:28:03 +0200
Subject: [PATCH v5 2/7] ASoC: qcom: sdm845: use DSP_A format for TDM codec
 DAIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-pixel3-audio-v5-2-7ffb32c980bf@ixit.cz>
References: <20260925-pixel3-audio-v5-0-7ffb32c980bf@ixit.cz>
In-Reply-To: <20260925-pixel3-audio-v5-0-7ffb32c980bf@ixit.cz>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Viken Dadhaniya <viken.dadhaniya@oss.qualcomm.com>, 
 linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1394; i=david@ixit.cz;
 h=from:subject:message-id; bh=XFtLmu+b3g8wRb/J2bbp/2wXHNURengB7rqb1bBnuDs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtpMFGNJVwvAsSowOISIt+TYBLqurxvvsuxipn
 sA3jGa0iqWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaraTBQAKCRBgAj/E00kg
 crSsD/9mM3cqrwaphqgoK4RgvUhXy+NXp4zPrPA1LpoSuv7mkwbz6u99oVmHCMdwXHF+KSZXsYd
 0JsCbttw3L9pICEnBbg2Cb68QjXLiy+q/6l+CbqlbFhbU80H1sKjg3JChSZExcivXjmdmnl4xs6
 j0vuKQGuLKyCxKERF8ygn4swzIuhPAcSfAKMnNp3wGpHZLzr/C9Vuqrco2SXnSwfK5AjCPNNP7B
 C0hWWHH8uRInJDz/SPbx9TxWl3Gwcai8tMb85h+yMHR0xIeeEDIPYEqwlwD3Zm7qBqWneDXZ9Kn
 4rF3BX+rZ6/bB1/CL/V7AjPIo2nWcKuEe9L5Jcp1NH8VpLd51xf7uDOtI9iU0IR8CGKyDeDfU9u
 PVFAiZirnmq8jSOJCi52bX0JmbgwkyjWWiUc/7zCis1uf5tPu1V6y68otovMmn+fT4C7yFdhYlk
 1aNyVtdbGINeN8UJEkpA6qe4pcQuRW6vuTKlQ8lJc+XG66wwG8iYBkusM2Tx65FVThREMDeKOi3
 GRUrW6StK5Iy3w/Skye4Sha6ryupz8aj9rpowpQ8mFDM2lDoDrJqtMnt5FDCwXImZjY40RbL4+I
 FGg08/XoIE5bx+wu9sS8mnDQwrcBAXlVCXCok6KPk1RnlIHQ7IgY88Vwt4D0RA+PJb5Md4urdBo
 Wrd5v3yM+JsJO2Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cs35l36 set_dai_fmt() never accepted DSP_B, so old DSP_B was broken with
"Left TDM fmt err:-22", not silently wrong timing.
cs35l36 codec was patched to map both DSP_A and DSP_B to the same
hardware register value (asp_fmt = 0), which is inherently DSP_A timing.
Use the right codec (DSP_A) which works as expected.

Reviewed-by: Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 sound/soc/qcom/sdm845.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/qcom/sdm845.c b/sound/soc/qcom/sdm845.c
index 0ce8265ab1c1f..d1cc825fc5cdc 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -382,17 +382,17 @@ static int sdm845_snd_startup(struct snd_pcm_substream *substream)
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
2.55.0

