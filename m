From: Michael Reeves <michael.reeves077@gmail.com>
Date: Tue, 30 Jun 2026 22:54:37 +1000
Subject: [PATCH 09/10] arm64: dts: apple: Add MTP DockChannel HID nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260630-apple-mtp-keyboard-final-v1-9-506d936a1707@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782824083; l=6768;
 i=michael.reeves077@gmail.com; s=20260105; h=from:subject:message-id;
 bh=bMwqHA+Egy8OA2vhAFSY5t62oYeUho9ZB0NPCjtkjoI=;
 b=PguWqSaT4+ksTgvbKhxg8jxpkvQ1bdIqmorWcBIGRWuyt9Yf22sPwdVtn6OWDD0FQV22T1CpK
 8YSeNGIIi81B417YM/EHCuSBcorSLyWiC1AHqedenxvjoQ3mHSQ2WNB
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=QIrgWBGCm3LG0YYc6MLCDkwuVXLTGGooVBdWX/KhSiU=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20260105 with auth_id=591
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add disabled MTP nodes for the Apple SoCs used by M2 and M3 systems.

Each instance describes the RTKit ASC mailbox, MTP DART, DockChannel
mailbox, and DockChannel HID client. Board files can enable them on
machines that route internal input through MTP.

Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 arch/arm64/boot/dts/apple/t602x-die0.dtsi | 46 ++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112.dtsi      | 46 ++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8122.dtsi      | 47 +++++++++++++++++++++++++++++++
 3 files changed, 139 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t602x-die0.dtsi b/arch/arm64/boot/dts/apple/t602x-die0.dtsi
index 8622ddea7b44..edc73682fd22 100644
--- a/arch/arm64/boot/dts/apple/t602x-die0.dtsi
+++ b/arch/arm64/boot/dts/apple/t602x-die0.dtsi
@@ -150,6 +150,52 @@ pinctrl_smc: pinctrl@2a2820000 {
 				<AIC_IRQ 0 857 IRQ_TYPE_LEVEL_HIGH>;
 	};
 
+	mtp_mbox: mbox@2a9408000 {
+		compatible = "apple,t6020-asc-mailbox", "apple,asc-mailbox-v4";
+		reg = <0x2 0xa9408000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ 0 693 IRQ_TYPE_LEVEL_HIGH>,
+			     <AIC_IRQ 0 694 IRQ_TYPE_LEVEL_HIGH>,
+			     <AIC_IRQ 0 695 IRQ_TYPE_LEVEL_HIGH>,
+			     <AIC_IRQ 0 696 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "send-empty", "send-not-empty",
+				  "recv-empty", "recv-not-empty";
+		#mbox-cells = <0>;
+		status = "disabled";
+	};
+
+	mtp_dart: iommu@2a9808000 {
+		compatible = "apple,t6020-dart", "apple,t8110-dart";
+		reg = <0x2 0xa9808000 0x0 0x4000>;
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ 0 676 IRQ_TYPE_LEVEL_HIGH>;
+		#iommu-cells = <1>;
+		status = "disabled";
+	};
+
+	mtp_dockchannel: mailbox@2a9b14000 {
+		compatible = "apple,t6020-dockchannel", "apple,t8112-dockchannel";
+		reg = <0x2 0xa9b14000 0x0 0x4000>,
+		      <0x2 0xa9b30000 0x0 0x4000>,
+		      <0x2 0xa9b34000 0x0 0x4000>;
+		reg-names = "irq", "config", "data";
+		interrupt-parent = <&aic>;
+		interrupts = <AIC_IRQ 0 677 IRQ_TYPE_LEVEL_HIGH>;
+		#mbox-cells = <0>;
+		status = "disabled";
+	};
+
+	mtp_hid: hid@2a9400000 {
+		compatible = "apple,t6020-dockchannel-hid", "apple,t8112-dockchannel-hid";
+		reg = <0x2 0xa9400000 0x0 0x4000>,
+		      <0x2 0xa9c00000 0x0 0x100000>;
+		reg-names = "coproc-asc", "coproc-sram";
+		mboxes = <&mtp_mbox>, <&mtp_dockchannel>;
+		mbox-names = "asc", "dockchannel";
+		iommus = <&mtp_dart 1>;
+		status = "disabled";
+	};
+
 	sio_dart: iommu@39b008000 {
 		compatible = "apple,t6020-dart", "apple,t8110-dart";
 		reg = <0x3 0x9b008000 0x0 0x8000>;
diff --git a/arch/arm64/boot/dts/apple/t8112.dtsi b/arch/arm64/boot/dts/apple/t8112.dtsi
index 85c47422d4e8..8411828c0772 100644
--- a/arch/arm64/boot/dts/apple/t8112.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112.dtsi
@@ -983,6 +983,52 @@ pinctrl_aop: pinctrl@24a820000 {
 				     <AIC_IRQ 307 IRQ_TYPE_LEVEL_HIGH>;
 		};
 
+		mtp_mbox: mbox@24e408000 {
+			compatible = "apple,t8112-asc-mailbox", "apple,asc-mailbox-v4";
+			reg = <0x2 0x4e408000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 864 IRQ_TYPE_LEVEL_HIGH>,
+				     <AIC_IRQ 865 IRQ_TYPE_LEVEL_HIGH>,
+				     <AIC_IRQ 866 IRQ_TYPE_LEVEL_HIGH>,
+				     <AIC_IRQ 867 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "send-empty", "send-not-empty",
+					  "recv-empty", "recv-not-empty";
+			#mbox-cells = <0>;
+			status = "disabled";
+		};
+
+		mtp_dart: iommu@24e808000 {
+			compatible = "apple,t8110-dart";
+			reg = <0x2 0x4e808000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 848 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <1>;
+			status = "disabled";
+		};
+
+		mtp_dockchannel: mailbox@24eb14000 {
+			compatible = "apple,t8112-dockchannel";
+			reg = <0x2 0x4eb14000 0x0 0x4000>,
+			      <0x2 0x4eb30000 0x0 0x4000>,
+			      <0x2 0x4eb34000 0x0 0x4000>;
+			reg-names = "irq", "config", "data";
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 850 IRQ_TYPE_LEVEL_HIGH>;
+			#mbox-cells = <0>;
+			status = "disabled";
+		};
+
+		mtp_hid: hid@24e400000 {
+			compatible = "apple,t8112-dockchannel-hid";
+			reg = <0x2 0x4e400000 0x0 0x4000>,
+			      <0x2 0x4ec00000 0x0 0x100000>;
+			reg-names = "coproc-asc", "coproc-sram";
+			mboxes = <&mtp_mbox>, <&mtp_dockchannel>;
+			mbox-names = "asc", "dockchannel";
+			iommus = <&mtp_dart 1>;
+			status = "disabled";
+		};
+
 		ans_mbox: mbox@277408000 {
 			compatible = "apple,t8112-asc-mailbox", "apple,asc-mailbox-v4";
 			reg = <0x2 0x77408000 0x0 0x4000>;
diff --git a/arch/arm64/boot/dts/apple/t8122.dtsi b/arch/arm64/boot/dts/apple/t8122.dtsi
index c6196225e96e..ec1f47d15ec9 100644
--- a/arch/arm64/boot/dts/apple/t8122.dtsi
+++ b/arch/arm64/boot/dts/apple/t8122.dtsi
@@ -438,6 +438,53 @@ pinctrl_aop: pinctrl@2f4824000 {
 				     <AIC_IRQ 351 IRQ_TYPE_LEVEL_HIGH>,
 				     <AIC_IRQ 352 IRQ_TYPE_LEVEL_HIGH>;
 		};
+
+		mtp_mbox: mbox@2fa408000 {
+			compatible = "apple,t8122-asc-mailbox", "apple,asc-mailbox-v4";
+			reg = <0x2 0xfa408000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 838 IRQ_TYPE_LEVEL_HIGH>,
+				     <AIC_IRQ 839 IRQ_TYPE_LEVEL_HIGH>,
+				     <AIC_IRQ 840 IRQ_TYPE_LEVEL_HIGH>,
+				     <AIC_IRQ 841 IRQ_TYPE_LEVEL_HIGH>;
+			interrupt-names = "send-empty", "send-not-empty",
+					  "recv-empty", "recv-not-empty";
+			#mbox-cells = <0>;
+			status = "disabled";
+		};
+
+		mtp_dart: iommu@2fa808000 {
+			compatible = "apple,t8122-dart", "apple,t8110-dart";
+			reg = <0x2 0xfa808000 0x0 0x4000>;
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 822 IRQ_TYPE_LEVEL_HIGH>;
+			#iommu-cells = <1>;
+			status = "disabled";
+		};
+
+		mtp_dockchannel: mailbox@2fab14000 {
+			compatible = "apple,t8122-dockchannel", "apple,t8112-dockchannel";
+			reg = <0x2 0xfab14000 0x0 0x4000>,
+			      <0x2 0xfab30000 0x0 0x4000>,
+			      <0x2 0xfab34000 0x0 0x4000>;
+			reg-names = "irq", "config", "data";
+			interrupt-parent = <&aic>;
+			interrupts = <AIC_IRQ 824 IRQ_TYPE_LEVEL_HIGH>;
+			#mbox-cells = <0>;
+			status = "disabled";
+		};
+
+		mtp_hid: hid@2fa400000 {
+			compatible = "apple,t8122-dockchannel-hid",
+				     "apple,t8112-dockchannel-hid";
+			reg = <0x2 0xfa400000 0x0 0x4000>,
+			      <0x2 0xfac00000 0x0 0x100000>;
+			reg-names = "coproc-asc", "coproc-sram";
+			mboxes = <&mtp_mbox>, <&mtp_dockchannel>;
+			mbox-names = "asc", "dockchannel";
+			iommus = <&mtp_dart 1>;
+			status = "disabled";
+		};
 	};
 };
 

-- 
2.51.2

