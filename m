From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 11 Jun 2024 13:10:57 +0800
Subject: [PATCH 1/3] dt-bindings: pinctrl: Add support for Amlogic A4 SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-a4_pinctrl-v1-1-dc487b1977b3@amlogic.com>
References: <20240611-a4_pinctrl-v1-0-dc487b1977b3@amlogic.com>
In-Reply-To: <20240611-a4_pinctrl-v1-0-dc487b1977b3@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718082658; l=4240;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=WJdLqydICRPbVCKDCtpTKEH09uhITX/xTeIPkd21RRQ=;
 b=PVSewCAjyLAxBYtjcUsmdwn415JiZNtIw03GJpTT6RaOOcEBj41islRy8V/RSzXvxA+MhCanC
 sPmwkT8iBFkCU0xsRg5JsoymYbsi5S2lS321dNcEECGHpeGhdaWWGyl
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the new compatible name for Amlogic A4 pin controller, and add
a new dt-binding header file which document the detail pin names.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml |  2 +
 .../dt-bindings/gpio/amlogic,a4-aobus-pinctrl.h    | 21 +++++
 .../dt-bindings/gpio/amlogic,a4-periphs-pinctrl.h  | 93 ++++++++++++++++++++++
 3 files changed, 116 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml
index d9e0b2c48e84..f5eefa0fab5b 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml
@@ -15,6 +15,8 @@ allOf:
 properties:
   compatible:
     enum:
+      - amlogic,a4-aobus-pinctrl
+      - amlogic,a4-periphs-pinctrl
       - amlogic,c3-periphs-pinctrl
       - amlogic,t7-periphs-pinctrl
       - amlogic,meson-a1-periphs-pinctrl
diff --git a/include/dt-bindings/gpio/amlogic,a4-aobus-pinctrl.h b/include/dt-bindings/gpio/amlogic,a4-aobus-pinctrl.h
new file mode 100644
index 000000000000..7c7e746baed5
--- /dev/null
+++ b/include/dt-bindings/gpio/amlogic,a4-aobus-pinctrl.h
@@ -0,0 +1,21 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2024 Amlogic, Inc. All rights reserved.
+ * Author: Xianwei Zhao <xianwei.zhao@amlogic.com>
+ */
+
+#ifndef _DT_BINDINGS_AMLOGIC_A4_AOBUS_PINCTRL_H
+#define _DT_BINDINGS_AMLOGIC_A4_AOBUS_PINCTRL_H
+
+/* GPIOAO */
+#define GPIOAO_0			0
+#define GPIOAO_1			1
+#define GPIOAO_2			2
+#define GPIOAO_3			3
+#define GPIOAO_4			4
+#define GPIOAO_5			5
+#define GPIOAO_6			6
+
+#define GPIO_TEST_N			7
+
+#endif
diff --git a/include/dt-bindings/gpio/amlogic,a4-periphs-pinctrl.h b/include/dt-bindings/gpio/amlogic,a4-periphs-pinctrl.h
new file mode 100644
index 000000000000..dfabca4b4790
--- /dev/null
+++ b/include/dt-bindings/gpio/amlogic,a4-periphs-pinctrl.h
@@ -0,0 +1,93 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2024 Amlogic, Inc. All rights reserved.
+ * Author: Xianwei Zhao <xianwei.zhao@amlogic.com>
+ */
+
+#ifndef _DT_BINDINGS_AMLOGIC_A4_PERIPHS_PINCTRL_H
+#define _DT_BINDINGS_AMLOGIC_A4_PERIPHS_PINCTRL_H
+
+/* GPIOE */
+#define GPIOE_0				0
+#define GPIOE_1				1
+
+/* GPIOD */
+#define GPIOD_0				2
+#define GPIOD_1				3
+#define GPIOD_2				4
+#define GPIOD_3				5
+#define GPIOD_4				6
+#define GPIOD_5				7
+#define GPIOD_6				8
+#define GPIOD_7				9
+#define GPIOD_8				10
+#define GPIOD_9				11
+#define GPIOD_10			12
+#define GPIOD_11			13
+#define GPIOD_12			14
+#define GPIOD_13			15
+#define GPIOD_14			16
+#define GPIOD_15			17
+
+/* GPIOB */
+#define GPIOB_0				18
+#define GPIOB_1				19
+#define GPIOB_2				20
+#define GPIOB_3				21
+#define GPIOB_4				22
+#define GPIOB_5				23
+#define GPIOB_6				24
+#define GPIOB_7				25
+#define GPIOB_8				26
+#define GPIOB_9				27
+#define GPIOB_10			28
+#define GPIOB_11			29
+#define GPIOB_12			30
+#define GPIOB_13			31
+
+/* GPIOX */
+#define GPIOX_0				32
+#define GPIOX_1				33
+#define GPIOX_2				34
+#define GPIOX_3				35
+#define GPIOX_4				36
+#define GPIOX_5				37
+#define GPIOX_6				38
+#define GPIOX_7				39
+#define GPIOX_8				40
+#define GPIOX_9				41
+#define GPIOX_10			42
+#define GPIOX_11			43
+#define GPIOX_12			44
+#define GPIOX_13			45
+#define GPIOX_14			46
+#define GPIOX_15			47
+#define GPIOX_16			48
+#define GPIOX_17			49
+
+/* GPIOT */
+#define GPIOT_0				50
+#define GPIOT_1				51
+#define GPIOT_2				52
+#define GPIOT_3				53
+#define GPIOT_4				54
+#define GPIOT_5				55
+#define GPIOT_6				56
+#define GPIOT_7				57
+#define GPIOT_8				58
+#define GPIOT_9				59
+#define GPIOT_10			60
+#define GPIOT_11			61
+#define GPIOT_12			62
+#define GPIOT_13			63
+#define GPIOT_14			64
+#define GPIOT_15			65
+#define GPIOT_16			66
+#define GPIOT_17			67
+#define GPIOT_18			68
+#define GPIOT_19			69
+#define GPIOT_20			70
+#define GPIOT_21			71
+#define GPIOT_22			72
+
+#endif

-- 
2.37.1

