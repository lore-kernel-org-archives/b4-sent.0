From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH v2 0/5] arm64: dts: freescale: add support for the
 GOcontroll Moduline IV/Mini
Date: Wed, 22 Oct 2025 09:22:36 +0200
Message-Id: <20251022-mini_iv-v2-0-20af8f9aac14@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADyG+GgC/2XMQQqDMBCF4avIrJuSjIZqV71HkSLpqAOaKYmEF
 sndm7rt8n88vh0iBaYI12qHQIkjiy+BpwrcPPiJFD9LA2q0RutOrez5wUkN2pJ16AxiDeX9CjT
 y+5DufemZ4ybhc8DJ/NZ/Ixml1Vi3beeaDht7uU3ixG9BluXsZIU+5/wFvo3v0aMAAAA=
X-Change-ID: 20251009-mini_iv-a05e5c2c1223
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761117763; l=1486;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=6MxoejU7iKxp9mf2s8THn5c4jDLFtHOP5ivmjYnDox0=;
 b=8EDC4BIHHluETyJsGoyj3Ub5ZCMaVm7eZYUrj9HEkXC3ILQwIrUDvDuWDi3lD+10vmAFhAPht
 fbrq37zJBZJCz9pkBRodQSo996DWROXX/di837e4v0DP/zUj/N4dKZ4
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
Changes in v2:
- Fix allignment issue in imx8mm-tx8m-1610.dtsi (fec1)
- Move phy-reset into fec (works better in barebox)
- Make the gpio-line-names groups of four on every line
- Link to v1: https://lore.kernel.org/r/20251009-mini_iv-v1-0-f3889c492457@gocontroll.com

---
Maud Spierings (5):
      dt-bindings: arm: fsl: Add GOcontroll Moduline IV/Mini
      arm64: dts: imx8mm: Add pinctrl config definitions
      arm64: dts: freescale: add Ka-Ro Electronics tx8m-1610 COM
      arm64: dts: freescale: Add the GOcontroll Moduline IV
      arm64: dts: freescale: Add the GOcontroll Moduline Mini

 Documentation/devicetree/bindings/arm/fsl.yaml     |   2 +
 arch/arm64/boot/dts/freescale/Makefile             |   3 +
 arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h     |  33 +
 .../imx8mm-tx8m-1610-moduline-iv-306-d.dts         | 801 +++++++++++++++++++++
 .../imx8mm-tx8m-1610-moduline-mini-111.dts         | 691 ++++++++++++++++++
 .../arm64/boot/dts/freescale/imx8mm-tx8m-1610.dtsi | 439 +++++++++++
 6 files changed, 1969 insertions(+)
---
base-commit: 7c3ba4249a3604477ea9c077e10089ba7ddcaa03
change-id: 20251009-mini_iv-a05e5c2c1223

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

