From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Fri, 24 Feb 2023 11:20:08 +0100
Subject: [PATCH RFC 3/4] arm64: dts: apple: t8103: Add touchbar bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230223-z2-for-ml-v1-3-028f2b85dc15@gmail.com>
References: <20230223-z2-for-ml-v1-0-028f2b85dc15@gmail.com>
In-Reply-To: <20230223-z2-for-ml-v1-0-028f2b85dc15@gmail.com>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 - <asahi@lists.linux.dev>, Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677234010; l=2182;
 i=fnkl.kernel@gmail.com; s=20230213; h=from:subject:message-id;
 bh=n1LEbnJGNHnfsCpIN9s17ImMS20Dap8uFST/5P947LI=;
 b=Z+MkwSkt7mmaoKRcS+hOzhrNIBUyg7rGRKE1Q6QyT8HRmCd/0mfzlyW5k8sACQITrZ5uyl2/f
 jbjdkjOq4GqB7VFI+IfxLDh2QXfjOG+yN3qg8/5YwX3qArspaR0+xXE
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=7LFSAJtxIWAs9LzCIyX0sSvCZy2wQTyEIu1zch6o804=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20230213 with auth_id=28
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds device tree entries for the touchbar digitizer

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 arch/arm64/boot/dts/apple/t8103-j293.dts | 20 ++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8103.dtsi     | 12 ++++++++++++
 2 files changed, 32 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8103-j293.dts b/arch/arm64/boot/dts/apple/t8103-j293.dts
index 151074109a11..c369493b1c06 100644
--- a/arch/arm64/boot/dts/apple/t8103-j293.dts
+++ b/arch/arm64/boot/dts/apple/t8103-j293.dts
@@ -15,6 +15,9 @@
 / {
 	compatible = "apple,j293", "apple,t8103", "apple,arm-platform";
 	model = "Apple MacBook Pro (13-inch, M1, 2020)";
+	aliases {
+		touchbar0 = &touchbar0;
+	};
 };
 
 &bluetooth0 {
@@ -25,6 +28,23 @@ &wifi0 {
 	brcm,board-type = "apple,honshu";
 };
 
+&spi0 {
+	status = "okay";
+
+	touchbar0: touchbar@0 {
+		compatible = "apple,z2-touchscreen";
+		reg = <0>;
+		spi-max-frequency = <11500000>;
+		reset-gpios = <&pinctrl_ap 139 0>;
+		cs-gpios = <&pinctrl_ap 109 0>;
+		interrupts-extended = <&pinctrl_ap 194 IRQ_TYPE_EDGE_FALLING>;
+		firmware-name = "apple/dfrmtfw-j293.bin";
+		touchscreen-size-x = <23045>;
+		touchscreen-size-y = <640>;
+		apple,z2-device-name = "MacBookPro17,1 Touch Bar";
+	};
+};
+
 /*
  * Remove unused PCIe ports and disable the associated DARTs.
  */
diff --git a/arch/arm64/boot/dts/apple/t8103.dtsi b/arch/arm64/boot/dts/apple/t8103.dtsi
index 9859219699f4..70d3183f72bf 100644
--- a/arch/arm64/boot/dts/apple/t8103.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103.dtsi
@@ -432,6 +432,18 @@ i2c4: i2c@235020000 {
 			status = "disabled"; /* only used in J293 */
 		};
 
+		spi0: spi@235100000 {
+			compatible = "apple,t8103-spi", "apple,spi";
+			reg = <0x2 0x35100000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 614 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&clk_200m>;
+			power-domains = <&ps_spi0>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled"; /* only used in J293 */
+		};
+
 		serial0: serial@235200000 {
 			compatible = "apple,s5l-uart";
 			reg = <0x2 0x35200000 0x0 0x1000>;

-- 
Git-137.1)

