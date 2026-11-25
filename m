From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Wed, 25 Nov 2026 12:13:37 +0100
Subject: [PATCH] arm64: dts: qcom: sc8180x: add IPA node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-sc8180x-dts-ipa-v1-1-12e54c7e13b5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAODCBmsC/x3MQQqAIBBA0avErBtQwdCuEi1Mp5qNhRMhRHdPW
 r7F/w8IFSaBsXug0M3CR27QfQdxD3kj5NQMRplBa2NRotNOVUyXIJ8BlXLkydrolwStOgutXP/
 jNL/vB4SIn6NhAAAA
X-Change-ID: 20261125-sc8180x-dts-ipa-008e9e55c9bd
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795605216; l=2739;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=d35IiIlbv8warTqyu0RnwigzG9v3xGp9TFd/CxAMx0o=;
 b=r3R/YJo7unyUuYBFlfVlfHvo5PmYAcWld7tzWbd+eoQ1+FgYf9la5tgdwbfo/sxZStQG415As
 fdhBHN8V393ANmGOkKq4ScsBtnFRrHRXN3nUi64DOZsjGb3Yx7T//KE
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the disabled IPA v4.1 (ipa@1e40000) SoC node to sc8180x.dtsi with
its register regions, GIC and SMP2P interrupts, RPMh core clock,
interconnects, SMMU streams, AOSS QMP handle, and SMP2P SMEM states so
board devicetrees can enable IPA with their board-specific firmware and
reserved memory region.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Depends-on: https://lore.kernel.org/r/20261125-qcom-ipa-sc8180x-v1-0-48a889acbe6b@gmail.com
The "qcom,sc8180x-ipa" binding patch in that series carries a
Reviewed-by from Krzysztof Kozlowski.
---
 arch/arm64/boot/dts/qcom/sc8180x.dtsi | 43 +++++++++++++++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sc8180x.dtsi b/arch/arm64/boot/dts/qcom/sc8180x.dtsi
index be79608b7161a0786463fe93e22798080ebba93c..d30e56fec6303ca0043b68c6c0f739c9614aa5fc 100644
--- a/arch/arm64/boot/dts/qcom/sc8180x.dtsi
+++ b/arch/arm64/boot/dts/qcom/sc8180x.dtsi
@@ -2261,6 +2261,49 @@ ufs_mem_phy: phy-wrapper@1d87000 {
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
+			status = "disabled";
+		};
+
 		tcsr_mutex: hwlock@1f40000 {
 			compatible = "qcom,tcsr-mutex";
 			reg = <0x0 0x01f40000 0x0 0x40000>;

---
base-commit: ef922b721a5e99348fc1f5801fdeb427ee14ee9f
change-id: 20261125-sc8180x-dts-ipa-008e9e55c9bd

Best regards,
-- 
Robert Ijtsma <robertijtsma@gmail.com>

