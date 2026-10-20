From: Long Zhao <longzhao@ambarella.com>
Date: Tue, 20 Oct 2026 15:54:07 +0800
Subject: [PATCH v11 3/9] gpio: pl061: drop redundant pending check in the
 IRQ handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-cv75-gpio-v11-3-e058bae19571@ambarella.com>
References: <20261020-cv75-gpio-v11-0-e058bae19571@ambarella.com>
In-Reply-To: <20261020-cv75-gpio-v11-0-e058bae19571@ambarella.com>
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>, Long Zhao <zl020895@163.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792482878; l=1082;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=3XWHZond2pOFeGIXcPtw+mHYxFL9WC432M4BN6DutlY=;
 b=24RcyVJR04fWwFo81vqAqi7vwj3ItdKTh0AeopAD4BEGKR81cupAkOrYX3PxWgmMVQJvFXXiG
 PljuIopZXDCAzQ141mtirmvDMP6PwBGBFbNTLLAAPaYZ54smUHI8R96
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

for_each_set_bit() does nothing when the mask is zero, so the
if (pending) wrapper around it is redundant.

Suggested-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Reviewed-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Reviewed-by: Linus Walleij <linusw@kernel.org>
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/gpio-pl061.c | 7 ++-----
 1 file changed, 2 insertions(+), 5 deletions(-)

diff --git a/drivers/gpio/gpio-pl061.c b/drivers/gpio/gpio-pl061.c
index 919cf86fd590..721f14cf404e 100644
--- a/drivers/gpio/gpio-pl061.c
+++ b/drivers/gpio/gpio-pl061.c
@@ -219,11 +219,8 @@ static void pl061_irq_handler(struct irq_desc *desc)
 	chained_irq_enter(irqchip, desc);
 
 	pending = readb(pl061->base + GPIOMIS);
-	if (pending) {
-		for_each_set_bit(offset, &pending, PL061_GPIO_NR)
-			generic_handle_domain_irq(gc->irq.domain,
-						  offset);
-	}
+	for_each_set_bit(offset, &pending, PL061_GPIO_NR)
+		generic_handle_domain_irq(gc->irq.domain, offset);
 
 	chained_irq_exit(irqchip, desc);
 }

-- 
2.34.1

