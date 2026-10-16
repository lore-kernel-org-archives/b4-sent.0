From: Demeter Barna <me@fromdisposition.org>
Date: Fri, 16 Oct 2026 06:13:52 +0000
Subject: [PATCH 2/2] arm64: dts: qcom: sm8350: Add CPU and LLCC BWMON
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-sm8350-bwmon-v1-2-562fe403bf6b@fromdisposition.org>
References: <20261016-sm8350-bwmon-v1-0-562fe403bf6b@fromdisposition.org>
In-Reply-To: <20261016-sm8350-bwmon-v1-0-562fe403bf6b@fromdisposition.org>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Georgi Djakov <djakov@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792131248; l=2940;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=nXdAocuEjzj92zdGAtIocuJPoJLdBGkW1hoCnioia2M=;
 b=9EgzFOHoBhmQbprXtUAp+sta5mjcoBmCMdWLdxXjmtRYAjSsRJf1Y9chit2BlcctUBCHI1OeP
 +ow0C6vlsBlBvY8LWcpmdgY56vlY56JLg342bJ4OAELDHdVFWafkp+1
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the CPU-to-LLCC and LLCC-to-DDR bandwidth monitors, so that the
interconnect votes follow the measured memory traffic.

The levels are those of the downstream llcc-bw-opp-table and
ddr-bw-opp-table. Downstream limits two DDR levels (5161 and 8136 MB/s)
to LPDDR4X; leave them out, as was done for SM8250.

Assisted-by: LLM
Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 arch/arm64/boot/dts/qcom/sm8350.dtsi | 100 +++++++++++++++++++++++++++++++++++
 1 file changed, 100 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8350.dtsi b/arch/arm64/boot/dts/qcom/sm8350.dtsi
index 55b32050ce9c..6335c7809d17 100644
--- a/arch/arm64/boot/dts/qcom/sm8350.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8350.dtsi
@@ -2476,6 +2476,106 @@ usb_2_qmpphy: phy@88eb000 {
 				      "phy_phy";
 		};
 
+		pmu@9091000 {
+			compatible = "qcom,sm8350-llcc-bwmon", "qcom,sc7280-llcc-bwmon";
+			reg = <0 0x09091000 0 0x1000>;
+			interrupts = <GIC_SPI 81 IRQ_TYPE_LEVEL_HIGH>;
+			interconnects = <&mc_virt MASTER_LLCC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &mc_virt SLAVE_EBI1 QCOM_ICC_TAG_ACTIVE_ONLY>;
+
+			operating-points-v2 = <&llcc_bwmon_opp_table>;
+
+			llcc_bwmon_opp_table: opp-table {
+				compatible = "operating-points-v2";
+
+				opp-0 {
+					opp-peak-kBps = <762000>;
+				};
+
+				opp-1 {
+					opp-peak-kBps = <1720000>;
+				};
+
+				opp-2 {
+					opp-peak-kBps = <2086000>;
+				};
+
+				opp-3 {
+					opp-peak-kBps = <2597000>;
+				};
+
+				opp-4 {
+					opp-peak-kBps = <2929000>;
+				};
+
+				opp-5 {
+					opp-peak-kBps = <3879000>;
+				};
+
+				opp-6 {
+					opp-peak-kBps = <5931000>;
+				};
+
+				opp-7 {
+					opp-peak-kBps = <6515000>;
+				};
+
+				opp-8 {
+					opp-peak-kBps = <7980000>;
+				};
+
+				opp-9 {
+					opp-peak-kBps = <10437000>;
+				};
+
+				opp-10 {
+					opp-peak-kBps = <12191000>;
+				};
+			};
+		};
+
+		pmu@90b6400 {
+			compatible = "qcom,sm8350-cpu-bwmon", "qcom,sdm845-bwmon";
+			reg = <0 0x090b6400 0 0x600>;
+			interrupts = <GIC_SPI 581 IRQ_TYPE_LEVEL_HIGH>;
+			interconnects = <&gem_noc MASTER_APPSS_PROC QCOM_ICC_TAG_ACTIVE_ONLY
+					 &gem_noc SLAVE_LLCC QCOM_ICC_TAG_ACTIVE_ONLY>;
+
+			operating-points-v2 = <&cpu_bwmon_opp_table>;
+
+			cpu_bwmon_opp_table: opp-table {
+				compatible = "operating-points-v2";
+
+				opp-0 {
+					opp-peak-kBps = <2288000>;
+				};
+
+				opp-1 {
+					opp-peak-kBps = <4577000>;
+				};
+
+				opp-2 {
+					opp-peak-kBps = <7110000>;
+				};
+
+				opp-3 {
+					opp-peak-kBps = <9155000>;
+				};
+
+				opp-4 {
+					opp-peak-kBps = <12298000>;
+				};
+
+				opp-5 {
+					opp-peak-kBps = <14236000>;
+				};
+
+				opp-6 {
+					opp-peak-kBps = <15258000>;
+				};
+			};
+		};
+
 		dc_noc: interconnect@90c0000 {
 			compatible = "qcom,sm8350-dc-noc";
 			reg = <0 0x090c0000 0 0x4200>;

-- 
2.53.0

