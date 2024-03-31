From: Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
Subject: [PATCH v3 0/2] Samsung Galaxy Z Fold5 initial support
Date: Sun, 31 Mar 2024 12:56:38 +0200
Message-Id: <20240331-samsung-galaxy-zfold5-q5q-v3-0-17ae8d0a9fba@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGZBCWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHUUlJIzE
 vPSU3UzU4B8JSMDIxMDY2ND3eLE3OLSvHTd9MScxIpK3aq0/JwUU91C00LdVOM0YxOLNDMTc1N
 zJaD+gqLUtMwKsNnRsbW1ABNhBOJrAAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711882599; l=884;
 i=serdeliuk@yahoo.com; s=20240326; h=from:subject:message-id;
 bh=3JA8zXWvxduJPtSIA4N0SAo+czSCUXl4wrmxDz54JAg=;
 b=aDq6wusCtpMghuggUJWzAmv91MkJfuMGcoau1D3E95KEyBKJtJ9oK6lw6cLQ4OZDBtiQdC54p
 iWgCy20wZV4BQxlAEf220eEyC68d7ITJVC67iRmpLT1zdSFwa5aMIP5
X-Developer-Key: i=serdeliuk@yahoo.com; a=ed25519;
 pk=aWyveUE11qfDOOlRIFayXukrNn39BvZ9k9uq94dAsgY=
X-Endpoint-Received: by B4 Relay for serdeliuk@yahoo.com/20240326 with auth_id=147
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

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
 arch/arm64/boot/dts/qcom/sm8550-samsung-q5q.dts | 582 ++++++++++++++++++++++++
 3 files changed, 584 insertions(+)
---
base-commit: 4cece764965020c22cff7665b18a012006359095
change-id: 20240331-samsung-galaxy-zfold5-q5q-e3f348f64757

Best regards,
-- 
Alexandru Marc Serdeliuc <serdeliuk@yahoo.com>

