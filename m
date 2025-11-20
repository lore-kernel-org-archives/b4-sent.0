From: Rudraksha Gupta <guptarud@gmail.com>
Date: Wed, 19 Nov 2025 23:14:45 -0800
Subject: [PATCH 4/4] ARM: dts: qcom: msm8960: expressatt: Add Accelerometer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-expressatt_nfc_accel_magn_light-v1-4-636f16f05cf4@gmail.com>
References: <20251119-expressatt_nfc_accel_magn_light-v1-0-636f16f05cf4@gmail.com>
In-Reply-To: <20251119-expressatt_nfc_accel_magn_light-v1-0-636f16f05cf4@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763622885; l=887;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=6ayiOr7JapmOLC4broKYTiOez9Grhv0EctruDrmHy5k=;
 b=jr+ybj1UXxg3Cy7st9H9R5i5BunAyujF8jZjp2M2CY9DT25oDfDOs5IaRKI6swYbc9mF6fFTa
 RpiHCHNRHw0AmDgQVeAuNXa6/tZpX8l8A+5M/086IjMLPNLDxKJ/Oap
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Bosch Accelerometer. Mount Matrix is left as a TODO.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 403bef67a148..5ae702693826 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -499,6 +499,15 @@ &gsbi12 {
 &gsbi12_i2c {
 	status = "okay";
 
+	accelerometer@18 {
+		compatible = "bosch,bma254";
+		reg = <0x18>;
+		vdd-supply = <&pm8921_l9>;
+		vddio-supply = <&pm8921_lvs4>;
+
+		// TODO: Figure out Mount Matrix
+	};
+
 	magnetometer@2e {
 		compatible = "yamaha,yas532";
 		reg = <0x2e>;

-- 
2.51.2

