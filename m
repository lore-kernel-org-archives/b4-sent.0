From: Maud Spierings <maudspierings@gocontroll.com>
Date: Wed, 02 Apr 2025 09:07:05 +0200
Subject: [PATCH v4 2/9] arm64: dts: imx8mp: Add pinctrl config definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-initial_display-v4-2-9f898838a864@gocontroll.com>
References: <20250402-initial_display-v4-0-9f898838a864@gocontroll.com>
In-Reply-To: <20250402-initial_display-v4-0-9f898838a864@gocontroll.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>, Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743577640; l=2170;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=mrxqwhYhMzGSTJWlhyHKyT15kZQ0Bh3K/pqX9Brfdms=;
 b=RSWJLRi+yCrV9P8qgazfvQVlwOXVi+fUOwjn7H9V2eRa6F25Q6DY2xPl+QPpoARL6a3Gqyof8
 6+AeYLUHr5nCZN3Ut4gOQPHRxmU4Tb90bsMuAR4IRah96Edlm9eWx/4
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently to configure each IOMUXC_SW_PAD_CTL_PAD the raw value of this
register is written in the dts, these values are not obvious. Add defines
which describe the fields of this register which can be or-ed together to
produce readable settings.

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
This patch has already been sent in a different group of patches: [1]
It was requested there to submit it along with a user, this series also
includes some users for it.

[1]: https://lore.kernel.org/all/20250218-pinctrl_defines-v2-2-c554cad0e1d2@gocontroll.com/
---
 arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h | 33 ++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h b/arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h
index 0fef066471ba607be02d0ab15da5a048a8a213a7..19a23d148246f4fb990050a9d06d20b6e769f254 100644
--- a/arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h
+++ b/arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h
@@ -6,6 +6,39 @@
 #ifndef __DTS_IMX8MP_PINFUNC_H
 #define __DTS_IMX8MP_PINFUNC_H
 
+/* Drive Strength */
+#define MX8MP_DSE_X1 0x0
+#define MX8MP_DSE_X2 0x4
+#define MX8MP_DSE_X4 0x2
+#define MX8MP_DSE_X6 0x6
+
+/* Slew Rate */
+#define MX8MP_FSEL_FAST 0x10
+#define MX8MP_FSEL_SLOW 0x0
+
+/* Open Drain */
+#define MX8MP_ODE_ENABLE 0x20
+#define MX8MP_ODE_DISABLE 0x0
+
+#define MX8MP_PULL_DOWN 0x0
+#define MX8MP_PULL_UP 0x40
+
+/* Hysteresis */
+#define MX8MP_HYS_CMOS 0x0
+#define MX8MP_HYS_SCHMITT 0x80
+
+#define MX8MP_PULL_ENABLE 0x100
+#define MX8MP_PULL_DISABLE 0x0
+
+/* SION force input mode */
+#define MX8MP_SION 0x40000000
+
+/* long defaults */
+#define MX8MP_USDHC_DATA_DEFAULT (MX8MP_FSEL_FAST | MX8MP_PULL_UP | \
+								  MX8MP_HYS_SCHMITT | MX8MP_PULL_ENABLE)
+#define MX8MP_I2C_DEFAULT (MX8MP_DSE_X6 | MX8MP_PULL_UP | MX8MP_HYS_SCHMITT | \
+						   MX8MP_PULL_ENABLE | MX8MP_SION)
+
 /*
  * The pin function ID is a tuple of
  * <mux_reg conf_reg input_reg mux_mode input_val>

-- 
2.49.0

