From: Rudraksha Gupta <guptarud@gmail.com>
Date: Sat, 22 Nov 2025 22:44:45 -0800
Subject: [PATCH v3 4/5] ARM: dts: qcom: msm8960: expressatt: Add
 Magnetometer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251122-expressatt_nfc_accel_magn_light-v3-4-78d198632360@gmail.com>
References: <20251122-expressatt_nfc_accel_magn_light-v3-0-78d198632360@gmail.com>
In-Reply-To: <20251122-expressatt_nfc_accel_magn_light-v3-0-78d198632360@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763880283; l=1006;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=7jrbiFxqBdAClrq/n9H3dJIomUxZ8Xc6QvLk/kgFMvE=;
 b=wbS+WSnGl/oI+NymG4Y8ZNfeWCqCSE9EKuaivOoI9gIV39oVhM4/VQW7BvNKpHcmJ6AKAxF6u
 AvIaItD9rEJC6mB/GoVv2fksPA4rgxIKOFu1QY4n9InwbXoOP2NDcpq
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Yamaha magnetometer. Mount Matrix is left as a TODO.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
index 4f9b59db7bc3..d32461fc58e9 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8960-samsung-expressatt.dts
@@ -487,3 +487,22 @@ nfc@2b {
 		pinctrl-names = "default";
 	};
 };
+
+&gsbi12 {
+	qcom,mode = <GSBI_PROT_I2C>;
+
+	status = "okay";
+};
+
+&gsbi12_i2c {
+	status = "okay";
+
+	magnetometer@2e {
+		compatible = "yamaha,yas532";
+		reg = <0x2e>;
+		vdd-supply = <&pm8921_l9>;
+		iovdd-supply = <&pm8921_lvs4>;
+
+		/* TODO: Figure out Mount Matrix */
+	};
+};

-- 
2.52.0

