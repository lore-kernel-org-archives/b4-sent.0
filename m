From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Subject: [PATCH v3 0/4] arm64: qcom: add Ayaneo Pocket DS gaming console
Date: Sun, 17 May 2026 20:14:19 +0700
Message-Id: <20260517-pocketds-v3-0-d5910c801756@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22Nyw7CIBQFf6VhLYbSV3DlfxgX9HJpUVsaqETT9
 N+FuqmJy0nOzFmIR2fQk1O2EIfBeGPHCMUhI9DLsUNqVGTCGa9ZlTM6WbjjrDxFhk0rBOiiFiT
 OJ4favLbU5fpl/2xvCHPy06I3frbuvX2FPO3+ZENOGQXNKgkIrJb63A3SPI5gB5Kyge/FfCfyK
 HIhlCp52Wj+I67r+gEwPo0H6wAAAA==
X-Change-ID: 20260510-pocketds-e0e7b99cf369
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779023659; l=3953;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=sgYaZc2jrbgHscXICpyw9V4m4a+P3iP44DuYc5/fTJA=;
 b=FLHTQYk6KJTQIcyIF9YexupL/BpiCdbWDZybfo8Ryk9D4LP/0GYu/vJ4T35bZNOLmOJ1hBV9R
 s/OcadF+wQyD1DFQTMhqPOZjmMudncENJvDhZwS5bLVgawKc0ghBjLc
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial support for the Ayaneo Pocket DS, a handheld
gaming console built around the Qualcomm QCS8550 SoC. It has UFS
storage, WiFi/Bluetooth, gaming buttons, microSD, dual displays, and
USB-C with DisplayPort. Game controls are exposed through a Renesas
uPD720201 PCIe USB 3.0 host controller hung off PCIe1, while a
dedicated gamepad MCU is reached over UART11.

The series is structured as:

  1. dt-bindings entry for the new qcom,qcs8550-ayaneo-pocketds
     compatible.
  2. sm8550.dtsi: add labels for the cpuss/cpu/gpuss thermal zones so
     the board can extend them with trip points and cooling maps via
     &label overrides instead of redeclaring zones by path.
  3. The Pocket DS board device tree itself, with the root-level
     nodes alphabetised and the fixed regulators named per the
     "<name>-regulator" convention.
  4. sm8550.dtsi: add the QUP2 SE3 (UART11) controller node and its
     default pinctrl, so the board can enable it as &uart11 instead
     of open-coding the controller in the board dts.

Only the basics are wired up at this stage (boot to console, core
peripherals, USB-C and DP); the display panel will follow in a later
submission.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
Changes in v3:
- New prerequisite patch adding the QUP2 SE3 (UART11) controller node
  and the qup_uart11_default pinctrl state to sm8550.dtsi, so the
  board can enable the gamepad MCU UART via &uart11 instead of
  duplicating the controller node in the board dts.
- Alphabetised the root-level nodes in the board dts and renamed the
  fixed regulators to the "<name>-regulator" node-name convention.
- Link to v2: https://patch.msgid.link/20260511-pocketds-v2-0-299dd4247f2f@gmail.com

Changes in v2:
- Inlined the board into a single qcs8550-ayaneo-pocketds.dts, matching
  the sm8650-ayaneo-pocket-s2 layout
- Added qcom,qcs8550 to the compatible chain
- Prerequisite patch labelling the sm8550 thermal zones so the board
  can extend them via &label overrides (and refactored the board's
  thermal-zones to use them)
- Added the Renesas uPD720201 USB 3.0 controller as a child of pcie1
  with proper avdd33 / vdd10 / vdd33 regulators
- Moved gamepad_pwr_en off &pcie1's pinctrl-0 and onto the
  usb-controller node
- Split the lumped upd720201_active pinctrl into per-regulator states
- Fixed mdss_dp0_out data-lanes to <0 1 2 3> (all four wired)
- Fixed gpio-reserved-ranges to <32 4> (gpio 38-39 drive the Goodix
  touchscreen)
- Renamed nodes with underscores (llcc-lpi-region, splash-region,
  gpio@20) per DT conventions
- Reordered pinctrl-names after pinctrl-N file-wide
- Dropped the unused cont_splash_region label
- Link to v1: https://patch.msgid.link/20260510-pocketds-v1-0-cf05acec06af@gmail.com

To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Alexandre Hamamdjian (3):
      dt-bindings: arm: qcom: document the Ayaneo Pocket DS
      arm64: dts: qcom: sm8550: add labels for thermal zones
      arm64: dts: qcom: sm8550: add UART11 node

Teguh Sobirin (1):
      arm64: dts: qcom: add basic devicetree for Ayaneo Pocket DS gaming console

 Documentation/devicetree/bindings/arm/qcom.yaml    |    6 +
 arch/arm64/boot/dts/qcom/Makefile                  |    1 +
 .../boot/dts/qcom/qcs8550-ayaneo-pocketds.dts      | 1883 ++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sm8550.dtsi               |   52 +-
 4 files changed, 1929 insertions(+), 13 deletions(-)
---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260510-pocketds-e0e7b99cf369

Best regards,
--  
Alexandre Hamamdjian <azkali.limited@gmail.com>

