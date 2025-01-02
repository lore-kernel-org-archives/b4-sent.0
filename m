From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:46 +0100
Subject: [PATCH 05/19] powerpc: dts: mpc8315e: Disable peripherals by
 default
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-5-86f78ba2a7af@posteo.net>
References: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
In-Reply-To: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Frank Li <Frank.Li@nxp.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=4954;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=AV1vR3Ihm+C41mrCgb+tb12Q+MpI9SpagJ/QC+gpFGE=;
 b=wAqdmKvmfb4haqZrhf4yvl5DxXw4IUZoX/quIcvJQO27pvqD85KdryfzhT56KvFnLJJyCWpdQ
 1mLSXu6XjPqC04bSBxUiu5G7ZBCVaZiJa5DxY+VGR/xmQwAai02WvEV
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Peripherals with a connection to the outside of the chip aren't
necessarily used on all board designs, so disable them by default,
and enable them per-board.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/mpc8315e.dtsi   | 15 +++++++++++++++
 arch/powerpc/boot/dts/mpc8315erdb.dts | 12 ++++++++++++
 2 files changed, 27 insertions(+)

diff --git a/arch/powerpc/boot/dts/mpc8315e.dtsi b/arch/powerpc/boot/dts/mpc8315e.dtsi
index 2531e702648f1bf922a7112c9ddaeac1c3113572..7e61a78850433fa43795a2a5fb06ce6a148bb11d 100644
--- a/arch/powerpc/boot/dts/mpc8315e.dtsi
+++ b/arch/powerpc/boot/dts/mpc8315e.dtsi
@@ -51,6 +51,7 @@ localbus: localbus@e0005000 {
 		reg = <0xe0005000 0x1000>;
 		interrupts = <77 IRQ_TYPE_LEVEL_LOW>;
 		interrupt-parent = <&ipic>;
+		status = "disabled";
 	};
 
 	immr@e0000000 {
@@ -77,6 +78,7 @@ i2c: i2c@3000 {
 			interrupts = <14 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 			dfsrr;
+			status = "disabled";
 		};
 
 		spi: spi@7000 {
@@ -86,6 +88,7 @@ spi: spi@7000 {
 			interrupts = <16 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 			mode = "cpu";
+			status = "disabled";
 		};
 
 		dma@82a8 {
@@ -135,6 +138,7 @@ usb: usb@23000 {
 			interrupt-parent = <&ipic>;
 			interrupts = <38 IRQ_TYPE_LEVEL_LOW>;
 			phy_type = "utmi";
+			status = "disabled";
 		};
 
 		enet0: ethernet@24000 {
@@ -151,12 +155,14 @@ enet0: ethernet@24000 {
 				     <33 IRQ_TYPE_LEVEL_LOW>,
 				     <34 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
+			status = "disabled";
 
 			mdio0: mdio@520 {
 				#address-cells = <1>;
 				#size-cells = <0>;
 				compatible = "fsl,gianfar-mdio";
 				reg = <0x520 0x20>;
+				status = "disabled";
 			};
 		};
 
@@ -174,12 +180,14 @@ enet1: ethernet@25000 {
 				     <36 IRQ_TYPE_LEVEL_LOW>,
 				     <37 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
+			status = "disabled";
 
 			mdio1: mdio@520 {
 				#address-cells = <1>;
 				#size-cells = <0>;
 				compatible = "fsl,gianfar-tbi";
 				reg = <0x520 0x20>;
+				status = "disabled";
 			};
 		};
 
@@ -191,6 +199,7 @@ serial0: serial@4500 {
 			clock-frequency = <133333333>;
 			interrupts = <9 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
+			status = "disabled";
 		};
 
 		serial1: serial@4600 {
@@ -201,6 +210,7 @@ serial1: serial@4600 {
 			clock-frequency = <133333333>;
 			interrupts = <10 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
+			status = "disabled";
 		};
 
 		security: crypto@30000 {
@@ -222,6 +232,7 @@ sata0: sata@18000 {
 			cell-index = <1>;
 			interrupts = <44 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
+			status = "disabled";
 		};
 
 		sata1: sata@19000 {
@@ -230,6 +241,7 @@ sata1: sata@19000 {
 			cell-index = <2>;
 			interrupts = <45 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
+			status = "disabled";
 		};
 
 		gtm1: timer@500 {
@@ -324,6 +336,7 @@ pci0: pci@e0008500 {
 		       0xe0008300 0x8>;		/* config space access registers */
 		compatible = "fsl,mpc8349-pci";
 		device_type = "pci";
+		status = "disabled";
 	};
 
 	pci1: pcie@e0009000 {
@@ -342,6 +355,7 @@ pci1: pcie@e0009000 {
 				 0 0 0 3 &ipic 1 IRQ_TYPE_LEVEL_LOW
 				 0 0 0 4 &ipic 1 IRQ_TYPE_LEVEL_LOW>;
 		clock-frequency = <0>;
+		status = "disabled";
 	};
 
 	pci2: pcie@e000a000 {
@@ -360,5 +374,6 @@ pci2: pcie@e000a000 {
 				 0 0 0 3 &ipic 2 IRQ_TYPE_LEVEL_LOW
 				 0 0 0 4 &ipic 2 IRQ_TYPE_LEVEL_LOW>;
 		clock-frequency = <0>;
+		status = "disabled";
 	};
 };
diff --git a/arch/powerpc/boot/dts/mpc8315erdb.dts b/arch/powerpc/boot/dts/mpc8315erdb.dts
index 2ea71514900131893a70b44bab7bcc0bf4d86e44..28c06faf8ce0eb330a0108eba321b4c1127a8ae2 100644
--- a/arch/powerpc/boot/dts/mpc8315erdb.dts
+++ b/arch/powerpc/boot/dts/mpc8315erdb.dts
@@ -25,6 +25,8 @@ memory {
 	};
 
 	localbus@e0005000 {
+		status = "okay";
+
 		// CS0 and CS1 are swapped when
 		// booting from nand, but the
 		// addresses are the same.
@@ -83,8 +85,11 @@ ethernet@24000 {
 			tbi-handle = <&tbi0>;
 			phy-handle = < &phy0 >;
 			fsl,magic-packet;
+			status = "okay";
 
 			mdio@520 {
+				status = "okay";
+
 				phy0: ethernet-phy@0 {
 					interrupt-parent = <&ipic>;
 					interrupts = <20 IRQ_TYPE_LEVEL_LOW>;
@@ -108,8 +113,11 @@ ethernet@25000 {
 			tbi-handle = <&tbi1>;
 			phy-handle = < &phy1 >;
 			fsl,magic-packet;
+			status = "okay";
 
 			mdio@520 {
+				status = "okay";
+
 				tbi1: tbi-phy@11 {
 					reg = <0x11>;
 					device_type = "tbi-phy";
@@ -119,6 +127,8 @@ tbi1: tbi-phy@11 {
 	};
 
 	pcie@e0009000 {
+		status = "okay";
+
 		pcie@0 {
 			#address-cells = <3>;
 			#size-cells = <2>;
@@ -134,6 +144,8 @@ pcie@0 {
 	};
 
 	pcie@e000a000 {
+		status = "okay";
+
 		pcie@0 {
 			#address-cells = <3>;
 			#size-cells = <2>;

-- 
2.45.2

