From: Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
Date: Wed, 15 Oct 2025 13:27:17 +0530
Subject: [PATCH v3 3/5] ASoC: qcom: sc8280xp: Add support for Kaanapali
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251015-knp-audio-v2-v3-3-e0e3e4167d87@oss.qualcomm.com>
References: <20251015-knp-audio-v2-v3-0-e0e3e4167d87@oss.qualcomm.com>
In-Reply-To: <20251015-knp-audio-v2-v3-0-e0e3e4167d87@oss.qualcomm.com>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rao Mandadapu <quic_srivasam@quicinc.com>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Jingyi Wang <jingyi.wang@oss.qualcomm.com>, 
 Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760515036; l=841;
 i=prasad.kumpatla@oss.qualcomm.com; s=20251014; h=from:subject:message-id;
 bh=7/U4Jmg6F6SwnO1ioLzeT7uYh7ZGHfDTbAMIyQre+6s=;
 b=K6X3RdEJfWGR8sYxA4MQ/xdzWEyVsOkaF5QW088LX/DjGzeuZVLeB7AVTGOgsBe5Iw84Z6axJ
 tkhnxvK+W1wDkU+9F03IO6vNPGMSELD4YSy7V2JTP/ONe/J3cx0mYCf
X-Developer-Key: i=prasad.kumpatla@oss.qualcomm.com; a=ed25519;
 pk=I3mn8JNlYnnm7frqMGXms1Rm2H+0gpAfknMlnBYqCzw=
X-Endpoint-Received: by B4 Relay for prasad.kumpatla@oss.qualcomm.com/20251014 with auth_id=541
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible for sound card on Qualcomm Kaanapali boards.

Signed-off-by: Jingyi Wang <jingyi.wang@oss.qualcomm.com>
Signed-off-by: Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
---
 sound/soc/qcom/sc8280xp.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/sound/soc/qcom/sc8280xp.c b/sound/soc/qcom/sc8280xp.c
index 78e327bc2f07..aea8c1daff32 100644
--- a/sound/soc/qcom/sc8280xp.c
+++ b/sound/soc/qcom/sc8280xp.c
@@ -191,6 +191,7 @@ static int sc8280xp_platform_probe(struct platform_device *pdev)
 }
 
 static const struct of_device_id snd_sc8280xp_dt_match[] = {
+	{.compatible = "qcom,kaanapali-sndcard", "kaanapali"},
 	{.compatible = "qcom,qcm6490-idp-sndcard", "qcm6490"},
 	{.compatible = "qcom,qcs6490-rb3gen2-sndcard", "qcs6490"},
 	{.compatible = "qcom,qcs8275-sndcard", "qcs8300"},

-- 
2.34.1

