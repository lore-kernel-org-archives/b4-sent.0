From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Sat, 28 Nov 2026 00:09:29 +0530
Subject: [PATCH v5 09/11] arm64: dts: qcom: Add Molokai (SM8845) SoC dtsi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-molokai-soc-v5-9-144801dfad7f@yahoo.com>
References: <20261128-molokai-soc-v5-0-144801dfad7f@yahoo.com>
In-Reply-To: <20261128-molokai-soc-v5-0-144801dfad7f@yahoo.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795804762; l=10720;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=MF0NUq9Df3Ci0gvVslU/Grk5h+q15+CFuXNbs4eqWWE=;
 b=pC1NAZB1BQXdHgwv8z9M9nec8UsJzGcB3e5xhVqpufk8VyEGUWerUMdHzDupPhHqkhGtAypQ7
 2lCin6vXeaLBJtfGp+RmBIp0bJuvOFWCh9PrWH0Rwvc6V13adFqojsq
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Molokai is a Kaanapali derivative. Describe it on top of the Kaanapali
dtsi: it has its own TLMM, with different pins for most serial engines
and a different GPIO to PDC wakeup map, and a PDC with one more interrupt
range. It has neither the I2C master hub nor the fourth QUP wrapper, and
QUP3 SE5 does not exist. Its graphics clock controller is not compatible
with the Kaanapali one.

Its NoCs differ from the Kaanapali ones as well (aggre-noc split into
aggre1 and aggre2, other QoS ports, MMSS config split into HF and SF), so
switch every interconnect provider to the Molokai compatibles, resize
their register windows and add aggre2_noc. The crypto engine, SCM and the
QUP2 and QUP3 serial engines use aggre2_noc.

The SDC2 lines are muxed on regular GPIOs instead of dedicated pins, so
the Kaanapali SDC2 pin states are dropped; boards using SDC2 describe
their own.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 arch/arm64/boot/dts/qcom/molokai.dtsi | 375 ++++++++++++++++++++++++++++++++++
 1 file changed, 375 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/molokai.dtsi b/arch/arm64/boot/dts/qcom/molokai.dtsi
new file mode 100644
index 000000000000..42446354fffb
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/molokai.dtsi
@@ -0,0 +1,375 @@
+// SPDX-License-Identifier: BSD-3-Clause
+/*
+ * Copyright (c) 2026 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+ *
+ * Molokai (SM8845) is a Kaanapali derivative with its own TLMM: the pins of
+ * most serial engines and all the GPIO wakeup interrupts are different. It
+ * has no I2C master hub, no fourth QUP wrapper and no QUP3 SE5, and its PDC
+ * maps one more interrupt range. The SDC2 lines are muxed on regular GPIOs
+ * instead of dedicated pins, and the GPU is an Adreno 829 instead of the
+ * Adreno 840.
+ */
+#include "kaanapali.dtsi"
+
+#include <dt-bindings/interconnect/qcom,molokai-rpmh.h>
+
+/delete-node/ &gpi_dma4;
+/delete-node/ &i2c_master_hub;
+/delete-node/ &qupv3_4;
+/delete-node/ &uart18;
+
+/delete-node/ &hub_i2c0_data_clk;
+/delete-node/ &hub_i2c1_data_clk;
+/delete-node/ &hub_i2c2_data_clk;
+/delete-node/ &hub_i2c3_data_clk;
+/delete-node/ &hub_i2c4_data_clk;
+/delete-node/ &qup_i2c19_data_clk;
+/delete-node/ &qup_i2c20_data_clk;
+/delete-node/ &qup_i2c21_data_clk;
+/delete-node/ &qup_i2c22_data_clk;
+/delete-node/ &qup_i2c23_data_clk;
+/delete-node/ &qup_spi19_cs;
+/delete-node/ &qup_spi19_data_clk;
+/delete-node/ &qup_spi20_cs;
+/delete-node/ &qup_spi20_data_clk;
+/delete-node/ &qup_spi21_cs;
+/delete-node/ &qup_spi21_data_clk;
+/delete-node/ &qup_uart18_cts_rts;
+/delete-node/ &qup_uart18_default;
+/delete-node/ &sdc2_default;
+/delete-node/ &sdc2_sleep;
+
+/* The Kaanapali aggre-noc is aggre1-noc on Molokai, see also aggre2_noc */
+&aggre_noc {
+	compatible = "qcom,molokai-aggre1-noc";
+	reg = <0x0 0x016e0000 0x0 0x16400>;
+	clocks = <&gcc GCC_AGGRE_UFS_PHY_AXI_CLK>,
+		 <&gcc GCC_AGGRE_USB3_PRIM_AXI_CLK>;
+};
+
+&clk_virt {
+	compatible = "qcom,molokai-clk-virt";
+};
+
+&cnoc_main {
+	compatible = "qcom,molokai-cnoc-main";
+};
+
+&config_noc {
+	compatible = "qcom,molokai-cnoc-cfg";
+	reg = <0x0 0x01600000 0x0 0x9200>;
+};
+
+&crypto {
+	interconnects = <&aggre2_noc MASTER_CRYPTO QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&gem_noc {
+	compatible = "qcom,molokai-gem-noc";
+};
+
+&gpucc {
+	compatible = "qcom,molokai-gpucc";
+};
+
+&i2c8 {
+	interconnects = <&clk_virt MASTER_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS
+			 &clk_virt SLAVE_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS>,
+			<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+			 &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ACTIVE_ONLY>,
+			<&aggre2_noc MASTER_QUP_2 QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&i2c9 {
+	interconnects = <&clk_virt MASTER_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS
+			 &clk_virt SLAVE_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS>,
+			<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+			 &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ACTIVE_ONLY>,
+			<&aggre2_noc MASTER_QUP_2 QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&i2c10 {
+	interconnects = <&clk_virt MASTER_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS
+			 &clk_virt SLAVE_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS>,
+			<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+			 &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ACTIVE_ONLY>,
+			<&aggre2_noc MASTER_QUP_2 QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&i2c11 {
+	interconnects = <&clk_virt MASTER_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS
+			 &clk_virt SLAVE_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS>,
+			<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+			 &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ACTIVE_ONLY>,
+			<&aggre2_noc MASTER_QUP_2 QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&i2c12 {
+	interconnects = <&clk_virt MASTER_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS
+			 &clk_virt SLAVE_QUP_CORE_2 QCOM_ICC_TAG_ALWAYS>,
+			<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+			 &config_noc SLAVE_QUP_2 QCOM_ICC_TAG_ACTIVE_ONLY>,
+			<&aggre2_noc MASTER_QUP_2 QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&i2c13 {
+	interconnects = <&clk_virt MASTER_QUP_CORE_3 QCOM_ICC_TAG_ALWAYS
+			 &clk_virt SLAVE_QUP_CORE_3 QCOM_ICC_TAG_ALWAYS>,
+			<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+			 &config_noc SLAVE_QUP_3 QCOM_ICC_TAG_ACTIVE_ONLY>,
+			<&aggre2_noc MASTER_QUP_3 QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&i2c14 {
+	interconnects = <&clk_virt MASTER_QUP_CORE_3 QCOM_ICC_TAG_ALWAYS
+			 &clk_virt SLAVE_QUP_CORE_3 QCOM_ICC_TAG_ALWAYS>,
+			<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+			 &config_noc SLAVE_QUP_3 QCOM_ICC_TAG_ACTIVE_ONLY>,
+			<&aggre2_noc MASTER_QUP_3 QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&i2c15 {
+	interconnects = <&clk_virt MASTER_QUP_CORE_3 QCOM_ICC_TAG_ALWAYS
+			 &clk_virt SLAVE_QUP_CORE_3 QCOM_ICC_TAG_ALWAYS>,
+			<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+			 &config_noc SLAVE_QUP_3 QCOM_ICC_TAG_ACTIVE_ONLY>,
+			<&aggre2_noc MASTER_QUP_3 QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&i2c16 {
+	interconnects = <&clk_virt MASTER_QUP_CORE_3 QCOM_ICC_TAG_ALWAYS
+			 &clk_virt SLAVE_QUP_CORE_3 QCOM_ICC_TAG_ALWAYS>,
+			<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+			 &config_noc SLAVE_QUP_3 QCOM_ICC_TAG_ACTIVE_ONLY>,
+			<&aggre2_noc MASTER_QUP_3 QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&i2c17 {
+	interconnects = <&clk_virt MASTER_QUP_CORE_3 QCOM_ICC_TAG_ALWAYS
+			 &clk_virt SLAVE_QUP_CORE_3 QCOM_ICC_TAG_ALWAYS>,
+			<&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+			 &config_noc SLAVE_QUP_3 QCOM_ICC_TAG_ACTIVE_ONLY>,
+			<&aggre2_noc MASTER_QUP_3 QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&lpass_ag_noc {
+	compatible = "qcom,molokai-lpass-ag-noc";
+};
+
+&lpass_lpiaon_noc {
+	compatible = "qcom,molokai-lpass-lpiaon-noc";
+};
+
+&lpass_lpicx_noc {
+	compatible = "qcom,molokai-lpass-lpicx-noc";
+};
+
+&mc_virt {
+	compatible = "qcom,molokai-mc-virt";
+};
+
+&mmss_noc {
+	compatible = "qcom,molokai-mmss-noc";
+	reg = <0x0 0x01780000 0x0 0x7d400>;
+};
+
+&nsp_noc {
+	compatible = "qcom,molokai-nsp-noc";
+	reg = <0x0 0x260c0000 0x0 0x1c080>;
+};
+
+&pcie_noc {
+	compatible = "qcom,molokai-pcie-anoc";
+};
+
+&pdc {
+	compatible = "qcom,molokai-pdc", "qcom,pdc";
+	qcom,pdc-ranges = <0 745 38>,
+			  <40 785 11>,
+			  <51 527 4>,
+			  <58 534 2>,
+			  <61 537 20>,
+			  <84 559 14>,
+			  <98 609 32>,
+			  <130 717 12>,
+			  <142 251 5>,
+			  <147 796 16>,
+			  <163 783 2>,
+			  <165 531 2>,
+			  <167 536 1>,
+			  <168 557 2>,
+			  <170 415 1>,
+			  <171 438 1>,
+			  <172 579 1>,
+			  <173 703 1>,
+			  <174 708 1>,
+			  <175 714 1>,
+			  <176 68 1>,
+			  <177 86 1>,
+			  <178 96 1>,
+			  <179 249 1>,
+			  <180 504 9>;
+};
+
+&qup_i2c0_data_clk {
+	pins = "gpio32", "gpio33";
+};
+
+&qup_i2c1_data_clk {
+	pins = "gpio36", "gpio37";
+};
+
+&qup_i2c4_data_clk {
+	pins = "gpio48", "gpio49";
+};
+
+&qup_i2c5_data_clk {
+	pins = "gpio72", "gpio73";
+	function = "qup1_se5_mira";
+};
+
+&qup_i2c10_data_clk {
+	pins = "gpio8", "gpio9";
+};
+
+&qup_i2c11_data_clk {
+	pins = "gpio12", "gpio13";
+};
+
+&qup_i2c12_data_clk {
+	pins = "gpio117", "gpio118";
+	function = "qup2_se4_mirb";
+};
+
+&qup_i2c14_data_clk {
+	pins = "gpio68", "gpio69";
+};
+
+&qup_i2c15_data_clk {
+	pins = "gpio80", "gpio81";
+};
+
+&qup_i2c16_data_clk {
+	pins = "gpio76", "gpio77";
+};
+
+&qup_i2c17_data_clk {
+	pins = "gpio52", "gpio53";
+};
+
+&qup_spi0_cs {
+	pins = "gpio35";
+};
+
+&qup_spi0_data_clk {
+	pins = "gpio32", "gpio33", "gpio34";
+};
+
+&qup_spi1_cs {
+	pins = "gpio39";
+};
+
+&qup_spi1_data_clk {
+	pins = "gpio36", "gpio37", "gpio38";
+};
+
+&qup_spi4_cs {
+	pins = "gpio51";
+};
+
+&qup_spi4_data_clk {
+	pins = "gpio48", "gpio49", "gpio50";
+};
+
+&qup_spi5_cs {
+	pins = "gpio75";
+	function = "qup1_se5_mira";
+};
+
+&qup_spi5_data_clk {
+	pins = "gpio72", "gpio73", "gpio74";
+	function = "qup1_se5_mira";
+};
+
+&qup_spi10_cs {
+	pins = "gpio11";
+};
+
+&qup_spi10_data_clk {
+	pins = "gpio8", "gpio9", "gpio10";
+};
+
+&qup_spi11_cs {
+	pins = "gpio15";
+};
+
+&qup_spi11_data_clk {
+	pins = "gpio12", "gpio13", "gpio14";
+};
+
+&qup_spi14_cs {
+	pins = "gpio71";
+};
+
+&qup_spi14_data_clk {
+	pins = "gpio68", "gpio69", "gpio70";
+};
+
+&qup_spi15_cs {
+	pins = "gpio83";
+};
+
+&qup_spi15_data_clk {
+	pins = "gpio80", "gpio81", "gpio82";
+};
+
+&qup_spi16_cs {
+	pins = "gpio147";
+};
+
+&qup_spi16_data_clk {
+	pins = "gpio76", "gpio77", "gpio146";
+};
+
+&qup_spi17_cs {
+	pins = "gpio55";
+};
+
+&qup_spi17_data_clk {
+	pins = "gpio52", "gpio53", "gpio54";
+};
+
+&scm {
+	interconnects = <&aggre2_noc MASTER_CRYPTO QCOM_ICC_TAG_ALWAYS
+			 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ALWAYS>;
+};
+
+&soc {
+	aggre2_noc: interconnect@1700000 {
+		compatible = "qcom,molokai-aggre2-noc";
+		reg = <0x0 0x01700000 0x0 0x22400>;
+		qcom,bcm-voters = <&apps_bcm_voter>;
+		#interconnect-cells = <2>;
+		clocks = <&rpmhcc RPMH_IPA_CLK>;
+	};
+};
+
+&system_noc {
+	compatible = "qcom,molokai-system-noc";
+};
+
+&tlmm {
+	compatible = "qcom,molokai-tlmm";
+	gpio-ranges = <&tlmm 0 0 206>;
+};

-- 
2.56.1

