From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 23 Jul 2026 15:57:42 +0200
Subject: [PATCH 04/19] ARM: dts: update RN102 Linux DTS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-rn102-rn104-series-v1-4-7698d25df866@gmail.com>
References: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
In-Reply-To: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784815061; l=4076;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=BgY4qJyf3fh09obXlvqr22vPCRU9NrmhvUjxq/gi0GY=;
 b=hsusyw8JNtz4lbQqYvUoF1rVvTDY6Pt+pFNYPiMVrYyA4arMqO9RulmG2BXYnjQYNplBoPznq
 s0mAbMFX4GHCrcSUsXJhqq+kgr/roDfwYLDG6thHY/oJiKKI7I8cYGr
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 dts/src/arm/marvell/armada-370-netgear-rn102.dts | 114 ++++++++++++++---------
 1 file changed, 71 insertions(+), 43 deletions(-)

diff --git a/dts/src/arm/marvell/armada-370-netgear-rn102.dts b/dts/src/arm/marvell/armada-370-netgear-rn102.dts
index 079b37cf14..f1bad2a233 100644
--- a/dts/src/arm/marvell/armada-370-netgear-rn102.dts
+++ b/dts/src/arm/marvell/armada-370-netgear-rn102.dts
@@ -15,6 +15,10 @@ / {
 	model = "NETGEAR ReadyNAS 102";
 	compatible = "netgear,readynas-102", "marvell,armada370", "marvell,armada-370-xp";
 
+	aliases {
+		state = &state_nand;
+    };
+
 	chosen {
 		stdout-path = "serial0:115200n8";
 	};
@@ -54,7 +58,7 @@ ethernet@74000 {
 				phy-mode = "rgmii-id";
 			};
 
-			usb@50000 {
+            usb@50000 {
 				status = "okay";
 			};
 
@@ -153,10 +157,35 @@ backup-button {
 
 	gpio-poweroff {
 		compatible = "gpio-poweroff";
-		pinctrl-0 = <&poweroff>;
+		pinctrl-0 = <&poweroff_pin>;
 		pinctrl-names = "default";
 		gpios = <&gpio0 8 GPIO_ACTIVE_LOW>;
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
@@ -219,58 +248,57 @@ reset_button_pin: reset-button-pin {
 		marvell,function = "gpio";
 	};
 
-	poweroff: poweroff {
+	poweroff_pin: poweroff-pin {
 		marvell,pins = "mpp8";
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
+	
+	/* Use Hardware BCH ECC */
+	nand-ecc-strength = <4>;
+	nand-ecc-step-size = <512>;
+
+	partitions {
+		compatible = "fixed-partitions";
+		#address-cells = <1>;
+		#size-cells = <1>;
+		
+		partition@0 {
+			label = "bootloader";
+			reg = <0x0 0x400000>;		 /* 4MB */
+			//read-only;
+		};
 
-			partition@180000 {
-				label = "u-boot-env";
-				reg = <0x180000 0x20000>;    /* 128KB */
-				read-only;
-			};
+		partition@0x400000 {
+			label = "environment";
+			reg = <0x400000 0x80000>;    /* 0.5MB */
+			//read-only;
+		};
 
-			partition@200000 {
-				label = "uImage";
-				reg = <0x0200000 0x600000>;    /* 6MB */
-			};
+		backend_state_nand: partition@0x480000 {
+			label = "state";
+			reg = <0x480000 0x80000>;    /* 0.5MB */
+		};
 
-			partition@800000 {
-				label = "minirootfs";
-				reg = <0x0800000 0x400000>;    /* 4MB */
-			};
+		partition@0x500000 {
+			label = "kernel";
+			reg = <0x500000 0x1400000>;    /* 20MB */
+		};
 
-			/* Last MB is for the BBT, i.e. not writable */
-			partition@c00000 {
-				label = "ubifs";
-				reg = <0x0c00000 0x7400000>; /* 116MB */
-			};
+		partition@0x1900000 {
+			label = "minirootfs";
+			reg = <0x1900000 0x6000000>;    /* 100MB */
 		};
+
+		/* Last MB is for the BBT, i.e. not writable */
 	};
-};
+};
\ No newline at end of file

-- 
2.47.3

