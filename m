From: Fenglin Wu <quic_fenglinw@quicinc.com>
Subject: [PATCH RESEND v7 0/3] Add support for vibrator in multiple PMICs
Date: Wed, 08 Nov 2023 15:36:33 +0800
Message-Id: <20231108-pm8xxx-vibrator-v7-0-632c731d25a8@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: linux-arm-msm@vger.kernel.org, Andy Gross <agross@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, quic_collinsd@quicinc.com, 
 quic_subbaram@quicinc.com, quic_kamalw@quicinc.com, jestar@qti.qualcomm.com, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Fenglin Wu <quic_fenglinw@quicinc.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699429013; l=2464;
 i=quic_fenglinw@quicinc.com; s=20230725; h=from:subject:message-id;
 bh=SSzKXj4HYgTm7zHPy0rOpxw6Ed5QTb2H+dQfnhkXJKo=;
 b=w3GvfpwJQDcTKDhpETrdjoDKdj197h/+qiHfVkUkJNswYpwyg8QvMme8o2T5kCRvhdf2W26AM
 qNQoRzbn6QyBTaZ6pPu7f5QcGQUzWTnyC4Fy8f0aW0+uYgfWxqUvu7L
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=hleIDz3Unk1zeiwwOnZUjoQVMMelRancDFXg927lNjI=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20230725 with auth_id=68
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SW support for the vibrator module inside PMI632, PM7250B, PM7325B, PM7550BA.
It is very similar to the vibrator module inside PM8916 which is supported in
pm8xxx-vib driver but just the drive amplitude is controlled with 2 registers,
and the register base offset in each PMIC is different.

Changes in v7;
  1. Fix a typo: SSBL_VIB_DRV_REG --> SSBI_VIB_DRV_REG
  2. Move the hw_type switch case in pm8xxx_vib_set() to the refactoring
     change.

Changes in v6:
  1. Add "qcom,pmi632-vib" as a standalone compatible string.

Changes in v5:
  1. Drop "qcom,spmi-vib-gen2" generic compatible string as requested
     and use device specific compatible strings only.

Changes in v4:
  1. Update to use the combination of the HW type and register offset
     as the constant match data, the register base address defined in
     'reg' property will be added when accessing SPMI registers using
     regmap APIs.
  2. Remove 'qcom,spmi-vib-gen1' generic compatible string.

Changes in v3:
  1. Refactor the driver to support different type of the vibrators with
    better flexibility by introducing the HW type with corresponding
    register fields definitions.
  2. Add 'qcom,spmi-vib-gen1' and 'qcom,spmi-vib-gen2' compatible
    strings, and add PMI632, PM7250B, PM7325B, PM7550BA as compatbile as
    spmi-vib-gen2.

Changes in v2:
  Remove the "pm7550ba-vib" compatible string as it's compatible with pm7325b.

Fenglin Wu (3):
  input: pm8xxx-vib: refactor to easily support new SPMI vibrator
  dt-bindings: input: qcom,pm8xxx-vib: add new SPMI vibrator module
  input: pm8xxx-vibrator: add new SPMI vibrator support

 .../bindings/input/qcom,pm8xxx-vib.yaml       |  16 +-
 drivers/input/misc/pm8xxx-vibrator.c          | 171 ++++++++++++------
 2 files changed, 132 insertions(+), 55 deletions(-)

--
2.25.1

---
Fenglin Wu (3):
      input: pm8xxx-vib: refactor to easily support new SPMI vibrator
      dt-bindings: input: qcom,pm8xxx-vib: add new SPMI vibrator module
      input: pm8xxx-vibrator: add new SPMI vibrator support

 .../devicetree/bindings/input/qcom,pm8xxx-vib.yaml |  16 +-
 drivers/input/misc/pm8xxx-vibrator.c               | 170 ++++++++++++++-------
 2 files changed, 131 insertions(+), 55 deletions(-)
---
base-commit: 650cda2ce25f08e8fae391b3ba6be27e7296c6a5
change-id: 20230925-pm8xxx-vibrator-62df3df46a6c

Best regards,
-- 
Fenglin Wu <quic_fenglinw@quicinc.com>

