From: Janne Grunau <j@jannau.net>
Date: Wed, 13 Aug 2025 11:53:34 +0200
Subject: [PATCH 2/5] arm64: dts: apple: t600x: Comple WiFi properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250813-apple-dt-sync-6-17-v1-2-209f15d10aa0@jannau.net>
References: <20250813-apple-dt-sync-6-17-v1-0-209f15d10aa0@jannau.net>
In-Reply-To: <20250813-apple-dt-sync-6-17-v1-0-209f15d10aa0@jannau.net>
To: Sven Peter <sven@kernel.org>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Mark Kettenis <kettenis@openbsd.org>, 
 Hector Martin <marcan@marcan.st>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4966; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=SrTiUajMl8doOD8Fc18xDAuFz8wdUpSfSiCRbDLpSoM=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhow5CWsuf9/3qkP3e+79V9JrgqMNY81+B+Q8P52Y/i3ow
 5fP5mt2d5SyMIhxMciKKbIkab/sYFhdoxhT+yAMZg4rE8gQBi5OAZiIbRDD/xQdn6CGMzPl5fmu
 V8dZysW+39Ty4NIM553Gl4Lu/LKx/8Lwv2DqjwRLHf8yfcNpfFcNtPOlfWclCTi8+ZzgI3PuyFo
 bXgA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Add compatible and antenna-sku properties to the shared node and
brcm,board-type property to individuall board device trees.
module and antenna properties

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 arch/arm64/boot/dts/apple/t6000-j314s.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t6000-j316s.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t6001-j314c.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t6001-j316c.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t6001-j375c.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t6002-j375d.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi | 2 ++
 arch/arm64/boot/dts/apple/t600x-j375.dtsi      | 2 ++
 8 files changed, 28 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t6000-j314s.dts b/arch/arm64/boot/dts/apple/t6000-j314s.dts
index c9e192848fe3f9f91c3c305e169b949a45e7f7e3..ac35870ca129ce353b04296800b197bf684d0bd7 100644
--- a/arch/arm64/boot/dts/apple/t6000-j314s.dts
+++ b/arch/arm64/boot/dts/apple/t6000-j314s.dts
@@ -16,3 +16,7 @@ / {
 	compatible = "apple,j314s", "apple,t6000", "apple,arm-platform";
 	model = "Apple MacBook Pro (14-inch, M1 Pro, 2021)";
 };
+
+&wifi0 {
+	brcm,board-type = "apple,maldives";
+};
diff --git a/arch/arm64/boot/dts/apple/t6000-j316s.dts b/arch/arm64/boot/dts/apple/t6000-j316s.dts
index ff1803ce23001c7817a336456bed626adc3931e3..77d6d8c14d741e9b6a0dc44f764ea54f966e0d59 100644
--- a/arch/arm64/boot/dts/apple/t6000-j316s.dts
+++ b/arch/arm64/boot/dts/apple/t6000-j316s.dts
@@ -16,3 +16,7 @@ / {
 	compatible = "apple,j316s", "apple,t6000", "apple,arm-platform";
 	model = "Apple MacBook Pro (16-inch, M1 Pro, 2021)";
 };
+
+&wifi0 {
+	brcm,board-type = "apple,madagascar";
+};
diff --git a/arch/arm64/boot/dts/apple/t6001-j314c.dts b/arch/arm64/boot/dts/apple/t6001-j314c.dts
index 1761d15b98c12f9f6a19798e10d0544805538397..0a5655792a8f1cb6d0029bf9f967aa74cf6c01f7 100644
--- a/arch/arm64/boot/dts/apple/t6001-j314c.dts
+++ b/arch/arm64/boot/dts/apple/t6001-j314c.dts
@@ -16,3 +16,7 @@ / {
 	compatible = "apple,j314c", "apple,t6001", "apple,arm-platform";
 	model = "Apple MacBook Pro (14-inch, M1 Max, 2021)";
 };
+
+&wifi0 {
+	brcm,board-type = "apple,maldives";
+};
diff --git a/arch/arm64/boot/dts/apple/t6001-j316c.dts b/arch/arm64/boot/dts/apple/t6001-j316c.dts
index 750e9beeffc0aa87f1dcac1b57dddf78184ddd47..9c215531ea543e9afe8c131f7c8dc68cfaae666c 100644
--- a/arch/arm64/boot/dts/apple/t6001-j316c.dts
+++ b/arch/arm64/boot/dts/apple/t6001-j316c.dts
@@ -16,3 +16,7 @@ / {
 	compatible = "apple,j316c", "apple,t6001", "apple,arm-platform";
 	model = "Apple MacBook Pro (16-inch, M1 Max, 2021)";
 };
+
+&wifi0 {
+	brcm,board-type = "apple,madagascar";
+};
diff --git a/arch/arm64/boot/dts/apple/t6001-j375c.dts b/arch/arm64/boot/dts/apple/t6001-j375c.dts
index 62ea437b58b25ca649e20b1072b4d835bbc17d3a..88ca2037556cec4307d27bba0244d7ba7f45b184 100644
--- a/arch/arm64/boot/dts/apple/t6001-j375c.dts
+++ b/arch/arm64/boot/dts/apple/t6001-j375c.dts
@@ -16,3 +16,7 @@ / {
 	compatible = "apple,j375c", "apple,t6001", "apple,arm-platform";
 	model = "Apple Mac Studio (M1 Max, 2022)";
 };
+
+&wifi0 {
+	brcm,board-type = "apple,okinawa";
+};
diff --git a/arch/arm64/boot/dts/apple/t6002-j375d.dts b/arch/arm64/boot/dts/apple/t6002-j375d.dts
index 3365429bdc8be90b63c8051822243d897854ab27..f56d13b37eaff1c3c14815575a71024661669296 100644
--- a/arch/arm64/boot/dts/apple/t6002-j375d.dts
+++ b/arch/arm64/boot/dts/apple/t6002-j375d.dts
@@ -38,6 +38,10 @@ hpm5: usb-pd@3a {
 	};
 };
 
+&wifi0 {
+	brcm,board-type = "apple,okinawa";
+};
+
 /* delete unused always-on power-domains on die 1 */
 
 /delete-node/ &ps_atc2_usb_aon_die1;
diff --git a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
index 22ebc78e120bf8f0f71fd532e9dce4dcd117bbc6..b699672a5543c1c172f9a788d36287c0b09051e1 100644
--- a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
@@ -99,9 +99,11 @@ &port00 {
 	/* WLAN */
 	bus-range = <1 1>;
 	wifi0: wifi@0,0 {
+		compatible = "pci14e4,4433";
 		reg = <0x10000 0x0 0x0 0x0 0x0>;
 		/* To be filled by the loader */
 		local-mac-address = [00 10 18 00 00 10];
+		apple,antenna-sku = "XX";
 	};
 };
 
diff --git a/arch/arm64/boot/dts/apple/t600x-j375.dtsi b/arch/arm64/boot/dts/apple/t600x-j375.dtsi
index d5b985ad567936111ee5cccc9ca9fc23d01d9edf..95560bf3798bfebe133afafba674005a3e62ddcc 100644
--- a/arch/arm64/boot/dts/apple/t600x-j375.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j375.dtsi
@@ -84,9 +84,11 @@ &port00 {
 	/* WLAN */
 	bus-range = <1 1>;
 	wifi0: wifi@0,0 {
+		compatible = "pci14e4,4433";
 		reg = <0x10000 0x0 0x0 0x0 0x0>;
 		/* To be filled by the loader */
 		local-mac-address = [00 10 18 00 00 10];
+		apple,antenna-sku = "XX";
 	};
 };
 

-- 
2.50.1

