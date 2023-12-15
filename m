From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 15 Dec 2023 16:28:00 +0800
Subject: [PATCH] arm64: dts: amlogic: fix format for s4 uart node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231215-s4-dts-v1-1-7831ab6972be@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAA8OfGUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2NDI0ND3WIT3ZSSYl2TREMLA9OkFFOzNAMloOKCotS0zAqwQdGxtbUAJ0N
 5KlgAAAA=
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702628927; l=1770;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=RArDScP4iapdXOoGmXRe1ouD3aGqNXEnjFAHeK0j36Y=;
 b=8YWVWYB68WIuagKY9/MmSOxi3cDEmfkIpy1lKXTc9hgqrbNzIU7HJskJxS+EyIteu9O7mhXxX
 +LUZ9N6K9wADTtpyiKd7z41yH/rd/YIMyc5TnCzuE6FhItyitGm7sjB
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Aliases use lowercase letters and place status in end.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/meson-s4-s805x2-aq222.dts | 4 ++--
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi             | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-s4-s805x2-aq222.dts b/arch/arm64/boot/dts/amlogic/meson-s4-s805x2-aq222.dts
index 18789242f05f..983caddc409c 100644
--- a/arch/arm64/boot/dts/amlogic/meson-s4-s805x2-aq222.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-s4-s805x2-aq222.dts
@@ -15,7 +15,7 @@ / {
 	#size-cells = <2>;
 
 	aliases {
-		serial0 = &uart_B;
+		serial0 = &uart_b;
 	};
 
 	memory@0 {
@@ -36,7 +36,7 @@ secmon_reserved: secmon@5000000 {
 	};
 };
 
-&uart_B {
+&uart_b {
 	status = "okay";
 };
 
diff --git a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
index c6b524e1a1ee..ce90b35686a2 100644
--- a/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-s4.dtsi
@@ -455,14 +455,14 @@ nand: nand-controller@8c800 {
 				status = "disabled";
 			};
 
-			uart_B: serial@7a000 {
+			uart_b: serial@7a000 {
 				compatible = "amlogic,meson-s4-uart",
 					     "amlogic,meson-ao-uart";
 				reg = <0x0 0x7a000 0x0 0x18>;
 				interrupts = <GIC_SPI 169 IRQ_TYPE_EDGE_RISING>;
-				status = "disabled";
 				clocks = <&xtal>, <&clkc_periphs CLKID_UART_B>, <&xtal>;
 				clock-names = "xtal", "pclk", "baud";
+				status = "disabled";
 			};
 
 			reset: reset-controller@2000 {

---
base-commit: 078c5db2a961f674cc27c10f15d15949eece6a49
change-id: 20231211-s4-dts-4a1805bd56f0

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

