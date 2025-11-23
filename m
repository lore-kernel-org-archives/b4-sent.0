From: Rudraksha Gupta <guptarud@gmail.com>
Date: Sat, 22 Nov 2025 22:44:46 -0800
Subject: [PATCH v3 5/5] ARM: dts: qcom: msm8960: expressatt: Add
 Accelerometer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251122-expressatt_nfc_accel_magn_light-v3-5-78d198632360@gmail.com>
References: <20251122-expressatt_nfc_accel_magn_light-v3-0-78d198632360@gmail.com>
In-Reply-To: <20251122-expressatt_nfc_accel_magn_light-v3-0-78d198632360@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763880283; l=813;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=OZ/k2+Tpqc0kQFWuC55IinM1SMWgAPprXjNRbIlFM6c=;
 b=BlIdU6mc/P35Oe1bo+hmxr0lNgn7Wm7mNIwuyg92DaOIU151cr6mMonnenrPB4VRAmi11zVPP
 5NpF6ey8cp5BxjBXU+QBQ0XjE030VdAtDGzeh8YHxrjK6j/zYOsbhj1
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Bosch Accelerometer.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index d32461fc58e9..cb7b56283f15 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -497,6 +497,13 @@ &gsbi12 {
 &gsbi12_i2c {
 	status = "okay";
 
+	accelerometer@18 {
+		compatible = "bosch,bma254";
+		reg = <0x18>;
+		vdd-supply = <&pm8921_l9>;
+		vddio-supply = <&pm8921_lvs4>;
+	};
+
 	magnetometer@2e {
 		compatible = "yamaha,yas532";
 		reg = <0x2e>;

-- 
2.52.0

