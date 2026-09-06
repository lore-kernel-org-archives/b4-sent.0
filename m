From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sun, 06 Sep 2026 15:58:22 +0200
Subject: [PATCH 2/2] arm64: dts: imx93-11x11-frdm: add missing vcc-supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-imx93_frdm_rtc-v1-2-3fadbda0bea1@hotmail.com>
References: <20260906-imx93_frdm_rtc-v1-0-3fadbda0bea1@hotmail.com>
In-Reply-To: <20260906-imx93_frdm_rtc-v1-0-3fadbda0bea1@hotmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788703104; l=734;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=/6HDos0ffXRqjJ/U+G+dvR4yRCMOxOYwMu+cAp0G3Jg=;
 b=hSwACxKfBKhB7HmhyoI+UsL9K5XAQkT+JQjZ6DWZIBvlqaOaK4j9Ebp7Nkwc/+PRSdzwxl+aI
 gkmEuP1tIaeC9CtWjfCOPchEfVSmRs4jpFeT4rh1D/bRu5XyxuXKgW4
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the power supply to the pcal6408 gpio expander, it doesn't have the
dependency loop like the pcal6524.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 arch/arm64/boot/dts/freescale/imx93-11x11-frdm.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/freescale/imx93-11x11-frdm.dts b/arch/arm64/boot/dts/freescale/imx93-11x11-frdm.dts
index 8034992a73c7..23d2b9930420 100644
--- a/arch/arm64/boot/dts/freescale/imx93-11x11-frdm.dts
+++ b/arch/arm64/boot/dts/freescale/imx93-11x11-frdm.dts
@@ -45,6 +45,7 @@ pcal6408: gpio@20 {
 		#gpio-cells = <2>;
 		gpio-controller;
 		reset-gpios = <&pcal6524 20 GPIO_ACTIVE_LOW>;
+		vcc-supply = <&buck5>;
 	};
 };
 

-- 
2.55.0

