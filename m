From: Jian Hu <jian.hu@amlogic.com>
Date: Mon, 11 May 2026 20:47:23 +0800
Subject: [PATCH 01/10] dt-bindings: clock: Add Amlogic A9 SCMI clock
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-b4-a9_clk-v1-1-41cb4071b7c9@amlogic.com>
References: <20260511-b4-a9_clk-v1-0-41cb4071b7c9@amlogic.com>
In-Reply-To: <20260511-b4-a9_clk-v1-0-41cb4071b7c9@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778503655; l=2094;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=XTWH35VQS5hQCyMsc3Rqm4Jf3SS3Wpu6au+/+82jp4M=;
 b=0qyx1x+Xocdhfssspl3XdDuyxegDJHm7fUJPPU+wIM1sH3jOffmTnfNwmSILLf8iBnHwppgJS
 kUaqfCzzcZcAbAIsyTVPRnbsBg/v0A60MQhMnh97ytVfMahgO+Y9Y19
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the SCMI clock controller dt-bindings for the Amlogic A9 SoC family.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 include/dt-bindings/clock/amlogic,a9-scmi-clkc.h | 51 ++++++++++++++++++++++++
 1 file changed, 51 insertions(+)

diff --git a/include/dt-bindings/clock/amlogic,a9-scmi-clkc.h b/include/dt-bindings/clock/amlogic,a9-scmi-clkc.h
new file mode 100644
index 000000000000..d543db9fe035
--- /dev/null
+++ b/include/dt-bindings/clock/amlogic,a9-scmi-clkc.h
@@ -0,0 +1,51 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (C) 2026 Amlogic, Inc. All rights reserved.
+ */
+
+#ifndef __AMLOGIC_A9_SCMI_CLKC_H
+#define __AMLOGIC_A9_SCMI_CLKC_H
+
+#define CLKID_GP0_PLL_OSC			0
+#define CLKID_GP1_PLL_OSC			1
+#define CLKID_HIFI_PLL_OSC			2
+#define CLKID_GP2_PLL_OSC			3
+#define CLKID_MCLK_PLL_OSC			4
+#define CLKID_FIXED_PLL				5
+#define CLKID_FCLK_50M_PREDIV			6
+#define CLKID_FCLK_50M_DIV			7
+#define CLKID_FCLK_50M				8
+#define CLKID_FCLK_DIV2_DIV			9
+#define CLKID_FCLK_DIV2				10
+#define CLKID_FCLK_DIV2P5_DIV			11
+#define CLKID_FCLK_DIV2P5			12
+#define CLKID_FCLK_DIV3_DIV			13
+#define CLKID_FCLK_DIV3				14
+#define CLKID_FCLK_DIV4_DIV			15
+#define CLKID_FCLK_DIV4				16
+#define CLKID_FCLK_DIV5_DIV			17
+#define CLKID_FCLK_DIV5				18
+#define CLKID_FCLK_DIV7_DIV			19
+#define CLKID_FCLK_DIV7				20
+#define CLKID_SYS_CLK				21
+#define CLKID_SYS_AO_SYS			22
+#define CLKID_SYS_MMC_APB			23
+#define CLKID_SYS_CPU_APB			24
+#define CLKID_SYS_GIC				25
+#define CLKID_AXI_CLK				26
+#define CLKID_AXI_SYS_NIC			27
+#define CLKID_AXI_RAMA				28
+#define CLKID_CPU_CLK				29
+#define CLKID_A78_CLK				30
+#define CLKID_DSU_CLK				31
+#define CLKID_ACLKM				32
+#define CLKID_GP1_PLL				33
+#define CLKID_GP2_PLL				34
+#define CLKID_SYS_PLL_DIV16			35
+#define CLKID_CPU_CLK_DIV16			36
+#define CLKID_A78_CLK_DIV16			37
+#define CLKID_DSU_CLK_DIV16			38
+#define CLKID_GIC_CLK				39
+#define CLKID_RTC				40
+
+#endif /* __AMLOGIC_A9_SCMI_CLKC_H */

-- 
2.47.1

