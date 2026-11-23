From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH v3 0/2] gpio: Add the Siflower SF19A2890 GPIO controller
Date: Sun, 22 Nov 2026 20:37:17 -0500
Message-Id: <20261122-sf19a2890-gpio-v3-0-3a4857ebc84a@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAM2YA2sC/2WOyw6CMBBFf4V0bQ0dChZX/odx0ZYBqgawhUZD+
 HcLanwtz+See2ckDq1BR7bRSCx640zbBEhWEdG1bCqkpghMIIaMsRioK1kuQeQxrTrTUgUszQB
 TKIUgQeoslua6FO4PD3aDOqLu55ZnwuJlCEv9O1Yb17f2trzh2Xx9LfLfRc9oTHmKPEs0FxsQu
 x7PUp7WBXoyd3n49PM/H4KvhEhLVQiuuf7yp2m6A6XtDeUUAQAA
X-Change-ID: 20261102-sf19a2890-gpio-b21562e52f88
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, Qingfang Deng <dqfext@gmail.com>, 
 Michael Walle <mwalle@kernel.org>, linux-mips@vger.kernel.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Joseph Telaak <joseph@telaak.dev>, 
 Qingfang Deng <qingfang.deng@siflower.com.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795397847; l=3796;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=AXm0Qoo5A885Q3LTnrRzlB7VaojIjbXk/hv1msZoJPo=;
 b=sI0vKKf/TJ9laYZhwu9XbhO4oc0WboOD0gtlj5K68soc3RYJ3Scpp5t/VFyLNvBJZgYvY8zy1
 C0SB5IqI6kGAxE8jYCWPNyxHi8NNJnnksPlmOrLf/c1TmeH6ilOMKek
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a binding and a driver for the GPIO controller of the
Siflower SoCs, starting with the SF19A2890, a MIPS SoC for home routers.
Each line has a register block of its own, and each group of 16 lines an
interrupt.

The binding is Chuanhong Guo's and the driver Qingfang Deng's, both from
Chuanhong's SF19A2890 branch [1], with my changes noted in each. The
same controller is in Siflower's SF21 RISC-V SoCs; the binding has only
the SF19A2890's compatible, the one I can test.

The SoC support itself (MACH_SIFLOWER_MIPS) goes through the MIPS tree;
until then the driver builds with COMPILE_TEST.

Tested on a GL.iNet GL-SFT1200. Earlier, on v7.4-rc1: gpio-keys sees
both buttons on both edges (the reset button on GPIO 27 as KEY_RESTART,
the mode slide switch on GPIO 1 as BTN_0, 1 and 0 per slide);
/sys/kernel/debug/gpio lists the 49 lines; the GSW150 switch comes out
of reset through GPIO 0 and the SPI NAND uses GPIO 8 as its chip select.
v3 was run again on OpenWrt's 6.18 kernel, with the driver backported
along with the gpio tree's gpio-regmap: the same four lines work, and
both buttons raise their interrupts on both edges through the driver's
IRQ domain. The board's device tree sets no debounce, so the debounce
path was not exercised.

[1] https://github.com/981213/linux/commits/siflower-7.1

---
Changes in v3:
- Move the driver to gpio-regmap on regmap-mmio, with a
  reg_mask_xlate() for the 0x40 stride between the lines' registers and
  the debounce in set_config() (Linus).
- Put the interrupts on an IRQ domain of the driver's own, with a
  chained handler for each group of 16 lines, since gpio-regmap sets up
  no gpio_irq_chip. The chained handlers are removed with devm.
- Patch 1: add Krzysztof's Reviewed-by.
- Link to v2: https://patch.msgid.link/20261109-sf19a2890-gpio-v2-0-b885fbd84c4c@telaak.dev

Changes in v2:
- Write my notes on Chuanhong's and Qingfang's patches as lists, with
  Co-developed-by on the driver (Bartosz).
- Get priv with gpiochip_get_data(), drop the two else branches, and add
  a blank line after the header comment (Bartosz).
- Get the reset with devm_reset_control_get_exclusive_deasserted(), as a
  local, not in priv (Philipp), and drop the OF_GPIO dependency.
- Name only the SF19A2890 in the Kconfig help and the binding's commit
  message, since the other SoCs need compatibles of their own (Conor).
- Drop the ngpios property, which the compatible implies: the driver
  takes the number of lines from its match data, and the binding takes
  exactly four interrupts (Conor).
- Order the binding's properties and its required list (Conor).
- Add a MAINTAINERS entry for the driver and its binding.
- Use GPL-2.0-or-later, not the deprecated GPL-2.0+ SPDX identifier.
- Use readl() and writel() directly, without wrapper functions (Linus).
- No comma after the match table's sentinel, as Uwe asked of the
  clock driver.
- Drop the unused linux/pinctrl/consumer.h include.
- Link to v1: https://patch.msgid.link/20261104-sf19a2890-gpio-v1-0-45e463c48728@telaak.dev

---
Chuanhong Guo (1):
      dt-bindings: gpio: Add Siflower SF19A2890 GPIO controller

Qingfang Deng (1):
      gpio: Add Siflower GPIO controller driver

 .../bindings/gpio/siflower,sf19a2890-gpio.yaml     |  76 +++++
 MAINTAINERS                                        |   7 +
 drivers/gpio/Kconfig                               |  14 +
 drivers/gpio/Makefile                              |   1 +
 drivers/gpio/gpio-siflower.c                       | 344 +++++++++++++++++++++
 5 files changed, 442 insertions(+)
---
base-commit: d66b6b86d5a6278ca930112c634d03725beb7d9a
change-id: 20261102-sf19a2890-gpio-b21562e52f88

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

