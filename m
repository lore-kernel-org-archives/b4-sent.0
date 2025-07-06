From: Frank Li <Frank.Li@nxp.com>
Date: Sun, 06 Jul 2025 14:47:04 -0400
Subject: [PATCH 08/11] ARM: dts: lpc: change node name 'button[0-9]' to
 button-[0-9]'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250706-lpc18xxx_dts-v1-8-7ae8cdfe8d7d@nxp.com>
References: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
In-Reply-To: <20250706-lpc18xxx_dts-v1-0-7ae8cdfe8d7d@nxp.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vladimir Zapolskiy <vz@mleia.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, vz@mleia.com, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751827628; l=3156;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=O0CmtFMiA/5+GFcpd4plsq9QzGUKBGisD91DfDl49E8=;
 b=MpIN6S64nW8nXpZdaC2MRTHAIxiu0ClgbIRwnjCtlNHbaKWtdyPPIQZtmPeGxj/aG/u5F0Etg
 vn4Iu0iyIxvDZly3zAZsrvgAshrigE6bOxrghsweoUiAe8/IFO+vxWH
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change node name 'button[0-9]' to button-[0-9]' to fix below CHECK_DTB
warning:
 arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dtb: pca_buttons (gpio-keys-polled): 'button0', ... do not match any of the regexes: '^(button|...', 'pinctrl-[0-9]+'

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
 arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts    | 16 ++++++++--------
 arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts | 10 +++++-----
 2 files changed, 13 insertions(+), 13 deletions(-)

diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts b/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts
index 9d36283efe0f6ea26efedae9f7246c04f00cbdb7..18f757c569057f6e1bac6ab9d78bf936c7cad0c3 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4350-hitex-eval.dts
@@ -43,50 +43,50 @@ pca_buttons {
 		poll-interval = <100>;
 		autorepeat;
 
-		button0 {
+		button-0 {
 			label = "joy:right";
 			linux,code = <KEY_RIGHT>;
 			gpios = <&pca_gpio 8 GPIO_ACTIVE_LOW>;
 		};
 
-		button1 {
+		button-1 {
 			label = "joy:up";
 			linux,code = <KEY_UP>;
 			gpios = <&pca_gpio 9 GPIO_ACTIVE_LOW>;
 		};
 
 
-		button2 {
+		button-2 {
 			label = "joy:enter";
 			linux,code = <KEY_ENTER>;
 			gpios = <&pca_gpio 10 GPIO_ACTIVE_LOW>;
 		};
 
-		button3 {
+		button-3 {
 			label = "joy:left";
 			linux,code = <KEY_LEFT>;
 			gpios = <&pca_gpio 11 GPIO_ACTIVE_LOW>;
 		};
 
-		button4 {
+		button-4 {
 			label = "joy:down";
 			linux,code = <KEY_DOWN>;
 			gpios = <&pca_gpio 12 GPIO_ACTIVE_LOW>;
 		};
 
-		button5 {
+		button-5 {
 			label = "user:sw3";
 			linux,code = <KEY_F1>;
 			gpios = <&pca_gpio 13 GPIO_ACTIVE_LOW>;
 		};
 
-		button6 {
+		button-6 {
 			label = "user:sw4";
 			linux,code = <KEY_F2>;
 			gpios = <&pca_gpio 14 GPIO_ACTIVE_LOW>;
 		};
 
-		button7 {
+		button-7 {
 			label = "user:sw5";
 			linux,code = <KEY_F3>;
 			gpios = <&pca_gpio 15 GPIO_ACTIVE_LOW>;
diff --git a/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts b/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts
index 9dc8c3cc2211001f30a5a15c3a04a240e4acd86b..7ccb4c2ca57102ac2d31c21c72a45bd3d72f2d86 100644
--- a/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts
+++ b/arch/arm/boot/dts/nxp/lpc/lpc4357-ea4357-devkit.dts
@@ -60,31 +60,31 @@ gpio_joystick {
 		poll-interval = <100>;
 		autorepeat;
 
-		button0 {
+		button-0 {
 			label = "joy_enter";
 			linux,code = <KEY_ENTER>;
 			gpios = <&gpio LPC_GPIO(4,8) GPIO_ACTIVE_LOW>;
 		};
 
-		button1 {
+		button-1 {
 			label = "joy_left";
 			linux,code = <KEY_LEFT>;
 			gpios = <&gpio LPC_GPIO(4,9) GPIO_ACTIVE_LOW>;
 		};
 
-		button2 {
+		button-2 {
 			label = "joy_up";
 			linux,code = <KEY_UP>;
 			gpios = <&gpio LPC_GPIO(4,10) GPIO_ACTIVE_LOW>;
 		};
 
-		button3 {
+		button-3 {
 			label = "joy_right";
 			linux,code = <KEY_RIGHT>;
 			gpios = <&gpio LPC_GPIO(4,12) GPIO_ACTIVE_LOW>;
 		};
 
-		button4 {
+		button-4 {
 			label = "joy_down";
 			linux,code = <KEY_DOWN>;
 			gpios = <&gpio LPC_GPIO(4,13) GPIO_ACTIVE_LOW>;

-- 
2.34.1

