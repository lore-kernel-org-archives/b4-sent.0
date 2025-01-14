From: Ricky Cheung <rcheung844@gmail.com>
Date: Tue, 14 Jan 2025 22:46:50 +0800
Subject: [PATCH RESEND v2 3/3] arm64: dts: qcom:
 msm8916-xiaoxun-jz0145-v33: Add initial device tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250114-xiaoxun-jz0145-v33-v2-3-495e986579ce@gmail.com>
References: <20250114-xiaoxun-jz0145-v33-v2-0-495e986579ce@gmail.com>
In-Reply-To: <20250114-xiaoxun-jz0145-v33-v2-0-495e986579ce@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Ricky Cheung <rcheung844@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736866013; l=2981;
 i=rcheung844@gmail.com; s=20250114; h=from:subject:message-id;
 bh=aIMQMh96vCDp6yLLJW7U1OCy3sPhGfKYSD82VLXOyKc=;
 b=Q9gCbGyNmj2MC/WTb3BTCarJrM+iQpvKWnQeA+GZ9Kdo/XuMKmuIhBvGAtL7sLBax9LU/zDK0
 JEjkA+kIma0APajAAMo+AtZS8/gtPNjKeqX/tG1tdAE1m+AGgSdYx6T
X-Developer-Key: i=rcheung844@gmail.com; a=ed25519;
 pk=JjZsSnuDD1xuR4EXY4XGKELgToA++HxxheDlHU/41yI=
X-Endpoint-Received: by B4 Relay for rcheung844@gmail.com/20250114 with auth_id=323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit implements support for the JZ0145 v33 WiFi/LTE dongle
based on MSM8916, which was sold by XiaoXun BiCheng Technology.

The stock bootloader could boot with this patch with lk2nd, but only
one CPU core would be enabled. Enablement for all CPU cores require
lk1st and d410c firmware files.

Currently supported / tested:
- All CPU cores
- Buttons
- LEDs
- Modem
- SDHC
- USB Device Mode

Although I do not have UART equipment on hand, UART should function
and is labelled on the PCB of this device.

Signed-off-by: Ricky Cheung <rcheung844@gmail.com>
---
 arch/arm64/boot/dts/qcom/Makefile                  |  1 +
 .../boot/dts/qcom/msm8916-xiaoxun-jz0145-v33.dts   | 66 ++++++++++++++++++++++
 2 files changed, 67 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/Makefile b/arch/arm64/boot/dts/qcom/Makefile
index ae002c7cf1268a6f848fefdfadbd746091ee517b..ce8d4a731645e012f1222a130f068b62cacaa514 100644
--- a/arch/arm64/boot/dts/qcom/Makefile
+++ b/arch/arm64/boot/dts/qcom/Makefile
@@ -58,6 +58,7 @@ dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-thwc-ufi001c.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-wingtech-wt86518.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-wingtech-wt86528.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-wingtech-wt88047.dtb
+dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-xiaoxun-jz0145-v33.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8916-yiming-uz801v3.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8929-wingtech-wt82918hd.dtb
 dtb-$(CONFIG_ARCH_QCOM)	+= msm8939-huawei-kiwi.dtb
diff --git a/arch/arm64/boot/dts/qcom/msm8916-xiaoxun-jz0145-v33.dts b/arch/arm64/boot/dts/qcom/msm8916-xiaoxun-jz0145-v33.dts
new file mode 100644
index 0000000000000000000000000000000000000000..7f1049e111b37213eeadc6a247d4cf21e7e0cd5f
--- /dev/null
+++ b/arch/arm64/boot/dts/qcom/msm8916-xiaoxun-jz0145-v33.dts
@@ -0,0 +1,66 @@
+// SPDX-License-Identifier: GPL-2.0-only
+
+/dts-v1/;
+
+#include "msm8916-ufi.dtsi"
+
+/ {
+	model = "JZ0145 v33 4G Modem Stick";
+	compatible = "xiaoxun,jz0145-v33", "qcom,msm8916";
+};
+
+&button_restart {
+	gpios = <&tlmm 37 GPIO_ACTIVE_HIGH>;
+};
+
+&led_b {
+	gpios = <&tlmm 8 GPIO_ACTIVE_HIGH>;
+};
+
+&led_g {
+	gpios = <&tlmm 7 GPIO_ACTIVE_HIGH>;
+};
+
+&led_r {
+	gpios = <&tlmm 6 GPIO_ACTIVE_HIGH>;
+};
+
+&mpss {
+	pinctrl-0 = <&sim_ctrl_default>;
+	pinctrl-names = "default";
+};
+
+&button_default {
+	pins = "gpio37";
+	bias-pull-down;
+};
+
+&gpio_leds_default {
+	pins = "gpio6", "gpio7", "gpio8";
+};
+
+/* This selects the external SIM card slot by default */
+&tlmm {
+	sim_ctrl_default: sim-ctrl-default-state {
+		esim-sel-pins {
+			pins = "gpio22", "gpio23";
+			function = "gpio";
+			bias-disable;
+			output-low;
+		};
+
+		sim-en-pins {
+			pins = "gpio1";
+			function = "gpio";
+			bias-disable;
+			output-low;
+		};
+
+		sim-sel-pins {
+			pins = "gpio20";
+			function = "gpio";
+			bias-disable;
+			output-high;
+		};
+	};
+};

-- 
2.47.1

