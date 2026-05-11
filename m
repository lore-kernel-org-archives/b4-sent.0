From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Subject: [PATCH v2 0/3] arm64: qcom: add Ayaneo Pocket DS gaming console
Date: Mon, 11 May 2026 18:33:52 +0700
Message-Id: <20260511-pocketds-v2-0-299dd4247f2f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ6CMBBFr0Jmbc1QAwZX3sOwKMMURoWSFhsN4
 e4W3Lp8yfvvLxDYCwe4ZAt4jhLEjQn0IQPqzdixkjYxaNQlFjmqydGD5zYoRj43VUX2VFaQ9Mm
 zlfeeutU/Dq/mzjRv+83oJczOf/avmG/en2zMFSqyWBhiwtLYazcYeR7JDVCv6/oFVcZiSrIAA
 AA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778499232; l=2566;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=tvd6ZTLuJ7HOkMjrrvnOyh5A5zjUjdnNxtckDH8Po7s=;
 b=byuN/FB3pvbmX47hyTt1leLWKl0EB3jX+h4Du7RnqYGbBML8/bOLrTSBW+RuIcetr/SBLPFrK
 l5JzezcUyFSA7oYbq42pQToLxq086CWh3t8hqwp+p4cgAXg/lAnCGtD
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial support for the Ayaneo Pocket DS, a handheld
gaming console built around the Qualcomm QCS8550 SoC. It has UFS
storage, WiFi/Bluetooth, gaming buttons, microSD, dual displays, and
USB-C with DisplayPort. Game controls are exposed through a Renesas
uPD720201 PCIe USB 3.0 host controller on PCIe1.

The first patch adds labels to the sm8550 thermal zones so the board
can attach its trip points and cooling maps through the &label override
syntax. The second introduces the Pocket DS device tree itself.

Only the basics are wired up at this stage (boot to console, core
peripherals, USB-C and DP); the display panel will follow in a later
submission.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
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

---
Alexandre Hamamdjian (1):
      arm64: dts: qcom: sm8550: add labels for thermal zones

Teguh Sobirin (2):
      dt-bindings: arm: qcom: document the Ayaneo Pocket DS
      arm64: dts: qcom: add basic devicetree for Ayaneo Pocket DS gaming console

 Documentation/devicetree/bindings/arm/qcom.yaml    |    6 +
 arch/arm64/boot/dts/qcom/Makefile                  |    1 +
 .../boot/dts/qcom/qcs8550-ayaneo-pocketds.dts      | 1861 ++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sm8550.dtsi               |   26 +-
 4 files changed, 1881 insertions(+), 13 deletions(-)
---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260510-pocketds-e0e7b99cf369

Best regards,
--  
Alexandre Hamamdjian <azkali.limited@gmail.com>

