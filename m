From: Fenglin Wu <quic_fenglinw@quicinc.com>
Subject: [PATCH v10 0/4] Add support for vibrator in multiple PMICs
Date: Fri, 12 Apr 2024 20:36:24 +0800
Message-Id: <20240412-pm8xxx-vibrator-new-design-v10-0-0ec0ad133866@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMgqGWYC/33NPRLCIBQE4KtkqMUB8kesvIdjAeQleYUkgiJOJ
 neXxEablLsz++1MPDgET07ZTBwE9DjaFDg7ZMQMyvZAsU0FEUwULBeSTjcZY6QBtVOP0VELL9q
 Cx95SKCXnqi0bkIokYHLQYdz0yzXlAX1avLezINf2yxaM77FBUkarTmipWa4LU5/vTzRozdGMN
 7LCofnB+D7WJKzWXVkZ3Qgt5D+2LMsHlfGQjxQBAAA=
To: kernel@quicinc.com, Andy Gross <agross@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Fenglin Wu <quic_fenglinw@quicinc.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712925404; l=3007;
 i=quic_fenglinw@quicinc.com; s=20240327; h=from:subject:message-id;
 bh=uVRPkLUxeBeImJcfochb9CYj4hSQ+3CFeTdiRt6pTwE=;
 b=3dgECVg3VxSnfiFMIJQ37rIrQuj5BeG0VyJXrmba1yHgjbZ3tFN0W0WUqz+vH7ymBbraGcj+d
 yiMwMwWyBGzANJTDLrgAxLmBYPgdzwbtnFsKBtmPYwwdJR4mdtyiZP6
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20240327 with auth_id=146
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SW support for the vibrator module inside PMI632, PM7250B, PM7325B, PM7550BA.
It is very similar to the vibrator module inside PM8916 which is supported in
pm8xxx-vib driver but just the drive amplitude is controlled with 2 registers,
and the register base offset in each PMIC is different.

Changes in v10:
  1. Add Fixes tag
  2. Update SSBI vibrator to use DT 'reg' value
  3. Add drv_in_step flag for programming vibrator level in steps
     Link to v9: https://lore.kernel.org/r/20240411-pm8xxx-vibrator-new-design-v9-0-7bf56cb92b28@quicinc.com

Changes in v9:
  1. Add a preceding change to correct VIB_MAX_LEVELS calculation
  2. Address review comments from Konrad
     Link to v8: https://lore.kernel.org/r/20240401-pm8xxx-vibrator-new-design-v8-0-6f2b8b03b4c7@quicinc.com

Changes in v8:
  1. Remove hw_type, and still keep the register info in match data
  2. Update to use register offset in pm8xxx_regs, and the base address
     defined in DT for SPMI vibrator will be added in register access
  3. Update voltage output range for SPMI vibrator which has 2 bytes drive
     registers

Changes in v7:
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

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
Fenglin Wu (4):
      input: pm8xxx-vibrator: correct VIB_MAX_LEVELS calculation
      input: pm8xxx-vibrator: refactor to support new SPMI vibrator
      dt-bindings: input: qcom,pm8xxx-vib: add new SPMI vibrator module
      input: pm8xxx-vibrator: add new SPMI vibrator support

 .../devicetree/bindings/input/qcom,pm8xxx-vib.yaml | 16 +++-
 drivers/input/misc/pm8xxx-vibrator.c               | 95 ++++++++++++++++------
 2 files changed, 84 insertions(+), 27 deletions(-)
---
base-commit: 650cda2ce25f08e8fae391b3ba6be27e7296c6a5
change-id: 20240328-pm8xxx-vibrator-new-design-e5811ad59e8a

Best regards,
-- 
Fenglin Wu <quic_fenglinw@quicinc.com>

