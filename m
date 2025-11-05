From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 05 Nov 2025 17:45:33 +0800
Subject: [PATCH 2/5] irqchip: Add support for Amlogic S6 S7 and S7D SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251105-irqchip-gpio-s6-s7-s7d-v1-2-b4d1fe4781c1@amlogic.com>
References: <20251105-irqchip-gpio-s6-s7-s7d-v1-0-b4d1fe4781c1@amlogic.com>
In-Reply-To: <20251105-irqchip-gpio-s6-s7-s7d-v1-0-b4d1fe4781c1@amlogic.com>
To: Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762336003; l=2575;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=8Qj9MLaQxbWjp8ZestvxizI5mF05EIMU/HlW0eH6014=;
 b=4RZQDlQ+vZEZoK73tT8R8TxrKC/7YG83xJ+YyAtAFiEh5hkkvEU9clUHwiGPkK2/C66L38kaK
 xnfyJ0ve5FvDLpxf4C/YxVsQsmL16A3U86H5gjXNt2wy3J/9/IGtum/
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Amlogic S6/S7/S7D SoCs support 12 GPIO IRQ lines,
details are as below.

    S6 IRQ Number:
    - 99:98    2 pins on bank CC
    - 97       1 pin  on bank TESTN
    - 96:81   16 pins on bank A
    - 80:65   16 pins on bank Z
    - 64:45   20 pins on bank X
    - 44:37    8 pins on bank H offs H1
    - 36:32    5 pins on bank F
    - 31:25    7 pins on bank D
    - 24:22    3 pins on bank E
    - 21:14    8 pins on bank C
    - 13:0    14 pins on bank B

    S7 IRQ Number:
    - 83:82    2 pins on bank CC
    - 81       1 pin  on bank TESTN
    - 80:68   13 pins on bank Z
    - 67:48   20 pins on bank X
    - 47:36   12 pins on bank H
    - 35:24   12 pins on bank D
    - 23:22    2 pins on bank E
    - 21:14    8 pins on bank C
    - 13:0    14 pins on bank B

    S7D IRQ Number:
    - 83:82    2 pins on bank CC
    - 81:75    7 pins on bank DV
    - 74       1 pin  on bank TESTN
    - 73:61   13 pins on bank Z
    - 60:41   20 pins on bank X
    - 40:29   12 pins on bank H
    - 28:24    5 pins on bank D
    - 23:22    2 pins on bank E
    - 21:14    8 pins on bank C
    - 13:0    14 pins on bank B

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/irqchip/irq-meson-gpio.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/irqchip/irq-meson-gpio.c b/drivers/irqchip/irq-meson-gpio.c
index 7d177626d64b..7e718b07e960 100644
--- a/drivers/irqchip/irq-meson-gpio.c
+++ b/drivers/irqchip/irq-meson-gpio.c
@@ -174,6 +174,14 @@ static const struct meson_gpio_irq_params s4_params = {
 	INIT_MESON_S4_COMMON_DATA(82)
 };
 
+static const struct meson_gpio_irq_params s6_params = {
+	INIT_MESON_S4_COMMON_DATA(100)
+};
+
+static const struct meson_gpio_irq_params s7_params = {
+	INIT_MESON_S4_COMMON_DATA(84)
+};
+
 static const struct meson_gpio_irq_params c3_params = {
 	INIT_MESON_S4_COMMON_DATA(55)
 };
@@ -195,6 +203,9 @@ static const struct of_device_id meson_irq_gpio_matches[] __maybe_unused = {
 	{ .compatible = "amlogic,a4-gpio-ao-intc", .data = &a4_ao_params },
 	{ .compatible = "amlogic,a4-gpio-intc", .data = &a4_params },
 	{ .compatible = "amlogic,a5-gpio-intc", .data = &a5_params },
+	{ .compatible = "amlogic,s6-gpio-intc", .data = &s6_params },
+	{ .compatible = "amlogic,s7-gpio-intc", .data = &s7_params },
+	{ .compatible = "amlogic,s7d-gpio-intc", .data = &s7_params },
 	{ .compatible = "amlogic,c3-gpio-intc", .data = &c3_params },
 	{ .compatible = "amlogic,t7-gpio-intc", .data = &t7_params },
 	{ }

-- 
2.37.1

