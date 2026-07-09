From: Roman Vivchar <rva333@protonmail.com>
Date: Thu, 09 Jul 2026 17:30:27 +0300
Subject: [PATCH v2 1/2] ARM: dts: mediatek: mt6572: rename fixed clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260709-6572-phase1-v2-1-1fd4a69542ab@protonmail.com>
References: <20260709-6572-phase1-v2-0-1fd4a69542ab@protonmail.com>
In-Reply-To: <20260709-6572-phase1-v2-0-1fd4a69542ab@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783607435; l=2336;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=SimJbn1seivrKmmRN96xb6J0kutHD3BQPIniNyDo7go=;
 b=VNI59q6VB4Q6KgEj6fN0jBXh2LcuBZP4Qhr0xeTN/qHjNCT/57zhZwCFs1cMbQWusZ2WWzEZ7
 Ymkjm9tkdETCUN41G+AD0y/m2EvZwp3Dgau03S0wre1mnCRnG/9K8PK
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Old-style naming like uart_clk, system_clk and rtc_clk doesn't actually
reflect hardware on the mt6572 SoC.

For example, uart_clk is used as parent for various parts of the SoC
like AXI bus, MMC controller, SPI, etc. While it usually shouldn't be
used as active parent, uart_clk is a wrong name. The same logic applies
to the rtc_clk, that is also used as input for MultiMedia subsystem
clock.

Therefore, rename all uart_clk, system_clk and rtc_clk to clk26m, clk13m
and clk32k to properly describe the hardware.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 arch/arm/boot/dts/mediatek/mt6572.dtsi | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/arch/arm/boot/dts/mediatek/mt6572.dtsi b/arch/arm/boot/dts/mediatek/mt6572.dtsi
index ac70f266d698..fa0e5df766c2 100644
--- a/arch/arm/boot/dts/mediatek/mt6572.dtsi
+++ b/arch/arm/boot/dts/mediatek/mt6572.dtsi
@@ -28,19 +28,19 @@ cpu@1 {
 		};
 	};
 
-	uart_clk: dummy26m {
+	clk26m: clk26m {
 		compatible = "fixed-clock";
 		clock-frequency = <26000000>;
 		#clock-cells = <0>;
 	};
 
-	system_clk: dummy13m {
+	clk13m: clk13m {
 		compatible = "fixed-clock";
 		clock-frequency = <13000000>;
 		#clock-cells = <0>;
 	};
 
-	rtc_clk: dummy32k {
+	clk32k: clk32k {
 		compatible = "fixed-clock";
 		clock-frequency = <32000>;
 		#clock-cells = <0>;
@@ -64,7 +64,7 @@ timer: timer@10008000 {
 			compatible = "mediatek,mt6572-timer", "mediatek,mt6577-timer";
 			reg = <0x10008000 0x80>;
 			interrupts = <GIC_SPI 74 IRQ_TYPE_LEVEL_LOW>;
-			clocks = <&system_clk>, <&rtc_clk>;
+			clocks = <&clk13m>, <&clk32k>;
 			clock-names = "system-clk", "rtc-clk";
 		};
 
@@ -91,7 +91,7 @@ uart0: serial@11005000 {
 			compatible = "mediatek,mt6572-uart", "mediatek,mt6577-uart";
 			reg = <0x11005000 0x400>;
 			interrupts = <GIC_SPI 31 IRQ_TYPE_LEVEL_LOW>;
-			clocks = <&uart_clk>;
+			clocks = <&clk26m>;
 			clock-names = "baud";
 			status = "disabled";
 		};
@@ -100,7 +100,7 @@ uart1: serial@11006000 {
 			compatible = "mediatek,mt6572-uart", "mediatek,mt6577-uart";
 			reg = <0x11006000 0x400>;
 			interrupts = <GIC_SPI 32 IRQ_TYPE_LEVEL_LOW>;
-			clocks = <&uart_clk>;
+			clocks = <&clk26m>;
 			clock-names = "baud";
 			status = "disabled";
 		};

-- 
2.54.0

