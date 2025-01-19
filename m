From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sun, 19 Jan 2025 15:50:52 +0100
Subject: [PATCH 2/2] arm64: dts: qcom: x1e80100-vivobook-s15: Enable
 micro-sd card reader
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250119-usb_a_micro_sd-v1-2-01eb7502ae05@hotmail.com>
References: <20250119-usb_a_micro_sd-v1-0-01eb7502ae05@hotmail.com>
In-Reply-To: <20250119-usb_a_micro_sd-v1-0-01eb7502ae05@hotmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737298255; l=1805;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=qEagHCN4mp21iK7xTZ9rdbXZ95q3ftiIVYE+wWP/Qys=;
 b=mRJxbTQ8UQcOnifr4c0sNJ1GMXjvTA8gQs78OsAvmkTEWPbKTcgqhafeEaHusblvuEiGlfGDs
 P8ZZWl3jTh3CORgC+JAoXa7bCIkJuzZ2GCKOrDNhlW0soF/ERKS17Dg
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The asus vivobook s15 has a micro-sd card reader attached to usb_2.

Enable usb_2 to enable this reader.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 39 ++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
index b66d03ee3ff30561e8665be6ad34919f89a79572..fb9567817be6f887c9214cafbfbabda8b8cb8203 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-asus-vivobook-s15.dts
@@ -422,6 +422,20 @@ keyboard@3a {
 		wakeup-source;
 	};
 
+	eusb5_repeater: redriver@43 {
+		compatible = "nxp,ptn3222";
+		reg = <0x43>;
+		#phy-cells = <0>;
+
+		vdd3v3-supply = <&vreg_l13b_3p0>;
+		vdd1v8-supply = <&vreg_l4b_1p8>;
+
+		reset-gpios = <&tlmm 7 GPIO_ACTIVE_LOW>;
+
+		pinctrl-0 = <&eusb5_reset_n>;
+		pinctrl-names = "default";
+	};
+
 	eusb3_repeater: redriver@47 {
 		compatible = "nxp,ptn3222";
 		reg = <0x47>;
@@ -620,6 +634,14 @@ eusb3_reset_n: eusb3-reset-n-state {
 		output-low;
 	};
 
+	eusb5_reset_n: eusb5-reset-n-state {
+		pins = "gpio7";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-pull-up;
+		output-low;
+	};
+
 	eusb6_reset_n: eusb6-reset-n-state {
 		pins = "gpio184";
 		function = "gpio";
@@ -764,6 +786,23 @@ &usb_1_ss1_qmpphy_out {
 	remote-endpoint = <&pmic_glink_ss1_ss_in>;
 };
 
+&usb_2 {
+	status = "okay";
+};
+
+&usb_2_dwc3 {
+	dr_mode = "host";
+};
+
+&usb_2_hsphy {
+	vdd-supply = <&vreg_l2e_0p8>;
+	vdda12-supply = <&vreg_l3e_1p2>;
+
+	phys = <&eusb5_repeater>;
+
+	status = "okay";
+};
+
 &usb_mp {
 	status = "okay";
 };

-- 
2.47.1

