From: Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
Subject: [PATCH v4 0/2] Samsung Galaxy Z Fold5 initial support
Date: Sun, 07 Apr 2024 07:38:12 +0200
Message-Id: <20240407-samsung-galaxy-zfold5-q5q-v4-0-8b67b1813653@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEQxEmYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyTHQUlJIzE
 vPSU3UzU4B8JSMDIxMDEwNz3eLE3OLSvHTd9MScxIpK3aq0/JwUU91C00LdxCTDtJQk45Q0SzM
 zJaD+gqLUtMwKsNnRsbW1AK52YrxrAAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712468293; l=974;
 i=serdeliuk@yahoo.com; s=20240326; h=from:subject:message-id;
 bh=gNaMHU635ETfkv5s8GiZH8o0VGPbI5LP8wCGPGKhkTs=;
 b=dmeCCXklsmwJ+mRqpko33fvgv3kX/Kr0q8edP8OQAo+0QYmb/eemYtJ38X0TvyQ/AbMJBPnw+
 6lIAktN0khUDbyI0gXurXGWsuYyt6wkuONkSMt6+RHXCroYmJZ72qCE
X-Developer-Key: i=serdeliuk@yahoo.com; a=ed25519;
 pk=aWyveUE11qfDOOlRIFayXukrNn39BvZ9k9uq94dAsgY=
X-Endpoint-Received: by B4 Relay for serdeliuk@yahoo.com/20240326 with auth_id=147
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- removed extraneous new line
- removed pcie_1_phy_aux_clk
- removed extranous pcie1

This documents and add intial dts support for Samsung Galaxy Z Fold5 (samsung,q5q)
which is a foldable phone by Samsung based on the sm8550 SoC.

Currently working features:
- Framebuffer
- UFS
- i2c
- Buttons

Signed-off-by: Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
---
Alexandru Marc Serdeliuc (2):
      dt-bindings: arm: qcom: Document the Samsung Galaxy Z Fold5
      arm64: dts: qcom: sm8550: Add support for Samsung Galaxy Z Fold5

 Documentation/devicetree/bindings/arm/qcom.yaml |   1 +
 arch/arm64/boot/dts/qcom/Makefile               |   1 +
 arch/arm64/boot/dts/qcom/sm8550-samsung-q5q.dts | 593 ++++++++++++++++++++++++
 3 files changed, 595 insertions(+)
---
base-commit: 39cd87c4eb2b893354f3b850f916353f2658ae6f
change-id: 20240407-samsung-galaxy-zfold5-q5q-ab1fdb3df966

Best regards,
-- 
Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>

