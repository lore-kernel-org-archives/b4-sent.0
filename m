From: Ishu Brar <patches@brar.si>
Date: Fri, 23 Oct 2026 15:48:24 +0530
Subject: [PATCH 1/2] dt-bindings: clock: qcom: Document the SM7250 display
 clock controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-dispcc-sm7250-v1-1-07bdefb99801@brar.si>
References: <20261023-dispcc-sm7250-v1-0-07bdefb99801@brar.si>
In-Reply-To: <20261023-dispcc-sm7250-v1-0-07bdefb99801@brar.si>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792750706; l=5475;
 i=patches@brar.si; h=from:subject:message-id;
 bh=Sc530KmGL8zaKa6SHDV02PUR6renziuJ0eqUJFmUVWM=;
 b=gSZmv1o3R88egNOvPZqRRMWUYGfrT8l7KReB53mFONMDRFASiQQFPUoMocK33yklZQixTeZHD
 ZiNyZ2So+14D/yWNi7KBI1a/hxq0WbieGAgvTtxRXNUDXlxcjjlsg+l
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the binding and the header with the clock, reset and GDSC indices
for the display clock controller (DISPCC) of the Qualcomm SM7250 SoC
(Snapdragon 765/765G/768G).

The header and the binding are derived from the SM7150 ones: the register
layout is the same, but the controller takes GPLL0 from the GCC as an
extra parent and has its own PLL.

Assisted-by: Claude
Signed-off-by: Ishu Brar <patches@brar.si>
---
 .../bindings/clock/qcom,sm7250-dispcc.yaml         | 73 ++++++++++++++++++++++
 include/dt-bindings/clock/qcom,sm7250-dispcc.h     | 62 ++++++++++++++++++
 2 files changed, 135 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/qcom,sm7250-dispcc.yaml b/Documentation/devicetree/bindings/clock/qcom,sm7250-dispcc.yaml
new file mode 100644
index 000000000..684aaf7bb
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/qcom,sm7250-dispcc.yaml
@@ -0,0 +1,73 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/qcom,sm7250-dispcc.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm Display Clock & Reset Controller for SM7250
+
+maintainers:
+  - Ishu Brar <patches@brar.si>
+
+description: |
+  Qualcomm display clock control module provides the clocks, resets and power
+  domains on SM7250.
+
+  See also: include/dt-bindings/clock/qcom,sm7250-dispcc.h
+
+properties:
+  compatible:
+    const: qcom,sm7250-dispcc
+
+  clocks:
+    items:
+      - description: Board XO source
+      - description: Board Always On XO source
+      - description: GPLL0 source from GCC
+      - description: Sleep clock source
+      - description: Byte clock from MDSS DSI PHY0
+      - description: Pixel clock from MDSS DSI PHY0
+      - description: Byte clock from MDSS DSI PHY1
+      - description: Pixel clock from MDSS DSI PHY1
+      - description: Link clock from DP PHY
+      - description: VCO DIV clock from DP PHY
+
+  power-domains:
+    maxItems: 1
+    description:
+      CX power domain.
+
+required:
+  - compatible
+  - clocks
+  - power-domains
+
+allOf:
+  - $ref: qcom,gcc.yaml#
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/qcom,sm7250-gcc.h>
+    #include <dt-bindings/clock/qcom,rpmh.h>
+    #include <dt-bindings/power/qcom,rpmhpd.h>
+    clock-controller@af00000 {
+      compatible = "qcom,sm7250-dispcc";
+      reg = <0x0af00000 0x20000>;
+      clocks = <&rpmhcc RPMH_CXO_CLK>,
+               <&rpmhcc RPMH_CXO_CLK_A>,
+               <&gcc GCC_DISP_GPLL0_CLK_SRC>,
+               <&sleep_clk>,
+               <&mdss_dsi0_phy 0>,
+               <&mdss_dsi0_phy 1>,
+               <&mdss_dsi1_phy 0>,
+               <&mdss_dsi1_phy 1>,
+               <&dp_phy 0>,
+               <&dp_phy 1>;
+      power-domains = <&rpmhpd RPMHPD_CX>;
+      #clock-cells = <1>;
+      #reset-cells = <1>;
+      #power-domain-cells = <1>;
+    };
+...
diff --git a/include/dt-bindings/clock/qcom,sm7250-dispcc.h b/include/dt-bindings/clock/qcom,sm7250-dispcc.h
new file mode 100644
index 000000000..907f4122c
--- /dev/null
+++ b/include/dt-bindings/clock/qcom,sm7250-dispcc.h
@@ -0,0 +1,62 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+/*
+ * Copyright (c) 2018, The Linux Foundation. All rights reserved.
+ * Copyright (c) 2024, Danila Tikhonov <danila@jiaxyga.com>
+ * Copyright (c) 2024, David Wronek <david@mainlining.org>
+ */
+
+#ifndef _DT_BINDINGS_CLK_QCOM_DISPCC_SM7250_H
+#define _DT_BINDINGS_CLK_QCOM_DISPCC_SM7250_H
+
+/* DISPCC clock registers */
+#define DISPCC_PLL0				0
+#define DISPCC_MDSS_AHB_CLK			1
+#define DISPCC_MDSS_AHB_CLK_SRC			2
+#define DISPCC_MDSS_BYTE0_CLK			3
+#define DISPCC_MDSS_BYTE0_CLK_SRC		4
+#define DISPCC_MDSS_BYTE0_DIV_CLK_SRC		5
+#define DISPCC_MDSS_BYTE0_INTF_CLK		6
+#define DISPCC_MDSS_BYTE1_CLK			7
+#define DISPCC_MDSS_BYTE1_CLK_SRC		8
+#define DISPCC_MDSS_BYTE1_DIV_CLK_SRC		9
+#define DISPCC_MDSS_BYTE1_INTF_CLK		10
+#define DISPCC_MDSS_DP_AUX_CLK			11
+#define DISPCC_MDSS_DP_AUX_CLK_SRC		12
+#define DISPCC_MDSS_DP_CRYPTO_CLK		13
+#define DISPCC_MDSS_DP_CRYPTO_CLK_SRC		14
+#define DISPCC_MDSS_DP_LINK_CLK			15
+#define DISPCC_MDSS_DP_LINK_CLK_SRC		16
+#define DISPCC_MDSS_DP_LINK_INTF_CLK		17
+#define DISPCC_MDSS_DP_PIXEL1_CLK		18
+#define DISPCC_MDSS_DP_PIXEL1_CLK_SRC		19
+#define DISPCC_MDSS_DP_PIXEL_CLK		20
+#define DISPCC_MDSS_DP_PIXEL_CLK_SRC		21
+#define DISPCC_MDSS_ESC0_CLK			22
+#define DISPCC_MDSS_ESC0_CLK_SRC		23
+#define DISPCC_MDSS_ESC1_CLK			24
+#define DISPCC_MDSS_ESC1_CLK_SRC		25
+#define DISPCC_MDSS_MDP_CLK			26
+#define DISPCC_MDSS_MDP_CLK_SRC			27
+#define DISPCC_MDSS_MDP_LUT_CLK			28
+#define DISPCC_MDSS_NON_GDSC_AHB_CLK		29
+#define DISPCC_MDSS_PCLK0_CLK			30
+#define DISPCC_MDSS_PCLK0_CLK_SRC		31
+#define DISPCC_MDSS_PCLK1_CLK			32
+#define DISPCC_MDSS_PCLK1_CLK_SRC		33
+#define DISPCC_MDSS_ROT_CLK			34
+#define DISPCC_MDSS_ROT_CLK_SRC			35
+#define DISPCC_MDSS_RSCC_AHB_CLK		36
+#define DISPCC_MDSS_RSCC_VSYNC_CLK		37
+#define DISPCC_MDSS_VSYNC_CLK			38
+#define DISPCC_MDSS_VSYNC_CLK_SRC		39
+#define DISPCC_XO_CLK_SRC			40
+#define DISPCC_SLEEP_CLK			41
+#define DISPCC_SLEEP_CLK_SRC			42
+
+/* DISPCC resets */
+#define DISPCC_MDSS_CORE_BCR			0
+
+/* DISPCC GDSCR */
+#define MDSS_GDSC				0
+
+#endif

-- 
2.56.0

