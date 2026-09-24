From: David Heidelberg <david@ixit.cz>
Date: Thu, 24 Sep 2026 14:46:48 +0200
Subject: [PATCH v3 4/8] ASoC: qcom: sdm845: Set codec dai and component
 sysclk during startup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-pixel3-audio-v3-4-5d06460fc8a9@ixit.cz>
References: <20260924-pixel3-audio-v3-0-5d06460fc8a9@ixit.cz>
In-Reply-To: <20260924-pixel3-audio-v3-0-5d06460fc8a9@ixit.cz>
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
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1661; i=david@ixit.cz;
 h=from:subject:message-id; bh=sf3oRG8KF1GI0iFA9IGZLcdnFZs9OCe5HnE3apZFGXM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtRu4cZHlSWv0fUFP4h4HtRLuwZJr3M7bAfJ1B
 MZf8XaDTG6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUbuAAKCRBgAj/E00kg
 csbgEACeikmiq4LGZavywoHHpt1ZCrtE5z45f/Om90w0Tx92nRQsXQUFVPPYHZOwU7nWVka2leh
 DvXj4tpxdc0Cy75YqxJGAZWgVdXNBqRJ+wtmlJ54UMs8kIywsbCo3X8jGovXTaWZV1INr/sS9GP
 p8PUxCKuTiTZP9cM+6HohzA6MlgRFf5/3Xm5/ld0eblAHz1VWXAlRkUmvA1w1hdXjzwJ4Lu2crW
 8BstwAFWKyTezV07je2b+pYFgZ2Y0gvrkh8ZU3b5DQCLzhPGpC/JiDIpbAo2jdhGwx6292ivbwp
 EINQIlA4aWJaeS7L4sOdvlp7iCiyXuMbMAsTvlhgL8hmrD32QMniYTH49MqEpGhv0SFMdexnz6B
 nYb/TLqUcxrVCF7TIg8cE7NLutylcj5u9kGlcrR+jofNIzv9NbKwEPxGcstUKjLde9W7V6lcOwz
 PksrsLBJe+YXlBoLpMfhVzYTSSsAFZDYIyhpd+5/E9UVtydQCE8OQCs1Uu8ht1hbdz2oJPx7riw
 cyWa/Tq1Sfh9O7UOl3YY+ma44ESPY5Z6ylxW9RBXGsON8HNe3jTjR0/8ja/Se5napoy1yrnt/wz
 fihB5BUBYtM3UHmKRvEkumDxfM59NOdp5c5j7qjqYNOOAyaqqK+4FWgxbJBuB9p0agFJsQBZRAu
 rAcqLUDxTqFHL0A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cs35l36 codec needs the codec dai and component sysclk to be set
during TDM startup. Set these for all codec DAIs on the QUATERNARY_TDM
path, gracefully handling codecs that don't support sysclk by ignoring
-ENOTSUPP returns.

Based on work of Joel Selvaraj.

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

