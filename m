From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH v12 00/11] gpio: add Ambarella CV75 PL061 support
Date: Tue, 27 Oct 2026 12:18:47 +0800
Message-Id: <20261027-cv75-gpio-v12-0-c22555400e18@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACgm4GoC/22OwQ7CIAyGX8VwFkNhDObJ9zAegHWKUWdgEs2yd
 5dtMZnGpJe2//e1PYkYPEayXfUkYPLRt7fcAF+viDuZ2xGpr/OAcMZLYExRl5Skx7tvqRCiVg7
 qBgFIzt8DNv45yfaHuY8Pe0bXjYIxcfKxa8NrupaqMffxwuxNuSrKaKFL57iuTGH1zlytCXi5m
 I1rr2Q0J2ALGOTiqbzKvGhQoBUgjZR/eVjwnH3xkHlkUluDUEkFv/wwDG8J9AvUNwEAAA==
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
 Chanho Min <chanho.min@lge.com>, Mika Westerberg <westeri@kernel.org>, 
 linux-acpi@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793074764; l=7280;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=0Vn5YE5RTpq1wislFUO7xmSSDUKpa3lVZ0MPoFilmtU=;
 b=s7I8jicPoyLtTHuSyKNV+f0J41pMCxLZ+ChxLtXsQadjOzgriZTg/aXTBu3IlG8Gr7eezMgPL
 gt/5Er5SIbIAQD7jBR1ExVAQqkKYuwdEevBn2u+gJzhZY0j5kxWnYPb
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ambarella vendor prefix [1] is in linux-next (applied by Rob).
The binding can be applied with this series.

Please take this series through the GPIO tree. The quirk, the PL061
conversion and the Ambarella layout belong together.

This is v12 of the GPIO patches from the combined CV75 series. The
posting on Oct 9 numbered them v1 after the split. That was a
mistake.

These patches convert the ARM PL061 data path to regmap, then add
the CV75 layout. The series now carries a gpiolib patch that
requests ACPI GPIO events for gpiochips using an external irq
domain.

GPIO data path uses gpio-regmap with two layouts (ARM PrimeCell and
Ambarella). ARM PL061 sets GPIO_REGMAP_QUIRK_SET_AFTER_DIR. IRQ stays
a custom PL061 irqchip. The linear domain is instantiated with
devm_irq_domain_instantiate() using the PL061 private data and
attached by gpio-regmap. regmap-irq is not used.

Tested with lockdep enabled on the CV75 EVK. The board boots.
gpio-hammer toggles gpiochip0 line 26 ten times, and gpio-event-mon
on line 27 records alternating rising and falling edges. unbind and
bind work; the chip re-registers and both tools work again after
the rebind.

Changes in v12:
- gpiolib: request ACPI GPIO events when a gpiochip gets an
  external irq domain, matching gpiochip_add_irqchip(). A gpiochip
  that gets its IRQ domain through gpiochip_irqchip_add_domain()
  never went through that path, so _AEI events, such as the power
  button on ARM64 ACPI platforms, were not requested (Sashiko).
- switch: give the child IRQs their own lockdep classes (the gc->irq
  keys stay NULL on the external irq_domain path), and clear the
  chained handler only after it was installed. The previous mix-up
  could leave a live IRQ with no chained handler after a failed
  probe. Checked with lockdep on the CV75 board (Sashiko).
- switch: keep not setting the gpiochip IRQ resource helpers. The
  gpio_chip is not reachable through gpio-regmap's external
  irq_domain path, so GPIOD_FLAG_USED_AS_IRQ is never tracked. This
  matches the other users of that path (gpio-idio-16,
  gpio-pcie-idio-24, gpio-104-idi-48) (Sashiko).
- convert: put the locals in the blocks this patch touches into
  reverse Christmas tree order, and keep regmap_assign_bits() in
  pl061_set_value() like pl061_get_value() (Andy).
- switch: leave the chained handler's regmap_read() unchecked.
  mis stays 0 on failure, so the loop is already a no-op. Call
  irq_dispose_mapping() directly (Andy).
- pl061: join the split dev_err() string, and use str_high_low()
  for the level debug line. str_rising_falling() is not in
  linux-next, so the edge line is unchanged (Andy).
- Link to v11: https://patch.msgid.link/20261020-cv75-gpio-v11-0-e058bae19571@ambarella.com

Changes in v11 (from Andy's v10 review):
- pending: keep generic_handle_domain_irq() on one line.
- convert: fit regmap_test_bits() on two lines, return
  regmap_assign_bits() directly, and put the new locals in
  reverse Christmas tree order.
- cleanup: fix the guard()() reference in the commit message and
  use scoped_guard() in pl061_irq_mask()/unmask().
- pl061: keep gc->parent in a local before the gpio-regmap switch,
  so that patch does not rewrite every log line.
- switch: keep the existing GPIO* register macros. Split
  reg_mask_xlate, drop pl061->dev for regmap_get_device(), and
  instantiate the IRQ domain with devm_irq_domain_instantiate().
  The remove action is registered before the gpiochip so devres
  unwinds it after gpiochip_remove() and before the domain removal.
- Drop the flags variable left unused by the guard() conversion.
- unbind/bind cycle tested on the CV75 EVK.
- Link to v10: https://patch.msgid.link/20261015-cv75-gpio-v10-0-3fe3eb315a55@ambarella.com

Changes since the combined v9 [2]:
- dt-bindings: explain that CV75 is a modified PL061 (Conor).
- gpio-regmap: move quirks after fixed_direction_output (Andy).
- gpio: pl061: Andy's review on the regmap conversion and switch:
  use regmap_test_bits()/clear_bits()/set_bits()/assign_bits(),
  drop the redundant if (pending) and fast_io, introduce the ARM
  regmap_config (including REGCACHE_FLAT_S) in the convert patch
  and leave it there, blank line after guard() plus the blank-line
  and reverse Christmas tree cleanups, and keep the upstream
  pl061_irq_chip name and unsigned irq_type() trigger without
  adding .name.
- gpio: pl061: cache DAT (REGCACHE_FLAT_S, not volatile) so
  gpio_set() does not read-modify-write the pin level (Sashiko).

Changes since the Oct 9 GPIO posting [3]:
- gpio: pl061: Andy's follow-ups since that posting: assign_bits
  for DAT writes, drop fast_io, name the ARM regmap_config in the
  convert patch, the guard()/blank-line/irq_type cleanups, and keep
  the upstream pl061_irq_chip name and unsigned trigger without
  adding .name.
- gpiolib: regmap: add Michael Walle's Reviewed-by on
  GPIO_REGMAP_QUIRK_SET_AFTER_DIR.
- gpio: pl061: restore Andy's and Linus's Reviewed-by on the
  Ambarella variant.

[1] https://patch.msgid.link/20261014-cv75-prefix-v1-1-fe95ed567880@ambarella.com
[2] https://patch.msgid.link/20261001-cv75-v5-v9-0-486cc289a4b8@ambarella.com
[3] https://patch.msgid.link/20261009-cv75-gpio-v1-0-5836bd438423@ambarella.com

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

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Long Zhao (11):
      dt-bindings: gpio: pl061: add Ambarella CV75 variant
      gpiolib: regmap: add GPIO_REGMAP_QUIRK_SET_AFTER_DIR
      gpio: pl061: drop redundant pending check in the IRQ handler
      gpio: pl061: convert register access to regmap
      gpio: pl061: use IRQ_TYPE_LEVEL_MASK and IRQ_TYPE_EDGE_BOTH
      gpio: pl061: use cleanup helpers for locks
      gpio: pl061: keep the parent device in a local
      gpiolib: request ACPI GPIO events for external IRQ domains
      gpio: pl061: switch data path to gpio-regmap
      gpio: pl061: add Ambarella register-layout variant
      gpio: pl061: tidy up IRQ trigger logging

 .../devicetree/bindings/gpio/pl061-gpio.yaml       |  25 +-
 drivers/gpio/Kconfig                               |   2 +
 drivers/gpio/gpio-pl061.c                          | 543 ++++++++++++++-------
 drivers/gpio/gpio-regmap.c                         |  15 +-
 drivers/gpio/gpiolib.c                             |  10 +-
 include/linux/amba/bus.h                           |   1 +
 include/linux/gpio/regmap.h                        |  14 +
 7 files changed, 415 insertions(+), 195 deletions(-)
---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20261007-cv75-gpio-333d7c1dfe11

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

