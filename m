From: Yedaya Katsman <yedaya.ka@gmail.com>
Date: Wed, 14 Jan 2026 11:31:08 +0200
Subject: [PATCH v2 3/3] arm64: dts: qcom: sm6125-xiaomi-laurel-sprout: Add
 Focaltech FT3518 touchscreen
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260114-touchscreen-patches-v2-3-4215f94c8aba@gmail.com>
References: <20260114-touchscreen-patches-v2-0-4215f94c8aba@gmail.com>
In-Reply-To: <20260114-touchscreen-patches-v2-0-4215f94c8aba@gmail.com>
To: SzczurekYT <szczurek@szczurek.yt>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Yedaya Katsman <yedaya.ka@gmail.com>, 
 =?utf-8?q?Kamil_Go=C5=82da?= <kamil.golda@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768383069; l=1681;
 i=yedaya.ka@gmail.com; s=20260113; h=from:subject:message-id;
 bh=MQJDxZRgMMx3ymnN/gSLrkJOIC2BOYzM4jCwI34QWOw=;
 b=nhZraJq9d/+bygyeCl7Xsit4hrgVv8uGiJcOqb/KP82EqguEJo1GsQmj/fuo+ip0ZI+QB+wB+
 SpQZQOsikcDAcTPidehMgtub4Eq68Ek4EisGQighE+vYhdTe7B+tutN
X-Developer-Key: i=yedaya.ka@gmail.com; a=ed25519;
 pk=CgNmxD3tYSws5dZfpmJfc6re/bV/f47veVijddHLytk=
X-Endpoint-Received: by B4 Relay for yedaya.ka@gmail.com/20260113 with auth_id=601
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree node for the Focaltech FT3518 touchscreen on
Xiaomi Mi A3 (laurel-sprout).

Enable qupv3_id_0 and i2c2 bus that the touchscreen is on.

Co-developed-by: Kamil Gołda <kamil.golda@protonmail.com>
Signed-off-by: Kamil Gołda <kamil.golda@protonmail.com>
Signed-off-by: Yedaya Katsman <yedaya.ka@gmail.com>
---
 .../boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts  | 34 ++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts b/arch/arm64/boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts
index 994fb0412fcbdf5466f87a325c48b697a37b514b..97feed708d3b6483eab72cfb0ae39be6f5ae3a11 100644
--- a/arch/arm64/boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts
+++ b/arch/arm64/boot/dts/qcom/sm6125-xiaomi-laurel-sprout.dts
@@ -119,6 +119,18 @@ active-config0 {
 			};
 		};
 	};
+
+	ts_vdd_supply: ts-vdd-supply {
+		compatible = "regulator-fixed";
+		regulator-name = "ts_vdd_supply";
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+
+		gpio = <&tlmm 83 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+
+		startup-delay-us = <70000>;
+	};
 };
 
 &hsusb_phy1 {
@@ -411,3 +423,25 @@ &usb3 {
 &usb3_dwc3 {
 	extcon = <&extcon_usb>;
 };
+
+&qupv3_id_0 {
+	status = "okay";
+};
+
+&i2c2 {
+	status = "okay";
+
+	touchscreen@38 {
+		compatible = "focaltech,ft3518";
+		reg = <0x38>;
+		interrupt-parent = <&tlmm>;
+		interrupts = <88 IRQ_TYPE_EDGE_FALLING>;
+
+		vcc-supply = <&ts_vdd_supply>;
+
+		reset-gpios = <&tlmm 87 GPIO_ACTIVE_LOW>;
+
+		touchscreen-size-x = <720>;
+		touchscreen-size-y = <1560>;
+	};
+};

-- 
2.52.0

