From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 14 Oct 2024 17:05:51 +0800
Subject: [PATCH v2 1/3] dt-bindings: pinctrl: Add support for Amlogic A4
 SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241014-a4_pinctrl-v2-1-3e74a65c285e@amlogic.com>
References: <20241014-a4_pinctrl-v2-0-3e74a65c285e@amlogic.com>
In-Reply-To: <20241014-a4_pinctrl-v2-0-3e74a65c285e@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728896762; l=2278;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=tfEbx/nawoF1xymN0PzEB9cyZ2GpGq42qC+H+M4aI/8=;
 b=hbSz+mu67oz8Xm3gwvv7Dh0vl4KUYQSgtNRar5EuSG7izhaLeElmw5rswB13rHysVOkjfsYat
 Oxl87PcxB9HD0SW7ijUpWi5fv4tZyx+2WMCKICJSOJ0qIMNpn7HYo7e
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the new compatible name for Amlogic A4 pin controller, and add
a new dt-binding header file which document the detail pin names.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml |  2 ++
 include/dt-bindings/gpio/amlogic-a4-gpio.h         | 38 ++++++++++++++++++++++
 2 files changed, 40 insertions(+)

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
diff --git a/include/dt-bindings/gpio/amlogic-a4-gpio.h b/include/dt-bindings/gpio/amlogic-a4-gpio.h
new file mode 100644
index 000000000000..e39f5e041875
--- /dev/null
+++ b/include/dt-bindings/gpio/amlogic-a4-gpio.h
@@ -0,0 +1,38 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2024 Amlogic, Inc. All rights reserved.
+ * Author: Xianwei Zhao <xianwei.zhao@amlogic.com>
+ */
+
+#ifndef _DT_BINDINGS_AMLOGIC_A4_GPIO_H
+#define _DT_BINDINGS_AMLOGIC_A4_GPIO_H
+
+/* Standard port */
+#define GPIOB_START	0
+#define GPIOB_NUM	14
+
+#define GPIOD_START	(GPIOB_START + GPIOB_NUM)
+#define GPIOD_NUM	16
+
+#define GPIOE_START	(GPIOD_START + GPIOD_NUM)
+#define GPIOE_NUM	2
+
+#define GPIOT_START	(GPIOE_START + GPIOE_NUM)
+#define GPIOT_NUM	23
+
+#define GPIOX_START	(GPIOT_START + GPIOT_NUM)
+#define GPIOX_NUM	18
+
+#define PERIPHS_PIN_NUM	(GPIOX_START + GPIOX_NUM)
+
+/* Aobus port */
+#define GPIOAO_START	0
+#define GPIOAO_NUM	7
+
+/* It's a special definition, put at the end, just 1 num */
+#define	GPIO_TEST_N	(GPIOAO_START +  GPIOAO_NUM)
+#define	AOBUS_PIN_NUM	(GPIO_TEST_N + 1)
+
+#define AMLOGIC_GPIO(port, offset)	(port##_START + (offset))
+
+#endif /* _DT_BINDINGS_AMLOGIC_A4_GPIO_H */

-- 
2.37.1

