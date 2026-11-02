From: Long Zhao <longzhao@ambarella.com>
Date: Mon, 02 Nov 2026 14:46:02 +0800
Subject: [PATCH v13 09/13] gpiolib: request ACPI GPIO events for external
 IRQ domains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-cv75-gpio-v13-9-4f93114ea204@ambarella.com>
References: <20261102-cv75-gpio-v13-0-4f93114ea204@ambarella.com>
In-Reply-To: <20261102-cv75-gpio-v13-0-4f93114ea204@ambarella.com>
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, Mika Westerberg <westeri@kernel.org>, 
 linux-acpi@vger.kernel.org, devicetree@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>, Long Zhao <zl020895@163.com>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793602013; l=1299;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=iX8Xb0+PinHVdTfUGv4kYZvwdiGV19SDmTbEVrsx8Kw=;
 b=SgVZg3oLNdgX7Cwul3GCiom5Nd2FLLWQUZtdfemMVC86x/tqx2ettJYHDNfcEDD5HvA67QgRE
 NOdjEnKtKmUAGj3TzRH0sYekOeMxcp7QKp1DYw/WwFn5ccbebJSkOTW
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gpiochip_add_irqchip() requests GPIO-signaled ACPI events after
installing the irqchip. A gpiochip that gets its IRQ domain through
gpiochip_irqchip_add_domain() never goes through that path, so _AEI
events, such as the power button on ARM64 ACPI platforms, are not
requested.

Request them here as well. gpiochip_remove() already calls
acpi_gpiochip_free_interrupts().

Cc: Mika Westerberg <westeri@kernel.org>
Cc: linux-acpi@vger.kernel.org
Acked-by: Mika Westerberg (Intel) <westeri@kernel.org>
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
 drivers/gpio/gpiolib.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/gpio/gpiolib.c b/drivers/gpio/gpiolib.c
index e5fb60111151..c708d81ef243 100644
--- a/drivers/gpio/gpiolib.c
+++ b/drivers/gpio/gpiolib.c
@@ -2353,7 +2353,14 @@ static void gpiochip_irqchip_remove(struct gpio_chip *gc)
 int gpiochip_irqchip_add_domain(struct gpio_chip *gc,
 				struct irq_domain *domain)
 {
-	return gpiochip_irqchip_add_allocated_domain(gc, domain, true);
+	int ret;
+
+	ret = gpiochip_irqchip_add_allocated_domain(gc, domain, true);
+	if (ret)
+		return ret;
+
+	acpi_gpiochip_request_interrupts(gc);
+	return 0;
 }
 EXPORT_SYMBOL_GPL(gpiochip_irqchip_add_domain);
 

-- 
2.34.1

