From: Fenglin Wu <quic_fenglinw@quicinc.com>
Subject: [PATCH v3 0/2] Add pm8010 RPMH regulators for sm8550 boards
Date: Fri, 15 Dec 2023 16:01:44 +0800
Message-Id: <20231215-pm8010-regulator-v3-0-1bfc4b7ee5ab@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOgHfGUC/23NzQ6CMAzA8VchOzuzbiDDk+9hPLBRoIl8uMmiI
 by7g3jQ6PHftL/OzKMj9OyYzMxhIE9DH0PtEmbbsm+QUxWbSSEVSJHxsdMCBHfYTNfyPjguVKq
 tgULovGTxbHRY02Mjz5fYLfm49tw+BFinbwzgFwvABc9yQJHVJkVrT7eJLPV2b4eOrVyQn0T6h
 5CR0BIUVPXBFLn5JpZleQGs/CT29QAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702627316; l=1213;
 i=quic_fenglinw@quicinc.com; s=20230725; h=from:subject:message-id;
 bh=cL4aJ9Ef2FV4/v1HsF2CM0pB+DdNoh12pxbeAGEls+Q=;
 b=vjXjJL1n7OizYx02Qb9kYiUtK00APtleGa4nw6kHvSqQa2SCyQUhjc85i+NrJJ+pyoSjp0GJK
 xIpseiD4nscDzPMSfXq8unJVnK0EwnT1ZABn6+OkRDVqNQHoGCFQpFc
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=hleIDz3Unk1zeiwwOnZUjoQVMMelRancDFXg927lNjI=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20230725 with auth_id=68
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are 2 PM8010 PMICs present in sm8550-mtp/sm8550-qrd boards and
each of them exposes 7 LDOs. Add RPMH regulator support for them.

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
Changes in v3:
- Mark has already applied the driver and dt-binding commits in regulator/for-next so only board
  file commits left.
- Added Reviewed-by tag.
- Link to v2: https://lore.kernel.org/r/20231214-pm8010-regulator-v2-0-82131df6b97b@quicinc.com

Changes in v2:
- Updated subject prefix in the dt-binding commit and fixed the typo.
- Separate the DTS commit with board name prefixes.
- Link to v1: https://lore.kernel.org/r/20231211-pm8010-regulator-v1-0-571e05fb4ecc@quicinc.com

---
Fenglin Wu (2):
      arm64: dts: qcom: sm8550-mtp: Add pm8010 regulators
      arm64: dts: qcom: sm8550-qrd: add PM8010 regulators

 arch/arm64/boot/dts/qcom/sm8550-mtp.dts | 120 ++++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sm8550-qrd.dts | 120 ++++++++++++++++++++++++++++++++
 2 files changed, 240 insertions(+)
---
base-commit: 753e4d5c433da57da75dd4c3e1aececc8e874a62
change-id: 20231205-pm8010-regulator-0348cb19087a

Best regards,
-- 
Fenglin Wu <quic_fenglinw@quicinc.com>

