From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH v3 0/6] arm64: dts: freescale: add support for the
 GOcontroll Moduline IV/Mini
Date: Thu, 30 Oct 2025 07:35:36 +0100
Message-Id: <20251030-mini_iv-v3-0-ef56c4d9f219@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADgHA2kC/2WMwQqDMBAFf0X23JRkNdT01P8opYQ00QVNJJHQI
 v57o5cWPM7jzSyQbCSb4FotEG2mRMEXqE8VmF77zjJ6FQbkKAXnio3k6UmZaS6tNGgEYg3lPUX
 r6L2X7o/CPaU5xM8ezmJbj40sGGeubltlGoWNvNy6YIKfYxiGswkjbKGMfzLiT8YiI9eudUprI
 5qDvK7rF7GCyXHgAAAA
X-Change-ID: 20251009-mini_iv-a05e5c2c1223
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Matti Vaittinen <mazziesaccount@gmail.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761806140; l=2171;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=U7srSnWzfH6yj+mfSTGf2OP0Gg/vZlzbpPNFl8Dk7XQ=;
 b=dUk+8sCZB3oHVtlOsJveFBg7XJlVdMloMj3tLjhulGXp3ipCK3pKsZ3y9+/ItK5lwGpdeSH5w
 w8ba6dfY5LSB1w1EJjYBMGOe9hQZkJEhiH4z1nI3D8f52VgHf6f8MpU
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add initial support for the Moduline IV and Moduline Mini embedded
controllers.

These systems are powered by the Ka-Ro Electronics tx8m-1610 COM, which
features an imx8mm SoC.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Changes in v3:
- Add patch fixing the pmic driver
- Use the proper feedback properties for BUCK6
- Slightly rework the compatibles, acked by conor dropped
- Add missing CAN interface supplies, remove the leftover comment
- Add missing vled-supply
- Add missing ethernet phy interrupt (doesn't work)
- Fix the cs-gpios properties in all spi interfaces
- Fix the order of properties in all spi interfaces
- Remove unused labels for regulators of the PMIC
- Link to v2: https://lore.kernel.org/r/20251022-mini_iv-v2-0-20af8f9aac14@gocontroll.com

Changes in v2:
- Fix allignment issue in imx8mm-tx8m-1610.dtsi (fec1)
- Move phy-reset into fec (works better in barebox)
- Make the gpio-line-names groups of four on every line
- Link to v1: https://lore.kernel.org/r/20251009-mini_iv-v1-0-f3889c492457@gocontroll.com

---
Maud Spierings (6):
      dt-bindings: arm: fsl: Add GOcontroll Moduline IV/Mini
      regulator: bd718x7: Fix voltages scaled by resistor divider
      arm64: dts: imx8mm: Add pinctrl config definitions
      arm64: dts: freescale: add Ka-Ro Electronics tx8m-1610 COM
      arm64: dts: freescale: Add the GOcontroll Moduline IV
      arm64: dts: freescale: Add the GOcontroll Moduline Mini

 Documentation/devicetree/bindings/arm/fsl.yaml     |   8 +
 arch/arm64/boot/dts/freescale/Makefile             |   3 +
 arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h     |  33 +
 .../imx8mm-tx8m-1610-moduline-iv-306-d.dts         | 800 +++++++++++++++++++++
 .../imx8mm-tx8m-1610-moduline-mini-111.dts         | 688 ++++++++++++++++++
 .../arm64/boot/dts/freescale/imx8mm-tx8m-1610.dtsi | 444 ++++++++++++
 drivers/regulator/bd718x7-regulator.c              |   2 +
 7 files changed, 1978 insertions(+)
---
base-commit: 7c3ba4249a3604477ea9c077e10089ba7ddcaa03
change-id: 20251009-mini_iv-a05e5c2c1223

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

