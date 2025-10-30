From: Maud Spierings <maudspierings@gocontroll.com>
Date: Thu, 30 Oct 2025 07:35:39 +0100
Subject: [PATCH v3 3/6] arm64: dts: imx8mm: Add pinctrl config definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251030-mini_iv-v3-3-ef56c4d9f219@gocontroll.com>
References: <20251030-mini_iv-v3-0-ef56c4d9f219@gocontroll.com>
In-Reply-To: <20251030-mini_iv-v3-0-ef56c4d9f219@gocontroll.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761806140; l=1757;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=Y0ox3F+eOcIA5j/xZwqJRea77ZkXXLU4NYh8FXOMxpo=;
 b=5BN4vkiwGnlRnoqLq2w/r89tFDsNhIQBVok3dwb28HuzV8vw9sBDL9u0ZLS72kQZXqLX4u9ws
 VW12EJxNVNMDeGsK62t81v6W8oxfA0TjNjIvbBpVpg3w9z1C7uIdItg
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently to configure each IOMUXC_SW_PAD_CTL_PAD the raw value of this
register is written in the dts, these values are not obvious. Add defines
which describe the fields of this register which can be or-ed together to
produce readable settings.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h | 33 ++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h b/arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h
index b1f11098d248e..31557b7b9ccc1 100644
--- a/arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h
+++ b/arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h
@@ -6,6 +6,39 @@
 #ifndef __DTS_IMX8MM_PINFUNC_H
 #define __DTS_IMX8MM_PINFUNC_H
 
+/* Drive Strength */
+#define MX8MM_DSE_X1		0x0
+#define MX8MM_DSE_X2		0x4
+#define MX8MM_DSE_X4		0x2
+#define MX8MM_DSE_X6		0x6
+
+/* Slew Rate */
+#define MX8MM_FSEL_FAST		0x10
+#define MX8MM_FSEL_SLOW		0x0
+
+/* Open Drain */
+#define MX8MM_ODE_ENABLE	0x20
+#define MX8MM_ODE_DISABLE	0x0
+
+#define MX8MM_PULL_DOWN		0x0
+#define MX8MM_PULL_UP		0x40
+
+/* Hysteresis */
+#define MX8MM_HYS_CMOS		0x0
+#define MX8MM_HYS_SCHMITT	0x80
+
+#define MX8MM_PULL_ENABLE	0x100
+#define MX8MM_PULL_DISABLE	0x0
+
+/* SION force input mode */
+#define MX8MM_SION		0x40000000
+
+/* long defaults */
+#define MX8MM_USDHC_DATA_DEFAULT (MX8MM_FSEL_FAST | MX8MM_PULL_UP | \
+				  MX8MM_HYS_SCHMITT | MX8MM_PULL_ENABLE)
+#define MX8MM_I2C_DEFAULT (MX8MM_DSE_X6 | MX8MM_PULL_UP | MX8MM_HYS_SCHMITT | \
+			   MX8MM_PULL_ENABLE | MX8MM_SION)
+
 /*
  * The pin function ID is a tuple of
  * <mux_reg conf_reg input_reg mux_mode input_val>

-- 
2.51.2

