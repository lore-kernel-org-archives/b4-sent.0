From: Jian Hu <jian.hu@amlogic.com>
Date: Thu, 29 Oct 2026 17:30:52 +0800
Subject: [PATCH RFC RFT v2 1/3] dt-bindings: clock: amlogic: Add PLL
 pre-divider clock IDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-meson_refactor_n-v2-1-ff4ac74e527b@amlogic.com>
References: <20261029-meson_refactor_n-v2-0-ff4ac74e527b@amlogic.com>
In-Reply-To: <20261029-meson_refactor_n-v2-0-ff4ac74e527b@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793266267; l=6174;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=NhD9+CXL9tRSS4fVfLHNmQWwe4J418AMvGpnb3FP5WA=;
 b=qAdesZJO1XCIOuoxCthYPtYVCo//JFzOXPg6eLoiDq5SqM4tdOsTBeMKe903dUHAe45fXUDQH
 wR++V2WYoz3AzsI7KyeaGUYvUXtaJ43E210hr1gczcj0HSFwSrE6UXk
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add clock IDs for the PLL pre-divider clocks. These IDs are
required for the subsequent conversion of the PLL pre-divider
into a standalone divider clock following the PLL framework refactoring.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 include/dt-bindings/clock/amlogic,a1-pll-clkc.h | 3 +++
 include/dt-bindings/clock/amlogic,c3-pll-clkc.h | 3 +++
 include/dt-bindings/clock/amlogic,s4-pll-clkc.h | 4 ++++
 include/dt-bindings/clock/amlogic,t7-pll-clkc.h | 6 ++++++
 include/dt-bindings/clock/axg-clkc.h            | 5 +++++
 include/dt-bindings/clock/g12a-clkc.h           | 8 ++++++++
 include/dt-bindings/clock/gxbb-clkc.h           | 4 ++++
 include/dt-bindings/clock/meson8-ddr-clkc.h     | 1 +
 include/dt-bindings/clock/meson8b-clkc.h        | 4 ++++
 9 files changed, 38 insertions(+)

diff --git a/include/dt-bindings/clock/amlogic,a1-pll-clkc.h b/include/dt-bindings/clock/amlogic,a1-pll-clkc.h
index 0dfc5e78a2d5..c09f215bf75b 100644
--- a/include/dt-bindings/clock/amlogic,a1-pll-clkc.h
+++ b/include/dt-bindings/clock/amlogic,a1-pll-clkc.h
@@ -22,5 +22,8 @@
 #define CLKID_FCLK_DIV7		9
 #define CLKID_HIFI_PLL		10
 #define CLKID_SYS_PLL		11
+#define CLKID_FIXED_PREDIV	12
+#define CLKID_HIFI_PREDIV	13
+#define CLKID_SYS_PREDIV	14
 
 #endif /* __A1_PLL_CLKC_H */
diff --git a/include/dt-bindings/clock/amlogic,c3-pll-clkc.h b/include/dt-bindings/clock/amlogic,c3-pll-clkc.h
index fcdc558715e8..771be7d53bc0 100644
--- a/include/dt-bindings/clock/amlogic,c3-pll-clkc.h
+++ b/include/dt-bindings/clock/amlogic,c3-pll-clkc.h
@@ -36,5 +36,8 @@
 #define CLKID_MCLK1_SEL_EN			26
 #define CLKID_MCLK1_DIV				27
 #define CLKID_MCLK1				28
+#define CLKID_GP0_PREDIV			29
+#define CLKID_HIFI_PREDIV			30
+#define CLKID_MCLK_PREDIV			31
 
 #endif  /* _DT_BINDINGS_CLOCK_AMLOGIC_C3_PLL_CLKC_H */
diff --git a/include/dt-bindings/clock/amlogic,s4-pll-clkc.h b/include/dt-bindings/clock/amlogic,s4-pll-clkc.h
index af9f110f8b62..e194185f5be8 100644
--- a/include/dt-bindings/clock/amlogic,s4-pll-clkc.h
+++ b/include/dt-bindings/clock/amlogic,s4-pll-clkc.h
@@ -39,5 +39,9 @@
 #define CLKID_MPLL2			29
 #define CLKID_MPLL3_DIV			30
 #define CLKID_MPLL3			31
+#define CLKID_FIXED_PREDIV		32
+#define CLKID_GP0_PREDIV		33
+#define CLKID_HIFI_PREDIV		34
+#define CLKID_HDMI_PREDIV		35
 
 #endif /* _DT_BINDINGS_CLOCK_AMLOGIC_S4_PLL_CLKC_H */
diff --git a/include/dt-bindings/clock/amlogic,t7-pll-clkc.h b/include/dt-bindings/clock/amlogic,t7-pll-clkc.h
index e2481f2f1163..69c90bc0be0a 100644
--- a/include/dt-bindings/clock/amlogic,t7-pll-clkc.h
+++ b/include/dt-bindings/clock/amlogic,t7-pll-clkc.h
@@ -9,20 +9,24 @@
 /* GP0 */
 #define CLKID_GP0_PLL_DCO	0
 #define CLKID_GP0_PLL		1
+#define CLKID_GP0_PREDIV	2
 
 /* GP1 */
 #define CLKID_GP1_PLL_DCO	0
 #define CLKID_GP1_PLL		1
+#define CLKID_GP1_PREDIV	2
 
 /* HIFI */
 #define CLKID_HIFI_PLL_DCO	0
 #define CLKID_HIFI_PLL		1
+#define CLKID_HIFI_PREDIV	2
 
 /* PCIE */
 #define CLKID_PCIE_PLL_DCO	0
 #define CLKID_PCIE_PLL_DCO_DIV2	1
 #define CLKID_PCIE_PLL_OD	2
 #define CLKID_PCIE_PLL		3
+#define CLKID_PCIE_PREDIV	4
 
 /* MPLL */
 #define CLKID_MPLL_PREDIV	0
@@ -39,6 +43,7 @@
 #define CLKID_HDMI_PLL_DCO	0
 #define CLKID_HDMI_PLL_OD	1
 #define CLKID_HDMI_PLL		2
+#define CLKID_HDMI_PREDIV	3
 
 /* MCLK */
 #define CLKID_MCLK_PLL_DCO	0
@@ -52,5 +57,6 @@
 #define CLKID_MCLK_1_DIV2	8
 #define CLKID_MCLK_1_PRE	9
 #define CLKID_MCLK_1		10
+#define CLKID_MCLK_PREDIV	11
 
 #endif /* __T7_PLL_CLKC_H */
diff --git a/include/dt-bindings/clock/axg-clkc.h b/include/dt-bindings/clock/axg-clkc.h
index 442162822b88..798b92919f60 100644
--- a/include/dt-bindings/clock/axg-clkc.h
+++ b/include/dt-bindings/clock/axg-clkc.h
@@ -144,5 +144,10 @@
 #define CLKID_VDIN_MEAS_SEL			134
 #define CLKID_VDIN_MEAS_DIV			135
 #define CLKID_VDIN_MEAS				136
+#define CLKID_FIXED_PREDIV			137
+#define CLKID_SYS_PREDIV			138
+#define CLKID_GP0_PREDIV			139
+#define CLKID_HIFI_PREDIV			140
+#define CLKID_PCIE_PREDIV			141
 
 #endif /* __AXG_CLKC_H */
diff --git a/include/dt-bindings/clock/g12a-clkc.h b/include/dt-bindings/clock/g12a-clkc.h
index fd09819da2ec..d2aa3df14149 100644
--- a/include/dt-bindings/clock/g12a-clkc.h
+++ b/include/dt-bindings/clock/g12a-clkc.h
@@ -287,5 +287,13 @@
 #define CLKID_MIPI_ISP_GATE			276
 #define CLKID_MIPI_ISP_CSI_PHY0			277
 #define CLKID_MIPI_ISP_CSI_PHY1			278
+#define CLKID_FIXED_PREDIV			279
+#define CLKID_SYS_PREDIV			280
+#define CLKID_GP0_PREDIV			281
+#define CLKID_HIFI_PREDIV			282
+#define CLKID_HDMI_PREDIV			283
+#define CLKID_PCIE_PREDIV			284
+#define CLKID_SYS1_PREDIV			285
+#define CLKID_GP1_PREDIV			286
 
 #endif /* __G12A_CLKC_H */
diff --git a/include/dt-bindings/clock/gxbb-clkc.h b/include/dt-bindings/clock/gxbb-clkc.h
index c0ce5e9c4151..e2e1ec60285d 100644
--- a/include/dt-bindings/clock/gxbb-clkc.h
+++ b/include/dt-bindings/clock/gxbb-clkc.h
@@ -212,5 +212,9 @@
 #define CLKID_HDMI_DIV		204
 #define CLKID_HDMI		205
 #define CLKID_ACODEC		206
+#define CLKID_FIXED_PREDIV	207
+#define CLKID_HDMI_PREDIV	208
+#define CLKID_SYS_PREDIV	209
+#define CLKID_GP0_PREDIV	210
 
 #endif /* __GXBB_CLKC_H */
diff --git a/include/dt-bindings/clock/meson8-ddr-clkc.h b/include/dt-bindings/clock/meson8-ddr-clkc.h
index a8e0fa2987ab..ce97a15c28a9 100644
--- a/include/dt-bindings/clock/meson8-ddr-clkc.h
+++ b/include/dt-bindings/clock/meson8-ddr-clkc.h
@@ -2,3 +2,4 @@
 
 #define DDR_CLKID_DDR_PLL_DCO			0
 #define DDR_CLKID_DDR_PLL			1
+#define DDR_CLKID_DDR_PREDIV			2
diff --git a/include/dt-bindings/clock/meson8b-clkc.h b/include/dt-bindings/clock/meson8b-clkc.h
index 385bf243c56c..c4fd127dca1e 100644
--- a/include/dt-bindings/clock/meson8b-clkc.h
+++ b/include/dt-bindings/clock/meson8b-clkc.h
@@ -221,5 +221,9 @@
 #define CLKID_VCLK2_EN		215
 #define CLKID_VID_PLL_LVDS_EN	216
 #define CLKID_HDMI_PLL_DCO_IN   217
+#define CLKID_PLL_FIXED_PREDIV	218
+#define CLKID_PLL_SYS_PREDIV	219
+#define CLKID_HDMI_PREDIV	220
+#define CLKID_GP_PREDIV		221
 
 #endif /* __MESON8B_CLKC_H */

-- 
2.47.1

