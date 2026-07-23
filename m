From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 23 Jul 2026 15:57:48 +0200
Subject: [PATCH 10/19] ARM: dts: update RN104 Linux DTS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-rn102-rn104-series-v1-10-7698d25df866@gmail.com>
References: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
In-Reply-To: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784815061; l=6636;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=45aTUSNmhAoWzf1SPHmz7JXpUIPYIhGMeePCGmP1Wjc=;
 b=AtnSmE9+tSPaAyR1i0J5r6dBPshBidaOi+h1gEveLsTVHpIpJVPqnDbYbr9yKJfyfpF8LP2El
 WT3TtAxMth4CE4Vt0YhG6Fi1LYubMDL+jfqPMhEImwWo+25DE/KAQfI
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 dts/src/arm/marvell/armada-370-netgear-rn104.dts | 173 ++++++++++++++---------
 1 file changed, 104 insertions(+), 69 deletions(-)

diff --git a/dts/src/arm/marvell/armada-370-netgear-rn104.dts b/dts/src/arm/marvell/armada-370-netgear-rn104.dts
index d752ac1d7b..d7cc0549f4 100644
--- a/dts/src/arm/marvell/armada-370-netgear-rn104.dts
+++ b/dts/src/arm/marvell/armada-370-netgear-rn104.dts
@@ -15,6 +15,10 @@ / {
 	model = "NETGEAR ReadyNAS 104";
 	compatible = "netgear,readynas-104", "marvell,armada370", "marvell,armada-370-xp";
 
+	aliases {
+		state = &state_nand;
+    };
+
 	chosen {
 		stdout-path = "serial0:115200n8";
 	};
@@ -40,6 +44,12 @@ serial@12000 {
 				status = "okay";
 			};
 
+			/* eSATA interface */
+			sata@a0000 {
+				nr-ports = <1>;
+				status = "okay";
+			};
+
 			ethernet@70000 {
 				pinctrl-0 = <&ge0_rgmii_pins>;
 				pinctrl-names = "default";
@@ -103,15 +113,10 @@ g762_clk: g762-oscillator {
 
 	gpio-leds {
 		compatible = "gpio-leds";
-		pinctrl-0 = <&backup_led_pin &power_led_pin>;
+		pinctrl-0 = <&power_led_pin
+			     &backup_led_pin>;
 		pinctrl-names = "default";
 
-		blue-backup-led {
-			label = "rn104:blue:backup";
-			gpios = <&gpio1 31 GPIO_ACTIVE_HIGH>;
-			default-state = "off";
-		};
-
 		blue-power-led {
 			label = "rn104:blue:pwr";
 			gpios = <&gpio2 0 GPIO_ACTIVE_LOW>;
@@ -141,6 +146,12 @@ blue-sata4-led {
 			gpios = <&pca9554 3 GPIO_ACTIVE_LOW>;
 			default-state = "off";
 		};
+
+		blue-backup-led {
+			label = "rn104:blue:backup";
+			gpios = <&gpio1 31 GPIO_ACTIVE_HIGH>;
+			default-state = "off";
+		};
 	};
 
 	auxdisplay {
@@ -159,17 +170,11 @@ auxdisplay {
 
 	gpio-keys {
 		compatible = "gpio-keys";
-		pinctrl-0 = <&backup_button_pin
-			     &power_button_pin
-			     &reset_button_pin>;
+		pinctrl-0 = <&power_button_pin
+			     &reset_button_pin
+			     &backup_button_pin>;
 		pinctrl-names = "default";
 
-		backup-button {
-			label = "Backup Button";
-			linux,code = <KEY_COPY>;
-			gpios = <&gpio1 20 GPIO_ACTIVE_LOW>;
-		};
-
 		power-button {
 			label = "Power Button";
 			linux,code = <KEY_POWER>;
@@ -181,6 +186,12 @@ reset-button {
 			linux,code = <KEY_RESTART>;
 			gpios = <&gpio2 1 GPIO_ACTIVE_LOW>;
 		};
+
+		backup-button {
+			label = "Backup Button";
+			linux,code = <KEY_COPY>;
+			gpios = <&gpio1 20 GPIO_ACTIVE_LOW>;
+		};
 	};
 
 	gpio-poweroff {
@@ -189,18 +200,43 @@ gpio-poweroff {
 		pinctrl-names = "default";
 		gpios = <&gpio1 28 GPIO_ACTIVE_LOW>;
 	};
+
+	/* configure nand partition to store barebox environment */
+	environment {
+      compatible = "barebox,environment";
+      device-path = &nand_controller, "partname:environment";
+	};
+
+	/* configure nand partition to store barebox-state backend */
+	state_nand: nand_state_memory {
+        #address-cells = <1>;
+        #size-cells = <1>;
+        compatible = "barebox,state";
+        magic = <0xab67421f>;
+        backend-type = "raw";
+        backend = <&backend_state_nand>;
+        backend-storage-type = "circular";
+		backend-stridesize = <32>;
+
+        
+        variable@0 {
+                reg = <0x0 0x1>;
+                type ="uint8";
+                default = <0x1>;
+        };
+	};
 };
 
 &pciec {
 	status = "okay";
 
-	/* Connected to FL1009 USB 3.0 controller */
+	/* Connected to Marvell 88SE9170 SATA controller */
 	pcie@1,0 {
 		/* Port 0, Lane 0 */
 		status = "okay";
 	};
 
-	/* Connected to Marvell 88SE9215 SATA controller */
+	/* Connected to FL1009 USB 3.0 controller */
 	pcie@2,0 {
 		/* Port 1, Lane 0 */
 		status = "okay";
@@ -220,8 +256,13 @@ phy1: ethernet-phy@1 { /* Marvell 88E1318 */
 };
 
 &pinctrl {
-	poweroff: poweroff {
-		marvell,pins = "mpp60";
+	power_led_pin: power-led-pin {
+		marvell,pins = "mpp64";
+		marvell,function = "gpio";
+	};
+
+	backup_led_pin: backup-led-pin {
+		marvell,pins = "mpp63";
 		marvell,function = "gpio";
 	};
 
@@ -235,68 +276,62 @@ power_button_pin: power-button-pin {
 		marvell,function = "gpio";
 	};
 
-	backup_led_pin: backup-led-pin {
-		marvell,pins = "mpp63";
-		marvell,function = "gpio";
-	};
-
-	power_led_pin: power-led-pin {
-		marvell,pins = "mpp64";
+	reset_button_pin: reset-button-pin {
+		marvell,pins = "mpp65";
 		marvell,function = "gpio";
 	};
 
-	reset_button_pin: reset-button-pin {
-		marvell,pins = "mpp65";
+	poweroff_pin: poweroff-pin {
+		marvell,pins = "mpp60";
 		marvell,function = "gpio";
 	};
 };
 
 &nand_controller {
+	compatible = "marvell,armada370-nand", "marvell,pxa3xx-nand";
 	status = "okay";
 
-	nand@0 {
-		reg = <0>;
-		label = "pxa3xx_nand-0";
-		nand-rb = <0>;
-		marvell,nand-keep-config;
-		nand-on-flash-bbt;
-
-		/* Use Hardware BCH ECC */
-		nand-ecc-strength = <4>;
-		nand-ecc-step-size = <512>;
-
-		partitions {
-			compatible = "fixed-partitions";
-			#address-cells = <1>;
-			#size-cells = <1>;
-
-			partition@0 {
-				label = "u-boot";
-				reg = <0x0000000 0x180000>;  /* 1.5MB */
-				read-only;
-			};
+	label = <&nand_controller>;
+	nand-rb = <0>;
+	marvell,nand-keep-config;
+	nand-on-flash-bbt;
 
-			partition@180000 {
-				label = "u-boot-env";
-				reg = <0x180000 0x20000>;    /* 128KB */
-				read-only;
-			};
+	/* Use Hardware BCH ECC */
+	nand-ecc-strength = <4>;
+	nand-ecc-step-size = <512>;
 
-			partition@200000 {
-				label = "uImage";
-				reg = <0x0200000 0x600000>;    /* 6MB */
-			};
+	partitions {
+		compatible = "fixed-partitions";
+		#address-cells = <1>;
+		#size-cells = <1>;
 
-			partition@800000 {
-				label = "minirootfs";
-				reg = <0x0800000 0x400000>;    /* 4MB */
-			};
+		partition@0 {
+			label = "bootloader";
+			reg = <0x0 0x400000>;		 /* 4MB */
+			//read-only;
+		};
 
-			/* Last MB is for the BBT, i.e. not writable */
-			partition@c00000 {
-				label = "ubifs";
-				reg = <0x0c00000 0x7400000>; /* 116MB */
-			};
+		partition@0x400000 {
+			label = "environment";
+			reg = <0x400000 0x80000>;    /* 0.5MB */
+			//read-only;
 		};
+
+		backend_state_nand: partition@0x480000 {
+			label = "state";
+			reg = <0x480000 0x80000>;    /* 0.5MB */
+		};
+
+		partition@0x500000 {
+			label = "kernel";
+			reg = <0x500000 0x1400000>;    /* 20MB */
+		};
+
+		partition@0x1900000 {
+			label = "minirootfs";
+			reg = <0x1900000 0x6000000>;    /* 100MB */
+		};
+
+		/* Last MB is for the BBT, i.e. not writable */
 	};
-};
+};
\ No newline at end of file

-- 
2.47.3

