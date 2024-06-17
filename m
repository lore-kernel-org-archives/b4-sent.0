From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 17 Jun 2024 23:22:29 +0200
Subject: [PATCH v2 3/3] ARM: dts: qcom: msm8926-motorola-peregrine: Add
 framebuffer supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240617-peregrine-v2-3-c8835d2da7af@apitzsch.eu>
References: <20240617-peregrine-v2-0-c8835d2da7af@apitzsch.eu>
In-Reply-To: <20240617-peregrine-v2-0-c8835d2da7af@apitzsch.eu>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718659400; l=1664;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=AVdHAcobzRIw/Gjph8HbL/rVZTR3nwbn7PLGoz3cDhU=;
 b=9k+Mh7PCXSDNtEdLjjom8Dts6wyGgQpYZ7F8MIt3DlGAej3ybDYviyz2Y6i5tyzG+6A9M1ele
 LNNiBv6ieMzBYFFlr3FKXE3IBbdXyJSzs0pGFN9qhaVXtzr1BYT79bD
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add regulators used by the framebuffer of Motorola Moto G 4G (2013).

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 .../dts/qcom/qcom-msm8926-motorola-peregrine.dts   | 24 ++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts b/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
index cff9415baa46..376a33125941 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8926-motorola-peregrine.dts
@@ -29,6 +29,10 @@ framebuffer0: framebuffer@3200000 {
 			height = <1280>;
 			stride = <(720 * 3)>;
 			format = "r8g8b8";
+			vsp-supply = <&reg_lcd_pos>;
+			vsn-supply = <&reg_lcd_neg>;
+			vdd-supply = <&pm8226_l28>;
+			vddio-supply = <&vddio_disp_vreg>;
 		};
 	};
 
@@ -51,6 +55,18 @@ key-volume-up {
 		};
 	};
 
+	vddio_disp_vreg: regulator-vddio-disp {
+		compatible = "regulator-fixed";
+		regulator-name = "vddio_disp";
+		gpio = <&tlmm 34 GPIO_ACTIVE_HIGH>;
+		startup-delay-us = <300>;
+		enable-active-high;
+		regulator-boot-on;
+		vin-supply = <&pm8226_l8>;
+		pinctrl-0 = <&disp_vddio_default>;
+		pinctrl-names = "default";
+	};
+
 	reserved-memory {
 		#address-cells = <1>;
 		#size-cells = <1>;
@@ -342,6 +358,14 @@ accel_int_default: accel-int-default-state {
 		output-disable;
 	};
 
+	disp_vddio_default: disp-vddio-default-state {
+		pins = "gpio34";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+		output-high;
+	};
+
 	mag_int_default: mag-int-default-state {
 		pins = "gpio38";
 		function = "gpio";

-- 
2.45.2

