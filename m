From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH v21 0/6] Add PWM support for IPQ chipsets
Date: Mon, 06 Apr 2026 22:24:37 +0200
Message-Id: <20260406-ipq-pwm-v21-0-6ed1e868e4c2@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAIUW1GkC/23O0U7DMAwF0F+Z+kwm22malKf9B0KoTRwWQZcu3
 QrT1H8nrTRWxB6d+FzfazFwCjwUz5trkXgMQ4iHPBA+bQq7bw7vLILLDwUBKaiJROiPov/qhDV
 WK4uldoqKvN0n9uF7iXp5zbNPsROnfeLm5iUCKKxAKdhSSRK0EiiO52DfXD7dp3DZzVM42K2N3
 Ry6D8MppstSb8Rqzl6a5CT8bZI/BAgJ4ElqBq7MLp5PnzF+LDFzmRH12pqV1dnWrSslO2+11w+
 sWVmqV9Zky65lb9i3reEHtr5bpPXdOluUrdVQWls16r8luNkKCMq7JZg7o5YSEBvp8K+dpukHU
 CXzXtgBAAA=
X-Change-ID: 20250922-ipq-pwm-c8c75c147d52
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Devi Priya <quic_devipriy@quicinc.com>, 
 Baruch Siach <baruch.siach@siklu.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775507135; l=6465;
 i=george.moussalem@outlook.com; s=20260406; h=from:subject:message-id;
 bh=SDhHc8Gdlrhgi2kS2fCmPzPir3jVgVnkcwYGV6/fk9M=;
 b=3JWHAb2VwyMun5FJ77dftxXSowjvRhsNsVjt17VuQmMMMLEZFy8r7ueQeWewK2OLqnScZg2nh
 KbGnOSdD2R7AOkqDVyp9wzw3F+8kVUYIL8kGu794NbXzZ5C5OHuwPuP
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=uqspem3ahtBvPEBuxVbyyXT/0Vp3JNb/mo1EPbmBzWg=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20260406 with auth_id=722
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PWM driver and binding support for IPQ chipsets.
Also, add nodes to add support for pwm in ipq6018, ipq5018, ipq5332, and
ipq9574.

I've picked up work based on Devi's last submission (v15) which dates
back to 05 October 2023 as below SoCs are still active.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Changes in v21:
- Added macro definition for minimum supported period and lower bound check to ensure a valid period 
- Added code comment to explain why pre_div won't overflow
- Link to v20: https://patch.msgid.link/20260204-ipq-pwm-v20-0-91733011a3d1@outlook.com

Changes in v20:
- Updated IPQ_PWM_MAX_DIV macro definition to use FIELD_MAX
- Removed clk struct from ipq_pwm struct and added clk_rate field
  instead which is set during probe.
- Consolidated config_div_and_duty into ipq_pwm_apply
- Fixed arithmetic overflows in apply and get_state
- Fixed off-by-one in divider calculation
- Enabled 100% relative duty cycle support
- Aligned continuation on next lines relative to opening parentheses
- Return 0 instead of ret in probe
- Link to v19: https://lore.kernel.org/r/20251128-ipq-pwm-v19-0-13bc704cc6a5@outlook.com

Changes in v19:
- Changed pwm-cells property in dt bindings from 2 to 3 as per Uwe's
  recommendation
- Added hardware notes and limitations based on own findings as
  requested. NOTE: there's no publically available datasheet though.
- Expanded comment on REG1_UPDATE to indicate that when this bit is set,
  values for div and pre-div take effect. The hardware automatically
  unsets it when the change is completed.
- Added newline between MACRO definition and next comment
- In config_div_and_duty, used mul_u64_u64_div_u64 to avoid overflow
- Removed unncessary restriction of pwm_div to MAX_DIV - 1 after testing
- Constrain pre_div to MAX_DIV is pre_div calculated is > MAX_DIV
- Use of mul_u64_u64_div_u64 in .apply
- Skip calculation of period and duty cycle when PWM_ENABLE REG is unset
- Set duty cycle to period value when calculated duty cycle > period to
  return a valid config
- Removed .npwm as it's taken care of in devm_pwmchip_alloc
- Added call to devm_clk_rate_exclusive_get to lock the clock rate
- Start all kernel messages with a capital letter and end with \n.
- Changed pwm-cells property in all dtsi from 2->3 for in scope IPQ SOCs
- Link to v18: https://lore.kernel.org/r/20251029-ipq-pwm-v18-0-edbef8efbb8e@outlook.com

Changes in v18:
- Updated maintainer info in binding
- Squashed dt bindings patches into the first for adding compatibles for
  IPQ5018, IPQ5332, and IPQ9574
- Link to v17: https://lore.kernel.org/r/20251008-ipq-pwm-v17-0-9bd43edfc7f7@outlook.com

Changes in v17:
- Picked up RB tags from Dmitry and Rob
- Removed unnecessary code comments
- Corrected reg property in PWM node in ipq6018 DTS in line with
  expected nr of bytes for address and size cells
- Link to v16: https://lore.kernel.org/r/20251001-ipq-pwm-v16-0-300f237e0e68@outlook.com

Changes in v16:
- Removed reg description in bindings as the offset is not relative to
  the TCSR region anymore since simple-mfd support was dropped and PWM
  nodes defined as their own nodes, not child nodes. Updated the example
  too.
- Dropped patch to add simple-mfd support to the qcom,tcsr bindings
- Simplified code to calculate divs and duty cycle as per Uwe's comments
- Removed unused pwm_chip struct from ipq_pwm_chip struct
- Removed unnecessary cast as per Uwe's comment
- Replaced devm_clk_get & clk_prepare_enable by devm_clk_get_enabled
- Replaced pwmchip_add by devm_pwmchip_add and removed .remove function
- Removed .owner from driver struct
- Added compatibles to the bindings and nodes to the device trees to add
  PWM support in the IPQ5018, IPQ5332, and IPQ9574 SoCs
- Link to v15: https://lore.kernel.org/r/20231005160550.2423075-1-quic_devipriy@quicinc.com

Changes in v15:
- No change
- Link to v14: https://lore.kernel.org/r/20231005033053.2626465-1-quic_devipriy@quicinc.com

Changes in v14:
- Picked up the R-b tag
- Link to v13: https://lore.kernel.org/r/20231004090449.256229-1-quic_devipriy@quicinc.com

Changes in v13:
- Updated the file name to match the compatible
- Sorted the properties and updated the order in the required field
- Dropped the syscon node from examples
- Link to v12: https://lore.kernel.org/r/20230925065915.3467964-1-quic_devipriy@quicinc.com

Changes in v12:
- Picked up the R-b tag

Changes in v11:
- No change

Changes in v10:
- No change

Changes in v9:
- Add 'ranges' property to example (Rob)
- Drop label in example (Rob)

Changes in v8:
- Add size cell to 'reg' (Rob)

Changes in v7:
- Use 'reg' instead of 'offset' (Rob)
- Drop 'clock-names' and 'assigned-clock*' (Bjorn)
- Use single cell address/size in example node (Bjorn)
- Move '#pwm-cells' lower in example node (Bjorn)
- List 'reg' as required

Changes in v6:
- Device node is child of TCSR; remove phandle (Rob Herring)
- Add assigned-clocks/assigned-clock-rates (Uwe Kleine-König)

Changes in v5:
- Use qcom,pwm-regs for phandle instead of direct regs (Bjorn
    Andersson, Kathiravan T)

Changes in v4:
- Update the binding example node as well (Rob Herring's bot)

Changes in v3:
- s/qcom,pwm-ipq6018/qcom,ipq6018-pwm/ (Rob Herring)

Changes in v2:
- Make #pwm-cells const (Rob Herring)

---

---
Devi Priya (3):
      dt-bindings: pwm: add IPQ6018 binding
      pwm: driver for qualcomm ipq6018 pwm block
      arm64: dts: qcom: ipq6018: add pwm node

George Moussalem (3):
      arm64: dts: qcom: ipq5018: add pwm node
      arm64: dts: qcom: ipq5332: add pwm node
      arm64: dts: qcom: ipq9574: add pwm node

 .../devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml  |  51 ++++
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              |  10 +
 arch/arm64/boot/dts/qcom/ipq5332.dtsi              |  10 +
 arch/arm64/boot/dts/qcom/ipq6018.dtsi              |  10 +
 arch/arm64/boot/dts/qcom/ipq9574.dtsi              |  10 +
 drivers/pwm/Kconfig                                |  12 +
 drivers/pwm/Makefile                               |   1 +
 drivers/pwm/pwm-ipq.c                              | 259 +++++++++++++++++++++
 8 files changed, 363 insertions(+)
---
base-commit: 2febe6e6ee6e34c7754eff3c4d81aa7b0dcb7979
change-id: 20250922-ipq-pwm-c8c75c147d52

Best regards,
--  
George Moussalem <george.moussalem@outlook.com>

