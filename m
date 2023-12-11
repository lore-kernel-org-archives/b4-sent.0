From: Fenglin Wu <quic_fenglinw@quicinc.com>
Subject: [PATCH 0/4] Add pm8010 RPMH regulators for sm8550 boards
Date: Mon, 11 Dec 2023 11:16:58 +0800
Message-Id: <20231211-pm8010-regulator-v1-0-571e05fb4ecc@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACp/dmUC/x3MTQ5AMBBA4avIrDWZtkS5ilgUg0n8ZYpIxN01l
 t/ivQcCCVOAKnlA6OLA2xqh0wS6ya8jKe6jwaCx2mCu9sWhRiU0nrM/NlFoM9e1ukRXeIjZLjT
 w/S/r5n0/2fy0AWIAAAA=
To: Andy Gross <agross@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, kernel@quicinc.com
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, quic_collinsd@quicinc.com, 
 quic_subbaram@quicinc.com, quic_jprakash@quicinc.com, 
 Fenglin Wu <quic_fenglinw@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702264624; l=1011;
 i=quic_fenglinw@quicinc.com; s=20230725; h=from:subject:message-id;
 bh=vZ6FAmeEuhuEnQfZxh3RBh9KdTxrTAeJpbw4mAMqY4Q=;
 b=HC3xI1nwGgSj0NizbiQXsnost3cz/SrXXU3YNnwjV1rMxvOW8SkP6NCPJJFouhI6iLqbVNGDg
 DDMW+jy+WhYCFVBpqdhJ5WlkRuCW6+pmPy3XZ2Xk6NMiLyfKa/Fdpfh
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=hleIDz3Unk1zeiwwOnZUjoQVMMelRancDFXg927lNjI=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20230725 with auth_id=68
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are 2 PM8010 PMICs present in sm8550-mtp/sm8550-qrd boards and
each of them exposes 7 LDOs. Add RPMH regulator support for them.

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
Fenglin Wu (4):
      regulator: qcom-rpmh: extend to support multiple linear voltage ranges
      regulator: qcom,rpmh: add compatible for pm8010 RPMH regultor
      regulator: qcom-rpmh: add support for pm8010 regulators
      arm64: dts: qcom: Add pm8010 regulators for sm8550 boards

 .../bindings/regulator/qcom,rpmh-regulator.yaml    |  14 ++
 arch/arm64/boot/dts/qcom/sm8550-mtp.dts            | 120 ++++++++++++++
 arch/arm64/boot/dts/qcom/sm8550-qrd.dts            | 120 ++++++++++++++
 drivers/regulator/qcom-rpmh-regulator.c            | 177 ++++++++++++++++++---
 4 files changed, 405 insertions(+), 26 deletions(-)
---
base-commit: 753e4d5c433da57da75dd4c3e1aececc8e874a62
change-id: 20231205-pm8010-regulator-0348cb19087a

Best regards,
-- 
Fenglin Wu <quic_fenglinw@quicinc.com>

