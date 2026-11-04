From: Demeter Barna <me@fromdisposition.org>
Date: Wed, 04 Nov 2026 18:07:10 +0000
Subject: [PATCH 2/7] clk: qcom: lpassaudiocc-sc7280: Add SM8350 audio CSR
 resets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b4-sm8350-sound-v1-2-4c872df294fa@fromdisposition.org>
References: <20261104-b4-sm8350-sound-v1-0-4c872df294fa@fromdisposition.org>
In-Reply-To: <20261104-b4-sm8350-sound-v1-0-4c872df294fa@fromdisposition.org>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-sound@vger.kernel.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793815654; l=1525;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=9ar4otrhuYQUlNK6qRIwOBsUEsXsIX335tkvdLVMcZo=;
 b=/Hbg+9HRwmhfM8q7TlfagS8ExqCph3R6R3NK7WGlxODcHKRVYPD9jIYDv9dMmQWKwbROOH8K1
 Dp0MC+QJJyXB8BJ7d1L5055yvNzi/UhfK8fl/suYi9lZgo7eLp1SpyX
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without these resets the codecs on the SoundWire buses fail to
initialize. The offsets match the QCM6490 reset-only descriptor, but
the SM8350 node only has the CSR region, so probe it from index 0.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 drivers/clk/qcom/lpassaudiocc-sc7280.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/clk/qcom/lpassaudiocc-sc7280.c b/drivers/clk/qcom/lpassaudiocc-sc7280.c
index 7e2172969..11332f9f0 100644
--- a/drivers/clk/qcom/lpassaudiocc-sc7280.c
+++ b/drivers/clk/qcom/lpassaudiocc-sc7280.c
@@ -732,6 +732,7 @@ static const struct qcom_cc_desc lpass_audio_cc_reset_sc7280_desc = {
 static const struct of_device_id lpass_audio_cc_sc7280_match_table[] = {
 	{ .compatible = "qcom,qcm6490-lpassaudiocc", .data = &lpass_audio_cc_reset_sc7280_desc },
 	{ .compatible = "qcom,sc7280-lpassaudiocc", .data = &lpass_audio_cc_sc7280_desc },
+	{ .compatible = "qcom,sm8350-lpassaudiocc", .data = &lpass_audio_cc_reset_sc7280_desc },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, lpass_audio_cc_sc7280_match_table);
@@ -768,6 +769,9 @@ static int lpass_audio_cc_sc7280_probe(struct platform_device *pdev)
 	if (of_device_is_compatible(pdev->dev.of_node, "qcom,qcm6490-lpassaudiocc"))
 		return qcom_cc_probe_by_index(pdev, 1, desc);
 
+	if (of_device_is_compatible(pdev->dev.of_node, "qcom,sm8350-lpassaudiocc"))
+		return qcom_cc_probe_by_index(pdev, 0, desc);
+
 	ret = lpass_audio_setup_runtime_pm(pdev);
 	if (ret)
 		return ret;

-- 
2.53.0

