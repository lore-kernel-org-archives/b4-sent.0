From: Maud Spierings <maudspierings@gocontroll.com>
Date: Fri, 14 Feb 2025 16:57:42 +0100
Subject: [PATCH 1/2] arm64: dts: imx8mm: Add pinctrl config definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250214-pinctrl_defines-v1-1-fbc86a42ef3c@gocontroll.com>
References: <20250214-pinctrl_defines-v1-0-fbc86a42ef3c@gocontroll.com>
In-Reply-To: <20250214-pinctrl_defines-v1-0-fbc86a42ef3c@gocontroll.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739548663; l=1502;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=xlMEruvPgyFBPz+wMGaLrdnLbqgaiStmZr5qOyP3uC0=;
 b=61kNMtfKPg3m9bDu0G1jq+xNlQh5OuZTSq5FjcNSJ0ZR/3PFj4GclVsunSHeRBmuQn3E9tLV3
 aF89iBwbHtTBckycY2S0sHRFG81+G2hLWnLIuTKWLwEblWa53X601/5
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
 arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h | 27 ++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h b/arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h
index b1f11098d248ed5fc8ac42daed808beebe3bf7bc..b231d5968d07d1e135963b714c3fe80ddd8641ab 100644
--- a/arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h
+++ b/arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h
@@ -6,6 +6,33 @@
 #ifndef __DTS_IMX8MM_PINFUNC_H
 #define __DTS_IMX8MM_PINFUNC_H
 
+//Drive Strength
+#define MX8MM_DSE_X1 0x0
+#define MX8MM_DSE_X2 0x4
+#define MX8MM_DSE_X4 0x2
+#define MX8MM_DSE_X6 0x6
+
+//Slew Rate
+#define MX8MM_FSEL_FAST 0x10
+#define MX8MM_FSEL_SLOW 0x0
+
+//Open Drain
+#define MX8MM_ODE_ENABLE 0x20
+#define MX8MM_ODE_DISABLE 0x0
+
+#define MX8MM_PULL_DOWN 0x0
+#define MX8MM_PULL_UP 0x40
+
+//Hysteresis
+#define MX8MM_HYS_CMOS 0x0
+#define MX8MM_HYS_SCHMITT 0x80
+
+#define MX8MM_PULL_ENABLE 0x100
+#define MX8MM_PULL_DISABLE 0x0
+
+//?
+#define MX8MM_MYSTERY_BIT 0x40000000
+
 /*
  * The pin function ID is a tuple of
  * <mux_reg conf_reg input_reg mux_mode input_val>

-- 
2.48.1

