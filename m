From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sun, 06 Sep 2026 15:58:21 +0200
Subject: [PATCH 1/2] arm64: dts: imx93-11x11-frdm-common: fix the rtc
 aliases
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-imx93_frdm_rtc-v1-1-3fadbda0bea1@hotmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788703104; l=851;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=BMNbgRGZryoXpTYGm7+rXC+ZV8ZnELNCq8RAs2p09Cg=;
 b=VDqYxWi6vFmns83ATAsUrFlV2oA/mNC2qqZiAY1xgxkD3YU6fdva837VwqbhXk4jFb8f1SOC7
 SZzhYQOxrILDrnIY/X70ZtBMVaHQP4SUd0GSZ3fwMlb8W+6M8L35ERu
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pcf2131 has been assigned the rtc0 alias, but if the bbnsm_rtc gets
probed first it will take this name.

Properly assign bbnsm_rtc to rtc1 so that this doesn't happen

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 arch/arm64/boot/dts/freescale/imx93-11x11-frdm-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/freescale/imx93-11x11-frdm-common.dtsi b/arch/arm64/boot/dts/freescale/imx93-11x11-frdm-common.dtsi
index 5c8fdd77ec15..97d89288db3c 100644
--- a/arch/arm64/boot/dts/freescale/imx93-11x11-frdm-common.dtsi
+++ b/arch/arm64/boot/dts/freescale/imx93-11x11-frdm-common.dtsi
@@ -13,6 +13,7 @@ aliases {
 		mmc0 = &usdhc1; /* EMMC */
 		mmc1 = &usdhc2; /* uSD */
 		rtc0 = &pcf2131;
+		rtc1 = &bbnsm_rtc;
 		serial0 = &lpuart1;
 		serial4 = &lpuart5;
 	};

-- 
2.55.0

