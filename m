From: Michael Reeves <michael.reeves077@gmail.com>
Date: Mon, 29 Jun 2026 20:01:01 +1000
Subject: [PATCH] arm64: dts: apple: t8122: Fix I2C resources
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-t8122-i2c-fix-v1-1-cec044001550@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFxCQmoC/x2MywqAIBAAfyX23IJtL+tXooPoVnux0IhA/Pek4
 wzMJIgchCPMVYLAj0Q5fYGmrsAexu+M4goDKRrUQBPeuiFCIYubvLi1o7NT3xltHJTmClz0/1v
 WnD8NkdvVXwAAAA==
X-Change-ID: 20260629-t8122-i2c-fix-f37dc954a8ad
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joshua Peisach <jpeisach@ubuntu.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782727271; l=3584;
 i=michael.reeves077@gmail.com; s=20260105; h=from:subject:message-id;
 bh=hlK9MIO4eVxPvoDNzV4TiPgH3mA8+0MVI+myk5cQbdQ=;
 b=vYF0LVjBAeCJcRh29ld6F43XBlcJxMcwpDIHly0ExE8C+l4bbcQoAmwrodt/K1BgAyA+/QP+v
 1coryZJwg20A0DSyZiyWQEwURtdFJQjZyyobYmlYB8v5roNUuRz/84f
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=QIrgWBGCm3LG0YYc6MLCDkwuVXLTGGooVBdWX/KhSiU=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20260105 with auth_id=591
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Correct the MMIO ranges and IRQs for T8122 I2C controllers.
They were mistakenly incorrect in the original commit. This
fix is required for i2c dependent hardware to function
correctly, i.e. audio codecs.

Tested on J613 (MacBook Air M3).

Fixes: c65ab4905e58 ("arm64: dts: apple: Initial t8122 (M3) device trees")
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 arch/arm64/boot/dts/apple/t8122.dtsi | 30 +++++++++++++++---------------
 1 file changed, 15 insertions(+), 15 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/t8122.dtsi b/arch/arm64/boot/dts/apple/t8122.dtsi
index c6196225e96e..1ee61c5b3409 100644
--- a/arch/arm64/boot/dts/apple/t8122.dtsi
+++ b/arch/arm64/boot/dts/apple/t8122.dtsi
@@ -186,12 +186,12 @@ soc {
 		/* Required to get >32-bit DMA via DARTs */
 		dma-ranges = <0 0 0 0 0xffffffff 0xffffc000>;
 
-		i2c0: i2c@235010000 {
+		i2c0: i2c@2a1010000 {
 			compatible = "apple,t8122-i2c", "apple,t8103-i2c";
-			reg = <0x2 0x35010000 0x0 0x4000>;
+			reg = <0x2 0xa1010000 0x0 0x4000>;
 			clocks = <&clkref>;
 			interrupt-parent = <&aic>;
-			interrupts = <AIC_IRQ 761 IRQ_TYPE_LEVEL_HIGH>;
+			interrupts = <AIC_IRQ 780 IRQ_TYPE_LEVEL_HIGH>;
 			pinctrl-0 = <&i2c0_pins>;
 			pinctrl-names = "default";
 			#address-cells = <0x1>;
@@ -200,12 +200,12 @@ i2c0: i2c@235010000 {
 			status = "disabled";
 		};
 
-		i2c1: i2c@235014000 {
+		i2c1: i2c@2a1014000 {
 			compatible = "apple,t8122-i2c", "apple,t8103-i2c";
-			reg = <0x2 0x35014000 0x0 0x4000>;
+			reg = <0x2 0xa1014000 0x0 0x4000>;
 			clocks = <&clkref>;
 			interrupt-parent = <&aic>;
-			interrupts = <AIC_IRQ 762 IRQ_TYPE_LEVEL_HIGH>;
+			interrupts = <AIC_IRQ 781 IRQ_TYPE_LEVEL_HIGH>;
 			pinctrl-0 = <&i2c1_pins>;
 			pinctrl-names = "default";
 			#address-cells = <0x1>;
@@ -214,12 +214,12 @@ i2c1: i2c@235014000 {
 			status = "disabled";
 		};
 
-		i2c2: i2c@235018000 {
+		i2c2: i2c@2a1018000 {
 			compatible = "apple,t8122-i2c", "apple,t8103-i2c";
-			reg = <0x2 0x35018000 0x0 0x4000>;
+			reg = <0x2 0xa1018000 0x0 0x4000>;
 			clocks = <&clkref>;
 			interrupt-parent = <&aic>;
-			interrupts = <AIC_IRQ 763 IRQ_TYPE_LEVEL_HIGH>;
+			interrupts = <AIC_IRQ 782 IRQ_TYPE_LEVEL_HIGH>;
 			pinctrl-0 = <&i2c2_pins>;
 			pinctrl-names = "default";
 			#address-cells = <0x1>;
@@ -228,12 +228,12 @@ i2c2: i2c@235018000 {
 			status = "disabled";
 		};
 
-		i2c3: i2c@23501c000 {
+		i2c3: i2c@2a101c000 {
 			compatible = "apple,t8122-i2c", "apple,t8103-i2c";
-			reg = <0x2 0x3501c000 0x0 0x4000>;
+			reg = <0x2 0xa101c000 0x0 0x4000>;
 			clocks = <&clkref>;
 			interrupt-parent = <&aic>;
-			interrupts = <AIC_IRQ 764 IRQ_TYPE_LEVEL_HIGH>;
+			interrupts = <AIC_IRQ 783 IRQ_TYPE_LEVEL_HIGH>;
 			pinctrl-0 = <&i2c3_pins>;
 			pinctrl-names = "default";
 			#address-cells = <0x1>;
@@ -242,12 +242,12 @@ i2c3: i2c@23501c000 {
 			status = "disabled";
 		};
 
-		i2c4: i2c@235020000 {
+		i2c4: i2c@2a1020000 {
 			compatible = "apple,t8122-i2c", "apple,t8103-i2c";
-			reg = <0x2 0x35020000 0x0 0x4000>;
+			reg = <0x2 0xa1020000 0x0 0x4000>;
 			clocks = <&clkref>;
 			interrupt-parent = <&aic>;
-			interrupts = <AIC_IRQ 765 IRQ_TYPE_LEVEL_HIGH>;
+			interrupts = <AIC_IRQ 784 IRQ_TYPE_LEVEL_HIGH>;
 			pinctrl-0 = <&i2c4_pins>;
 			pinctrl-names = "default";
 			#address-cells = <0x1>;

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260629-t8122-i2c-fix-f37dc954a8ad

Best regards,
-- 
Michael Reeves <michael.reeves077@gmail.com>

