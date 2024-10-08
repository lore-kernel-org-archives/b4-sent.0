From: Renjiang Han <quic_renjiang@quicinc.com>
Date: Tue, 08 Oct 2024 16:46:34 +0530
Subject: [PATCH 1/2] arm64: dts: qcom: add video DT for qcs615
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241008-add_qcs615_video-v1-1-436ce07bfc63@quicinc.com>
References: <20241008-add_qcs615_video-v1-0-436ce07bfc63@quicinc.com>
In-Reply-To: <20241008-add_qcs615_video-v1-0-436ce07bfc63@quicinc.com>
To: Vikash Garodia <quic_vgarodia@quicinc.com>
Cc: kernel@quicinc.com, Renjiang Han <quic_renjiang@quicinc.com>, 
 linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728386222; l=3460;
 i=quic_renjiang@quicinc.com; s=20241001; h=from:subject:message-id;
 bh=/Bx9teN1YmKVEZFAZmCAcYjiC5RdA6hKz5QrvyVujYA=;
 b=AKtNMAPx5tz1SYWSdXlpCt3fjK4AcYJdDTuyyKRTBP2ud0g9ZzkCMjtCdW7/edj6dNUvDZsNF
 zwlQRAD6H1iAKAX+xvvVEbDqyzK3OhyMfJh9WNc90HiwW3/G6U0r7WK
X-Developer-Key: i=quic_renjiang@quicinc.com; a=ed25519;
 pk=8N59kMJUiVH++5QxJzTyHB/wh/kG5LxQ44j9zhUvZmw=
X-Endpoint-Received: by B4 Relay for quic_renjiang@quicinc.com/20241001 with auth_id=235
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

1. add video DT in the qcs615.dtsi
2. enable video codec in the qcs615-ride.dts

Change-Id: I80017997005878145a22fc8f38c0ffb653938aee
Signed-off-by: Renjiang Han <quic_renjiang@quicinc.com>
---
 arch/arm64/boot/dts/qcom/qcs615-ride.dts | 12 +++++
 arch/arm64/boot/dts/qcom/qcs615.dtsi     | 75 ++++++++++++++++++++++++++++++++
 2 files changed, 87 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/qcs615-ride.dts b/arch/arm64/boot/dts/qcom/qcs615-ride.dts
index 73a8213cbbea58715677855c71b5b94e6c534711..c54e01640d4e455b1f985a553b6c5a83be31090e 100644
--- a/arch/arm64/boot/dts/qcom/qcs615-ride.dts
+++ b/arch/arm64/boot/dts/qcom/qcs615-ride.dts
@@ -262,6 +262,18 @@ &gcc {
 		 <&sleep_clk>;
 };
 
+&venus {
+	status = "okay";
+
+	video-decoder {
+		status = "okay";
+	};
+
+	video-encoder {
+		status = "okay";
+	};
+};
+
 &i2c2 {
 	clock-frequency = <400000>;
 	pinctrl-0 = <&qup_i2c2_data_clk &ioexp_intr_active &ioexp_reset_active>;
diff --git a/arch/arm64/boot/dts/qcom/qcs615.dtsi b/arch/arm64/boot/dts/qcom/qcs615.dtsi
index 1379900f753eff64d17fb1fe106b6a859e7f1aa3..a28a53ac500241f589a45f419ee3cfb8b64bca8b 100644
--- a/arch/arm64/boot/dts/qcom/qcs615.dtsi
+++ b/arch/arm64/boot/dts/qcom/qcs615.dtsi
@@ -1525,6 +1525,81 @@ usb_dwc3: usb@4e00000 {
 
 		};
 
+		venus: video-codec@aa00000 {
+			compatible = "qcom,qcs615-venus";
+			reg = <0x0 0xaa00000 0x0 0x100000>;
+			interrupts = <GIC_SPI 174 IRQ_TYPE_LEVEL_HIGH>;
+
+			clocks = <&videocc VIDEO_CC_VENUS_CTL_CORE_CLK>,
+				 <&videocc VIDEO_CC_VENUS_AHB_CLK>,
+				 <&videocc VIDEO_CC_VENUS_CTL_AXI_CLK>,
+				 <&videocc VIDEO_CC_VCODEC0_CORE_CLK>,
+				 <&videocc VIDEO_CC_VCODEC0_AXI_CLK>;
+			clock-names = "core", "iface", "bus",
+				"vcodec0_core", "vcodec0_bus";
+
+			power-domains = <&videocc VENUS_GDSC>,
+					<&videocc VCODEC0_GDSC>,
+					<&rpmhpd RPMHPD_CX>;
+			power-domain-names = "venus", "vcodec0", "cx";
+
+			operating-points-v2 = <&venus_opp_table>;
+
+			interconnects = <&mmss_noc MASTER_VIDEO_P0 0 &mc_virt SLAVE_EBI1 0>,
+					<&gem_noc MASTER_APPSS_PROC 0 &config_noc SLAVE_VENUS_CFG 0>;
+			interconnect-names = "video-mem", "cpu-cfg";
+
+			iommus = <&apps_smmu 0xe40 0x20>,
+				 <&apps_smmu 0xe44 0x20>;
+
+			memory-region = <&pil_video_mem>;
+
+			status = "disabled";
+			video-decoder {
+				compatible = "venus-decoder";
+				status = "disabled";
+			};
+
+			video-encoder {
+				compatible = "venus-encoder";
+				status = "disabled";
+			};
+
+			venus_opp_table: opp-table {
+				compatible = "operating-points-v2";
+
+				opp-133330000 {
+					opp-hz = /bits/ 64 <133330000>;
+					required-opps = <&rpmhpd_opp_low_svs>;
+				};
+
+				opp-240000000 {
+					opp-hz = /bits/ 64 <240000000>;
+					required-opps = <&rpmhpd_opp_svs>;
+				};
+
+				opp-300000000 {
+					opp-hz = /bits/ 64 <300000000>;
+					required-opps = <&rpmhpd_opp_svs_l1>;
+				};
+
+				opp-380000000 {
+					opp-hz = /bits/ 64 <380000000>;
+					required-opps = <&rpmhpd_opp_nom>;
+				};
+
+				opp-410000000 {
+					opp-hz = /bits/ 64 <410000000>;
+					required-opps = <&rpmhpd_opp_turbo>;
+				};
+
+				opp-460000000 {
+					opp-hz = /bits/ 64 <460000000>;
+					required-opps = <&rpmhpd_opp_turbo_l1>;
+				};
+			};
+		};
+
 		videocc: clock-controller@ab00000 {
 			compatible = "qcom,qcs615-videocc";
 			reg = <0 0xab00000 0 0x10000>;

-- 
2.34.1

