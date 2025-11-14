From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH 0/3] arm64: dts: freescale: moduline-display: several fixes
Date: Fri, 14 Nov 2025 15:11:48 +0100
Message-Id: <20251114-disp_fix-v1-0-49cbe826afc2@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKQ4F2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQ0MT3ZTM4oL4tMwKXaNkS4MUY9PEJIOUFCWg8oKiVKAw2Kjo2NpaAHR
 ob81aAAAA
X-Change-ID: 20251114-disp_fix-2c90d35ab0dd
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763129510; l=971;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=dar1GitVgzSL3thT8mS4kxQWjGPcF9tQbQT2Aymvgos=;
 b=PuPgSFng3RzGVizBii7B7MV3Vbtta44/VL4M7bg/F4COAzYEuLd0ahfv4wT90G6ISGumlb6k/
 qAdZK50Fa7PDc+++LX7EXgXB8CJGQs/UCkK166ioG8esh7w0G1D7ZHb
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A couple of issues where discovered:
- compatibles should integrate the SoM
- the eqos mac address is stored in eth_mac1

The first one is breaking, but it is early enough that it can be
corrected without causing any issues.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Maud Spierings (3):
      dt-bindings: arm: fsl: moduline-display: fix compatible
      arm64: dts: freescale: moduline-display: fix compatible
      arm64: dts: freescale: tx8p-ml81: fix eqos nvmem-cells

 Documentation/devicetree/bindings/arm/fsl.yaml                     | 7 ++++++-
 .../boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts   | 2 +-
 arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi                | 5 +++++
 3 files changed, 12 insertions(+), 2 deletions(-)
---
base-commit: 0f2995693867bfb26197b117cd55624ddc57582f
change-id: 20251114-disp_fix-2c90d35ab0dd

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

