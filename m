From: David Heidelberg <david@ixit.cz>
Date: Fri, 25 Sep 2026 17:28:05 +0200
Subject: [PATCH v5 4/7] ASoC: qcom: sdm845: Set codec dai and component
 sysclk during startup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-pixel3-audio-v5-4-7ffb32c980bf@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1734; i=david@ixit.cz;
 h=from:subject:message-id; bh=Z8qWthLOmn2/btoR+RRIL+/KcnpzGuSOEGEitmr2DFY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtpMFwtoqCPHsE4uxyqouCuoLZ5wtZ+r8b3Gsl
 uTbZh6zBOmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaraTBQAKCRBgAj/E00kg
 csZ4D/9ONMQvkNRXeBs565c4W2eZNFqkHnyWEZcY+3Nm2AahObwOvUlXlyy4r8kd8fOm5jy87Dl
 lYTGfQBEojGScxCI/x8Mge/Z5RWlWQAIXxvMz4p7rZ/BIYsyH8Fi8/FcjkUcwItXBbzDFlixv9d
 xVO+99JjMjirTv/TzpqJEFQpjEyImZHGM0luZwN6f6R6n7PKAcojgzbH+s3udOJGshqaZ0psOS1
 Jr+HmGkOyOQ8u0RA3cR1Qw2XTFX28cJDUop0rsY8MKUmy5nVkzoEIg547FKzg4wmYVHo3Jj7qof
 r7cAayWUGeVzQrkZg+hQU1LT97LrICsgp540l+Tw+jl8zQ/ARR/P/Q8zwqTgxTMtPwhfb9FRdNy
 Ej1d3+Eg0sF4nm+uAcsCjiOrGoWjvUWtgRT0v8q0/S8IkvkkhFt305pE3b2tD1sYdjkqvEyJwa6
 CltPLSKNW6+XF1cM79tYk5WOuqOhkHnU5FGeH3tlMDzheXaAbHwM5S+qX0KQ5EBkzdkc2eNs9X4
 1EPAiCk2h4I3E+RqKQyHhNJXW9ae9MvhcnDdp7LiHwyH2gmZ435a3k4/hGDjjakPlxaRn7IVJpH
 CpJoGdrVcbK9dVeJO4hlGrK3YXJGWvALOCRAqkPfOHRZu5nIY/Ke9PqTDC73IOw7r7V9HrH1QG1
 JRRdhnhSiY52QVw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cs35l36 codec needs the codec dai and component sysclk to be set
during TDM startup. Set these for all codec DAIs on the QUATERNARY_TDM
path, gracefully handling codecs that don't support sysclk by ignoring
-ENOTSUPP returns.

Based on work of Joel Selvaraj.

Reviewed-by: Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 sound/soc/qcom/sdm845.c | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/sound/soc/qcom/sdm845.c b/sound/soc/qcom/sdm845.c
index 59cfa3b26cd4d..f0fbec9c8df25 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -407,16 +407,38 @@ static int sdm845_snd_startup(struct snd_pcm_substream *substream)
 				ret = snd_soc_dai_set_fmt(
 						codec_dai, codec_dai_fmt);
 				if (ret < 0) {
 					dev_err(rtd->dev,
 						"Right TDM slot err:%d\n", ret);
 					return ret;
 				}
 			}
+
+			/* Set codec sysclk needed by codecs like cs35l36. */
+			ret = snd_soc_dai_set_sysclk(codec_dai, 0,
+						     TDM_BCLK_RATE,
+						     SND_SOC_CLOCK_IN);
+			if (ret < 0 && ret != -ENOTSUPP) {
+				dev_err(codec_dai->dev,
+					"Failed to set codec dai sysclk: %d\n",
+					ret);
+				return ret;
+			}
+
+			ret = snd_soc_component_set_sysclk(codec_dai->component,
+							   0, 0,
+							   TDM_BCLK_RATE,
+							   SND_SOC_CLOCK_IN);
+			if (ret < 0 && ret != -ENOTSUPP) {
+				dev_err(codec_dai->dev,
+					"Failed to set codec component sysclk: %d\n",
+					ret);
+				return ret;
+			}
 		}
 		break;
 	case SLIMBUS_0_RX...SLIMBUS_6_TX:
 		break;
 
 	default:
 		pr_err("%s: invalid dai id 0x%x\n", __func__, cpu_dai->id);
 		break;

-- 
2.55.0

