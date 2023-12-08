From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 08 Dec 2023 15:16:27 +0800
Subject: [PATCH v2 2/2] arm64: dts: amlogic: enable some nodes for board
 AQ222
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231208-s4-dts-v2-2-5a93fa356c5d@amlogic.com>
References: <20231208-s4-dts-v2-0-5a93fa356c5d@amlogic.com>
In-Reply-To: <20231208-s4-dts-v2-0-5a93fa356c5d@amlogic.com>
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702019788; l=1856;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=FPfG6Qexq9rPMZ1Ih+HGmxDokcf3sZTqaUTwsk9LhrI=;
 b=TFxXu9LH3b6E9JDbmpAZ++m2/kXsninEktll5WYBjpjcq4iwMqaSQLy3IOChg7F93LIiVrCfR
 vGEFzRjx+eQBxCdJgF3nIihzGVUXl5mqHOYM3yH21A9+s/2yWEB7pQT
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add reserved memory for board AQ222 which is used by ATF.
Enable NAND, SPICC nodes for board AQ222.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../boot/dts/amlogic/meson-s4-s805x2-aq222.dts     | 56 ++++++++++++++++++++++
 1 file changed, 56 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-s4-s805x2-aq222.dts b/arch/arm64/boot/dts/amlogic/meson-s4-s805x2-aq222.dts
index c1f322c73982..18789242f05f 100644
--- a/arch/arm64/boot/dts/amlogic/meson-s4-s805x2-aq222.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-s4-s805x2-aq222.dts
@@ -23,6 +23,17 @@ memory@0 {
 		reg = <0x0 0x0 0x0 0x40000000>;
 	};
 
+	reserved-memory {
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		/* 52 MiB reserved for ARM Trusted Firmware */
+		secmon_reserved: secmon@5000000 {
+			reg = <0x0 0x05000000 0x0 0x3400000>;
+			no-map;
+		};
+	};
 };
 
 &uart_B {
@@ -34,3 +45,48 @@ &ir {
 	pinctrl-0 = <&remote_pins>;
 	pinctrl-names = "default";
 };
+
+&nand {
+	status = "okay";
+	#address-cells = <1>;
+	#size-cells = <0>;
+
+	pinctrl-0 = <&nand_pins>;
+	pinctrl-names = "default";
+
+	nand@0 {
+		reg = <0>;
+		#address-cells = <1>;
+		#size-cells = <1>;
+
+		nand-on-flash-bbt;
+
+		partition@0 {
+			label = "boot";
+			reg = <0x0 0x00200000>;
+		};
+		partition@200000 {
+			label = "env";
+			reg = <0x00200000 0x00400000>;
+		};
+		partition@600000 {
+			label = "system";
+			reg = <0x00600000 0x00a00000>;
+		};
+		partition@1000000 {
+			label = "rootfs";
+			reg = <0x01000000 0x03000000>;
+		};
+		partition@4000000 {
+			label = "media";
+			reg = <0x04000000 0x8000000>;
+		};
+	};
+};
+
+&spicc0 {
+	status = "okay";
+	pinctrl-names = "default";
+	pinctrl-0 = <&spicc0_pins_x>;
+	cs-gpios = <&gpio GPIOX_10 GPIO_ACTIVE_LOW>;
+};

-- 
2.37.1

