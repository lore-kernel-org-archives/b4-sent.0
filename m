From: David Heidelberg <david@ixit.cz>
Date: Thu, 03 Sep 2026 20:26:40 +0200
Subject: [PATCH RFC v2 4/6] ASoC: qcom: sdm845: Set codec dai and component
 sysclk during startup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-pixel3-audio-v2-4-7c22ed915291@ixit.cz>
References: <20260903-pixel3-audio-v2-0-7c22ed915291@ixit.cz>
In-Reply-To: <20260903-pixel3-audio-v2-0-7c22ed915291@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmbvhVf+BHR6OoT2qWp0MF2oRKI49tPqVizxc6
 hnNYneoM22JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapm74QAKCRBgAj/E00kg
 chGQD/wKIzd9gp3hnX31hFcPrcgQ99vrDL0Fr9tuuMjOOX/NtGrh0zS9M1Rj6lkyhgehLbuucmQ
 o9XhapjIBx/UWWULyXlfTclOEBC/UPt42lnotVCEmnC/StoofpI7MMJTNfTV/Gw9Y1YVOZOATcP
 9SGeUmzp5j7bfGw30iB5kPIJPPM8uuPgl8p8g9R0ZeWwP7mgGoALahPqYoz23a4F4WSuixneucm
 IWDE4c1FpsuWwGjxgx6XI6eav+PItqkgJNhOePNcoYInCEqU/Uvw674Crc9t6SK+50p1QqMhEQu
 M0/GcSNWAQx+htVv87QlvK/HoZHed1yQze8HL5tJ3O6fgumqkPrL+/bs0j0K0JJZfrKuyCHBO92
 06hX+01HMqG691NFJyfYD+or4h1g2woy8aE9twgz08mNfmuZKM+FbWycVFw+kUhTL6lzc9UtsI/
 l8XUFA9voii4QbBYmSHzBlLg2W9I9RdVie1k0vzQxkjdDF29nduqDwNO10s6sPlqjRF45cibRWW
 hYJH6zT0DG5/hUV/RpwhD7d2LFYDVvJT4Icc7chXM3tHliIskm/OgdV0MoGg9bvNmNSJdGxYfmO
 tecAgJO/4qYP1gfru9ZmpsZKYHvsLz0wv2Wy+rcJkXNqckUyd1a/uz81Vaiitp1RrxlQ/uI+hoW
 CuKsNgYTdW+kf/A==
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

