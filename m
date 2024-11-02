From: Janne Grunau <j@jannau.net>
Date: Sat, 02 Nov 2024 12:34:24 +0100
Subject: [PATCH 5/5] arm64: dts: apple: Add SPI NOR nvram partition to all
 devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241102-asahi-spi-dt-v1-5-7ac44c0a88f9@jannau.net>
References: <20241102-asahi-spi-dt-v1-0-7ac44c0a88f9@jannau.net>
In-Reply-To: <20241102-asahi-spi-dt-v1-0-7ac44c0a88f9@jannau.net>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3506; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=4sH2FvtVOU7J6ZD/GsHPG804yvHnrTdh0gHvxrTVtvc=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnQ1PrvyhtB54ap732lO8opJM52R+f/D5FkNsoGxHWksx
 +wqDt/pKGVhEONikBVTZEnSftnBsLpGMab2QRjMHFYmkCEMXJwCMJH10YwMR55PusaXVe8n5XBh
 Jqvmi6X3HwnWcxaqPZLuPqRQ7laTxMjwjb09Sa9la9eqb9+XvDPIMT0xK+7G9qk8gW1XQyw2N6m
 zAQA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All known M1* and M2* devices use an identical SPI NOR flash
configuration with a partition containing a non-volatile key:value
storage. Use a .dtsi and include it for every device.
The nvram partition parameters itself depend on the version of the
installed Apple iboot boot loader. m1n1 will fill in the current values
provided by Apple's iboot.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 arch/arm64/boot/dts/apple/spi1-nvram.dtsi      | 39 ++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi |  2 ++
 arch/arm64/boot/dts/apple/t600x-j375.dtsi      |  2 ++
 arch/arm64/boot/dts/apple/t8103-jxxx.dtsi      |  2 ++
 arch/arm64/boot/dts/apple/t8112-jxxx.dtsi      |  2 ++
 5 files changed, 47 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/spi1-nvram.dtsi b/arch/arm64/boot/dts/apple/spi1-nvram.dtsi
new file mode 100644
index 0000000000000000000000000000000000000000..3df2fd3993b52884d7c00b65099c88d830a7a4c3
--- /dev/null
+++ b/arch/arm64/boot/dts/apple/spi1-nvram.dtsi
@@ -0,0 +1,39 @@
+// SPDX-License-Identifier: GPL-2.0+ OR MIT
+//
+// Devicetree include for common spi-nor nvram flash.
+//
+// Apple uses a consistent configiguration for the nvram on all known M1* and
+// M2* devices.
+//
+// Copyright The Asahi Linux Contributors
+
+/ {
+	aliases {
+		nvram = &nvram;
+	};
+};
+
+&spi1 {
+	status = "okay";
+
+	flash@0 {
+		compatible = "jedec,spi-nor";
+		reg = <0x0>;
+		spi-max-frequency = <25000000>;
+		#address-cells = <1>;
+		#size-cells = <1>;
+
+		partitions {
+			compatible = "fixed-partitions";
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			nvram: partition@700000 {
+				label = "nvram";
+				/* To be filled by the loader */
+				reg = <0x0 0x0>;
+				status = "disabled";
+			};
+		};
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
index 2e471dfe43cf885c1234d36bf0e0acfdc4904621..22ebc78e120bf8f0f71fd532e9dce4dcd117bbc6 100644
--- a/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi
@@ -119,3 +119,5 @@ sdhci0: mmc@0,0 {
 &fpwm0 {
 	status = "okay";
 };
+
+#include "spi1-nvram.dtsi"
diff --git a/arch/arm64/boot/dts/apple/t600x-j375.dtsi b/arch/arm64/boot/dts/apple/t600x-j375.dtsi
index 1e5a19e49b089d4b3c5e12828b682d1993e35e75..d5b985ad567936111ee5cccc9ca9fc23d01d9edf 100644
--- a/arch/arm64/boot/dts/apple/t600x-j375.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-j375.dtsi
@@ -126,3 +126,5 @@ &pcie0_dart_2 {
 &pcie0_dart_3 {
 	status = "okay";
 };
+
+#include "spi1-nvram.dtsi"
diff --git a/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi b/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi
index 5988a4eb6efaa008c290b1842e0da2aae8052ba4..8e82231acab59ca0bffdcecfb6681f59661fcd96 100644
--- a/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103-jxxx.dtsi
@@ -90,3 +90,5 @@ bluetooth0: bluetooth@0,1 {
 &nco_clkref {
 	clock-frequency = <900000000>;
 };
+
+#include "spi1-nvram.dtsi"
diff --git a/arch/arm64/boot/dts/apple/t8112-jxxx.dtsi b/arch/arm64/boot/dts/apple/t8112-jxxx.dtsi
index f5edf61113e7aa869613d672b281f7b7e84efb79..6da35496a4c88dbaba125ebbe8c5a4a428c647c3 100644
--- a/arch/arm64/boot/dts/apple/t8112-jxxx.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112-jxxx.dtsi
@@ -79,3 +79,5 @@ &i2c3 {
 &nco_clkref {
 	clock-frequency = <900000000>;
 };
+
+#include "spi1-nvram.dtsi"

-- 
2.47.0

