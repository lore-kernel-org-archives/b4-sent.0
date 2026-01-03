From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sat, 03 Jan 2026 19:54:06 +0100
Subject: [PATCH v2 2/5] powerpc: dts: mpc8315erdb: Use IRQ_TYPE_* macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260103-mpc83xx-cleanup-v2-2-b2a13c0a0d63@posteo.net>
References: <20260103-mpc83xx-cleanup-v2-0-b2a13c0a0d63@posteo.net>
In-Reply-To: <20260103-mpc83xx-cleanup-v2-0-b2a13c0a0d63@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767466660; l=9600;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=qJSNJfVmiDZG+g6KBxDQ/n/7zXxMj4agDbro7jKlVcE=;
 b=ezJaCNs8FJEtTao+ZSRrR2B8jYoBByxnxkLgCDCha2WEzaXyVShfdnTTmuRWn099peT3JP6dI
 tejbOFZNYp4ANmzOosDWgwYQJe3RuJIcfAcFzJSTjDf0S3Ky1aNcQhD
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This increases readability, because "0x8" isn't very descriptive.

mpc8315erdb.dtb remains identical after this patch.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/mpc8315erdb.dts | 111 ++++++++++++++++++----------------
 1 file changed, 59 insertions(+), 52 deletions(-)

diff --git a/arch/powerpc/boot/dts/mpc8315erdb.dts b/arch/powerpc/boot/dts/mpc8315erdb.dts
index a8f68d6e50b0dd..1957b6687b2987 100644
--- a/arch/powerpc/boot/dts/mpc8315erdb.dts
+++ b/arch/powerpc/boot/dts/mpc8315erdb.dts
@@ -50,7 +50,7 @@ localbus@e0005000 {
 		#size-cells = <1>;
 		compatible = "fsl,mpc8315-elbc", "fsl,elbc", "simple-bus";
 		reg = <0xe0005000 0x1000>;
-		interrupts = <77 0x8>;
+		interrupts = <77 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-parent = <&ipic>;
 
 		// CS0 and CS1 are swapped when
@@ -112,7 +112,7 @@ i2c@3000 {
 			cell-index = <0>;
 			compatible = "fsl-i2c";
 			reg = <0x3000 0x100>;
-			interrupts = <14 0x8>;
+			interrupts = <14 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 			dfsrr;
 			rtc@68 {
@@ -133,7 +133,7 @@ spi@7000 {
 			cell-index = <0>;
 			compatible = "fsl,spi";
 			reg = <0x7000 0x1000>;
-			interrupts = <16 0x8>;
+			interrupts = <16 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 			mode = "cpu";
 		};
@@ -145,35 +145,35 @@ dma@82a8 {
 			reg = <0x82a8 4>;
 			ranges = <0 0x8100 0x1a8>;
 			interrupt-parent = <&ipic>;
-			interrupts = <71 8>;
+			interrupts = <71 IRQ_TYPE_LEVEL_LOW>;
 			cell-index = <0>;
 			dma-channel@0 {
 				compatible = "fsl,mpc8315-dma-channel", "fsl,elo-dma-channel";
 				reg = <0 0x80>;
 				cell-index = <0>;
 				interrupt-parent = <&ipic>;
-				interrupts = <71 8>;
+				interrupts = <71 IRQ_TYPE_LEVEL_LOW>;
 			};
 			dma-channel@80 {
 				compatible = "fsl,mpc8315-dma-channel", "fsl,elo-dma-channel";
 				reg = <0x80 0x80>;
 				cell-index = <1>;
 				interrupt-parent = <&ipic>;
-				interrupts = <71 8>;
+				interrupts = <71 IRQ_TYPE_LEVEL_LOW>;
 			};
 			dma-channel@100 {
 				compatible = "fsl,mpc8315-dma-channel", "fsl,elo-dma-channel";
 				reg = <0x100 0x80>;
 				cell-index = <2>;
 				interrupt-parent = <&ipic>;
-				interrupts = <71 8>;
+				interrupts = <71 IRQ_TYPE_LEVEL_LOW>;
 			};
 			dma-channel@180 {
 				compatible = "fsl,mpc8315-dma-channel", "fsl,elo-dma-channel";
 				reg = <0x180 0x28>;
 				cell-index = <3>;
 				interrupt-parent = <&ipic>;
-				interrupts = <71 8>;
+				interrupts = <71 IRQ_TYPE_LEVEL_LOW>;
 			};
 		};
 
@@ -183,7 +183,7 @@ usb@23000 {
 			#address-cells = <1>;
 			#size-cells = <0>;
 			interrupt-parent = <&ipic>;
-			interrupts = <38 0x8>;
+			interrupts = <38 IRQ_TYPE_LEVEL_LOW>;
 			phy_type = "utmi";
 		};
 
@@ -197,7 +197,9 @@ enet0: ethernet@24000 {
 			reg = <0x24000 0x1000>;
 			ranges = <0x0 0x24000 0x1000>;
 			local-mac-address = [ 00 00 00 00 00 00 ];
-			interrupts = <32 0x8 33 0x8 34 0x8>;
+			interrupts = <32 IRQ_TYPE_LEVEL_LOW>,
+				     <33 IRQ_TYPE_LEVEL_LOW>,
+				     <34 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 			tbi-handle = <&tbi0>;
 			phy-handle = < &phy0 >;
@@ -238,7 +240,9 @@ enet1: ethernet@25000 {
 			reg = <0x25000 0x1000>;
 			ranges = <0x0 0x25000 0x1000>;
 			local-mac-address = [ 00 00 00 00 00 00 ];
-			interrupts = <35 0x8 36 0x8 37 0x8>;
+			interrupts = <35 IRQ_TYPE_LEVEL_LOW>,
+				     <36 IRQ_TYPE_LEVEL_LOW>,
+				     <37 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 			tbi-handle = <&tbi1>;
 			phy-handle = < &phy1 >;
@@ -263,7 +267,7 @@ serial0: serial@4500 {
 			compatible = "fsl,ns16550", "ns16550";
 			reg = <0x4500 0x100>;
 			clock-frequency = <133333333>;
-			interrupts = <9 0x8>;
+			interrupts = <9 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 		};
 
@@ -273,7 +277,7 @@ serial1: serial@4600 {
 			compatible = "fsl,ns16550", "ns16550";
 			reg = <0x4600 0x100>;
 			clock-frequency = <133333333>;
-			interrupts = <10 0x8>;
+			interrupts = <10 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 		};
 
@@ -282,7 +286,7 @@ crypto@30000 {
 				     "fsl,sec2.4", "fsl,sec2.2", "fsl,sec2.1",
 				     "fsl,sec2.0";
 			reg = <0x30000 0x10000>;
-			interrupts = <11 0x8>;
+			interrupts = <11 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 			fsl,num-channels = <4>;
 			fsl,channel-fifo-len = <24>;
@@ -294,7 +298,7 @@ sata@18000 {
 			compatible = "fsl,mpc8315-sata", "fsl,pq-sata";
 			reg = <0x18000 0x1000>;
 			cell-index = <1>;
-			interrupts = <44 0x8>;
+			interrupts = <44 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 		};
 
@@ -302,14 +306,17 @@ sata@19000 {
 			compatible = "fsl,mpc8315-sata", "fsl,pq-sata";
 			reg = <0x19000 0x1000>;
 			cell-index = <2>;
-			interrupts = <45 0x8>;
+			interrupts = <45 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 		};
 
 		gtm1: timer@500 {
 			compatible = "fsl,mpc8315-gtm", "fsl,gtm";
 			reg = <0x500 0x100>;
-			interrupts = <90 8 78 8 84 8 72 8>;
+			interrupts = <90 IRQ_TYPE_LEVEL_LOW>,
+				     <78 IRQ_TYPE_LEVEL_LOW>,
+				     <84 IRQ_TYPE_LEVEL_LOW>,
+				     <72 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 			clock-frequency = <133333333>;
 		};
@@ -317,16 +324,16 @@ gtm1: timer@500 {
 		timer@600 {
 			compatible = "fsl,mpc8315-gtm", "fsl,gtm";
 			reg = <0x600 0x100>;
-			interrupts = <91 8 79 8 85 8 73 8>;
+			interrupts = <91 IRQ_TYPE_LEVEL_LOW>,
+				     <79 IRQ_TYPE_LEVEL_LOW>,
+				     <85 IRQ_TYPE_LEVEL_LOW>,
+				     <73 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 			clock-frequency = <133333333>;
 		};
 
 		/* IPIC
-		 * interrupts cell = <intr #, sense>
-		 * sense values match linux IORESOURCE_IRQ_* defines:
-		 * sense == 8: Level, low assertion
-		 * sense == 2: Edge, high-to-low change
+		 * interrupts cell = <intr #, type>
 		 */
 		ipic: interrupt-controller@700 {
 			interrupt-controller;
@@ -340,14 +347,14 @@ ipic-msi@7c0 {
 			compatible = "fsl,ipic-msi";
 			reg = <0x7c0 0x40>;
 			msi-available-ranges = <0 0x100>;
-			interrupts = <0x43 0x8
-				      0x4  0x8
-				      0x51 0x8
-				      0x52 0x8
-				      0x56 0x8
-				      0x57 0x8
-				      0x58 0x8
-				      0x59 0x8>;
+			interrupts = <0x43 IRQ_TYPE_LEVEL_LOW
+				      0x4  IRQ_TYPE_LEVEL_LOW
+				      0x51 IRQ_TYPE_LEVEL_LOW
+				      0x52 IRQ_TYPE_LEVEL_LOW
+				      0x56 IRQ_TYPE_LEVEL_LOW
+				      0x57 IRQ_TYPE_LEVEL_LOW
+				      0x58 IRQ_TYPE_LEVEL_LOW
+				      0x59 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = < &ipic >;
 		};
 
@@ -355,7 +362,7 @@ pmc: power@b00 {
 			compatible = "fsl,mpc8315-pmc", "fsl,mpc8313-pmc",
 				     "fsl,mpc8349-pmc";
 			reg = <0xb00 0x100 0xa00 0x100>;
-			interrupts = <80 8>;
+			interrupts = <80 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 			fsl,mpc8313-wakeup-timer = <&gtm1>;
 		};
@@ -374,24 +381,24 @@ pci0: pci@e0008500 {
 		interrupt-map-mask = <0xf800 0x0 0x0 0x7>;
 		interrupt-map = <
 				/* IDSEL 0x0E -mini PCI */
-				 0x7000 0x0 0x0 0x1 &ipic 18 0x8
-				 0x7000 0x0 0x0 0x2 &ipic 18 0x8
-				 0x7000 0x0 0x0 0x3 &ipic 18 0x8
-				 0x7000 0x0 0x0 0x4 &ipic 18 0x8
+				 0x7000 0x0 0x0 0x1 &ipic 18 IRQ_TYPE_LEVEL_LOW
+				 0x7000 0x0 0x0 0x2 &ipic 18 IRQ_TYPE_LEVEL_LOW
+				 0x7000 0x0 0x0 0x3 &ipic 18 IRQ_TYPE_LEVEL_LOW
+				 0x7000 0x0 0x0 0x4 &ipic 18 IRQ_TYPE_LEVEL_LOW
 
 				/* IDSEL 0x0F -mini PCI */
-				 0x7800 0x0 0x0 0x1 &ipic 17 0x8
-				 0x7800 0x0 0x0 0x2 &ipic 17 0x8
-				 0x7800 0x0 0x0 0x3 &ipic 17 0x8
-				 0x7800 0x0 0x0 0x4 &ipic 17 0x8
+				 0x7800 0x0 0x0 0x1 &ipic 17 IRQ_TYPE_LEVEL_LOW
+				 0x7800 0x0 0x0 0x2 &ipic 17 IRQ_TYPE_LEVEL_LOW
+				 0x7800 0x0 0x0 0x3 &ipic 17 IRQ_TYPE_LEVEL_LOW
+				 0x7800 0x0 0x0 0x4 &ipic 17 IRQ_TYPE_LEVEL_LOW
 
 				/* IDSEL 0x10 - PCI slot */
-				 0x8000 0x0 0x0 0x1 &ipic 48 0x8
-				 0x8000 0x0 0x0 0x2 &ipic 17 0x8
-				 0x8000 0x0 0x0 0x3 &ipic 48 0x8
-				 0x8000 0x0 0x0 0x4 &ipic 17 0x8>;
+				 0x8000 0x0 0x0 0x1 &ipic 48 IRQ_TYPE_LEVEL_LOW
+				 0x8000 0x0 0x0 0x2 &ipic 17 IRQ_TYPE_LEVEL_LOW
+				 0x8000 0x0 0x0 0x3 &ipic 48 IRQ_TYPE_LEVEL_LOW
+				 0x8000 0x0 0x0 0x4 &ipic 17 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-parent = <&ipic>;
-		interrupts = <66 0x8>;
+		interrupts = <66 IRQ_TYPE_LEVEL_LOW>;
 		bus-range = <0x0 0x0>;
 		ranges = <0x02000000 0 0x90000000 0x90000000 0 0x10000000
 			  0x42000000 0 0x80000000 0x80000000 0 0x10000000
@@ -417,10 +424,10 @@ pci1: pcie@e0009000 {
 		          0x01000000 0 0x00000000 0xb1000000 0 0x00800000>;
 		bus-range = <0 255>;
 		interrupt-map-mask = <0xf800 0 0 7>;
-		interrupt-map = <0 0 0 1 &ipic 1 8
-				 0 0 0 2 &ipic 1 8
-				 0 0 0 3 &ipic 1 8
-				 0 0 0 4 &ipic 1 8>;
+		interrupt-map = <0 0 0 1 &ipic 1 IRQ_TYPE_LEVEL_LOW
+				 0 0 0 2 &ipic 1 IRQ_TYPE_LEVEL_LOW
+				 0 0 0 3 &ipic 1 IRQ_TYPE_LEVEL_LOW
+				 0 0 0 4 &ipic 1 IRQ_TYPE_LEVEL_LOW>;
 		clock-frequency = <0>;
 
 		pcie@0 {
@@ -448,10 +455,10 @@ pci2: pcie@e000a000 {
 			  0x01000000 0 0x00000000 0xd1000000 0 0x00800000>;
 		bus-range = <0 255>;
 		interrupt-map-mask = <0xf800 0 0 7>;
-		interrupt-map = <0 0 0 1 &ipic 2 8
-				 0 0 0 2 &ipic 2 8
-				 0 0 0 3 &ipic 2 8
-				 0 0 0 4 &ipic 2 8>;
+		interrupt-map = <0 0 0 1 &ipic 2 IRQ_TYPE_LEVEL_LOW
+				 0 0 0 2 &ipic 2 IRQ_TYPE_LEVEL_LOW
+				 0 0 0 3 &ipic 2 IRQ_TYPE_LEVEL_LOW
+				 0 0 0 4 &ipic 2 IRQ_TYPE_LEVEL_LOW>;
 		clock-frequency = <0>;
 
 		pcie@0 {

-- 
2.51.0

