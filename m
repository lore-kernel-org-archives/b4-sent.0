From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Sat, 14 Sep 2024 13:25:24 +0800
Subject: [PATCH 2/5] dt-bindings: clock: add Amlogic A5 SCMI clock
 controller support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240914-a5-clk-v1-2-5ee2c4f1b08c@amlogic.com>
References: <20240914-a5-clk-v1-0-5ee2c4f1b08c@amlogic.com>
In-Reply-To: <20240914-a5-clk-v1-0-5ee2c4f1b08c@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chuan Liu <chuan.liu@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726291530; l=1704;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=0VCFX2M/yMc0qFVf2pmxfgH7H6Hn/BYk4VGTASRH4GA=;
 b=px+kiFx0mdhXES0XOipO96yHeklV9a3/lQKjlLMzizKg/LpwjHRjuxA6w5hmuihPkXCK0Io+t
 oqr9LBja/8nDeYrshGL6w+md5QIH/yPRJTym02nPg5ceoWGs6sL+TtR
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chuan Liu <chuan.liu@amlogic.com>

Add the SCMI clock controller dt-bindings for Amlogic A5 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 include/dt-bindings/clock/amlogic,a5-scmi-clkc.h | 37 ++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/include/dt-bindings/clock/amlogic,a5-scmi-clkc.h b/include/dt-bindings/clock/amlogic,a5-scmi-clkc.h
new file mode 100644
index 000000000000..d35d1ff6bab3
--- /dev/null
+++ b/include/dt-bindings/clock/amlogic,a5-scmi-clkc.h
@@ -0,0 +1,37 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2024 Amlogic, Inc. All rights reserved.
+ * Author: Chuan Liu <chuan.liu@amlogic.com>
+ */
+
+#ifndef __AMLOGIC_A5_SCMI_CLKC_H
+#define __AMLOGIC_A5_SCMI_CLKC_H
+
+#define CLKID_OSC				0
+#define CLKID_SYS_CLK				1
+#define CLKID_AXI_CLK				2
+#define CLKID_CPU_CLK				3
+#define CLKID_DSU_CLK				4
+#define CLKID_GP1_PLL				5
+#define CLKID_FIXED_PLL_DCO			6
+#define CLKID_FIXED_PLL				7
+#define CLKID_ACLKM				8
+#define CLKID_SYS_PLL_DIV16			9
+#define CLKID_CPU_CLK_DIV16			10
+#define CLKID_FCLK_50M_PREDIV			11
+#define CLKID_FCLK_50M_DIV			12
+#define CLKID_FCLK_50M				13
+#define CLKID_FCLK_DIV2_DIV			14
+#define CLKID_FCLK_DIV2				15
+#define CLKID_FCLK_DIV2P5_DIV			16
+#define CLKID_FCLK_DIV2P5			17
+#define CLKID_FCLK_DIV3_DIV			18
+#define CLKID_FCLK_DIV3				19
+#define CLKID_FCLK_DIV4_DIV			20
+#define CLKID_FCLK_DIV4				21
+#define CLKID_FCLK_DIV5_DIV			22
+#define CLKID_FCLK_DIV5				23
+#define CLKID_FCLK_DIV7_DIV			24
+#define CLKID_FCLK_DIV7				25
+
+#endif /* __AMLOGIC_A5_SCMI_CLKC_H */

-- 
2.37.1

