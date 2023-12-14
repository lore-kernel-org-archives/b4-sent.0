From: Fenglin Wu <quic_fenglinw@quicinc.com>
Subject: [PATCH v2 0/5] Add pm8010 RPMH regulators for sm8550 boards
Date: Thu, 14 Dec 2023 10:59:10 +0800
Message-Id: <20231214-pm8010-regulator-v2-0-82131df6b97b@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH9vemUC/2WNSw6CQBBEr0J67ZjuAQK68h6GBbQNdCIfZ4Roy
 Nzdkbhz+SpVrzbw4lQ8nJMNnKzqdRoj2EMC3NdjJ0ZvkcGiTclibuahRELjpFvu9XNyBtOs5IZ
 OWBY1xNnspNXXrrxWkXv1sfbeH1b6pj8Z0b9sJYMmL0gwb5tMmC+PRVlHPvI0QBVC+ADKJw6zs
 gAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702522752; l=1307;
 i=quic_fenglinw@quicinc.com; s=20230725; h=from:subject:message-id;
 bh=Ke3Hfe/ljNKuZm1h7cmur868QzI0qQ9j6+vgudXVa3g=;
 b=5EIvBK0008mKfFkqIlHkM9+7i4Yw6lKkrWQ8+ty7d8AIKFEV2zL6xkfIfF5udccUINlvJC3pf
 30F4q5n3TzQD+/w8fkr1WZS8wQEsq9qEMXn5uyoiZpGeL/fTHhq6Mv7
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=hleIDz3Unk1zeiwwOnZUjoQVMMelRancDFXg927lNjI=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20230725 with auth_id=68
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are 2 PM8010 PMICs present in sm8550-mtp/sm8550-qrd boards and
each of them exposes 7 LDOs. Add RPMH regulator support for them.

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
Changes in v2:
- Updated subject prefix in the dt-binding commit and fixed the typo.
- Separate the DTS commit with board name prefixes.
- Link to v1: https://lore.kernel.org/r/20231211-pm8010-regulator-v1-0-571e05fb4ecc@quicinc.com

---
Fenglin Wu (5):
      regulator: qcom-rpmh: extend to support multiple linear voltage ranges
      regulator: dt-bindings: qcom,rpmh: add compatible for pm8010
      regulator: qcom-rpmh: add support for pm8010 regulators
      arm64: dts: qcom: sm8550-mtp: Add pm8010 regulators
      arm64: dts: qcom: sm8550-qrd: add PM8010 regulators

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

