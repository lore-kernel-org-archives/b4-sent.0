From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Thu, 26 Nov 2026 14:39:44 +0100
Subject: [PATCH v2 2/2] arm64: dts: qcom: sc8180x: add IMEM and IPA nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-sc8180x-dts-ipa-v2-2-ad57b1be7c70@gmail.com>
References: <20261126-sc8180x-dts-ipa-v2-0-ad57b1be7c70@gmail.com>
In-Reply-To: <20261126-sc8180x-dts-ipa-v2-0-ad57b1be7c70@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Robert Ijtsma <robertijtsma@gmail.com>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795700384; l=2992;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=BnOyacuhbzcDt4clZZEwyrtjCfWK2nniZzvmzD0VMb8=;
 b=/7CX6GX1/hsUemErPlHdtYlhYC3EQyQd6z3vWI/vnEUv6tgXCPAU8VQI06CNo3n/rX4vUqqSV
 /WUvb2kCigoBjAyRF5BiL5fZXfNS0vJ/T/mfB4rLqke/vab7XKrxMtP
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the on-chip SRAM (sram@14680000) node with the IPA modem-tables
region and the disabled IPA v4.1 (ipa@1e40000) node to sc8180x.dtsi
with its register regions, GIC and SMP2P interrupts, RPMh core clock,
interconnects, SMMU streams, AOSS QMP handle, SMP2P SMEM states, and
IMEM sram reference so board devicetrees can enable IPA with their
board-specific firmware and reserved memory region.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 arch/arm64/boot/dts/qcom/sc8180x.dtsi | 60 +++++++++++++++++++++++++++++++++++
 1 file changed, 60 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sc8180x.dtsi b/arch/arm64/boot/dts/qcom/sc8180x.dtsi
index a85e321..5d83734 100644
--- a/arch/arm64/boot/dts/qcom/sc8180x.dtsi
+++ b/arch/arm64/boot/dts/qcom/sc8180x.dtsi
@@ -2253,6 +2253,51 @@ ufs_mem_phy: phy-wrapper@1d87000 {
 			status = "disabled";
 		};
 
+		ipa: ipa@1e40000 {
+			compatible = "qcom,sc8180x-ipa";
+			reg = <0x0 0x01e40000 0x0 0x7000>,
+			      <0x0 0x01e47000 0x0 0x4000>,
+			      <0x0 0x01e04000 0x0 0x2c000>;
+			reg-names = "ipa-reg",
+				    "ipa-shared",
+				    "gsi";
+
+			interrupts-extended = <&intc GIC_SPI 311 IRQ_TYPE_EDGE_RISING>,
+					      <&intc GIC_SPI 432 IRQ_TYPE_LEVEL_HIGH>,
+					      <&modem_smp2p_ipa_in 0 IRQ_TYPE_EDGE_RISING>,
+					      <&modem_smp2p_ipa_in 1 IRQ_TYPE_EDGE_RISING>;
+			interrupt-names = "ipa",
+					  "gsi",
+					  "ipa-clock-query",
+					  "ipa-setup-ready";
+
+			clocks = <&rpmhcc RPMH_IPA_CLK>;
+			clock-names = "core";
+
+			interconnects = <&aggre2_noc MASTER_IPA QCOM_ICC_TAG_ALWAYS
+					 &mc_virt SLAVE_EBI_CH0 QCOM_ICC_TAG_ALWAYS>,
+					<&aggre2_noc MASTER_IPA QCOM_ICC_TAG_ALWAYS
+					 &system_noc SLAVE_OCIMEM QCOM_ICC_TAG_ALWAYS>,
+					<&gem_noc MASTER_AMPSS_M0 QCOM_ICC_TAG_ALWAYS
+					 &config_noc SLAVE_IPA_CFG QCOM_ICC_TAG_ALWAYS>;
+			interconnect-names = "memory",
+					     "imem",
+					     "config";
+
+			iommus = <&apps_smmu 0x520 0x0>,
+				 <&apps_smmu 0x522 0x0>;
+
+			qcom,qmp = <&aoss_qmp>;
+			qcom,smem-states = <&modem_smp2p_ipa_out 0>,
+					   <&modem_smp2p_ipa_out 1>;
+			qcom,smem-state-names = "ipa-clock-enabled-valid",
+						"ipa-clock-enabled";
+
+			sram = <&ipa_modem_tables>;
+
+			status = "disabled";
+		};
+
 		tcsr_mutex: hwlock@1f40000 {
 			compatible = "qcom,tcsr-mutex";
 			reg = <0x0 0x01f40000 0x0 0x40000>;
@@ -3615,6 +3660,21 @@ spmi_bus: spmi@c440000 {
 			#interrupt-cells = <4>;
 		};
 
+		sram@14680000 {
+			compatible = "qcom,sc8180x-imem", "mmio-sram";
+			reg = <0x0 0x14680000 0x0 0x40000>;
+			ranges = <0x0 0x0 0x14680000 0x40000>;
+
+			no-memory-wc;
+
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			ipa_modem_tables: modem-tables-sram@3d000 {
+				reg = <0x3d000 0x2000>;
+			};
+		};
+
 		apps_smmu: iommu@15000000 {
 			compatible = "qcom,sc8180x-smmu-500", "arm,mmu-500";
 			reg = <0 0x15000000 0 0x100000>;

-- 
2.56.0

