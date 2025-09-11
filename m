From: Maud Spierings <maudspierings@gocontroll.com>
Date: Thu, 11 Sep 2025 09:53:21 +0200
Subject: [PATCH v3 4/4] arm64: dts: freescale:
 moduline-display-av123z7m-n17: add backlight
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250911-max25014-v3-4-d03f4eba375e@gocontroll.com>
References: <20250911-max25014-v3-0-d03f4eba375e@gocontroll.com>
In-Reply-To: <20250911-max25014-v3-0-d03f4eba375e@gocontroll.com>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757577207; l=1572;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=+aYLH/ybVi5ZerWepGpRa9xOZexNmERp/UmcwCxehRI=;
 b=YtagMT7BdxUBqeoCBONoCdU+5rEpYVDLrI6lTl22BO4sEXpAhosycuRxEdFyi3aLKihg2F4gu
 N/ak4sYXqdpCsm5KBsGV2d4+qsLu8ep3uhIhCWgTzFc8zObCS/xTg/F
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the missing backlight.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 ...p-tx8p-ml81-moduline-display-106-av123z7m-n17.dtso | 19 ++++++++++++++++++-
 1 file changed, 18 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106-av123z7m-n17.dtso b/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106-av123z7m-n17.dtso
index 3eb665ce9d5d2a1c742ffb4feca046e406e29956..0b969c8c04db1c86b2a90c5f5ef91e494e5de7a6 100644
--- a/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106-av123z7m-n17.dtso
+++ b/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81-moduline-display-106-av123z7m-n17.dtso
@@ -16,6 +16,7 @@
 
 	panel {
 		compatible = "boe,av123z7m-n17";
+		backlight = <&backlight>;
 		enable-gpios = <&gpio1 7 GPIO_ACTIVE_HIGH>;
 		pinctrl-0 = <&pinctrl_panel>;
 		pinctrl-names = "default";
@@ -91,10 +92,26 @@ lvds1_out: endpoint {
 		};
 	};
 
-	/* max25014 @ 0x6f */
+	backlight: backlight@6f {
+		compatible = "maxim,max25014";
+		reg = <0x6f>;
+		default-brightness = <50>;
+		enable-gpios = <&gpio1 4 GPIO_ACTIVE_HIGH>;
+		pinctrl-names = "default";
+		pinctrl-0 = <&pinctrl_backlight>;
+		maxim,iset = <7>;
+		maxim,strings = <1 1 1 1>;
+	};
 };
 
 &iomuxc {
+	pinctrl_backlight: backlightgrp {
+		fsl,pins = <
+			MX8MP_IOMUXC_GPIO1_IO04__GPIO1_IO04
+				(MX8MP_PULL_UP | MX8MP_PULL_ENABLE)
+		>;
+	};
+
 	pinctrl_lvds_bridge: lvdsbridgegrp {
 		fsl,pins = <
 			MX8MP_IOMUXC_SAI1_TXD2__GPIO4_IO14

-- 
2.51.0

