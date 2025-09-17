From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Wed, 17 Sep 2025 18:15:21 +0800
Subject: [PATCH v5 8/9] arm64: dts: qcom: x1e80100-crd: Add charge limit
 nvmem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-qcom_battmgr_update-v5-8-270ade9ffe13@oss.qualcomm.com>
References: <20250917-qcom_battmgr_update-v5-0-270ade9ffe13@oss.qualcomm.com>
In-Reply-To: <20250917-qcom_battmgr_update-v5-0-270ade9ffe13@oss.qualcomm.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, 
 =?utf-8?q?Gy=C3=B6rgy_Kurucz?= <me@kuruczgy.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, devicetree@vger.kernel.org, 
 linux-usb@vger.kernel.org, Fenglin Wu <fenglin.wu@oss.qualcomm.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758104128; l=2081;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=xJkmh8H8fqVeUkTKnSTN4qTVDnBNRbRfNDN7UjY4z8w=;
 b=GOkbgr4Y7240IXrxDPsyFhRguTh2EIsmP4Qnth0enjb3H6q8a1D36MyVCreJk6IKbwYi1CuZy
 yegMO5awAR9AXOqATkVFPj2h2Lat7WLFs5RsC/5hpb3it2Rp0ULmEP3
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add nvmem cells for getting charge control thresholds if they have
been set previously.

Tested-by: Neil Armstrong <neil.armstrong@linaro.org> # on Thinkpad T14S OLED
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 arch/arm64/boot/dts/qcom/x1-crd.dtsi         |  7 +++++++
 arch/arm64/boot/dts/qcom/x1e80100-pmics.dtsi | 20 ++++++++++++++++++++
 2 files changed, 27 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1-crd.dtsi b/arch/arm64/boot/dts/qcom/x1-crd.dtsi
index c9f0d505267081af66b0973fe6c1e33832a2c86b..cd3c071624ce66f8c28ee4521fe3db8b737757a6 100644
--- a/arch/arm64/boot/dts/qcom/x1-crd.dtsi
+++ b/arch/arm64/boot/dts/qcom/x1-crd.dtsi
@@ -82,6 +82,13 @@ pmic-glink {
 				    <&tlmm 123 GPIO_ACTIVE_HIGH>,
 				    <&tlmm 125 GPIO_ACTIVE_HIGH>;
 
+		nvmem-cells = <&charge_limit_en>,
+			      <&charge_limit_end>,
+			      <&charge_limit_delta>;
+		nvmem-cell-names = "charge_limit_en",
+				   "charge_limit_end",
+				   "charge_limit_delta";
+
 		/* Left-side rear port */
 		connector@0 {
 			compatible = "usb-c-connector";
diff --git a/arch/arm64/boot/dts/qcom/x1e80100-pmics.dtsi b/arch/arm64/boot/dts/qcom/x1e80100-pmics.dtsi
index c02fd4d15c9649c222caaafa5ed2c777a10fb4f5..eb5562e4393c88faa16d9172ee2a1ceabef076ff 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-pmics.dtsi
+++ b/arch/arm64/boot/dts/qcom/x1e80100-pmics.dtsi
@@ -239,6 +239,26 @@ reboot_reason: reboot-reason@48 {
 			};
 		};
 
+		pmk8550_sdam_15: nvram@7e00 {
+			compatible = "qcom,spmi-sdam";
+			reg = <0x7e00>;
+			#address-cells = <1>;
+			#size-cells = <1>;
+			ranges = <0 0x7e00 0x100>;
+
+			charge_limit_en: charge-limit-en@73 {
+				reg = <0x73 0x1>;
+			};
+
+			charge_limit_end: charge-limit-end@75 {
+				reg = <0x75 0x1>;
+			};
+
+			charge_limit_delta: charge-limit-delta@76 {
+				reg = <0x76 0x1>;
+			};
+		};
+
 		pmk8550_gpios: gpio@8800 {
 			compatible = "qcom,pmk8550-gpio", "qcom,spmi-gpio";
 			reg = <0xb800>;

-- 
2.34.1

