From: Frank Li <Frank.Li@nxp.com>
Subject: [PATCH 00/11] ARM: dts: nxp: clean lpc18xx DTB check warning
Date: Sun, 06 Jul 2025 14:46:56 -0400
Message-Id: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKDEamgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcwMz3ZyCZEOLioqK+JSSYt0kI0NjcyNDs1SzZAMloJaCotS0zAqwcdG
 xtbUAqorP3V4AAAA=
X-Change-ID: 20250706-lpc18xxx_dts-b2137216e6c0
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=1879;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=F01Zl2KLwJZEJs0qPrL6t3cMCxuqK7s2DTQP4dCVqcU=;
 b=Y44sZ3YsNp/IVrlrnvKtROO939BSVTW6WmqJDHFZ8OzLPEspu1u3iBWJ8qukYTqtKbLiW+fNR
 6+5hPmY9vrpDnEJLlArm74FP/V1e9PqGTeDkmqGWIPjxgFh5t5hSHCt
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are 3 dt-binding patch wait for pick.
[1] https://lore.kernel.org/imx/20250617-hound-of-improbable-intensity-e7c3c9@kuoka/
[2] https://lore.kernel.org/imx/174916907717.3619367.3745642154654809311.robh@kernel.org/
[3] https://lore.kernel.org/imx/175087864578.2055525.4510390315154712025.robh@kernel.org/

lpc18xx related DTB warnings reduce to 0.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
Frank Li (11):
      ARM: dts: lpc18xx: rename node name flash-controller to spi
      ARM: dts: lpc18xx: rename node name mmcsd to mmc
      ARM: dts: lpc4350-hitex-eval: change node name flash to flash@0
      ARM: dts: lpc18xx: swap clock-names bic and cui
      ARM: dts: lpc: add #address-cells and #size-cells for sram node
      ARM: dts: lpc: add cfg surfix in pinctrl child node
      ARM: dts: lpc4357-myd-lpc4357: add power-supply for innolux,at070tn92
      ARM: dts: lpc: change node name 'button[0-9]' to button-[0-9]'
      ARM: dts: lpc4357-myd-lpc4357: change node name mdio0 to mdio
      ARM: dts: lpc18xx: add #address-cell and #szie-cell for spi flash controller
      ARM: dts: lpc18xx: add missed arm,num-irq-priority-bits

 arch/arm/boot/dts/nxp/lpc/lpc18xx.dtsi             | 14 ++++++++++----
 arch/arm/boot/dts/nxp/lpc/lpc4337-ciaa.dts         |  6 +++---
 arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts   | 22 +++++++++++++---------
 arch/arm/boot/dts/nxp/lpc/lpc4350.dtsi             |  9 +++++++++
 .../arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts | 21 +++++++++++----------
 arch/arm/boot/dts/nxp/lpc/lpc4357-myd-lpc4357.dts  |  6 ++++--
 arch/arm/boot/dts/nxp/lpc/lpc4357.dtsi             |  9 +++++++++
 7 files changed, 59 insertions(+), 28 deletions(-)
---
base-commit: bb0fde92b56b76f7a0c90a6e9d9f050919fa835e
change-id: 20250706-lpc18xxx_dts-b2137216e6c0

Best regards,
--
Frank Li <Frank.Li@nxp.com>

