From: Michael Reeves <michael.reeves077@gmail.com>
Date: Sun, 08 Nov 2026 07:25:13 +0000
Subject: [PATCH v5 8/8] arm64: dts: apple: Enable DockChannel HID on M2 and
 M3 laptops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-apple-mtp-keyboard-v5-8-e2c97b82669a@gmail.com>
References: <20261108-b4-apple-mtp-keyboard-v5-0-e2c97b82669a@gmail.com>
In-Reply-To: <20261108-b4-apple-mtp-keyboard-v5-0-e2c97b82669a@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 Michael Reeves <michael.reeves077@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-input@vger.kernel.org, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794122710; l=7011;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=zDBnGRKF6WdRKeYPVV1cRA9LKeT1joknp1YiOamAuYY=;
 b=7ih6zc2CRUNGW7YZSoHyM3WcE1c3TcQ48RNtmqYUpdjnnEIqMyrLYmtf5KlnK1OE7BIp2u85l
 +HtEF51PWMyDaJ0IrNrPn60Sw82yJPXZmYteimVwG23S1m6gcsvtCrA
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the MTP mailbox, DART, DockChannel mailbox, and HID transport on
the M2 and M3 laptop device trees using this internal input path.

Add a keyboard alias and enable DockChannel HID on each machine so the
transport can expose the internal keyboard.

Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi | 24 ++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t603x-j514-j516.dtsi | 19 +++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112-j413.dts       | 19 +++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112-j415.dts       | 19 +++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112-j493.dts       | 21 ++++++++++++++++++++-
 arch/arm64/boot/dts/apple/t8122-j504.dts       | 22 ++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8122-j613.dts       | 22 ++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8122-j615.dts       | 22 ++++++++++++++++++++++
 8 files changed, 167 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi b/arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi
index 0e806d8ddf81..98d58b340aee 100644
--- a/arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi
+++ b/arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi
@@ -16,6 +16,12 @@
 
 #include "t600x-j314-j316.dtsi"
 
+/ {
+	aliases {
+		keyboard = &mtp_hid;
+	};
+};
+
 &framebuffer0 {
 	power-domains = <&ps_disp0_cpu0>, <&ps_dptx_phy_ps>;
 };
@@ -43,3 +49,21 @@ &wifi0 {
 &bluetooth0 {
 	compatible = "pci14e4,5f72";
 };
+
+&mtp_mbox {
+	status = "okay";
+};
+
+&mtp_dart {
+	status = "okay";
+};
+
+&mtp_dockchannel {
+	status = "okay";
+};
+
+&mtp_hid {
+	status = "okay";
+	apple,has-stm;
+	hid-country-code = <0>;
+};
diff --git a/arch/arm64/boot/dts/apple/t603x-j514-j516.dtsi b/arch/arm64/boot/dts/apple/t603x-j514-j516.dtsi
index bbee373044f9..555c160e6bd7 100644
--- a/arch/arm64/boot/dts/apple/t603x-j514-j516.dtsi
+++ b/arch/arm64/boot/dts/apple/t603x-j514-j516.dtsi
@@ -21,6 +21,7 @@ / {
 	chassis-type = "laptop";
 
 	aliases {
+		keyboard = &mtp_hid;
 		serial0 = &serial0;
 	};
 
@@ -67,3 +68,21 @@ &serial0 {
 &fpwm0 {
 	status = "okay";
 };
+
+&mtp_mbox {
+	status = "okay";
+};
+
+&mtp_dart {
+	status = "okay";
+};
+
+&mtp_dockchannel {
+	status = "okay";
+};
+
+&mtp_hid {
+	status = "okay";
+	apple,has-stm;
+	hid-country-code = <0>;
+};
diff --git a/arch/arm64/boot/dts/apple/t8112-j413.dts b/arch/arm64/boot/dts/apple/t8112-j413.dts
index 7ccfceb08093..04a394abf479 100644
--- a/arch/arm64/boot/dts/apple/t8112-j413.dts
+++ b/arch/arm64/boot/dts/apple/t8112-j413.dts
@@ -20,6 +20,7 @@ / {
 
 	aliases {
 		bluetooth0 = &bluetooth0;
+		keyboard = &mtp_hid;
 		wifi0 = &wifi0;
 	};
 
@@ -93,3 +94,21 @@ &fpwm1 {
 };
 
 #include "hwmon-laptop.dtsi"
+
+&mtp_mbox {
+	status = "okay";
+};
+
+&mtp_dart {
+	status = "okay";
+};
+
+&mtp_dockchannel {
+	status = "okay";
+};
+
+&mtp_hid {
+	status = "okay";
+	apple,has-stm;
+	hid-country-code = <0>;
+};
diff --git a/arch/arm64/boot/dts/apple/t8112-j415.dts b/arch/arm64/boot/dts/apple/t8112-j415.dts
index fdc3409d2e07..ae28c75e8f97 100644
--- a/arch/arm64/boot/dts/apple/t8112-j415.dts
+++ b/arch/arm64/boot/dts/apple/t8112-j415.dts
@@ -20,6 +20,7 @@ / {
 
 	aliases {
 		bluetooth0 = &bluetooth0;
+		keyboard = &mtp_hid;
 		wifi0 = &wifi0;
 	};
 
@@ -93,3 +94,21 @@ &fpwm1 {
 };
 
 #include "hwmon-laptop.dtsi"
+
+&mtp_mbox {
+	status = "okay";
+};
+
+&mtp_dart {
+	status = "okay";
+};
+
+&mtp_dockchannel {
+	status = "okay";
+};
+
+&mtp_hid {
+	status = "okay";
+	apple,has-stm;
+	hid-country-code = <0>;
+};
diff --git a/arch/arm64/boot/dts/apple/t8112-j493.dts b/arch/arm64/boot/dts/apple/t8112-j493.dts
index 7cea5c594810..8e29872ce907 100644
--- a/arch/arm64/boot/dts/apple/t8112-j493.dts
+++ b/arch/arm64/boot/dts/apple/t8112-j493.dts
@@ -1,6 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0+ OR MIT
 /*
- * Apple MacBook Pro (13-inch, M1, 2022)
+ * Apple MacBook Pro (13-inch, M2, 2022)
  *
  * target-type: J493
  *
@@ -24,6 +24,7 @@ / {
 	 */
 	aliases {
 		bluetooth0 = &bluetooth0;
+		keyboard = &mtp_hid;
 		touchbar0 = &touchbar0;
 		wifi0 = &wifi0;
 	};
@@ -149,3 +150,21 @@ touchbar0: touchbar@0 {
 
 #include "hwmon-laptop.dtsi"
 #include "hwmon-fan.dtsi"
+
+&mtp_mbox {
+	status = "okay";
+};
+
+&mtp_dart {
+	status = "okay";
+};
+
+&mtp_dockchannel {
+	status = "okay";
+};
+
+&mtp_hid {
+	status = "okay";
+	apple,has-stm;
+	hid-country-code = <0>;
+};
diff --git a/arch/arm64/boot/dts/apple/t8122-j504.dts b/arch/arm64/boot/dts/apple/t8122-j504.dts
index e60ec3039196..05ae01262c85 100644
--- a/arch/arm64/boot/dts/apple/t8122-j504.dts
+++ b/arch/arm64/boot/dts/apple/t8122-j504.dts
@@ -18,6 +18,10 @@ / {
 	compatible = "apple,j504", "apple,t8122", "apple,arm-platform";
 	model = "Apple MacBook Pro (14-inch, M3, 2023)";
 
+	aliases {
+		keyboard = &mtp_hid;
+	};
+
 	led-controller {
 		compatible = "pwm-leds";
 
@@ -35,3 +39,21 @@ led-0 {
 &fpwm1 {
 	status = "okay";
 };
+
+&mtp_mbox {
+	status = "okay";
+};
+
+&mtp_dart {
+	status = "okay";
+};
+
+&mtp_dockchannel {
+	status = "okay";
+};
+
+&mtp_hid {
+	status = "okay";
+	apple,has-stm;
+	hid-country-code = <0>;
+};
diff --git a/arch/arm64/boot/dts/apple/t8122-j613.dts b/arch/arm64/boot/dts/apple/t8122-j613.dts
index 40274a983849..c6070cc4aa42 100644
--- a/arch/arm64/boot/dts/apple/t8122-j613.dts
+++ b/arch/arm64/boot/dts/apple/t8122-j613.dts
@@ -17,6 +17,10 @@ / {
 	compatible = "apple,j613", "apple,t8122", "apple,arm-platform";
 	model = "Apple MacBook Air (13-inch, M3, 2024)";
 
+	aliases {
+		keyboard = &mtp_hid;
+	};
+
 	led-controller {
 		compatible = "pwm-leds";
 
@@ -34,3 +38,21 @@ led-0 {
 &fpwm1 {
 	status = "okay";
 };
+
+&mtp_mbox {
+	status = "okay";
+};
+
+&mtp_dart {
+	status = "okay";
+};
+
+&mtp_dockchannel {
+	status = "okay";
+};
+
+&mtp_hid {
+	status = "okay";
+	apple,has-stm;
+	hid-country-code = <0>;
+};
diff --git a/arch/arm64/boot/dts/apple/t8122-j615.dts b/arch/arm64/boot/dts/apple/t8122-j615.dts
index 61833f6d019b..71bf2949d8a6 100644
--- a/arch/arm64/boot/dts/apple/t8122-j615.dts
+++ b/arch/arm64/boot/dts/apple/t8122-j615.dts
@@ -17,6 +17,10 @@ / {
 	compatible = "apple,j615", "apple,t8122", "apple,arm-platform";
 	model = "Apple MacBook Air (15-inch, M3, 2024)";
 
+	aliases {
+		keyboard = &mtp_hid;
+	};
+
 	led-controller {
 		compatible = "pwm-leds";
 
@@ -34,3 +38,21 @@ led-0 {
 &fpwm1 {
 	status = "okay";
 };
+
+&mtp_mbox {
+	status = "okay";
+};
+
+&mtp_dart {
+	status = "okay";
+};
+
+&mtp_dockchannel {
+	status = "okay";
+};
+
+&mtp_hid {
+	status = "okay";
+	apple,has-stm;
+	hid-country-code = <0>;
+};

-- 
2.56.0

