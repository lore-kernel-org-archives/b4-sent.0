From: Janne Grunau <j@jannau.net>
Date: Wed, 13 Aug 2025 11:53:35 +0200
Subject: [PATCH 3/5] arm64: dts: apple: t600x: Add bluetooth device nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250813-apple-dt-sync-6-17-v1-3-209f15d10aa0@jannau.net>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5002; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=C2YwY38W49BVPlqekZccmVQQ104q7sB0ZkEUHkDIXu8=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhow5CWuYtHo0f/1vSt+eLWglGlpdeSL2geTTZU0lMgohR
 ydJTjrXUcrCIMbFICumyJKk/bKDYXWNYkztgzCYOaxMIEMYuDgFYCJyoowMF9nPxilazN7M9eP+
 lHzWNZv+W4TZrhPbOW1P6Jss5vw3sYwMd2Ifrxfc0bTw+5R2+Y1XRJ6sWSm6Ycq+qiuOT1f+ito
 XygIA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Add bluetooth PCIe device nodes to specify per device brcm,board-type
and provide the bootloader filled "local-bd-address" and calibration
data.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 arch/arm64/boot/dts/apple/t6000-j314s.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t6000-j316s.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t6001-j314c.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t6001-j316c.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t6001-j375c.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t6002-j375d.dts      | 4 ++++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi | 8 ++++++++
 arch/arm64/boot/dts/apple/t600x-j375.dtsi      | 8 ++++++++
 8 files changed, 40 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t6000-j314s.dts b/arch/arm64/boot/dts/apple/t6000-j314s.dts
index ac35870ca129ce353b04296800b197bf684d0bd7..1430b91ff1b152e5a23025d5377f189601bb5a09 100644
--- a/arch/arm64/boot/dts/apple/t6000-j314s.dts
+++ b/arch/arm64/boot/dts/apple/t6000-j314s.dts
@@ -20,3 +20,7 @@ / {
 &wifi0 {
 	brcm,board-type = "apple,maldives";
 };
+
+&bluetooth0 {
+	brcm,board-type = "apple,maldives";
+};
diff --git a/arch/arm64/boot/dts/apple/t6000-j316s.dts b/arch/arm64/boot/dts/apple/t6000-j316s.dts
index 77d6d8c14d741e9b6a0dc44f764ea54f966e0d59..da0cbe7d96736b1491497243bdbd1d13c9ab6c62 100644
--- a/arch/arm64/boot/dts/apple/t6000-j316s.dts
+++ b/arch/arm64/boot/dts/apple/t6000-j316s.dts
@@ -20,3 +20,7 @@ / {
 &wifi0 {
 	brcm,board-type = "apple,madagascar";
 };
+
+&bluetooth0 {
+	brcm,board-type = "apple,madagascar";
+};
diff --git a/arch/arm64/boot/dts/apple/t6001-j314c.dts b/arch/arm64/boot/dts/apple/t6001-j314c.dts
index 0a5655792a8f1cb6d0029bf9f967aa74cf6c01f7..c37097dcfdb304d8fcdf77de82e494e158d94c72 100644
--- a/arch/arm64/boot/dts/apple/t6001-j314c.dts
+++ b/arch/arm64/boot/dts/apple/t6001-j314c.dts
@@ -20,3 +20,7 @@ / {
 &wifi0 {
 	brcm,board-type = "apple,maldives";
 };
+
+&bluetooth0 {
+	brcm,board-type = "apple,maldives";
+};
diff --git a/arch/arm64/boot/dts/apple/t6001-j316c.dts b/arch/arm64/boot/dts/apple/t6001-j316c.dts
index 9c215531ea543e9afe8c131f7c8dc68cfaae666c..3bc6e0c3294cf98c89dddfb4891eefbe8aae7020 100644
--- a/arch/arm64/boot/dts/apple/t6001-j316c.dts
+++ b/arch/arm64/boot/dts/apple/t6001-j316c.dts
@@ -20,3 +20,7 @@ / {
 &wifi0 {
 	brcm,board-type = "apple,madagascar";
 };
+
+&bluetooth0 {
+	brcm,board-type = "apple,madagascar";
+};
diff --git a/arch/arm64/boot/dts/apple/t6001-j375c.dts b/arch/arm64/boot/dts/apple/t6001-j375c.dts
index 88ca2037556cec4307d27bba0244d7ba7f45b184..2e7c23714d4d0007b7096d469f32c689944c85ff 100644
--- a/arch/arm64/boot/dts/apple/t6001-j375c.dts
+++ b/arch/arm64/boot/dts/apple/t6001-j375c.dts
@@ -20,3 +20,7 @@ / {
 &wifi0 {
 	brcm,board-type = "apple,okinawa";
 };
+
+&bluetooth0 {
+	brcm,board-type = "apple,okinawa";
+};
diff --git a/arch/arm64/boot/dts/apple/t6002-j375d.dts b/arch/arm64/boot/dts/apple/t6002-j375d.dts
index f56d13b37eaff1c3c14815575a71024661669296..2b7f80119618ad1b497b67597c55968585bd92a9 100644
--- a/arch/arm64/boot/dts/apple/t6002-j375d.dts
+++ b/arch/arm64/boot/dts/apple/t6002-j375d.dts
@@ -42,6 +42,10 @@ &wifi0 {
 	brcm,board-type = "apple,okinawa";
 };
 
+&bluetooth0 {
+	brcm,board-type = "apple,okinawa";
+};
+
 /* delete unused always-on power-domains on die 1 */
 
 /delete-node/ &ps_atc2_usb_aon_die1;
diff --git a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
index b699672a5543c1c172f9a788d36287c0b09051e1..c0aac59a6fae4f6f4b387483665349a8e2521c1e 100644
--- a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
@@ -13,6 +13,7 @@
 
 / {
 	aliases {
+		bluetooth0 = &bluetooth0;
 		serial0 = &serial0;
 		wifi0 = &wifi0;
 	};
@@ -105,6 +106,13 @@ wifi0: wifi@0,0 {
 		local-mac-address = [00 10 18 00 00 10];
 		apple,antenna-sku = "XX";
 	};
+
+	bluetooth0: bluetooth@0,1 {
+		compatible = "pci14e4,5f71";
+		reg = <0x10100 0x0 0x0 0x0 0x0>;
+		/* To be filled by the loader */
+		local-bd-address = [00 00 00 00 00 00];
+	};
 };
 
 &port01 {
diff --git a/arch/arm64/boot/dts/apple/t600x-j375.dtsi b/arch/arm64/boot/dts/apple/t600x-j375.dtsi
index 95560bf3798bfebe133afafba674005a3e62ddcc..ed38acc0dfc36a1e30b1d44f1a8dcee089e87232 100644
--- a/arch/arm64/boot/dts/apple/t600x-j375.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j375.dtsi
@@ -11,6 +11,7 @@
 
 / {
 	aliases {
+		bluetooth0 = &bluetooth0;
 		serial0 = &serial0;
 		wifi0 = &wifi0;
 	};
@@ -90,6 +91,13 @@ wifi0: wifi@0,0 {
 		local-mac-address = [00 10 18 00 00 10];
 		apple,antenna-sku = "XX";
 	};
+
+	bluetooth0: bluetooth@0,1 {
+		compatible = "pci14e4,5f71";
+		reg = <0x10100 0x0 0x0 0x0 0x0>;
+		/* To be filled by the loader */
+		local-bd-address = [00 00 00 00 00 00];
+	};
 };
 
 &port01 {

-- 
2.50.1

