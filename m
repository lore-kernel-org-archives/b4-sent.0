From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH v2 0/2] gpio: Add the Siflower SF19A2890 GPIO controller
Date: Mon, 09 Nov 2026 15:09:30 -0500
Message-Id: <20261109-sf19a2890-gpio-v2-0-b885fbd84c4c@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHoo8moC/12OQQ6CMBBFr2K6tqYdCxZX3sOwKDDAqAFsS6Mh3
 N2CGhOXb/L/fzMxh5bQseNmYhYDOeq7CLDdsLI1XYOcqsgMBKRSCuCulpkBnQneDNTzAmSSAiZ
 Qa81iabBY02MdPOdvdmNxwdIvK5+ExfsYTf4Xa8n53j7XN4Jcrl+j+jcGyQVXCap0Xyp9AH3ye
 DPmuqswsHye5xcPo6kw1AAAAA==
X-Change-ID: 20261102-sf19a2890-gpio-b21562e52f88
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, Qingfang Deng <dqfext@gmail.com>, 
 linux-mips@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>, 
 Qingfang Deng <qingfang.deng@siflower.com.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794254987; l=2936;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=YNNuUIhjyiZTY0/u39z7F4DHkB1CR2mjqFrrVwxsTQw=;
 b=aDWYDVEqbwGQOOzgeVDJcyo7dMkWGrTYnRUqmnnPNtCDyslKc9bZGlOK0oXMYMpUkLscHESvz
 BkExt1y9aMJDu1qc+SzG0x1KhQeDIPeY/2ng/JusVy51kaqWLIHGlKZ
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

Tested on a GL.iNet GL-SFT1200: gpio-keys sees both buttons on both
edges (the reset button on GPIO 27 as KEY_RESTART, the mode slide switch
on GPIO 1 as BTN_0, 1 and 0 per slide); /sys/kernel/debug/gpio lists the
49 lines; the GSW150 switch comes out of reset through GPIO 0 and the
SPI NAND uses GPIO 8 as its chip select.

[1] https://github.com/981213/linux/commits/siflower-7.1

---
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
 drivers/gpio/Kconfig                               |  12 +
 drivers/gpio/Makefile                              |   1 +
 drivers/gpio/gpio-siflower.c                       | 310 +++++++++++++++++++++
 5 files changed, 406 insertions(+)
---
base-commit: d66b6b86d5a6278ca930112c634d03725beb7d9a
change-id: 20261102-sf19a2890-gpio-b21562e52f88

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

