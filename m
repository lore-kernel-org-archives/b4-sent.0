From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Fri, 19 Sep 2025 11:18:50 +0800
Subject: [PATCH v6 1/2] arm64: dts: qcom: x1e80100-crd: Add charge limit
 nvmem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250919-qcom_battmgr_update_new-v6-1-ed5c38867614@oss.qualcomm.com>
References: <20250919-qcom_battmgr_update_new-v6-0-ed5c38867614@oss.qualcomm.com>
In-Reply-To: <20250919-qcom_battmgr_update_new-v6-0-ed5c38867614@oss.qualcomm.com>
To: kernel@oss.qualcomm.com, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sebastian Reichel <sre@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 Fenglin Wu <fenglin.wu@oss.qualcomm.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758251938; l=2081;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=nPLGHoTJ5NTWoHSd8PH9bD21pqqTFHYPJjavOYsTnQM=;
 b=Qp3/B+LF3wqioqgmabrMHJVOowVh8ukpc4RgSqGleDq4wKLqjAuYJnP6TjFOGdig2SSHGFqzv
 rwXgC4/m20nCC4bkKA4hSx4apR2QwABRpioEVkbFdc4+s5MU9s9/qlq
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
index e3888bc143a0aaae23c92d400d48ea94423e0366..cc4994f890f83540c4fb238811bc879ac9356256 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-pmics.dtsi
+++ b/arch/arm64/boot/dts/qcom/x1e80100-pmics.dtsi
@@ -240,6 +240,26 @@ reboot_reason: reboot-reason@48 {
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

