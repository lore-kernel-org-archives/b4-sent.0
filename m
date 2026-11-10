From: Long Zhao <longzhao@ambarella.com>
Date: Tue, 10 Nov 2026 12:32:33 +0800
Subject: [PATCH v14 08/14] gpio: pl061: keep the parent device in a local
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-cv75-gpio-v14-8-e586aad0467a@ambarella.com>
References: <20261110-cv75-gpio-v14-0-e586aad0467a@ambarella.com>
In-Reply-To: <20261110-cv75-gpio-v14-0-e586aad0467a@ambarella.com>
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, Mika Westerberg <westeri@kernel.org>, 
 devicetree@vger.kernel.org, Long Zhao <longzhao@ambarella.com>, 
 Long Zhao <zl020895@163.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794285162; l=3327;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=U7nepCgkgjETq5eVgsmzh5zmWKMmPTFdo3YH5lWwtPQ=;
 b=Hcb7eyqbLjEgVWScLntr8tmV4hUvl+V1v3XdlWUerIaAMb+lQUoR3kG1jUV0OFuweyob55lnT
 i59bJAWAypkDK/ENB7X7y1Fr9DhdaqYb8AzPjAiIbKT4254XW0JIFnP
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IRQ logging uses gc->parent. Keep that device in a local so the
gpio-regmap switch can change where it comes from without rewriting
every log line.

Suggested-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Reviewed-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Reviewed-by: Linus Walleij <linusw@kernel.org>
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/gpio-pl061.c | 15 ++++++++-------
 1 file changed, 8 insertions(+), 7 deletions(-)

diff --git a/drivers/gpio/gpio-pl061.c b/drivers/gpio/gpio-pl061.c
index a232b63fbc0b..27ed759486ca 100644
--- a/drivers/gpio/gpio-pl061.c
+++ b/drivers/gpio/gpio-pl061.c
@@ -156,6 +156,7 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(d);
 	struct pl061 *pl061 = gpiochip_get_data(gc);
+	struct device *parent = gc->parent;
 	int offset = irqd_to_hwirq(d);
 	unsigned int bit = BIT(offset);
 	unsigned int gpioiev = 0;
@@ -166,7 +167,7 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 		return -EINVAL;
 
 	if ((trigger & IRQ_TYPE_LEVEL_MASK) && (trigger & IRQ_TYPE_EDGE_BOTH)) {
-		dev_err(gc->parent,
+		dev_err(parent,
 			"trying to configure line %d for both level and edge "
 			"detection, choose one!\n",
 			offset);
@@ -192,7 +193,7 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 		else
 			gpioiev &= ~bit;
 		irq_set_handler_locked(d, handle_level_irq);
-		dev_dbg(gc->parent, "line %d: IRQ on %s level\n",
+		dev_dbg(parent, "line %d: IRQ on %s level\n",
 			offset,
 			polarity ? "HIGH" : "LOW");
 	} else if ((trigger & IRQ_TYPE_EDGE_BOTH) == IRQ_TYPE_EDGE_BOTH) {
@@ -201,7 +202,7 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 		/* Select both edges, setting this makes GPIOEV be ignored */
 		gpioibe |= bit;
 		irq_set_handler_locked(d, handle_edge_irq);
-		dev_dbg(gc->parent, "line %d: IRQ on both edges\n", offset);
+		dev_dbg(parent, "line %d: IRQ on both edges\n", offset);
 	} else if ((trigger & IRQ_TYPE_EDGE_RISING) ||
 		   (trigger & IRQ_TYPE_EDGE_FALLING)) {
 		bool rising = trigger & IRQ_TYPE_EDGE_RISING;
@@ -216,7 +217,7 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 		else
 			gpioiev &= ~bit;
 		irq_set_handler_locked(d, handle_edge_irq);
-		dev_dbg(gc->parent, "line %d: IRQ on %s edge\n",
+		dev_dbg(parent, "line %d: IRQ on %s edge\n",
 			offset,
 			rising ? "RISING" : "FALLING");
 	} else {
@@ -225,8 +226,7 @@ static int pl061_irq_type(struct irq_data *d, unsigned trigger)
 		gpioibe &= ~bit;
 		gpioiev &= ~bit;
 		irq_set_handler_locked(d, handle_bad_irq);
-		dev_warn(gc->parent, "no trigger selected for line %d\n",
-			 offset);
+		dev_warn(parent, "no trigger selected for line %d\n", offset);
 	}
 
 	regmap_write(pl061->regmap, GPIOIS, gpiois);
@@ -307,8 +307,9 @@ static int pl061_irq_set_wake(struct irq_data *d, unsigned int state)
 static void pl061_irq_print_chip(struct irq_data *data, struct seq_file *p)
 {
 	struct gpio_chip *gc = irq_data_get_irq_chip_data(data);
+	struct device *parent = gc->parent;
 
-	seq_puts(p, dev_name(gc->parent));
+	seq_puts(p, dev_name(parent));
 }
 
 static const struct irq_chip pl061_irq_chip = {

-- 
2.34.1

