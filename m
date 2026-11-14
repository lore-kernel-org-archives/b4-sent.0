From: Sven Peter <sven@kernel.org>
Date: Sat, 14 Nov 2026 14:03:35 +0100
Subject: [PATCH] arm64: dts: apple: Lowercase hwmon node names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-hwmon-nodes-v1-1-7d0a9674e3ae@kernel.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrB1wgj/YqxQXiU7rCCYlY6sg3
 t1Yl9/ivR2Uo7DCI9sh8k9Ugk+gPIN+tP7NKEMymMLURFSiK3Fc5+DRh4EVbd06Y7ki0zSQok/
 kl2z/4bO7rV83cb9cFziOE8WxGmpyAAAA
X-Change-ID: 20261114-b4-hwmon-nodes-a69b2ae51277
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3915; i=sven@kernel.org;
 h=from:subject:message-id; bh=gizQ5l+OSD2VXAgRLhGonhOWVto+Q+V1PVlMy8YyyeE=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aPGK2cp18Wd4gIKraF7DoZdXqjU03KfZOlBw9NcVO2F
 3+5fMrkjlIWBjEuBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBENrswMrywFs4xb9fdcOLL
 gx9pz9b+/vthYdl1n587BPWaK1SmFU5h+KedY96V4nrGJ9I8Y+pkIbaQe0fO1TT5BqtJR/y//MA
 skgsA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following dt-check-style strict warnings by using lower-case for
hwmon node names:

  arch/arm64/boot/dts/apple/hwmon-common.dtsi:9: [node-name] node name "power-PSTR" is using discouraged style

Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/hwmon-common.dtsi   | 12 ++++++------
 arch/arm64/boot/dts/apple/hwmon-fan-dual.dtsi |  4 ++--
 arch/arm64/boot/dts/apple/hwmon-fan.dtsi      |  2 +-
 arch/arm64/boot/dts/apple/hwmon-laptop.dtsi   | 12 ++++++------
 arch/arm64/boot/dts/apple/hwmon-mini.dtsi     |  2 +-
 5 files changed, 16 insertions(+), 16 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/hwmon-common.dtsi b/arch/arm64/boot/dts/apple/hwmon-common.dtsi
index a35c7b14fec8..b5153332e819 100644
--- a/arch/arm64/boot/dts/apple/hwmon-common.dtsi
+++ b/arch/arm64/boot/dts/apple/hwmon-common.dtsi
@@ -6,32 +6,32 @@
  */
 
 &smc_hwmon {
-	power-PSTR {
+	power-pstr {
 		apple,key-id = "PSTR";
 		label = "Total System Power";
 	};
 
-	power-PDTR {
+	power-pdtr {
 		apple,key-id = "PDTR";
 		label = "AC Input Power";
 	};
 
-	power-PMVR {
+	power-pmvr {
 		apple,key-id = "PMVR";
 		label = "3.8 V Rail Power";
 	};
 
-	temperature-TH0x {
+	temperature-th0x {
 		apple,key-id = "TH0x";
 		label = "NAND Flash Temperature";
 	};
 
-	voltage-VD0R {
+	voltage-vd0r {
 		apple,key-id = "VD0R";
 		label = "AC Input Voltage";
 	};
 
-	current-ID0R {
+	current-id0r {
 		apple,key-id = "ID0R";
 		label = "AC Input Current";
 	};
diff --git a/arch/arm64/boot/dts/apple/hwmon-fan-dual.dtsi b/arch/arm64/boot/dts/apple/hwmon-fan-dual.dtsi
index e87997d21e22..771484ed5870 100644
--- a/arch/arm64/boot/dts/apple/hwmon-fan-dual.dtsi
+++ b/arch/arm64/boot/dts/apple/hwmon-fan-dual.dtsi
@@ -8,11 +8,11 @@
 #include "hwmon-fan.dtsi"
 
 &smc_hwmon {
-	fan-F0Ac {
+	fan-f0ac {
 		label = "Fan 1";
 	};
 
-	fan-F1Ac {
+	fan-f1ac {
 		apple,key-id = "F1Ac";
 		label = "Fan 2";
 		apple,fan-minimum = "F1Mn";
diff --git a/arch/arm64/boot/dts/apple/hwmon-fan.dtsi b/arch/arm64/boot/dts/apple/hwmon-fan.dtsi
index 180eb8d7441f..b36d0c9b6af3 100644
--- a/arch/arm64/boot/dts/apple/hwmon-fan.dtsi
+++ b/arch/arm64/boot/dts/apple/hwmon-fan.dtsi
@@ -6,7 +6,7 @@
  */
 
 &smc_hwmon {
-	fan-F0Ac {
+	fan-f0ac {
 		apple,key-id = "F0Ac";
 		label = "Fan";
 		apple,fan-minimum = "F0Mn";
diff --git a/arch/arm64/boot/dts/apple/hwmon-laptop.dtsi b/arch/arm64/boot/dts/apple/hwmon-laptop.dtsi
index cadffd000c76..674013b1f387 100644
--- a/arch/arm64/boot/dts/apple/hwmon-laptop.dtsi
+++ b/arch/arm64/boot/dts/apple/hwmon-laptop.dtsi
@@ -6,32 +6,32 @@
  */
 
 &smc_hwmon {
-	power-PHPC {
+	power-phpc {
 		apple,key-id = "PHPC";
 		label = "Heatpipe Power";
 	};
 
-	temperature-TB0T {
+	temperature-tb0t {
 		apple,key-id = "TB0T";
 		label = "Battery Hotspot";
 	};
 
-	temperature-TCHP {
+	temperature-tchp {
 		apple,key-id = "TCHP";
 		label = "Charge Regulator Temp";
 	};
 
-	temperature-TW0P {
+	temperature-tw0p {
 		apple,key-id = "TW0P";
 		label = "WiFi/BT Module Temp";
 	};
 
-	voltage-SBAV {
+	voltage-sbav {
 		apple,key-id = "SBAV";
 		label = "Battery Voltage";
 	};
 
-	voltage-VD0R {
+	voltage-vd0r {
 		apple,key-id = "VD0R";
 		label = "Charger Input Voltage";
 	};
diff --git a/arch/arm64/boot/dts/apple/hwmon-mini.dtsi b/arch/arm64/boot/dts/apple/hwmon-mini.dtsi
index 7fd86e911acf..ce61805dc879 100644
--- a/arch/arm64/boot/dts/apple/hwmon-mini.dtsi
+++ b/arch/arm64/boot/dts/apple/hwmon-mini.dtsi
@@ -9,7 +9,7 @@
 #include "hwmon-fan.dtsi"
 
 &smc_hwmon {
-	temperature-TW0P {
+	temperature-tw0p {
 		apple,key-id = "TW0P";
 		label = "WiFi/BT Module Temp";
 	};

---
base-commit: 7809dfc2040bd6b8808da2cb7b8ce429ce3df946
change-id: 20261114-b4-hwmon-nodes-a69b2ae51277

Best regards,
--  
Sven Peter <sven@kernel.org>

