From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 19 Nov 2025 23:14:44 -0800
Subject: [PATCH 3/4] ARM: dts: qcom: msm8960: expressatt: Add Magnetometer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-expressatt_nfc_accel_magn_light-v1-3-636f16f05cf4@gmail.com>
References: <20251119-expressatt_nfc_accel_magn_light-v1-0-636f16f05cf4@gmail.com>
In-Reply-To: <20251119-expressatt_nfc_accel_magn_light-v1-0-636f16f05cf4@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763622884; l=943;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=YhqxAzSOCOeCQlEI5U8jpQj+HTe6yqqN3vpsUK3rJ3c=;
 b=JpcQamOMZqyhAWTYeQpFuh+Nt3Xqhbyq9HmE7dgA+e5sWJJ9QrUPss12nOQ4tFzcjcmYboF6l
 bO2gRP/ZESOAdeV4dj6/Ld4yEMIMPn4gYs1PqyMnenjwBBi69PbC2Zh
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Yamaha magnetometer. Mount Matrix is left as a TODO.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts  | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 81806d7ca001..403bef67a148 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -490,3 +490,21 @@ &usb1 {
 	dr_mode = "otg";
 	status = "okay";
 };
+
+&gsbi12 {
+	qcom,mode = <GSBI_PROT_I2C>;
+	status = "okay";
+};
+
+&gsbi12_i2c {
+	status = "okay";
+
+	magnetometer@2e {
+		compatible = "yamaha,yas532";
+		reg = <0x2e>;
+		vdd-supply   = <&pm8921_l9>;
+		iovdd-supply = <&pm8921_lvs4>;
+
+		// TODO: Figure out Mount Matrix
+	};
+};

-- 
2.51.2

