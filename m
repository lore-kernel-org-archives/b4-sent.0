From: Maud Spierings <maudspierings@gocontroll.com>
Date: Mon, 01 Dec 2025 12:56:51 +0100
Subject: [PATCH v2 2/3] arm64: dts: freescale: moduline-display: fix
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251201-disp_fix-v2-2-9b03026311b6@gocontroll.com>
References: <20251201-disp_fix-v2-0-9b03026311b6@gocontroll.com>
In-Reply-To: <20251201-disp_fix-v2-0-9b03026311b6@gocontroll.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764590218; l=1431;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=aBjyYr0KgPqqBX1balGgsZXHNYxS/418tzQqfsE7U/M=;
 b=ENP1Jh0LkCOmw9V6meQOx6iaYrkPrEj23ilMw94d30dw9P9X2sEOUdDY08dVr6PNOuPPLJlUa
 kcFQPRxMRHsC3P2JmzfG8k6JMGisI01U0xW1T2fJaQo+xUov9VmixIC
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The compatibles should include the SoM compatible, this board is based
on the Ka-Ro TX8P-ML81 SoM, so add it to allow using shared code in the
bootloader which uses upstream Linux devicetrees as a base.

Also add the hardware revision to the board compatible to handle
revision specific quirks in the bootloader/userspace.

This is a breaking change, but it is early enough that it can be
corrected without causing any issues.

Fixes: 03f07be54cdc ("arm64: dts: freescale: Add the GOcontroll Moduline Display baseboard")
Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts b/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts
index 88ad422c2760..399230144ce3 100644
--- a/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts
+++ b/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106.dts
@@ -9,7 +9,7 @@
 #include "imx8mp-tx8p-ml81.dtsi"
 
 / {
-	compatible = "gocontroll,moduline-display", "fsl,imx8mp";
+	compatible = "gocontroll,moduline-display-106", "karo,tx8p-ml81", "fsl,imx8mp";
 	chassis-type = "embedded";
 	hardware = "Moduline Display V1.06";
 	model = "GOcontroll Moduline Display baseboard";

-- 
2.52.0

