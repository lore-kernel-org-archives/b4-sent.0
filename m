From: Fenglin Wu <quic_fenglinw@quicinc.com>
Date: Thu, 14 Dec 2023 10:59:14 +0800
Subject: [PATCH v2 4/5] arm64: dts: qcom: sm8550-mtp: Add pm8010 regulators
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231214-pm8010-regulator-v2-4-82131df6b97b@quicinc.com>
References: <20231214-pm8010-regulator-v2-0-82131df6b97b@quicinc.com>
In-Reply-To: <20231214-pm8010-regulator-v2-0-82131df6b97b@quicinc.com>
To: Andy Gross <agross@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, kernel@quicinc.com
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, quic_collinsd@quicinc.com, 
 quic_subbaram@quicinc.com, quic_jprakash@quicinc.com, 
 Fenglin Wu <quic_fenglinw@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702522752; l=4205;
 i=quic_fenglinw@quicinc.com; s=20230725; h=from:subject:message-id;
 bh=4C8r1RX6jrprmI3bI9Nod0mp3ISCSyQLdpiWSlrmkOE=;
 b=1Rji7b2dj+2vfGExHlkN46xe7+Qr0OGIoHdNTEC2ZriIqR8pFgAfoDTSHBNcaJ6+oP6kMDviT
 aLOCev936BzDKcau3FT+Kh2Z+upnz8ufv5MGiGFLy4MN5sg1sCSBQFp
X-Developer-Key: i=quic_fenglinw@quicinc.com; a=ed25519;
 pk=hleIDz3Unk1zeiwwOnZUjoQVMMelRancDFXg927lNjI=
X-Endpoint-Received: by B4 Relay for quic_fenglinw@quicinc.com/20230725 with auth_id=68
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PM8010 regulator device nodes for sm8550-mtp board.

Signed-off-by: Fenglin Wu <quic_fenglinw@quicinc.com>
---
 arch/arm64/boot/dts/qcom/sm8550-mtp.dts | 120 ++++++++++++++++++++++++++++++++
 1 file changed, 120 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550-mtp.dts b/arch/arm64/boot/dts/qcom/sm8550-mtp.dts
index 9a70875028b7..8395d363d18d 100644
--- a/arch/arm64/boot/dts/qcom/sm8550-mtp.dts
+++ b/arch/arm64/boot/dts/qcom/sm8550-mtp.dts
@@ -510,6 +510,126 @@ vreg_l3g_1p2: ldo3 {
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
 		};
 	};
+
+	regulators-6 {
+		compatible = "qcom,pm8010-rpmh-regulators";
+		qcom,pmic-id = "m";
+
+		vdd-l1-l2-supply = <&vreg_s4g_1p3>;
+		vdd-l3-l4-supply = <&vreg_bob2>;
+		vdd-l5-supply = <&vreg_s6g_1p8>;
+		vdd-l6-supply = <&vreg_s6g_1p8>;
+		vdd-l7-supply = <&vreg_bob1>;
+
+		vreg_l1m_1p056: ldo1 {
+			regulator-name = "vreg_l1m_1p056";
+			regulator-min-microvolt = <1056000>;
+			regulator-max-microvolt = <1056000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l2m_1p056: ldo2 {
+			regulator-name = "vreg_l2m_1p056";
+			regulator-min-microvolt = <1056000>;
+			regulator-max-microvolt = <1056000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l3m_2p8: ldo3 {
+			regulator-name = "vreg_l3m_2p8";
+			regulator-min-microvolt = <2800000>;
+			regulator-max-microvolt = <2800000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l4m_2p8: ldo4 {
+			regulator-name = "vreg_l4m_2p8";
+			regulator-min-microvolt = <2800000>;
+			regulator-max-microvolt = <2800000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l5m_1p8: ldo5 {
+			regulator-name = "vreg_l5m_1p8";
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l6m_1p8: ldo6 {
+			regulator-name = "vreg_l6m_1p8";
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l7m_2p9: ldo7 {
+			regulator-name = "vreg_l7m_2p9";
+			regulator-min-microvolt = <2800000>;
+			regulator-max-microvolt = <2904000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+	};
+
+	regulators-7 {
+		compatible = "qcom,pm8010-rpmh-regulators";
+		qcom,pmic-id = "n";
+
+		vdd-l1-l2-supply = <&vreg_s4g_1p3>;
+		vdd-l3-l4-supply = <&vreg_bob2>;
+		vdd-l5-supply = <&vreg_s6g_1p8>;
+		vdd-l6-supply = <&vreg_bob1>;
+		vdd-l7-supply = <&vreg_bob1>;
+
+		vreg_l1n_1p1: ldo1 {
+			regulator-name = "vreg_l1n_1p1";
+			regulator-min-microvolt = <1104000>;
+			regulator-max-microvolt = <1200000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l2n_1p1: ldo2 {
+			regulator-name = "vreg_l2n_1p1";
+			regulator-min-microvolt = <1104000>;
+			regulator-max-microvolt = <1200000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l3n_2p8: ldo3 {
+			regulator-name = "vreg_l3n_2p8";
+			regulator-min-microvolt = <2800000>;
+			regulator-max-microvolt = <3000000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l4n_2p8: ldo4 {
+			regulator-name = "vreg_l4n_2p8";
+			regulator-min-microvolt = <2800000>;
+			regulator-max-microvolt = <3300000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l5n_1p8: ldo5 {
+			regulator-name = "vreg_l5n_1p8";
+			regulator-min-microvolt = <1800000>;
+			regulator-max-microvolt = <1800000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l6n_3p3: ldo6 {
+			regulator-name = "vreg_l6n_3p3";
+			regulator-min-microvolt = <2800000>;
+			regulator-max-microvolt = <3304000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+
+		vreg_l7n_2p96: ldo7 {
+			regulator-name = "vreg_l7n_2p96";
+			regulator-min-microvolt = <2800000>;
+			regulator-max-microvolt = <2960000>;
+			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+		};
+	};
 };
 
 &i2c_master_hub_0 {

-- 
2.25.1

