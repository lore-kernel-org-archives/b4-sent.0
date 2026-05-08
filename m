From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 08 May 2026 07:36:54 +0000
Subject: [PATCH 1/3] irqchip/meson-gpio: fix incorrect register address
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-a9-gpio-irqchip-v1-1-9dc5f3e022e0@amlogic.com>
References: <20260508-a9-gpio-irqchip-v1-0-9dc5f3e022e0@amlogic.com>
In-Reply-To: <20260508-a9-gpio-irqchip-v1-0-9dc5f3e022e0@amlogic.com>
To: Thomas Gleixner <tglx@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778225816; l=1007;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=M9zM13CLYOdG+lkNB/tDdOWTKQ5cZ8tHYqZIsNYUo+4=;
 b=qZctPN2tSMJSPBgkkvRhlV2W+Ntn38soTuIOLXMPw7l1tQGc2KIYT5X8SsQjTaTjoAzgCj9i+
 3tfomMZgj8gASyXaPOMb3Rs1X/ws7vR2ku7AfIfYNw9mKkB/EB2f9SQ
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When set gpio irq type(level and single-edge) for S4, register address is
REG_EDGE_POL, not both-edge trigger register. This patch fix it.

Fixes: bbd6fcc76b39 ("irqchip: Add support for Amlogic A4 and A5 SoCs")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/irqchip/irq-meson-gpio.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/irqchip/irq-meson-gpio.c b/drivers/irqchip/irq-meson-gpio.c
index f722e9c57e2e..74a376ef452e 100644
--- a/drivers/irqchip/irq-meson-gpio.c
+++ b/drivers/irqchip/irq-meson-gpio.c
@@ -415,8 +415,7 @@ static int meson_s4_gpio_irq_set_type(struct meson_gpio_irq_controller *ctl,
 	if (type & (IRQ_TYPE_EDGE_RISING | IRQ_TYPE_EDGE_FALLING))
 		val |= BIT(ctl->params->edge_single_offset + idx);
 
-	meson_gpio_irq_update_bits(ctl, params->edge_pol_reg,
-				   BIT(idx) | BIT(12 + idx), val);
+	meson_gpio_irq_update_bits(ctl, REG_EDGE_POL, BIT(idx) | BIT(12 + idx), val);
 	return 0;
 };
 

-- 
2.52.0

