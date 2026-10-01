From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH v9 00/15] Ambarella CV75 SoC minimal bring-up
Date: Thu, 01 Oct 2026 20:40:49 +0800
Message-Id: <20261001-cv75-v5-v9-0-486cc289a4b8@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIANFUvmoC/12Oy27CMBREfwV5XVd+xMSXVf8DsfDjmrgipLKDR
 YXy77UpIojlSGfmzI1kTBEz2W1uJGGJOU7nGuBjQ9xgzkek0ddMBBNbprmmrvSKFkUBBZNgZQf
 WkUqHNI10HhKalQfWPfmypYwicK1456y0/MuM1iQ8ncynm8Y28ZMwxOv9zP7wn/PFfqOb22Ijh
 pjnKf3e35a+cQ8RV6uoryIpoPcyWAeOvYnactEvXcHXrq5doUUIyoP23rx3l2X5A2yNVuUzAQA
 A
X-Change-ID: 20260818-cv75-v5-9e2039b349bc
To: Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, soc@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Long Zhao <longzhao@ambarella.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Jerome Brunet <jbrunet@baylibre.com>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Michael Walle <mwalle@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Long Zhao <zl020895@163.com>, Lee Jones <lee@kernel.org>, 
 mfd@lists.linux.dev, devicetree@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790858457; l=9410;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=coHglYm9+1GQYQb+OpOOg0LrOVVxDuyh/0xYFK/oIn0=;
 b=WmWVByOx143QOAObt0mds1XXHtI0Ehlw/BSyI/PfNtcvSDueF5z4wfBcX9zDbnzRpXbaXgciY
 I2fPXRJWC+MD2reQ/3DzzjspPJQgJPsjhdprrIxpCKzLYUM2UmaLnB1
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds minimal Ambarella CV75 support for early bring-up with
a serial console: DT bindings, RCT clocks, PL061 GPIO via gpio-regmap,
8250_dw UART quirks, ARCH_AMBARELLA, CV75 EVK DT, and MAINTAINERS.
The pinctrl binding and driver are already in the pinctrl tree. The
CV75 DT still describes that pin controller.

This series is sent together for review. Please take the GPIO
patches through the GPIO tree and provide an immutable branch
for the SoC tree. The remaining patches should be applied via
the SoC tree; subsystem maintainers are Cc'd for their pieces.

GPIO data path uses gpio-regmap with two layouts (ARM PrimeCell and
Ambarella). IRQ stays a custom PL061 irqchip. The linear domain is
created with the PL061 private data and attached by gpio-regmap.
regmap-irq is not used.

Verified with:
- scripts/checkpatch.pl --strict (0 errors)
- make dt_binding_check DT_SCHEMA_FILES=ambarella:pl061-gpio.yaml:syscon.yaml:snps-dw-apb-uart.yaml
- make CHECK_DTBS=y ambarella/cv75-evk.dtb
- arm64 build of new drivers/DTS
- CV75 EVK: console via 8250_dw (dw-apb-uart); GPIO edge IRQ
  (gpio-hammer / gpio-event-mon) with CONFIG_PROVE_LOCKING after
  use_raw_spinlock

Assisted-by: LLM
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Changes in v9:
- gpio-regmap: GPIO_REGMAP_QUIRK_SET_AFTER_DIR instead of
  write_data_after_dir (Michael); put the flag in its own
  group (Linus)
- gpio-regmap: drop gpio_regmap_get_chip() (Michael)
- gpio: pl061: create the irq domain with PL061 private data
  before gpio_regmap_register() and let gpio-regmap attach it;
  drop the gpio_chip irq helpers (Michael)
- gpio: pl061: GPIO_REGMAP_ADDR() for the direction register
  (Michael)
- pinctrl: binding and driver applied by Linus Walleij; drop
  them from this series (Linus)
- Cc Michael Walle <mwalle@kernel.org>
- collect Reviewed-by on the unchanged PL061 split patches
  (Linus)

Link to v8: https://patch.msgid.link/20260921-cv75-v5-v8-0-282ff5d98dda@ambarella.com

Changes in v8:
- gpio: split v7 10/15 into 10/18 MMIO to regmap, 11/18 IRQ_TYPE_*
  helpers, 12/18 cleanup.h guard(), 13/18 gpio-regmap + custom
  irqchip, 14/18 Ambarella layout (Andy)
- gpio: keep gpio_regmap_get_chip(); drop the irq_domain attach
  change in gpio-regmap (Andy)
- gpio-regmap: skip the pre-direction data write when write_data_after_dir
  is set (Linus); still ignore gpio_regmap_set() returns (Andy)
- gpio: use_raw_spinlock so irq_ack() can run under the irq
  descriptor lock (PROVE_LOCKING on CV75); irq_set_parent() for wake
- gpio: drop errno.h; -ENODATA; for_each_set_bit in PM; split virq
  assignment; chained handler checks regmap_read (Andy)
- pinctrl: 15/18 PINCTRL_PINGROUP + per-pin alts; header uses
  forward declarations; regmap_assign_bits / __assign_bit;
  -ENOTSUPP; -ENODATA; devm_kasprintf_strarray (Andy)
- dt-bindings: gpio: 05/18 move allOf after required; explain why
  CV75 is PrimeCell GPIO but not an arm,pl061 fallback, and why a
  fixed arm,primecell-periphid is required (Krzysztof)
- serial: 16/18 keep snps,dw-apb-uart first; Andy and Ilpo R-b
- clk: drop mod_devicetable.h; use u16_fract (Andy, Uwe)
- collect lore tags on unchanged bindings (Linus, Krzysztof)

Link to v7: https://patch.msgid.link/20260915-cv75-v5-v7-0-3297d3fbc9c0@ambarella.com

Changes in v7:
- gpio: 10/15 convert ARM PL061 to gpio-regmap; 11/15 add Ambarella
  layout with a second gpio_regmap config (Andy)
- gpio: 10/15 drop gpio-regmap girq; custom irqchip with a linear
  domain, gpio_chip chip data, and a chained handler (Andy)
- gpio-regmap: 08/15 write_data_after_dir; 09/15 gpio_regmap_get_chip()
  and quirk kerneldoc (Andy)
- dt-bindings: gpio: 05/15 $ref arm/primecell.yaml and
  unevaluatedProperties (Rob)
- clk: fold the RCT driver into a single clk-cv75.c (Jerome)
- serial: 8250_dw startup only updates the up->ier shadow (Ilpo)
- collect lore tags on unchanged patches (Linus Reviewed-by; Krzysztof
  Acked-by on the UART binding)

Link to v6:
https://lore.kernel.org/r/20260904-cv75-v5-v6-0-e918514cb3b1@ambarella.com

Changes in v6:
- gpio: convert gpio-pl061 data path to gpio-regmap; keep PL061 irqchip
  (Andy, Linus). Add write_data_after_dir + girq helpers to gpio-regmap.
  Ambarella layout uses JEP106 periphid 0x000e8061; no AFSEL clearing in
  the GPIO driver; Ambarella skips unverified GPIO PM save/restore
- serial: restore 8250_dw Ambarella quirks from v3; drop standalone
  8250_ambarella (Andy). Commit message clarifies Ambarella IP with a
  DW-like register map needing only a thin quirk. Binding under
  snps-dw-apb-uart; DT uses ambarella,cv75-uart + snps,dw-apb-uart with
  reg-shift/reg-io-width
- clock/RCT: document #reset-cells (Krzysztof); soft-reset ID header and
  reset provider deferred (no resets= consumers in this series)
- arm64/Kconfig: do not select ARM_PSCI / HAVE_ARM_ARCH_TIMER (Sashiko)
- pinctrl: no Ambarella suspend/resume claim without validated PM

Link to v5:
https://lore.kernel.org/r/20260818-cv75-v5-v5-0-7bbb12f0360f@ambarella.com
Link to v2:
https://lore.kernel.org/r/20260806-longzhao-upstream-cv75-v2-v2-0-6b09707c5fe9@ambarella.com
Link to v3-A:
https://lore.kernel.org/r/20260813-cv75-v3-a-v3-0-cfdd20b1b4dd@ambarella.com
Link to v3-B:
https://lore.kernel.org/r/20260813-cv75-v3-b-v3-0-1d82e18da09b@ambarella.com
Link to v3-C:
https://lore.kernel.org/r/20260813-cv75-v3-c-v3-0-9352b3fd6026@ambarella.com
Link to v4-B:
https://lore.kernel.org/r/20260814-cv75-v4-b-v4-0-622e63153d97@ambarella.com

To: Arnd Bergmann <arnd@arndb.de>
To: Krzysztof Kozlowski <krzk@kernel.org>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
To: soc@lists.linux.dev
To: linux-arm-kernel@lists.infradead.org
To: Long Zhao <longzhao@ambarella.com>
Cc: Rob Herring <robh@kernel.org>
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: Conor Dooley <conor+dt@kernel.org>
Cc: Michael Turquette <mturquette@baylibre.com>
Cc: Stephen Boyd <sboyd@kernel.org>
Cc: Jerome Brunet <jbrunet@baylibre.com>
Cc: Linus Walleij <linusw@kernel.org>
Cc: Bartosz Golaszewski <brgl@kernel.org>
Cc: Michael Walle <mwalle@kernel.org>
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Jiri Slaby <jirislaby@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Ilpo Järvinen <ilpo.jarvinen@linux.intel.com>
Cc: Catalin Marinas <catalin.marinas@arm.com>
Cc: Will Deacon <will@kernel.org>
Cc: Long Zhao <zl020895@163.com>
Cc: Lee Jones <lee@kernel.org>
Cc: mfd@lists.linux.dev
Cc: devicetree@vger.kernel.org
Cc: linux-clk@vger.kernel.org
Cc: linux-gpio@vger.kernel.org
Cc: linux-serial@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Long Zhao (15):
      dt-bindings: arm: add Ambarella CV75 platforms
      dt-bindings: mfd: syscon: add Ambarella CV75 secure scratchpad
      dt-bindings: clock: add Ambarella CV75 RCT
      dt-bindings: gpio: pl061: add Ambarella CV75 variant
      dt-bindings: serial: snps-dw-apb-uart: add ambarella,cv75-uart
      clk: ambarella: add CV75 RCT clock controller
      gpiolib: regmap: add GPIO_REGMAP_QUIRK_SET_AFTER_DIR
      gpio: pl061: convert register access to regmap
      gpio: pl061: use IRQ_TYPE_LEVEL_MASK and IRQ_TYPE_EDGE_BOTH
      gpio: pl061: use cleanup helpers for locks
      gpio: pl061: switch data path to gpio-regmap
      gpio: pl061: add Ambarella register-layout variant
      serial: 8250_dw: add Ambarella CV75 quirks
      arm64: ambarella: add ARCH_AMBARELLA and CV75 EVK DT
      MAINTAINERS: add ARM/AMBARELLA SoC support

 .../devicetree/bindings/arm/ambarella.yaml         |  24 +
 .../bindings/clock/ambarella,cv75-rct.yaml         |  64 +++
 .../devicetree/bindings/gpio/pl061-gpio.yaml       |  25 +-
 Documentation/devicetree/bindings/mfd/syscon.yaml  |   1 +
 .../bindings/serial/snps-dw-apb-uart.yaml          |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |  14 +
 arch/arm64/Kconfig.platforms                       |   6 +
 arch/arm64/boot/dts/Makefile                       |   1 +
 arch/arm64/boot/dts/ambarella/Makefile             |   3 +
 arch/arm64/boot/dts/ambarella/cv75-evk.dts         |  30 ++
 arch/arm64/boot/dts/ambarella/cv75.dtsi            | 177 +++++++
 arch/arm64/configs/defconfig                       |   1 +
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/ambarella/Kconfig                      |   9 +
 drivers/clk/ambarella/Makefile                     |   3 +
 drivers/clk/ambarella/clk-cv75.c                   | 365 +++++++++++++
 drivers/gpio/Kconfig                               |   2 +
 drivers/gpio/gpio-pl061.c                          | 571 +++++++++++++--------
 drivers/gpio/gpio-regmap.c                         |  15 +-
 drivers/tty/serial/8250/8250_dw.c                  |  32 ++
 include/dt-bindings/clock/ambarella,cv75-rct.h     |  14 +
 include/linux/amba/bus.h                           |   1 +
 include/linux/gpio/regmap.h                        |  14 +
 25 files changed, 1167 insertions(+), 210 deletions(-)
---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20260818-cv75-v5-9e2039b349bc

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

