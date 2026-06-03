From: Jian Hu <jian.hu@amlogic.com>
Date: Wed, 03 Jun 2026 19:45:49 +0800
Subject: [PATCH v2] dt-bindings: clock: Add Amlogic A9 SCMI clock
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260603-a9_scmi-v2-1-350aec9ab10a@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAO0TIGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDMwNj3UTL+OLk3Exdk0QjE2PDJAOLlFQLJaDqgqLUtMwKsEnRsbW1AFl
 EC89ZAAAA
X-Change-ID: 20260603-a9_scmi-4a2431b08de8
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780487153; l=2724;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=lR+o3x3gboUZWAVXeJmwYp2k19Y4CpRBHj71GeANfYk=;
 b=K2iCLdnGW4o8mWxGa+Ki1c9z0W/B0AvIVHFt4tvUVEaNJ6YlPoAfVTyJ+9usy0ZcziDf7Olq7
 jnXubItgcd+DV1iUTecqImKDh3RTjXCK+osfKMjWlhLg/A3ePUdNNub
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the SCMI clock controller dt-bindings for the Amlogic A9 SoC family.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
Changes in v2:
- Split the A9 clock driver and send the SCMI clock separately.
  The A9 PLL introduces several new features, and the Meson PLL framework
  needs to be refactored to support them. Since this work requires more
  time and there is no hard dependency between the different A9 clock
  controllers, split out the A9 clock driver and submit it separately to
  ease review.
- Link to v1: https://lore.kernel.org/all/20260511-b4-a9_clk-v1-1-41cb4071b7c9@amlogic.com/
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

---
base-commit: ca89c88bcf69daca829044c638a8163d5ce47af0
change-id: 20260603-a9_scmi-4a2431b08de8

Best regards,
-- 
Jian Hu <jian.hu@amlogic.com>

