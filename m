From: Esteban Urrutia <esteuwu@proton.me>
Date: Wed, 29 Jul 2026 15:31:55 -0400
Subject: [PATCH 2/2] ASoC: qcom: sc8280xp: Add support for SM8475
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-sm8475-asoc-v1-2-3edad8aa7628@proton.me>
References: <20260729-sm8475-asoc-v1-0-3edad8aa7628@proton.me>
In-Reply-To: <20260729-sm8475-asoc-v1-0-3edad8aa7628@proton.me>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785353516; l=1427;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=LPNPk32JR+3Yfc6bcAUf5H0iSCn6KrddoUkqE6S79To=;
 b=kqdC7AoaptT1gMKNhyV6c/egWFeHnpURHaXskErHKYgEFEinbXaTeA0+rTKVP8VooK+vVx2wZ
 f44wenZn1N3B1LnzcCNy7ET5vhfCTAVKBJDWcWNgyWReVHZokn3CCzA
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With this, SM8475 topologies can have their own firmware folder.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 sound/soc/qcom/sc8280xp.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/sound/soc/qcom/sc8280xp.c b/sound/soc/qcom/sc8280xp.c
index a9304784d41e..f0f3cd8fca38 100644
--- a/sound/soc/qcom/sc8280xp.c
+++ b/sound/soc/qcom/sc8280xp.c
@@ -362,6 +362,13 @@ static const struct snd_soc_common sm8450_priv_data = {
 	.wcd_jack = true,
 };
 
+static const struct snd_soc_common sm8475_priv_data = {
+	.driver_name = "sm8475",
+	.dapm_widgets = sc8280xp_dapm_widgets,
+	.num_dapm_widgets = ARRAY_SIZE(sc8280xp_dapm_widgets),
+	.wcd_jack = true,
+};
+
 static const struct snd_soc_common sm8550_priv_data = {
 	.driver_name = "sm8550",
 	.dapm_widgets = sc8280xp_dapm_widgets,
@@ -395,6 +402,7 @@ static const struct of_device_id snd_sc8280xp_dt_match[] = {
 	{ .compatible = "qcom,qcs9100-sndcard", .data = &qcs9100_priv_data },
 	{ .compatible = "qcom,sc8280xp-sndcard", .data = &sc8280xp_priv_data },
 	{ .compatible = "qcom,sm8450-sndcard", .data = &sm8450_priv_data },
+	{ .compatible = "qcom,sm8475-sndcard", .data = &sm8475_priv_data },
 	{ .compatible = "qcom,sm8550-sndcard", .data = &sm8550_priv_data },
 	{ .compatible = "qcom,sm8650-sndcard", .data = &sm8650_priv_data },
 	{ .compatible = "qcom,sm8750-sndcard", .data = &sm8750_priv_data },

-- 
2.55.0

