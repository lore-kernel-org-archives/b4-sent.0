From: Eric Yang <eric.yang.wiwynn@gmail.com>
Date: Thu, 05 Nov 2026 09:49:21 +0000
Subject: [PATCH] ARM: dts: aspeed: yosemite4: Remove Floating Falls board
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-yv4-remove-ff-nodes-v1-1-aa707a9577b7@gmail.com>
X-B4-Tracking: v=1; b=H4sIACBR7GoC/x3MQQqDMBBG4auEWXcgGUWwVxEXxfxpZ2FSEghK8
 O4Gl9/ivUYFWVHobRplVC2aYod7Gdp+n/gFq+8msTI5Zwc+68gZe6rgEDgmj8IzxDo7ehkmoV7
 +M4Iez3VZr+sGsiT61WUAAAA=
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>, 
 Ryan Chen <ryan_chen@aspeedtech.com>, 
 Billy Tsai <billy_tsai@aspeedtech.com>, patrick@stwcx.xyz
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Sean He <sean.he.wiwynn@gmail.com>, Eric Yang <eric.yang.wiwynn@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793872161; l=4662;
 i=eric.yang.wiwynn@gmail.com; s=20260911; h=from:subject:message-id;
 bh=T4XeuvV+KGamPG2baiyhX3Us0yn42pCuMdWIPVBaYz8=;
 b=L/oFlGYm96Adbk9JS+0cKrrf3+UCzEcvN0mp8Rny3aSD0XxKxLi5JYtosxQ6OaB05Ra+llXYm
 vmNZ0Uw3r65CjqW8GIlH6H/vGm8XPD3/HCNcfF8oaSDnA0xgoNGXcAX
X-Developer-Key: i=eric.yang.wiwynn@gmail.com; a=ed25519;
 pk=XYQiwgPZNUCt1JCbsO7zX8ODEiRKocz7fYwt+aWnXBs=
X-Endpoint-Received: by B4 Relay for eric.yang.wiwynn@gmail.com/20260911 with auth_id=1023
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sean He <sean.he.wiwynn@gmail.com>

The Floating Falls (FF) board carries a pca9537 GPIO expander at address
0x49 and a FRU EEPROM at address 0x50 on each slot I2C bus. FF was
planned in the early Yosemite 4 design but has not been used since the
DVT stage, so these addresses never acknowledge. The pca953x driver
fails to probe all eight pca9537 nodes on every boot, and the at24
driver does not bind to the eight EEPROM nodes either. Remove the nodes
for both devices.

Signed-off-by: Sean He <sean.he.wiwynn@gmail.com>
Signed-off-by: Eric Yang <eric.yang.wiwynn@gmail.com>
---
The changelog was drafted with an AI assistant (Claude Code) and
reviewed by the submitter.

Tested on two Yosemite 4 BMCs, baseline vs patched image: the eight
pca9537 nodes and the sixteen 0x49/0x50 slot-bus clients are gone, while
the 0x51/0x54 clients, gpio chips and FRU objects are unchanged.
CHECK_DTBS=y W=1 shows no new warnings and the DTB diff is exactly the
sixteen removed nodes.
---
 .../dts/aspeed/aspeed-bmc-facebook-yosemite4.dts   | 96 ----------------------
 1 file changed, 96 deletions(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-yosemite4.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-yosemite4.dts
index e4172be84..4c7c96ce4 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-yosemite4.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-yosemite4.dts
@@ -604,18 +604,6 @@ imux16: i2c@0 {
 			reg = <0>;
 			#address-cells = <1>;
 			#size-cells = <0>;
-			gpio@49 {
-				compatible = "nxp,pca9537";
-				reg = <0x49>;
-				gpio-controller;
-				#gpio-cells = <2>;
-			};
-
-			eeprom@50 {
-				compatible = "atmel,24c128";
-				reg = <0x50>;
-			};
-
 			eeprom@51 {
 				compatible = "atmel,24c128";
 				reg = <0x51>;
@@ -631,18 +619,6 @@ imux17: i2c@1 {
 			reg = <1>;
 			#address-cells = <1>;
 			#size-cells = <0>;
-			gpio@49 {
-				compatible = "nxp,pca9537";
-				reg = <0x49>;
-				gpio-controller;
-				#gpio-cells = <2>;
-			};
-
-			eeprom@50 {
-				compatible = "atmel,24c128";
-				reg = <0x50>;
-			};
-
 			eeprom@51 {
 				compatible = "atmel,24c128";
 				reg = <0x51>;
@@ -658,18 +634,6 @@ imux18: i2c@2 {
 			reg = <2>;
 			#address-cells = <1>;
 			#size-cells = <0>;
-			gpio@49 {
-				compatible = "nxp,pca9537";
-				reg = <0x49>;
-				gpio-controller;
-				#gpio-cells = <2>;
-			};
-
-			eeprom@50 {
-				compatible = "atmel,24c128";
-				reg = <0x50>;
-			};
-
 			eeprom@51 {
 				compatible = "atmel,24c128";
 				reg = <0x51>;
@@ -685,18 +649,6 @@ imux19: i2c@3 {
 			reg = <3>;
 			#address-cells = <1>;
 			#size-cells = <0>;
-			gpio@49 {
-				compatible = "nxp,pca9537";
-				reg = <0x49>;
-				gpio-controller;
-				#gpio-cells = <2>;
-			};
-
-			eeprom@50 {
-				compatible = "atmel,24c128";
-				reg = <0x50>;
-			};
-
 			eeprom@51 {
 				compatible = "atmel,24c128";
 				reg = <0x51>;
@@ -726,18 +678,6 @@ imux20: i2c@0 {
 			reg = <0>;
 			#address-cells = <1>;
 			#size-cells = <0>;
-			gpio@49 {
-				compatible = "nxp,pca9537";
-				reg = <0x49>;
-				gpio-controller;
-				#gpio-cells = <2>;
-			};
-
-			eeprom@50 {
-				compatible = "atmel,24c128";
-				reg = <0x50>;
-			};
-
 			eeprom@51 {
 				compatible = "atmel,24c128";
 				reg = <0x51>;
@@ -753,18 +693,6 @@ imux21: i2c@1 {
 			reg = <1>;
 			#address-cells = <1>;
 			#size-cells = <0>;
-			gpio@49 {
-				compatible = "nxp,pca9537";
-				reg = <0x49>;
-				gpio-controller;
-				#gpio-cells = <2>;
-			};
-
-			eeprom@50 {
-				compatible = "atmel,24c128";
-				reg = <0x50>;
-			};
-
 			eeprom@51 {
 				compatible = "atmel,24c128";
 				reg = <0x51>;
@@ -780,18 +708,6 @@ imux22: i2c@2 {
 			reg = <2>;
 			#address-cells = <1>;
 			#size-cells = <0>;
-			gpio@49 {
-				compatible = "nxp,pca9537";
-				reg = <0x49>;
-				gpio-controller;
-				#gpio-cells = <2>;
-			};
-
-			eeprom@50 {
-				compatible = "atmel,24c128";
-				reg = <0x50>;
-			};
-
 			eeprom@51 {
 				compatible = "atmel,24c128";
 				reg = <0x51>;
@@ -807,18 +723,6 @@ imux23: i2c@3 {
 			reg = <3>;
 			#address-cells = <1>;
 			#size-cells = <0>;
-			gpio@49 {
-				compatible = "nxp,pca9537";
-				reg = <0x49>;
-				gpio-controller;
-				#gpio-cells = <2>;
-			};
-
-			eeprom@50 {
-				compatible = "atmel,24c128";
-				reg = <0x50>;
-			};
-
 			eeprom@51 {
 				compatible = "atmel,24c128";
 				reg = <0x51>;

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261103-yv4-remove-ff-nodes-9e20104d2362

Best regards,
-- 
Eric Yang <eric.yang.wiwynn@gmail.com>

