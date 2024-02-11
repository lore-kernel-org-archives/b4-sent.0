From: Bjorn Andersson <quic_bjorande@quicinc.com>
Date: Sat, 10 Feb 2024 20:42:00 -0800
Subject: [PATCH 2/2] arm64: dts: qcom: sc8280xp-pmics: Define adc for
 temp-alarms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240210-sc8280xp-pmic-thermal-v1-2-a1c215a17d10@quicinc.com>
References: <20240210-sc8280xp-pmic-thermal-v1-0-a1c215a17d10@quicinc.com>
In-Reply-To: <20240210-sc8280xp-pmic-thermal-v1-0-a1c215a17d10@quicinc.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Bjorn Andersson <quic_bjorande@quicinc.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=2888;
 i=quic_bjorande@quicinc.com; h=from:subject:message-id;
 bh=K7rQywm19ZMJOEqTCjhdaKmYaGUNjH5+Bg7BEu/x3tU=;
 b=owEBgwJ8/ZANAwAIAQsfOT8Nma3FAcsmYgBlyFAXylL8zK5qj0ajAD7+jN8JFAwl72hjdDBAR
 evaltzZSm6JAkkEAAEIADMWIQQF3gPMXzXqTwlm1SULHzk/DZmtxQUCZchQFxUcYW5kZXJzc29u
 QGtlcm5lbC5vcmcACgkQCx85Pw2ZrcUwFhAAp6X19C1/915JgP6bSfzLi13eAGiI3IFxPXxGKP1
 Cg91LS/4pyv0OygvGP8BrhXm9R5fNyMIxjbhRAjazIfkWdPriIGdMEUUTBco+2BFrB4vEGkiXH+
 98DDKC4UErvnb3c0rodDZkvycqsbMKhKeo/8y/GeisD58oMWSqMV8nCv0lifkO2tD2IYak7MOcZ
 SZH9xN1q6p2YSYi5kerWUWrgjf1Q7OjRtYavFmBWn9+nPnvItCRNd2GW8/H72WOvtEHKHgjYT60
 1gTRNGZnk3L4sciH+5DRceJpD0GmA8uCJmWf2HPbc5KYai+ThNu2ieRcwGVMZ9rASSH7BOVkd9c
 VVkQCfHmq2aj7WtRcG4m9bRutSI9A7TyFIAEcJojJXP+E2esmq7xGRhnN7MjMnFEVVYc4C1G+5g
 +0naX0Myh24lJLzA7EcJK9D1BiW3Xwm1Hr7/UhFMccptwfZ2HJdZ9aFjcIeCM+HXlkSVsp8QCIh
 ZEQVCKJRrKdr3GKyhCmO3+3LlqJ1KkwWvTBZKIimsRrmI2hxIt9Qlk8aF9X+Kf4zc/YXQEsDJId
 7ZjtCI9mWgcIlOxY0NsWr8bhv8/rZyJRnnKBtf3I03q68HWiMqgQD1DFPDt85Uzl26X762jHzik
 jmEe1WS8LdIxgSvxVL5YpBKbgdEtK8gcnsbTalMyWtMs=
X-Developer-Key: i=quic_bjorande@quicinc.com; a=openpgp;
 fpr=05DE03CC5F35EA4F0966D5250B1F393F0D99ADC5
X-Endpoint-Received: by B4 Relay for quic_bjorande@quicinc.com/default with auth_id=118
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sc8280xp-pmics define the two thermal zones "pm8280-1-thermal" and
"pm8280-2-thermal", but the related temp-alarm instances are not tied to
any adc channels, and as such continuously report the bogus temperature
of 37C.

After previously defining these adc channels across all boards using
sc8280xp-pmics.dtsi, we can now add these references.

This does however mean that we have a non-disabled node referencing
default-disabled nodes, requiring each board to enable the pmk8280_vadc.
Avoid this by marking pmk8280_vadc okay.

Signed-off-by: Bjorn Andersson <quic_bjorande@quicinc.com>
---
 arch/arm64/boot/dts/qcom/sc8280xp-crd.dts                  | 4 ----
 arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts | 2 --
 arch/arm64/boot/dts/qcom/sc8280xp-pmics.dtsi               | 5 ++++-
 3 files changed, 4 insertions(+), 7 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-crd.dts b/arch/arm64/boot/dts/qcom/sc8280xp-crd.dts
index 22f10813aa3c..ffc4406422ae 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-crd.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-crd.dts
@@ -604,10 +604,6 @@ rtc_offset: rtc-offset@bc {
 	};
 };
 
-&pmk8280_vadc {
-	status = "okay";
-};
-
 &qup0 {
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts b/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
index ce2564a6c26e..ad42966c94e5 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
@@ -851,8 +851,6 @@ rtc_offset: rtc-offset@bc {
 };
 
 &pmk8280_vadc {
-	status = "okay";
-
 	channel@144 {
 		reg = <PM8350_ADC7_AMUX_THM1_100K_PU(1)>;
 		qcom,hw-settle-time = <200>;
diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-pmics.dtsi b/arch/arm64/boot/dts/qcom/sc8280xp-pmics.dtsi
index 58fea376f0e2..945de77911de 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-pmics.dtsi
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-pmics.dtsi
@@ -87,7 +87,6 @@ pmk8280_vadc: adc@3100 {
 			#address-cells = <1>;
 			#size-cells = <0>;
 			#io-channel-cells = <1>;
-			status = "disabled";
 
 			channel@3 {
 				reg = <PMK8350_ADC7_DIE_TEMP>;
@@ -160,6 +159,8 @@ pm8280_1_temp_alarm: temp-alarm@a00 {
 			compatible = "qcom,spmi-temp-alarm";
 			reg = <0xa00>;
 			interrupts-extended = <&spmi_bus 0x1 0xa 0x0 IRQ_TYPE_EDGE_BOTH>;
+			io-channels = <&pmk8280_vadc PM8350_ADC7_DIE_TEMP(1)>;
+			io-channel-names = "thermal";
 			#thermal-sensor-cells = <0>;
 		};
 
@@ -212,6 +213,8 @@ pm8280_2_temp_alarm: temp-alarm@a00 {
 			compatible = "qcom,spmi-temp-alarm";
 			reg = <0xa00>;
 			interrupts-extended = <&spmi_bus 0x2 0xa 0x0 IRQ_TYPE_EDGE_BOTH>;
+			io-channels = <&pmk8280_vadc PM8350_ADC7_DIE_TEMP(3)>;
+			io-channel-names = "thermal";
 			#thermal-sensor-cells = <0>;
 		};
 

-- 
2.43.0

