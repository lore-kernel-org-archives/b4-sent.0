From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Mon, 10 Mar 2025 23:08:00 +0100
Subject: [PATCH v3 3/3] arm64: dts: apple: Add SPMI controller nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250310-spmi-v3-3-92a82e7d9f0d@gmail.com>
References: <20250310-spmi-v3-0-92a82e7d9f0d@gmail.com>
In-Reply-To: <20250310-spmi-v3-0-92a82e7d9f0d@gmail.com>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Stephen Boyd <sboyd@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Nick Chan <towinchenmi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741644479; l=2708;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=Pa8VSPAfUl5rQWcSmiEYDiYAy3MCXTK35oo91BheHOg=;
 b=GOd8zWco/1HabLA5aHDW6D1sJ33ybbnjoVDC+caUzRNKsUkXPPsrIOcdLLp+IHdKIJkQEUa3P
 4iebaR/tpqwBdnnuk5Px2vlaS0qWgeJz8kJYHVfMf3kdbnhUqMwM1tz
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree entries for the SPMI controller

Reviewed-by: Nick Chan <towinchenmi@gmail.com>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 arch/arm64/boot/dts/apple/t600x-die0.dtsi | 7 +++++++
 arch/arm64/boot/dts/apple/t8103.dtsi      | 8 ++++++++
 arch/arm64/boot/dts/apple/t8112.dtsi      | 7 +++++++
 3 files changed, 22 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t600x-die0.dtsi b/arch/arm64/boot/dts/apple/t600x-die0.dtsi
index b1c875e692c8fb9c0af46a23568a7b0cd720141b..64d4f301ca850ddb043bccc087e0b874fb96da9b 100644
--- a/arch/arm64/boot/dts/apple/t600x-die0.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-die0.dtsi
@@ -45,6 +45,13 @@ pinctrl_smc: pinctrl@290820000 {
 				<AIC_IRQ 0 749 IRQ_TYPE_LEVEL_HIGH>;
 	};
 
+	nub_spmi0: spmi@2920a1300 {
+		compatible = "apple,t6000-spmi", "apple,spmi";
+		reg = <0x2 0x920a1300 0x0 0x100>;
+		#address-cells = <2>;
+		#size-cells = <0>;
+	};
+
 	wdt: watchdog@2922b0000 {
 		compatible = "apple,t6000-wdt", "apple,wdt";
 		reg = <0x2 0x922b0000 0x0 0x4000>;
diff --git a/arch/arm64/boot/dts/apple/t8103.dtsi b/arch/arm64/boot/dts/apple/t8103.dtsi
index 9b0dad6b618444ac6b1c9735c50cccfc3965f947..0f03dc808cf7c6b7d71afc79dd29d368f957f979 100644
--- a/arch/arm64/boot/dts/apple/t8103.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103.dtsi
@@ -11,6 +11,7 @@
 #include <dt-bindings/interrupt-controller/apple-aic.h>
 #include <dt-bindings/interrupt-controller/irq.h>
 #include <dt-bindings/pinctrl/apple.h>
+#include <dt-bindings/spmi/spmi.h>
 
 / {
 	compatible = "apple,t8103", "apple,arm-platform";
@@ -604,6 +605,13 @@ pcie_pins: pcie-pins {
 			};
 		};
 
+		nub_spmi: spmi@23d0d9300 {
+			compatible = "apple,t8103-spmi", "apple,spmi";
+			reg = <0x2 0x3d0d9300 0x0 0x100>;
+			#address-cells = <2>;
+			#size-cells = <0>;
+		};
+
 		pinctrl_nub: pinctrl@23d1f0000 {
 			compatible = "apple,t8103-pinctrl", "apple,pinctrl";
 			reg = <0x2 0x3d1f0000 0x0 0x4000>;
diff --git a/arch/arm64/boot/dts/apple/t8112.dtsi b/arch/arm64/boot/dts/apple/t8112.dtsi
index 1666e6ab250bc0be9b8318e3c8fc903ccd3f3760..fa4309bb92975c4edbc11c998496f125267f2353 100644
--- a/arch/arm64/boot/dts/apple/t8112.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112.dtsi
@@ -679,6 +679,13 @@ wdt: watchdog@23d2b0000 {
 			interrupts = <AIC_IRQ 379 IRQ_TYPE_LEVEL_HIGH>;
 		};
 
+		nub_spmi: spmi@23d714000 {
+			compatible = "apple,t8112-spmi", "apple,spmi";
+			reg = <0x2 0x3d714000 0x0 0x100>;
+			#address-cells = <2>;
+			#size-cells = <0>;
+		};
+
 		pinctrl_smc: pinctrl@23e820000 {
 			compatible = "apple,t8112-pinctrl", "apple,pinctrl";
 			reg = <0x2 0x3e820000 0x0 0x4000>;

-- 
2.48.1

