From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 30 Sep 2025 17:37:14 +0800
Subject: [PATCH 01/19] dt-bindings: clock: Add Amlogic A4 SCMI clock
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250930-a4_a5_add_clock_driver-v1-1-a9acf7951589@amlogic.com>
References: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
In-Reply-To: <20250930-a4_a5_add_clock_driver-v1-0-a9acf7951589@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759225047; l=1814;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=lepg6iT8bmM81rEU5ToL/dWT4QLnpMs52RztUgBBpJI=;
 b=9DlKusjYS9lvJ5c+yIorherlGXVHoEWA7WXl+kn4Crs79ES3JyMECgX8nYfKzxnBZ3aewWJbC
 PNqO/UxUUyuC5w6Rvv8v4ryBepX5x7v5MVHuUbUJjfzWlvDFRb2nrux
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the SCMI clock controller dt-bindings for Amlogic A4 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 include/dt-bindings/clock/amlogic,a4-scmi-clkc.h | 42 ++++++++++++++++++++++++
 1 file changed, 42 insertions(+)

diff --git a/include/dt-bindings/clock/amlogic,a4-scmi-clkc.h b/include/dt-bindings/clock/amlogic,a4-scmi-clkc.h
new file mode 100644
index 000000000000..454e492f8f6f
--- /dev/null
+++ b/include/dt-bindings/clock/amlogic,a4-scmi-clkc.h
@@ -0,0 +1,42 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2025 Amlogic, Inc. All rights reserved.
+ * Author: Chuan Liu <chuan.liu@amlogic.com>
+ */
+
+#ifndef __AMLOGIC_A4_SCMI_CLKC_H
+#define __AMLOGIC_A4_SCMI_CLKC_H
+
+#define CLKID_OSC				0
+#define CLKID_SYS_CLK				1
+#define CLKID_AXI_CLK				2
+#define CLKID_CPU_CLK				3
+#define CLKID_FIXED_PLL				4
+#define CLKID_GP1_PLL				5
+#define CLKID_ACLKM				6
+#define CLKID_SYS_PLL_DIV16			7
+#define CLKID_CPU_CLK_DIV16			8
+#define CLKID_FCLK_50M_PREDIV			9
+#define CLKID_FCLK_50M_DIV			10
+#define CLKID_FCLK_50M				11
+#define CLKID_FCLK_DIV2_DIV			12
+#define CLKID_FCLK_DIV2				13
+#define CLKID_FCLK_DIV2P5_DIV			14
+#define CLKID_FCLK_DIV2P5			15
+#define CLKID_FCLK_DIV3_DIV			16
+#define CLKID_FCLK_DIV3				17
+#define CLKID_FCLK_DIV4_DIV			18
+#define CLKID_FCLK_DIV4				19
+#define CLKID_FCLK_DIV5_DIV			20
+#define CLKID_FCLK_DIV5				21
+#define CLKID_FCLK_DIV7_DIV			22
+#define CLKID_FCLK_DIV7				23
+#define CLKID_SYS_MMC_PCLK			24
+#define CLKID_SYS_CPU_CTRL			25
+#define CLKID_SYS_IRQ_CTRL			26
+#define CLKID_SYS_GIC				27
+#define CLKID_SYS_BIG_NIC			28
+#define CLKID_AXI_SYS_NIC			29
+#define CLKID_AXI_CPU_DMC			30
+
+#endif /* __AMLOGIC_A4_SCMI_CLKC_H */

-- 
2.42.0

