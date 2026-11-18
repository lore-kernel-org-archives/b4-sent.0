From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH v15 00/14] gpio: add Ambarella CV75 PL061 support
Date: Wed, 18 Nov 2026 15:42:17 +0800
Message-Id: <20261118-cv75-gpio-v15-0-e3c563673fe1@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANlW/WoC/23PQW7DIBAF0KtErEs1A4yxu+o9qi7GeJxQJXGEU
 6tV5LsXElW1K0tsgHmfz02NkqKM6mV3U0mmOMbhnDdITzsVDnzei45dPlAGTIUAXofJk95f4qC
 ttZ0P2PWCqPL8JUkfv+5hb++P/fjZfki4loAycYjjdUjf99empsz95uIjd8qr0aBdXYVg6oZdW
 7/yqeUkxyM/h+GkSvKEsMBIi1L5Knvbi5XWIjHRpseFN7DymL0A1S0LNuRx05ul9ytvsg/GEJE
 DENzub/98Dlh5W/7fNxbRCRtwm94tPK77u9Kf6oq5A1d5/u/nef4Bng8chvcBAAA=
X-Change-ID: 20261007-cv75-gpio-333d7c1dfe11
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, Mika Westerberg <westeri@kernel.org>, 
 devicetree@vger.kernel.org, Long Zhao <longzhao@ambarella.com>, 
 Long Zhao <zl020895@163.com>, linux-kernel@vger.kernel.org, 
 Conor Dooley <conor.dooley@microchip.com>, Chanho Min <chanho.min@lge.com>, 
 linux-acpi@vger.kernel.org, Kees Cook <kees@kernel.org>, 
 linux-hardening@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794987752; l=4295;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=y3I78avvWB7/oGZfxXwD/pE3NGDD4Ih4+VVvkpVdeBI=;
 b=YyRsVVcVRBn4qY+ZmLIM/qZYSKAibd/uZBHy/uB9xCPCYzg8LmMyqWQ0kcyEp1eGckWA0+eri
 U7J/OrOPW21DN6iK/CG29V8cAVK5JhzNCrRQ+IprIoehRmQA8iQOJ9U
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Please take this series through the GPIO tree. The quirk, the PL061
conversion and the Ambarella layout belong together.

These patches convert the ARM PL061 data path to regmap, then add
the CV75 layout. They also request ACPI GPIO events for an external
irq domain, and remove the gpiochip before tearing down its irqchip.

The data path uses gpio-regmap with two layouts, ARM PrimeCell and
Ambarella. ARM PL061 sets GPIO_REGMAP_QUIRK_SET_AFTER_DIR. IRQ stays
a custom PL061 irqchip, attached through gpio-regmap. regmap-irq is
not used.

Tested with lockdep enabled on the CV75 EVK. The board boots.
gpio-hammer toggles gpiochip0 line 26 ten times, and gpio-event-mon
on line 27 records alternating rising and falling edges. unbind and
bind work; the chip re-registers and both tools work again after
the rebind. Holding line 27 as an edge IRQ and unbinding, without
blocking in read, no longer warns from remove_proc_entry().

The registration error-path leak fix is already applied in the GPIO
tree as 80415a6ff295 ("gpio: regmap: free the irqchip if adding the
irq domain fails"). Apply this series on top of that commit.

Changes in v15:
- gpio: pl061: call gpiolib irq helpers on the immutable chip. (Sashiko)
- lib/string_choices: collect Andy's Reviewed-by on the helper. (Andy)
- gpio: pl061: collect Andy's Reviewed-by on the string_choices use. (Andy)
- Link to v14: https://patch.msgid.link/20261110-cv75-gpio-v14-0-e586aad0467a@ambarella.com

Changes in v14:
- lib/string_choices: add str_rising_falling() and use it in pl061. (Andy)
- gpio: regmap: keep removing the gpiochip before the irqchip. (Sashiko)
- gpio: regmap: rename the SET_AFTER_DIR subject from gpiolib:. (Michael)
- gpiolib: collect Mika's Acked-by and move linux-acpi below ---. (Mika)
- gpio: pl061: collect Andy's Reviewed-by on the IRQ logging patch. (Andy)
- gpio: pl061: collect Linus's Reviewed-by on the parent local. (Linus)
- Link to v13: https://patch.msgid.link/20261102-cv75-gpio-v13-0-4f93114ea204@ambarella.com

To: Bartosz Golaszewski <brgl@kernel.org>
To: linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>
Cc: Michael Walle <mwalle@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Rob Herring <robh@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Cc: Conor Dooley <conor+dt@kernel.org>
Cc: Mika Westerberg <westeri@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: Long Zhao <longzhao@ambarella.com>
Cc: Long Zhao <zl020895@163.com>
Cc: linux-kernel@vger.kernel.org

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Long Zhao (14):
      dt-bindings: gpio: pl061: add Ambarella CV75 variant
      gpio: regmap: add GPIO_REGMAP_QUIRK_SET_AFTER_DIR
      gpio: regmap: remove gpiochip before tearing down irqchip
      gpio: pl061: drop redundant pending check in the IRQ handler
      gpio: pl061: convert register access to regmap
      gpio: pl061: use IRQ_TYPE_LEVEL_MASK and IRQ_TYPE_EDGE_BOTH
      gpio: pl061: use cleanup helpers for locks
      gpio: pl061: keep the parent device in a local
      gpiolib: request ACPI GPIO events for external IRQ domains
      gpio: pl061: switch data path to gpio-regmap
      gpio: pl061: add Ambarella register-layout variant
      gpio: pl061: tidy up IRQ trigger logging
      lib/string_choices: add str_rising_falling()
      gpio: pl061: use string_choices helpers for IRQ trigger logging

 .../devicetree/bindings/gpio/pl061-gpio.yaml       |  25 +-
 drivers/gpio/Kconfig                               |   2 +
 drivers/gpio/gpio-pl061.c                          | 592 ++++++++++++++-------
 drivers/gpio/gpio-regmap.c                         |  24 +-
 drivers/gpio/gpiolib.c                             |   9 +-
 include/linux/amba/bus.h                           |   1 +
 include/linux/gpio/regmap.h                        |  14 +
 include/linux/string_choices.h                     |   6 +
 8 files changed, 475 insertions(+), 198 deletions(-)
---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20261007-cv75-gpio-333d7c1dfe11

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

