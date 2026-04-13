From: Antony Kurniawan Soemardi <linux@smankusors.com>
Date: Tue, 14 Apr 2026 01:55:37 +0700
Subject: [PATCH 10/10] ARM: dts: qcom: msm8960: huashan: enable Wi-Fi and
 Bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260414-msm8960-wifi-v1-10-007fda9d6134@smankusors.com>
References: <20260414-msm8960-wifi-v1-0-007fda9d6134@smankusors.com>
In-Reply-To: <20260414-msm8960-wifi-v1-0-007fda9d6134@smankusors.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lee Jones <lee@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776106820; l=1159;
 i=linux@smankusors.com; s=20250609; h=from:subject:message-id;
 bh=w2QY1SWIjWYGcYn3nvZVk0yd85oYpHn7KLQBpKGh+S8=;
 b=7Kw5rMwOHVG5mwW0WdSfplxWpnAYtI67JA73FXq3/z1Tk2jl1Ws44/TE91NtoIrhO4G0F+mIn
 +pWaBCXX86SAcdqoeuxCrm3hx17zYKOpGmHmtZJylLNtm0Rtiax63oX
X-Developer-Key: i=linux@smankusors.com; a=ed25519;
 pk=65wTy06fJl2/h/EJwjr704YG+yjHFhZObJBWzzK+N00=
X-Endpoint-Received: by B4 Relay for linux@smankusors.com/20250609 with auth_id=733
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Wi-Fi and Bluetooth support for Sony Xperia SP.

Signed-off-by: Antony Kurniawan Soemardi <linux@smankusors.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960-sony-huashan.dts | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-sony-huashan.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-sony-huashan.dts
index 591dc837e600..79fa9bd038f2 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-sony-huashan.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-sony-huashan.dts
@@ -95,6 +95,25 @@ MATRIX_KEY(1, 1, KEY_CAMERA)
 	status = "okay";
 };
 
+&riva {
+	pinctrl-0 = <&riva_wlan_default_state>, <&riva_bt_default_state>;
+	pinctrl-1 = <&riva_wlan_sleep_state>, <&riva_bt_sleep_state>;
+	pinctrl-names = "default", "sleep";
+
+	vddcx-supply = <&pm8921_s3>;
+	vddmx-supply = <&pm8921_l24>;
+	vddpx-supply = <&pm8921_s4>;
+
+	status = "okay";
+
+	iris {
+		vdddig-supply = <&pm8921_lvs2>;
+		vddpa-supply = <&pm8921_l10>;
+		vddrfa-supply = <&pm8921_s2>;
+		vddxo-supply = <&pm8921_l4>;
+	};
+};
+
 &rpm {
 	regulators {
 		compatible = "qcom,rpm-pm8921-regulators";

-- 
2.34.1

