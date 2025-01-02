From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:45 +0100
Subject: [PATCH 04/19] powerpc: dts: mpc8315e: Add labels to peripherals
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-4-86f78ba2a7af@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=2746;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=JWG24yKk9tKJztiNlXB5Hna42dBR5XCLmCda3s4BqBY=;
 b=Fqpu6KOl1IDStHphfeNxyTVjxQMUqH96DufHMXOAJgSY48bPEprSxuxfwuayggOiI9f8hAsrn
 QtlDpQcen04AYKtIDo3uRqnWQR11t8Z30E826BlCY42QKv++IhxX/ns
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Labels can be used in board-specific devicetrees to refer to nodes more
conveniently.

mpc8315erdb.dtb remains identical after this patch.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/mpc8315e.dtsi | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/arch/powerpc/boot/dts/mpc8315e.dtsi b/arch/powerpc/boot/dts/mpc8315e.dtsi
index 8741482905f0f30bf893a08b2602fdc6e74c23ff..2531e702648f1bf922a7112c9ddaeac1c3113572 100644
--- a/arch/powerpc/boot/dts/mpc8315e.dtsi
+++ b/arch/powerpc/boot/dts/mpc8315e.dtsi
@@ -44,7 +44,7 @@ memory {
 		reg = <0 0>;
 	};
 
-	localbus@e0005000 {
+	localbus: localbus@e0005000 {
 		#address-cells = <2>;
 		#size-cells = <1>;
 		compatible = "fsl,mpc8315-elbc", "fsl,elbc", "simple-bus";
@@ -62,13 +62,13 @@ immr@e0000000 {
 		reg = <0xe0000000 0x00000200>;
 		bus-frequency = <0>;
 
-		wdt@200 {
+		wdt: wdt@200 {
 			device_type = "watchdog";
 			compatible = "mpc83xx_wdt";
 			reg = <0x200 0x100>;
 		};
 
-		i2c@3000 {
+		i2c: i2c@3000 {
 			#address-cells = <1>;
 			#size-cells = <0>;
 			cell-index = <0>;
@@ -79,7 +79,7 @@ i2c@3000 {
 			dfsrr;
 		};
 
-		spi@7000 {
+		spi: spi@7000 {
 			cell-index = <0>;
 			compatible = "fsl,spi";
 			reg = <0x7000 0x1000>;
@@ -127,7 +127,7 @@ dma-channel@180 {
 			};
 		};
 
-		usb@23000 {
+		usb: usb@23000 {
 			compatible = "fsl-usb2-dr";
 			reg = <0x23000 0x1000>;
 			#address-cells = <1>;
@@ -152,7 +152,7 @@ enet0: ethernet@24000 {
 				     <34 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 
-			mdio@520 {
+			mdio0: mdio@520 {
 				#address-cells = <1>;
 				#size-cells = <0>;
 				compatible = "fsl,gianfar-mdio";
@@ -175,7 +175,7 @@ enet1: ethernet@25000 {
 				     <37 IRQ_TYPE_LEVEL_LOW>;
 			interrupt-parent = <&ipic>;
 
-			mdio@520 {
+			mdio1: mdio@520 {
 				#address-cells = <1>;
 				#size-cells = <0>;
 				compatible = "fsl,gianfar-tbi";
@@ -203,7 +203,7 @@ serial1: serial@4600 {
 			interrupt-parent = <&ipic>;
 		};
 
-		crypto@30000 {
+		security: crypto@30000 {
 			compatible = "fsl,sec3.3", "fsl,sec3.1", "fsl,sec3.0",
 				     "fsl,sec2.4", "fsl,sec2.2", "fsl,sec2.1",
 				     "fsl,sec2.0";
@@ -216,7 +216,7 @@ crypto@30000 {
 			fsl,descriptor-types-mask = <0x3a30abf>;
 		};
 
-		sata@18000 {
+		sata0: sata@18000 {
 			compatible = "fsl,mpc8315-sata", "fsl,pq-sata";
 			reg = <0x18000 0x1000>;
 			cell-index = <1>;
@@ -224,7 +224,7 @@ sata@18000 {
 			interrupt-parent = <&ipic>;
 		};
 
-		sata@19000 {
+		sata1: sata@19000 {
 			compatible = "fsl,mpc8315-sata", "fsl,pq-sata";
 			reg = <0x19000 0x1000>;
 			cell-index = <2>;

-- 
2.45.2

