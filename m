From: Alexandre MINETTE <contact@alex-min.fr>
Date: Tue, 09 Jun 2026 10:13:45 +0200
Subject: [PATCH v4 2/6] pinctrl: qcom: Register functions before enabling
 pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260609-mainline-send-v1-sending-v4-2-83768fbf404d@alex-min.fr>
References: <20260609-mainline-send-v1-sending-v4-0-83768fbf404d@alex-min.fr>
In-Reply-To: <20260609-mainline-send-v1-sending-v4-0-83768fbf404d@alex-min.fr>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Guru Das Srinagesh <linux@gurudas.dev>, Linus Walleij <linusw@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 phone-devel@vger.kernel.org, Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780992834; l=2004;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=gqK5qmgCceA2ln5R06RBqAB8HOklQ9gk21qwB8S51xo=;
 b=oBXpglylxTL8r10fHries+jj6sz0vvWF+pd91bThspg4YbX+vsu5D/py2VN/VVL2saD7OMEIs
 tTcEhnLN/F2BihmfHOaQaRt8roOJubzk8/A0jBBIY2YOXy41lsUczPl
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pinctrl consumers can request states while the pinctrl core enables the
controller. On Qualcomm pinctrl drivers this can happen before the SoC
function list has been registered, which leaves the function table
incomplete during state lookup.

On APQ8064 this can fail while claiming pinctrl hogs:

   apq8064-pinctrl 800000.pinctrl: invalid function ps_hold in map table
   apq8064-pinctrl 800000.pinctrl: error claiming hogs: -22
   apq8064-pinctrl 800000.pinctrl: could not claim hogs: -22

Register Qualcomm pinctrl with devm_pinctrl_register_and_init(), add the
SoC pin functions, and only then enable the pinctrl device.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
 drivers/pinctrl/qcom/pinctrl-msm.c | 15 ++++++++++-----
 1 file changed, 10 insertions(+), 5 deletions(-)

diff --git a/drivers/pinctrl/qcom/pinctrl-msm.c b/drivers/pinctrl/qcom/pinctrl-msm.c
index 45b3a2763eb8..a2a1e0835735 100644
--- a/drivers/pinctrl/qcom/pinctrl-msm.c
+++ b/drivers/pinctrl/qcom/pinctrl-msm.c
@@ -1593,11 +1593,11 @@ int msm_pinctrl_probe(struct platform_device *pdev,
 	pctrl->desc.pins = pctrl->soc->pins;
 	pctrl->desc.npins = pctrl->soc->npins;
 
-	pctrl->pctrl = devm_pinctrl_register(&pdev->dev, &pctrl->desc, pctrl);
-	if (IS_ERR(pctrl->pctrl)) {
-		dev_err(&pdev->dev, "Couldn't register pinctrl driver\n");
-		return PTR_ERR(pctrl->pctrl);
-	}
+	ret = devm_pinctrl_register_and_init(&pdev->dev, &pctrl->desc,
+					     pctrl, &pctrl->pctrl);
+	if (ret)
+		return dev_err_probe(&pdev->dev, ret,
+				     "Couldn't register pinctrl driver\n");
 
 	for (i = 0; i < soc_data->nfunctions; i++) {
 		func = &soc_data->functions[i];
@@ -1607,6 +1607,11 @@ int msm_pinctrl_probe(struct platform_device *pdev,
 			return ret;
 	}
 
+	ret = pinctrl_enable(pctrl->pctrl);
+	if (ret)
+		return dev_err_probe(&pdev->dev, ret,
+				     "Couldn't enable pinctrl driver\n");
+
 	ret = msm_gpio_init(pctrl);
 	if (ret)
 		return ret;

-- 
2.43.0

