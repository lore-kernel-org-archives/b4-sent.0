From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Tue, 23 Apr 2024 12:50:49 +0300
Subject: [PATCH v3 5/5] ARM: dts: BCM5301X: Conform to DTS Coding Style on
 ASUS RT-AC3100 & AC88U
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240423-for-soc-asus-rt-ac3200-ac5300-v3-5-23d33cfafe7a@arinc9.com>
References: <20240423-for-soc-asus-rt-ac3200-ac5300-v3-0-23d33cfafe7a@arinc9.com>
In-Reply-To: <20240423-for-soc-asus-rt-ac3200-ac5300-v3-0-23d33cfafe7a@arinc9.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Hauke Mehrtens <hauke@hauke-m.de>, Rafal Milecki <zajec5@gmail.com>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>
Cc: Tom Brautaset <tbrautaset@gmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713865858; l=5167;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=7L5W/7z1WpF8NCI8e+TnYZn6sscmCDy3pZyH1HtB4TY=;
 b=4cWPEzSSJNXKt801p2f2aFZ9J2U7DbqJ4jQ8ThzSDmM9xJDRIqCbAwmOM0n2jKuiLGogoEkL7
 f2X06SHj9LLCKUxF+booXR8f0cfre9vQuL/W7a6fF8aEuW51Rqovoe8
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reorder the nodes and properties to conform to the Devicetree Sources (DTS)
Coding Style.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 .../boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi | 92 +++++++++++-----------
 .../boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts   | 69 ++++++++--------
 2 files changed, 80 insertions(+), 81 deletions(-)

diff --git a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi
index 9c7efb1c44f1..2cfaaabc7a6a 100644
--- a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi
+++ b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi
@@ -10,9 +10,9 @@
 
 / {
 	memory@0 {
-		device_type = "memory";
 		reg = <0x00000000 0x08000000>,
 		      <0x88000000 0x18000000>;
+		device_type = "memory";
 	};
 
 	nvram@1c080000 {
@@ -20,6 +20,34 @@ nvram@1c080000 {
 		reg = <0x1c080000 0x00180000>;
 	};
 
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		button-led {
+			label = "Backlight";
+			linux,code = <KEY_BRIGHTNESS_ZERO>;
+			gpios = <&chipcommon 4 GPIO_ACTIVE_LOW>;
+		};
+
+		button-reset {
+			label = "Reset";
+			linux,code = <KEY_RESTART>;
+			gpios = <&chipcommon 11 GPIO_ACTIVE_LOW>;
+		};
+
+		button-wifi {
+			label = "Wi-Fi";
+			linux,code = <KEY_RFKILL>;
+			gpios = <&chipcommon 18 GPIO_ACTIVE_LOW>;
+		};
+
+		button-wps {
+			label = "WPS";
+			linux,code = <KEY_WPS_BUTTON>;
+			gpios = <&chipcommon 20 GPIO_ACTIVE_LOW>;
+		};
+	};
+
 	leds {
 		compatible = "gpio-leds";
 
@@ -66,32 +94,29 @@ led-wps {
 			gpios = <&chipcommon 19 GPIO_ACTIVE_LOW>;
 		};
 	};
+};
 
-	gpio-keys {
-		compatible = "gpio-keys";
-
-		button-led {
-			label = "Backlight";
-			linux,code = <KEY_BRIGHTNESS_ZERO>;
-			gpios = <&chipcommon 4 GPIO_ACTIVE_LOW>;
-		};
+&nandcs {
+	partitions {
+		compatible = "fixed-partitions";
+		#address-cells = <1>;
+		#size-cells = <1>;
 
-		button-reset {
-			label = "Reset";
-			linux,code = <KEY_RESTART>;
-			gpios = <&chipcommon 11 GPIO_ACTIVE_LOW>;
+		partition@0 {
+			reg = <0x00000000 0x00080000>;
+			label = "boot";
+			read-only;
 		};
 
-		button-wifi {
-			label = "Wi-Fi";
-			linux,code = <KEY_RFKILL>;
-			gpios = <&chipcommon 18 GPIO_ACTIVE_LOW>;
+		partition@80000 {
+			reg = <0x00080000 0x00180000>;
+			label = "nvram";
 		};
 
-		button-wps {
-			label = "WPS";
-			linux,code = <KEY_WPS_BUTTON>;
-			gpios = <&chipcommon 20 GPIO_ACTIVE_LOW>;
+		partition@200000 {
+			compatible = "brcm,trx";
+			reg = <0x00200000 0x07e00000>;
+			label = "firmware";
 		};
 	};
 };
@@ -141,28 +166,3 @@ &usb2 {
 &usb3_phy {
 	status = "okay";
 };
-
-&nandcs {
-	partitions {
-		compatible = "fixed-partitions";
-		#address-cells = <1>;
-		#size-cells = <1>;
-
-		partition@0 {
-			label = "boot";
-			reg = <0x00000000 0x00080000>;
-			read-only;
-		};
-
-		partition@80000 {
-			label = "nvram";
-			reg = <0x00080000 0x00180000>;
-		};
-
-		partition@200000 {
-			label = "firmware";
-			reg = <0x00200000 0x07e00000>;
-			compatible = "brcm,trx";
-		};
-	};
-};
diff --git a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts
index c78f0c7b137d..a197f447fd97 100644
--- a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts
+++ b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts
@@ -19,13 +19,34 @@ et1macaddr: et1macaddr {
 
 	switch {
 		compatible = "realtek,rtl8365mb";
-		/* 7 = MDIO (has input reads), 6 = MDC (clock, output only) */
 		mdc-gpios = <&chipcommon 6 GPIO_ACTIVE_HIGH>;
 		mdio-gpios = <&chipcommon 7 GPIO_ACTIVE_HIGH>;
 		reset-gpios = <&chipcommon 10 GPIO_ACTIVE_LOW>;
 		realtek,disable-leds;
 		dsa,member = <1 0>;
 
+		mdio {
+			compatible = "realtek,smi-mdio";
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			ethphy0: ethernet-phy@0 {
+				reg = <0>;
+			};
+
+			ethphy1: ethernet-phy@1 {
+				reg = <1>;
+			};
+
+			ethphy2: ethernet-phy@2 {
+				reg = <2>;
+			};
+
+			ethphy3: ethernet-phy@3 {
+				reg = <3>;
+			};
+		};
+
 		ports {
 			#address-cells = <1>;
 			#size-cells = <0>;
@@ -69,29 +90,21 @@ fixed-link {
 				};
 			};
 		};
+	};
+};
 
-		mdio {
-			compatible = "realtek,smi-mdio";
-			#address-cells = <1>;
-			#size-cells = <0>;
-
-			ethphy0: ethernet-phy@0 {
-				reg = <0>;
-			};
-
-			ethphy1: ethernet-phy@1 {
-				reg = <1>;
-			};
+&gmac0 {
+	status = "disabled";
+};
 
-			ethphy2: ethernet-phy@2 {
-				reg = <2>;
-			};
+&gmac1 {
+	nvmem-cells = <&et1macaddr 0>;
+	nvmem-cell-names = "mac-address";
+};
 
-			ethphy3: ethernet-phy@3 {
-				reg = <3>;
-			};
-		};
-	};
+&gmac2 {
+	nvmem-cells = <&et1macaddr 1>;
+	nvmem-cell-names = "mac-address";
 };
 
 &srab {
@@ -112,17 +125,3 @@ fixed-link {
 		};
 	};
 };
-
-&gmac0 {
-	status = "disabled";
-};
-
-&gmac1 {
-	nvmem-cells = <&et1macaddr 0>;
-	nvmem-cell-names = "mac-address";
-};
-
-&gmac2 {
-	nvmem-cells = <&et1macaddr 1>;
-	nvmem-cell-names = "mac-address";
-};

-- 
2.40.1

