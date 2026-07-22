From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 22 Jul 2026 08:39:31 +0000
Subject: [PATCH 1/3] dt-bindings: power: Add Amlogic A9 power domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-a9-pm-v1-1-1fe20a44bf2d@amlogic.com>
References: <20260722-a9-pm-v1-0-1fe20a44bf2d@amlogic.com>
In-Reply-To: <20260722-a9-pm-v1-0-1fe20a44bf2d@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulfh@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784709572; l=3033;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=vpFb6MO7p6AA5kHtUgazEsyrRR4E6EHks7lJJa+cLZ8=;
 b=9/FHHo814FjLOz0QZGsCYKIUd6uaz9LzMRoMhURLgnw9IdTZWGXSrNkRltgjH38S7Tv9q6wHl
 xty8DlG0G24Cym43lnpsTeg8qi3ngLKiWaY75sejCxz/epehbUliSB5
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding document and related header file for
Amlogic A9 secure power domains.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/power/amlogic,meson-sec-pwrc.yaml     |  1 +
 include/dt-bindings/power/amlogic,a9-pwrc.h        | 61 ++++++++++++++++++++++
 2 files changed, 62 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml b/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
index 12b71688dd34..e608a0c75961 100644
--- a/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
+++ b/Documentation/devicetree/bindings/power/amlogic,meson-sec-pwrc.yaml
@@ -22,6 +22,7 @@ properties:
       - amlogic,meson-s4-pwrc
       - amlogic,a4-pwrc
       - amlogic,a5-pwrc
+      - amlogic,a9-pwrc
       - amlogic,c3-pwrc
       - amlogic,t7-pwrc
       - amlogic,s6-pwrc
diff --git a/include/dt-bindings/power/amlogic,a9-pwrc.h b/include/dt-bindings/power/amlogic,a9-pwrc.h
new file mode 100644
index 000000000000..c1c2308a0d0c
--- /dev/null
+++ b/include/dt-bindings/power/amlogic,a9-pwrc.h
@@ -0,0 +1,61 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (C) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#ifndef _DT_BINDINGS_AMLOGIC_A9_POWER_H
+#define _DT_BINDINGS_AMLOGIC_A9_POWER_H
+
+#define PWRC_A9_DSPA_ID			0
+#define PWRC_A9_U3HSG_U3_ID		1
+#define PWRC_A9_DP_ID			2
+#define PWRC_A9_DOS_HCODEC_ID		3
+#define PWRC_A9_TAHOE_ID		4
+#define PWRC_A9_DOS_HEVC_ID		5
+#define PWRC_A9_U2H_ID			6
+#define PWRC_A9_U3DRD_B_ID		7
+#define PWRC_A9_VPU_HDMI_ID		8
+#define PWRC_A9_U2DRD_ID		9
+#define PWRC_A9_U3DRD_A_ID		10
+#define PWRC_A9_SD_EMMC_C_ID		11
+#define PWRC_A9_GE2D_ID			12
+#define PWRC_A9_AMFC_ID			13
+#define PWRC_A9_EDPTX_ID		14
+#define PWRC_A9_OPP_ID			15
+#define PWRC_A9_VICP_ID			16
+#define PWRC_A9_SD_EMMC_A_ID		17
+#define PWRC_A9_SD_EMMC_B_ID		18
+#define PWRC_A9_ETH_ID			19
+#define PWRC_A9_PCIE_A_ID		20
+#define PWRC_A9_PCIE_B_ID		21
+#define PWRC_A9_NNA_4T_ID		22
+#define PWRC_A9_HDMIRX_ID		23
+#define PWRC_A9_CVE_ID			24
+#define PWRC_A9_ISP_ID			25
+#define PWRC_A9_ETH_1G_ID		26
+#define PWRC_A9_U3HSG_HSG_ID		27
+#define PWRC_A9_U3DPPHY_U3_ID		28
+#define PWRC_A9_U3DPPHY_DP_ID		29
+#define PWRC_A9_PCIE3PHY_ID		30
+#define PWRC_A9_U3HSG_PCIE2_ID		31
+#define PWRC_A9_MALI_TOP_ID		32
+#define PWRC_A9_AO_SED_ID		33
+#define PWRC_A9_AO_IR_ID		34
+#define PWRC_A9_AO_UART_B_ID		35
+#define PWRC_A9_AO_UART_C_ID		36
+#define PWRC_A9_AO_UART_D_ID		37
+#define PWRC_A9_AO_SPISG_ID		38
+#define PWRC_A9_AO_UART_E_ID		39
+#define PWRC_A9_AO_CEC_ID		40
+#define PWRC_A9_EE_SRAMA_ID		41
+#define PWRC_A9_AUDIO_ID		42
+#define PWRC_A9_DMC0_ID			43
+#define PWRC_A9_GIC_ID			44
+#define PWRC_A9_DDRPHY_ID		45
+#define PWRC_A9_AUCPU_ID		46
+#define PWRC_A9_DSI0_ID			47
+#define PWRC_A9_DSI1_ID			48
+#define PWRC_A9_CAN0_ID			49
+#define PWRC_A9_CAN1_ID			50
+
+#endif

-- 
2.52.0

