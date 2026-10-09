From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH 0/7] gpio: add Ambarella CV75 PL061 support
Date: Fri, 09 Oct 2026 18:57:53 +0800
Message-Id: <20261009-cv75-gpio-v1-0-5836bd438423@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALLIyGoC/yXMQQqAIBBA0avErBOcpISuEi1KR5sWFVoSRHfPa
 vng8y+IFJgitMUFgRJHXpcMLAsw07B4EmyzoZJVg1JqYZKuhd94FUopqw1aR4iQ+y2Q4/N7df3
 veIwzmf0dwH0/ut0jAm0AAAA=
X-Change-ID: 20261007-cv75-gpio-333d7c1dfe11
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>, Long Zhao <zl020895@163.com>, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 Chanho Min <chanho.min@lge.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791543577; l=3358;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=42kcK+AHvkO+tjvdujuT/Cniga2XDvo1iIMpmm1LJNg=;
 b=idWkadIvQ9W5eSKIO5Iron6mysw4dO8hdBf8s4DMZzCErlWVUadW7cncJ24NTXlwVUqZ2BAuw
 hdItSSXiIK+Dxng22iEy5Y5T9o3BTzfgyHUvliA1FT+3WkG6t1un6MY
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split from the combined CV75 bring-up series. These patches convert
the ARM PL061 data path to regmap, then add the CV75 layout.

Please take this series through the GPIO tree. The quirk, the PL061
conversion and the Ambarella layout belong together.

The GPIO driver does not depend on ARCH_AMBARELLA. The binding uses
the ambarella vendor prefix, which is added by the SoC series and is
not in mainline yet; dt_binding_check needs that prefix.

GPIO data path uses gpio-regmap with two layouts (ARM PrimeCell and
Ambarella). ARM PL061 sets GPIO_REGMAP_QUIRK_SET_AFTER_DIR. IRQ stays
a custom PL061 irqchip. The linear domain is created with the PL061
private data and attached by gpio-regmap. regmap-irq is not used.

Tested on the CV75 EVK. The board boots. gpio-hammer toggles gpiochip0 line 26 ten times, and gpio-event-mon on line 27 records ten alternating rising and falling edges.

Changes since the patches in the combined v9:
- dt-bindings: explain that CV75 is a modified PL061 (Conor)
- gpio-regmap: move quirks after fixed_direction_output (Andy)
- gpio: pl061: use regmap_test_bits(), regmap_clear_bits() and
  regmap_set_bits() for direction and interrupt enable (Andy).
  The data register stays regmap_write(): regmap_set_bits() can
  only set bits to 1, so it cannot drive a pin low.
- gpio: pl061: add Ambarella register-layout variant: cache DAT
  (REGCACHE_FLAT_S, not volatile) so gpio_set() does not
  read-modify-write the pin level (Sashiko). Drop the Reviewed-by
  from Andy and Linus on this commit; the code changed after
  those tags.

Link: https://patch.msgid.link/20261001-cv75-v5-v9-0-486cc289a4b8@ambarella.com

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
Cc: devicetree@vger.kernel.org
Cc: Long Zhao <longzhao@ambarella.com>
Cc: Long Zhao <zl020895@163.com>
Cc: linux-kernel@vger.kernel.org

Assisted-by: LLM
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Long Zhao (7):
      dt-bindings: gpio: pl061: add Ambarella CV75 variant
      gpiolib: regmap: add GPIO_REGMAP_QUIRK_SET_AFTER_DIR
      gpio: pl061: convert register access to regmap
      gpio: pl061: use IRQ_TYPE_LEVEL_MASK and IRQ_TYPE_EDGE_BOTH
      gpio: pl061: use cleanup helpers for locks
      gpio: pl061: switch data path to gpio-regmap
      gpio: pl061: add Ambarella register-layout variant

 .../devicetree/bindings/gpio/pl061-gpio.yaml       |  25 +-
 drivers/gpio/Kconfig                               |   2 +
 drivers/gpio/gpio-pl061.c                          | 571 +++++++++++++--------
 drivers/gpio/gpio-regmap.c                         |  15 +-
 include/linux/amba/bus.h                           |   1 +
 include/linux/gpio/regmap.h                        |  14 +
 6 files changed, 418 insertions(+), 210 deletions(-)
---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20261007-cv75-gpio-333d7c1dfe11

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

