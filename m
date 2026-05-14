From: Antony Kurniawan Soemardi <linux@smankusors.com>
Date: Thu, 14 May 2026 21:08:39 +0700
Subject: [PATCH v2 10/10] ARM: dts: qcom: msm8960: huashan: enable Wi-Fi
 and Bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260514-msm8960-wifi-v2-10-7cbae45dab5e@smankusors.com>
References: <20260514-msm8960-wifi-v2-0-7cbae45dab5e@smankusors.com>
In-Reply-To: <20260514-msm8960-wifi-v2-0-7cbae45dab5e@smankusors.com>
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
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778767762; l=1040;
 i=linux@smankusors.com; s=20250609; h=from:subject:message-id;
 bh=SLa77ZNp7lfbDqaVc3OTTZcPOotiwNceDTW3KD4D7DQ=;
 b=wenOAgoSYUbFmEFqpoDXTncdQcdFpkHhnzibnktdaM3GvNB6AGKz2bc5M63fs3bDrT6o+scuJ
 dTpr8VSPUFTBkiyXBE/OUo1S/YQH4ROqu9QmvQoVMoSG4nFIjVMqhGu
X-Developer-Key: i=linux@smankusors.com; a=ed25519;
 pk=65wTy06fJl2/h/EJwjr704YG+yjHFhZObJBWzzK+N00=
X-Endpoint-Received: by B4 Relay for linux@smankusors.com/20250609 with auth_id=733
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Wi-Fi and Bluetooth support for Sony Xperia SP.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Antony Kurniawan Soemardi <linux@smankusors.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960-sony-huashan.dts | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-sony-huashan.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-sony-huashan.dts
index 591dc837e600..7d54ced3641f 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-sony-huashan.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-sony-huashan.dts
@@ -95,6 +95,21 @@ MATRIX_KEY(1, 1, KEY_CAMERA)
 	status = "okay";
 };
 
+&riva {
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

