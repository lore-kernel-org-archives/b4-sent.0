From: David Heidelberg <david@ixit.cz>
Date: Sun, 05 Jul 2026 22:06:54 +0200
Subject: [PATCH RFC 4/6] ASoC: qcom: sdm845: Set codec dai and component
 sysclk during startup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-pixel3-audio-v1-4-3b66f33859f1@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1661; i=david@ixit.cz;
 h=from:subject:message-id; bh=n0PeFm63dnLy+X+LVgbtdOBKLaGfaMF2ztTB1COcsjk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqSrmMR4XPVxQio6cQDFEW8o1Exzr5qz0l3N4Kr
 2AsCbMI+5aJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCakq5jAAKCRBgAj/E00kg
 cpkhD/9SGmyX53buIajBlu1QAMJQjK6dp++8jlZpT1uVr/zpG/0swg3GoZaihX/GLINFDRdhESE
 f2zCg2Irdjj4ey4twlT8XNaaw1mXX+mRu7Kx0AJ5wfSe1TS57oIcpdIv89xpij2c6TQlVd6ca/k
 9vJmGierJ8k5jqdUMme38EHxCpnWVoGeW2wRYGHX+kvM9IUuUdekK8nnvpF7ks5j56jmzJAk+j7
 3jhKtnXLEqAJY74d45tlV9Px/duegCs3R6+j/eA9KTwSvfc3+HcabHW9nDStfHZJP29Lxhb0J8v
 K/3DW0ObxQ0+MndNSXjql3x7q8SzLrzLr4Ld99TFvA7xYa+RUgDc4SRJ22YW0UxC9rHFrGfUTGG
 3YDDMT9KnwS+j0USNfUljJrDECbSahFmWkpOhtjsxb4pOAe7ebBHyXH3DKbw4BEhhfAdLv3Fr9u
 Swq+bbWdSTSHXNtNtjP63Q021Gx/e6RTLXr6xh7GPOVmYiIyf/ElhwknTbfLIYa2AJJEwdlmdGP
 f51YkMXEowrxQ/lmuaorrbGXKFdQbCJX0gPwbSNUXnUqEgHGwDKUk3akkGps2i7+tCM4HnFjWIO
 hfIbl2J0fliDUja81URL7YEAbjzievSK/NfLDH2V8oG6tL1/gnesLQKaqyr0ifi+7a1rEdDPIL3
 kPV5wwzYYcehFjw==
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
index 8b65aa3982d47..b2d51e472bc26 100644
--- a/sound/soc/qcom/sdm845.c
+++ b/sound/soc/qcom/sdm845.c
@@ -405,16 +405,38 @@ static int sdm845_snd_startup(struct snd_pcm_substream *substream)
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
2.53.0

