From: Michael Reeves <michael.reeves077@gmail.com>
Date: Tue, 30 Jun 2026 22:54:38 +1000
Subject: [PATCH 10/10] arm64: dts: apple: Enable DockChannel HID on M2 and
 M3 laptops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260630-apple-mtp-keyboard-final-v1-10-506d936a1707@gmail.com>
References: <20260630-apple-mtp-keyboard-final-v1-0-506d936a1707@gmail.com>
In-Reply-To: <20260630-apple-mtp-keyboard-final-v1-0-506d936a1707@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-input@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782824083; l=6180;
 i=michael.reeves077@gmail.com; s=20260105; h=from:subject:message-id;
 bh=tv27VX+CaTGZeapPRJMnGAMPH4P1r9z5DHhM9G5AeOE=;
 b=zWEgyKLqb7DYVLvaL+tRccLtoK0/mCGzg4iLmXtFH8zbgRDoMOuTzjnwtAwiOBUUdzqKDaSVd
 u96i5HuJzPLA0KJi2OEMocQlcZP1UlTnM2yym4ZyJhgOtzNjVxCUy77
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=QIrgWBGCm3LG0YYc6MLCDkwuVXLTGGooVBdWX/KhSiU=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20260105 with auth_id=591
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the MTP mailbox, DART, DockChannel mailbox, and HID transport on
the M2 and M3 laptop device trees using this internal input path.

Add a keyboard alias and keyboard child node for each machine so the
transport can expose the internal keyboard.

Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi | 25 +++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112-j413.dts       | 20 ++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112-j415.dts       | 20 ++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112-j493.dts       | 22 +++++++++++++++++++++-
 arch/arm64/boot/dts/apple/t8122-j504.dts       | 22 ++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8122-j613.dts       | 23 +++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8122-j615.dts       | 23 +++++++++++++++++++++++
 7 files changed, 154 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi b/arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi
index 0e806d8ddf81..46ed5ea86242 100644
--- a/arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi
+++ b/arch/arm64/boot/dts/apple/t602x-j414-j416.dtsi
@@ -16,6 +16,12 @@
 
 #include "t600x-j314-j316.dtsi"
 
+/ {
+	aliases {
+		keyboard = &keyboard;
+	};
+};
+
 &framebuffer0 {
 	power-domains = <&ps_disp0_cpu0>, <&ps_dptx_phy_ps>;
 };
@@ -43,3 +49,22 @@ &wifi0 {
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
+
+	keyboard: keyboard {
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t8112-j413.dts b/arch/arm64/boot/dts/apple/t8112-j413.dts
index 1a08a41f369b..1256e7cd9876 100644
--- a/arch/arm64/boot/dts/apple/t8112-j413.dts
+++ b/arch/arm64/boot/dts/apple/t8112-j413.dts
@@ -20,6 +20,7 @@ / {
 
 	aliases {
 		bluetooth0 = &bluetooth0;
+		keyboard = &keyboard;
 		wifi0 = &wifi0;
 	};
 
@@ -91,3 +92,22 @@ &i2c4 {
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
+
+	keyboard: keyboard {
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t8112-j415.dts b/arch/arm64/boot/dts/apple/t8112-j415.dts
index e37c56d9fb4d..1db3500e991f 100644
--- a/arch/arm64/boot/dts/apple/t8112-j415.dts
+++ b/arch/arm64/boot/dts/apple/t8112-j415.dts
@@ -20,6 +20,7 @@ / {
 
 	aliases {
 		bluetooth0 = &bluetooth0;
+		keyboard = &keyboard;
 		wifi0 = &wifi0;
 	};
 
@@ -91,3 +92,22 @@ &i2c4 {
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
+
+	keyboard: keyboard {
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t8112-j493.dts b/arch/arm64/boot/dts/apple/t8112-j493.dts
index ec116da3e4dd..5deb2dd9802a 100644
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
+		keyboard = &keyboard;
 		touchbar0 = &touchbar0;
 		wifi0 = &wifi0;
 	};
@@ -146,3 +147,22 @@ touchbar0: touchbar@0 {
 		touchscreen-inverted-y;
 	};
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
+
+	keyboard: keyboard {
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t8122-j504.dts b/arch/arm64/boot/dts/apple/t8122-j504.dts
index 464491b55b01..0d93ac72fff9 100644
--- a/arch/arm64/boot/dts/apple/t8122-j504.dts
+++ b/arch/arm64/boot/dts/apple/t8122-j504.dts
@@ -18,6 +18,10 @@ / {
 	compatible = "apple,j504", "apple,t8122", "apple,arm-platform";
 	model = "Apple MacBook Pro (14-inch, M3, 2023)";
 
+	aliases {
+		keyboard = &keyboard;
+	};
+
 	led-controller {
 		compatible = "pwm-leds";
 		led-0 {
@@ -35,3 +39,21 @@ &fpwm1 {
 	status = "okay";
 };
 
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
+
+	keyboard: keyboard {
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t8122-j613.dts b/arch/arm64/boot/dts/apple/t8122-j613.dts
index 51894ea705e7..e77b1ad869eb 100644
--- a/arch/arm64/boot/dts/apple/t8122-j613.dts
+++ b/arch/arm64/boot/dts/apple/t8122-j613.dts
@@ -17,6 +17,10 @@ / {
 	compatible = "apple,j613", "apple,t8122", "apple,arm-platform";
 	model = "Apple MacBook Air (13-inch, M3, 2024)";
 
+	aliases {
+		keyboard = &keyboard;
+	};
+
 	led-controller {
 		compatible = "pwm-leds";
 		led-0 {
@@ -33,3 +37,22 @@ led-0 {
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
+
+	keyboard: keyboard {
+	};
+};
diff --git a/arch/arm64/boot/dts/apple/t8122-j615.dts b/arch/arm64/boot/dts/apple/t8122-j615.dts
index 2a1970c1bc90..5da0021d40f8 100644
--- a/arch/arm64/boot/dts/apple/t8122-j615.dts
+++ b/arch/arm64/boot/dts/apple/t8122-j615.dts
@@ -17,6 +17,10 @@ / {
 	compatible = "apple,j615", "apple,t8122", "apple,arm-platform";
 	model = "Apple MacBook Air (15-inch, M3, 2024)";
 
+	aliases {
+		keyboard = &keyboard;
+	};
+
 	led-controller {
 		compatible = "pwm-leds";
 		led-0 {
@@ -33,3 +37,22 @@ led-0 {
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
+
+	keyboard: keyboard {
+	};
+};

-- 
2.51.2

