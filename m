From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 13:10:08 +0530
Subject: [PATCH v2 10/11] arm64: dts: qcom: molokai: Describe the Adreno
 829 GPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-molokai-soc-v2-10-9dc4dddc4e96@yahoo.com>
References: <20261116-molokai-soc-v2-0-9dc4dddc4e96@yahoo.com>
In-Reply-To: <20261116-molokai-soc-v2-0-9dc4dddc4e96@yahoo.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794814798; l=4118;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=2HkDl1+9itKBIsKaFYMNX6gN+5ciNOiOA4CxVzbOQLU=;
 b=SZS8Tw5lYWqw0RjAYLAnmBnhn8eficsy4G9sRmMD81LlpbUPjeYHtkRcTpcHxHmJ9aBiN5NHf
 aQXJ1CUp0jjCoKSFRCxB+juJGYR90QyoVl/l/XoE57MbtK1qecUl+kT
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Molokai GPU is an Adreno 829 instead of the Kaanapali Adreno 840. It
has no speed bin fuse and its own set of operating points.

Assisted-by: LLM
Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 arch/arm64/boot/dts/qcom/molokai.dtsi | 123 ++++++++++++++++++++++++++++++++++
 1 file changed, 123 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/molokai.dtsi b/arch/arm64/boot/dts/qcom/molokai.dtsi
index 82fd31bda1d9..3b9772edd68f 100644
--- a/arch/arm64/boot/dts/qcom/molokai.dtsi
+++ b/arch/arm64/boot/dts/qcom/molokai.dtsi
@@ -12,6 +12,7 @@
 #include "kaanapali.dtsi"
 
 /delete-node/ &gpi_dma4;
+/delete-node/ &gpu_opp_table;
 /delete-node/ &i2c_master_hub;
 /delete-node/ &qupv3_4;
 /delete-node/ &uart18;
@@ -37,6 +38,128 @@
 /delete-node/ &sdc2_default;
 /delete-node/ &sdc2_sleep;
 
+&gmu {
+	compatible = "qcom,adreno-gmu-829.0", "qcom,adreno-gmu";
+};
+
+&gpu {
+	compatible = "qcom,adreno-44030a00", "qcom,adreno";
+
+	/* No GPU speed bin fuse */
+	/delete-property/ nvmem-cells;
+	/delete-property/ nvmem-cell-names;
+
+	gpu_opp_table: opp-table {
+		compatible = "operating-points-v2-adreno",
+			     "operating-points-v2";
+
+		opp-195000000 {
+			opp-hz = /bits/ 64 <195000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS_D2>;
+			opp-peak-kBps = <2136718>;
+			qcom,opp-acd-level = <0xc82f5ffd>;
+		};
+
+		opp-301000000 {
+			opp-hz = /bits/ 64 <301000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS_D1>;
+			opp-peak-kBps = <5285156>;
+			qcom,opp-acd-level = <0xc82f5ffd>;
+		};
+
+		opp-403000000 {
+			opp-hz = /bits/ 64 <403000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS>;
+			opp-peak-kBps = <5285156>;
+			qcom,opp-acd-level = <0xc8295ffd>;
+		};
+
+		opp-496000000 {
+			opp-hz = /bits/ 64 <496000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_LOW_SVS_L1>;
+			opp-peak-kBps = <5285156>;
+			qcom,opp-acd-level = <0xc8295ffd>;
+		};
+
+		opp-589000000 {
+			opp-hz = /bits/ 64 <589000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_SVS>;
+			opp-peak-kBps = <6074218>;
+			qcom,opp-acd-level = <0xc02b5ffd>;
+		};
+
+		opp-660000000 {
+			opp-hz = /bits/ 64 <660000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_SVS_L0>;
+			opp-peak-kBps = <6074218>;
+			qcom,opp-acd-level = <0x882f5ffd>;
+		};
+
+		opp-714000000 {
+			opp-hz = /bits/ 64 <714000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_SVS_L1>;
+			opp-peak-kBps = <6074218>;
+			qcom,opp-acd-level = <0x882f5ffd>;
+		};
+
+		opp-732000000 {
+			opp-hz = /bits/ 64 <732000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_SVS_L2>;
+			opp-peak-kBps = <8171875>;
+			qcom,opp-acd-level = <0x882e5ffd>;
+		};
+
+		opp-795000000 {
+			opp-hz = /bits/ 64 <795000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_NOM>;
+			opp-peak-kBps = <12449218>;
+			qcom,opp-acd-level = <0x882d5ffd>;
+		};
+
+		opp-891000000 {
+			opp-hz = /bits/ 64 <891000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_NOM_L1>;
+			opp-peak-kBps = <12449218>;
+			qcom,opp-acd-level = <0xa82b5ffd>;
+		};
+
+		opp-975000000 {
+			opp-hz = /bits/ 64 <975000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_TURBO>;
+			opp-peak-kBps = <14398437>;
+			qcom,opp-acd-level = <0x882b5ffd>;
+		};
+
+		opp-1025000000 {
+			opp-hz = /bits/ 64 <1025000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_TURBO_L0>;
+			opp-peak-kBps = <14398437>;
+			qcom,opp-acd-level = <0xa82a5ffd>;
+		};
+
+		opp-1075000000 {
+			opp-hz = /bits/ 64 <1075000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_TURBO_L1>;
+			opp-peak-kBps = <14398437>;
+			qcom,opp-acd-level = <0x882a5ffd>;
+		};
+
+		opp-1150000000 {
+			opp-hz = /bits/ 64 <1150000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_TURBO_L2>;
+			opp-peak-kBps = <18671875>;
+			qcom,opp-acd-level = <0xa8295ffd>;
+		};
+
+		opp-1225000000 {
+			opp-hz = /bits/ 64 <1225000000>;
+			opp-level = <RPMH_REGULATOR_LEVEL_TURBO_L3>;
+			opp-peak-kBps = <18671875>;
+			qcom,opp-acd-level = <0x88295ffd>;
+		};
+	};
+};
+
 &gpucc {
 	compatible = "qcom,molokai-gpucc";
 };

-- 
2.56.1

