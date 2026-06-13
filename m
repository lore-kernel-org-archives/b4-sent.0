From: David Heidelberg <david@ixit.cz>
Date: Sat, 13 Jun 2026 21:55:59 +0200
Subject: [PATCH QUESTION] ASoC: qcom: sdm845: use DSP_A format for TDM
 codec DAIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260613-rfc-dsp-b-to-a-v1-1-7d095fe90a05@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAM61LWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDM0Nj3aK0ZN2U4gLdJN2SfN1EXUNzi0TjZIPEVPNUQyWgpoKi1LTMCrC
 B0UqBoa7BIZ7+fkqxtbUAYR9AAWoAAAA=
X-Change-ID: 20260613-rfc-dsp-b-to-a-178a3c0ae7e1
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1593; i=david@ixit.cz;
 h=from:subject:message-id; bh=neg8UtFcZBwtlMB/SdEqzf3x1Nv6xr1NWuiZgMsq2qA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqLbXUV2DAYE19NFvHsGSAv1VryqAgndBwZCCld
 JE0CEuOCv2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCai211AAKCRBgAj/E00kg
 csyJD/9d6Vh67hpZ+04lqqTZChLaF1FB8No+Rgo3u0rUKnAyKAEp5EGqL5Rse8VWCMjkiYuJ9df
 rd2bK+2Hr4bBeP/Mb4Riy6V8B7wHZo+d9jdzmALaCOvjTlY7O8a1VpgNJ5tzd3LHUzY51rqOg9J
 G6Y5uYXNQER8jlMgGsEobjp3SiqvjeZW88P7+arplidO5j6sFw1EFStLaGlgRIR6F5yTA+wzfns
 v95bgmpxuNhcpeFlRtBkonAGgBVsnIa+88Ucc2dKk2SjdqC7GUXgQ0PsJ8hHSSJeoj3CIS+r0A5
 GyIN8/K5yGgqqYptI/OPlVLZWygZrGNNlkJUpzR8cCF+SRrTAUTPZtSaC76aLL2/qeWnSe8uMjE
 uIqQbxoeTmiA87axeSzPpZdbhLRVGgjojnXUXJOieys1SfvpFGxLzIhlBXCwufWvtYv8L67J3EF
 KolWhSGsygDHH4R12Zb2UYDZz6Bxfq3cqexYSjZa7vmNHWHUYZasdnrg5iSF80ZKTaxl/eW6l8H
 ox+3ItIqYY7/ZJbEAzadEZfpiA42Z+la4otS0kFcwrxVBLJQoaYU/268HQyFG+7e/SnFVEUDHWg
 S7Po6/p0eFWJjq4bW6J4Z37aHyzdtR7g+BG8gji8J6HSwKjcxA6gMUC9CL67SSawiI5y459iv6T
 OPiPvPcLIA9vp/A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I'm currently pairing this with cs35l36 codec.

Currently this worked only because the cs35l36
codec mapped both DSP_A and DSP_B to the same hardware register value
(asp_fmt = 0), which is inherently DSP_A timing.

The CPU-side AFE is configured with qcom,tdm-data-delay = <1> which
produces DSP_A framing.
The codec format should match what is actually on the wire.

So I'm pretty lost if I should go fixing cs35l36 or sdm845.c.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 sound/soc/qcom/sdm845.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/soc/qcom/sdm845.c b/sound/soc/qcom/sdm845.c
index 0ce9dff4dc525..7bf22e24b193a 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -376,17 +376,17 @@ static int sdm845_snd_startup(struct snd_pcm_substream *substream)
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

---
base-commit: ec039126b7fac4e3af35ebccaa7c6f9b6875ba81
change-id: 20260613-rfc-dsp-b-to-a-178a3c0ae7e1

Best regards,
-- 
David Heidelberg <david@ixit.cz>

