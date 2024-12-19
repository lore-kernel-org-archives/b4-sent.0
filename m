From: Anthony Ruhier <aruhier@mailbox.org>
Date: Thu, 19 Dec 2024 16:49:04 +0100
Subject: [PATCH v2] arm64: dts: qcom: x1e80100-lenovo-yoga-slim7x: Add lid
 switch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241219-patch-lenovo-yoga-v2-1-4932aefcb9c8@mailbox.org>
X-B4-Tracking: v=1; b=H4sIAG9AZGcC/x3MQQqAIBBA0avErBvQwYi6SrQQm3IgNDSiCO+et
 HyL/1/InIQzjM0LiS/JEkMFtQ04b8PGKEs1kCKjSQ942NN53DnEK+ITN4u6N6ZzyirHBLU7Eq9
 y/89pLuUD0SiCVWMAAAA=
X-Change-ID: 20241219-patch-lenovo-yoga-17445c0a0ce2
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Anthony Ruhier <aruhier@mailbox.org>, 
 Maya Matuszczyk <maccraft123mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2730; i=aruhier@mailbox.org;
 h=from:subject:message-id; bh=TTMO6JsOBuxC/vkZ9rwpeM21isvIooWgkodHAdZY6GU=;
 b=owGbwMvMwCVW2Nrw47jsO3/G02pJDOkpDgVtahl7TtuZb3k67aY7i/IbuVcb1h6u1I/7dKqFp
 fL55yrDjlIWBjEuBlkxRZaS/VHCt1U67jusXc4CM4eVCWQIAxenAEyEwYzhn8HcSxtjVh65vd+q
 n6X1lzbD2cjFnXfyDoRsXLFswcV49lWMDD1Oq7asmdoa+4i/ZqXKs+VChgs1c6S3SqTfeJuS6VO
 9kB8A
X-Developer-Key: i=aruhier@mailbox.org; a=openpgp;
 fpr=F4A378DD8D494AE48EBA554CB00FBC7D08D231D9
X-Endpoint-Received: by B4 Relay for aruhier@mailbox.org/default with auth_id=302
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the lid switch for the Lenovo Yoga Slim 7x.

Other x1e80100 laptops use the GPIO pin 92 only, however on the Yoga
Slim 7x this pin seems to be bridged with the pin 71. By default, the
pin 71 is set as output-high, which blocks any event on pin 92.

This patch sets the pin 71 as output-disable and sets the LID switch on
pin 92. This is aligned with how they're configured on Windows:
    GPIO  71 | 0xf147000 | in | func0 | hi | pull up   | 16 mA
    GPIO  92 | 0xf15c000 | in | func0 | lo | no pull   |  2 mA

Signed-off-by: Anthony Ruhier <aruhier@mailbox.org>
---
Changes in v2:
- Fixes patch format.

Tested-by: Maya Matuszczyk <maccraft123mc@gmail.com>
---
 .../boot/dts/qcom/x1e80100-lenovo-yoga-slim7x.dts  | 38 ++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-lenovo-yoga-slim7x.dts b/arch/arm64/boot/dts/qcom/x1e80100-lenovo-yoga-slim7x.dts
index ca5a808f2c7df66a861a933df407fd4bdaea3fe1..311202aa9015a30f1d70108bb214d427f811dc3b 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-lenovo-yoga-slim7x.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-lenovo-yoga-slim7x.dts
@@ -6,6 +6,7 @@
 /dts-v1/;
 
 #include <dt-bindings/gpio/gpio.h>
+#include <dt-bindings/input/gpio-keys.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 
 #include "x1e80100.dtsi"
@@ -19,6 +20,21 @@ aliases {
 		serial0 = &uart21;
 	};
 
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		pinctrl-0 = <&hall_int_n_default>;
+		pinctrl-names = "default";
+
+		switch-lid {
+			gpios = <&tlmm 92 GPIO_ACTIVE_LOW>;
+			linux,input-type = <EV_SW>;
+			linux,code = <SW_LID>;
+			wakeup-source;
+			wakeup-event-action = <EV_ACT_DEASSERTED>;
+		};
+	};
+
 	chosen {
 		stdout-path = "serial0:115200n8";
 	};
@@ -811,6 +827,28 @@ edp_reg_en: edp-reg-en-state {
 		bias-disable;
 	};
 
+	hall_int_n_default: hall-int-n-state {
+		lid-n-pins {
+			pins = "gpio92";
+			function = "gpio";
+			bias-disable;
+		};
+
+		/*
+		 * Pins 71 and 92 seem to be bridged together (pin 71 and 92 show the same
+		 * events). By default, pin 71 is set as output-high, which blocks any
+		 * event on pin 92. Output-disable on pin 71 is necessary to get events on
+		 * pin 92.
+		 * The purpose of pin 71 is not yet known; lid-pull is a supposition.
+		 */
+		lid-pull-n-pins {
+			pins = "gpio71";
+			function = "gpio";
+			bias-pull-up;
+			output-disable;
+		};
+	};
+
 	kybd_default: kybd-default-state {
 		pins = "gpio67";
 		function = "gpio";

---
base-commit: 78d4f34e2115b517bcbfe7ec0d018bbbb6f9b0b8
change-id: 20241219-patch-lenovo-yoga-17445c0a0ce2

Best regards,
-- 
Anthony Ruhier <aruhier@mailbox.org>

