From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH v16 0/9] Add PWM support for IPQ chipsets
Date: Wed, 01 Oct 2025 18:04:16 +0400
Message-Id: <20251001-ipq-pwm-v16-0-300f237e0e68@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOA03WgC/zWNzQ6CQAyEX8X0bEm3UFBPvocxhpRFegCWxd8Q3
 t3VxOM3mW9mgdlH8zMcNgtE/7DZxiGBK7cb0K4erh6tSQEwsdCeGS1MGJ496k4rUVdUjTCkdoi
 +tddv6nRO3Maxx1sXff33c0ckriQRyrjgnCpBh9Pd9NKk6xDtffySDZrp2MO6fgAls/aQnwAAA
 A==
X-Change-ID: 20250922-ipq-pwm-c8c75c147d52
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Baruch Siach <baruch@tkos.co.il>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Devi Priya <quic_devipriy@quicinc.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Baruch Siach <baruch.siach@siklu.com>, 
 George Moussalem <george.moussalem@outlook.com>, 
 Bjorn Andersson <andersson@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759327459; l=4387;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=7+BKdybQdA+TbIKKvtFc6vQ+I/JxwRRAUowkGuhh7dA=;
 b=/0tv5ydgdeNWP7z8mhbWkfAZBJKAvz/jLW2yE2D21TSCQcIvgeormrV7z68m6x0LtqKBJbtch
 lMgm/BtqT8xB7oY852gOced/kxRRnBhQ13dOU4N/fccy1KR6MgPlDXk
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PWM driver and binding support for IPQ chipsets.
Also, add nodes to add support for pwm in ipq6018, ipq5018, ipq5332, and
ipq9574.

I've picked up work based on Devi's last submission (v15) which dates
back to 05 October 2023 as below SoCs are still active.

V16:

  Removed reg description in bindings as the offset is not relative to
  the TCSR region anymore since simple-mfd support was dropped and PWM
  nodes defined as their own nodes, not child nodes. Updated the example
  too.

  Dropped patch to add simple-mfd support to the qcom,tcsr bindings

  Simplified code to calculate divs and duty cycle as per Uwe's comments

  Removed unused pwm_chip struct from ipq_pwm_chip struct

  Removed unnecessary cast as per Uwe's comment

  Replaced devm_clk_get & clk_prepare_enable by devm_clk_get_enabled

  Replaced pwmchip_add by devm_pwmchip_add and removed .remove function

  Removed .owner from driver struct

  Added compatibles to the bindings and nodes to the device trees to add
  PWM support PWM in the IPQ5018, IPQ5332, and IPQ9574 SoCs

v15:

  No change

v14:

  Picked up the R-b tag

v13:

  Updated the file name to match the compatible

  Sorted the properties and updated the order in the required field

  Dropped the syscon node from examples

v12:

  Picked up the R-b tag

v11:

  No change

v10:

  No change

v9:

  Add 'ranges' property to example (Rob)

  Drop label in example (Rob)

v8:

  Add size cell to 'reg' (Rob)

v7:

  Use 'reg' instead of 'offset' (Rob)

  Drop 'clock-names' and 'assigned-clock*' (Bjorn)

  Use single cell address/size in example node (Bjorn)

  Move '#pwm-cells' lower in example node (Bjorn)

  List 'reg' as required

v6:

  Device node is child of TCSR; remove phandle (Rob Herring)

  Add assigned-clocks/assigned-clock-rates (Uwe Kleine-König)

v5: Use qcom,pwm-regs for phandle instead of direct regs (Bjorn
    Andersson, Kathiravan T)

v4: Update the binding example node as well (Rob Herring's bot)

v3: s/qcom,pwm-ipq6018/qcom,ipq6018-pwm/ (Rob Herring)

v2: Make #pwm-cells const (Rob Herring)

V15:
Detailed Change logs are added to the respective patches.

V14 can be found at:
https://lore.kernel.org/linux-arm-msm/20231005043127.2690639-1-quic_devipriy@quicinc.com/

Devi Priya (4):
  pwm: driver for qualcomm ipq6018 pwm block
  dt-bindings: pwm: add IPQ6018 binding
  dt-bindings: mfd: qcom,tcsr: Add simple-mfd support for IPQ6018
  arm64: dts: qcom: ipq6018: add pwm node

 .../devicetree/bindings/mfd/qcom,tcsr.yaml    | 112 +++++--
 .../bindings/pwm/qcom,ipq6018-pwm.yaml        |  45 +++
 arch/arm64/boot/dts/qcom/ipq6018.dtsi         |  15 +-
 drivers/pwm/Kconfig                           |  12 +
 drivers/pwm/Makefile                          |   1 +
 drivers/pwm/pwm-ipq.c                         | 282 ++++++++++++++++++
 6 files changed, 435 insertions(+), 32 deletions(-)
 create mode 100644 Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
 create mode 100644 drivers/pwm/pwm-ipq.c

--
2.34.1

---
Devi Priya (3):
      dt-bindings: pwm: add IPQ6018 binding
      pwm: driver for qualcomm ipq6018 pwm block
      arm64: dts: qcom: ipq6018: add pwm node

George Moussalem (6):
      dt-bindings: pwm: qcom,ipq6018-pwm: Add compatible for ipq5018
      dt-bindings: pwm: qcom,ipq6018-pwm: Add compatible for ipq5332
      dt-bindings: pwm: qcom,ipq6018-pwm: Add compatible for ipq9574
      arm64: dts: qcom: ipq5018: add pwm node
      arm64: dts: qcom: ipq5332: add pwm node
      arm64: dts: qcom: ipq9574: add pwm node

 .../devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml  |  51 +++++
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              |  10 +
 arch/arm64/boot/dts/qcom/ipq5332.dtsi              |  10 +
 arch/arm64/boot/dts/qcom/ipq6018.dtsi              |  10 +
 arch/arm64/boot/dts/qcom/ipq9574.dtsi              |  10 +
 drivers/pwm/Kconfig                                |  12 ++
 drivers/pwm/Makefile                               |   1 +
 drivers/pwm/pwm-ipq.c                              | 214 +++++++++++++++++++++
 8 files changed, 318 insertions(+)
---
base-commit: 846bd2225ec3cfa8be046655e02b9457ed41973e
change-id: 20250922-ipq-pwm-c8c75c147d52

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

