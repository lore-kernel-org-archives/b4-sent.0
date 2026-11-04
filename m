From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH 0/2] pinctrl: Add the Siflower SF19A2890 pin controller
Date: Wed, 04 Nov 2026 02:21:16 -0500
Message-Id: <20261104-sf19a2890-pinctrl-v1-0-4bb83afdbacf@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOzc6moC/y2NQQrCMBBFr1JmbSATMBqvIi5iMtURiXUmFaH07
 k21ywfvvz+BkjApnLoJhD6s/CoNcNdBusdyI8O5MTjrPKJ1RnsM0R2DNQOXVOVpko05+EMm3Ht
 ou0Go5++veb78Wcfrg1JdQ5sh9B7bWd20eV4AoyN4z4oAAAA=
X-Change-ID: 20261102-sf19a2890-pinctrl-c0ad967de156
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776885; l=2123;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=trQxyC9FnpPDYSg5QLUGaKvpgYZNU0c3D/uLunjy+mc=;
 b=cG2tGjvNZZfQ7+rF4DSN6J5m1V1K9pe3HskaPhBlnEQ4NuKy8YXfcWz42m+ZgI+QVXgPDK9fp
 tH7ds7ZtbaqDWad/X7L09Qybo2d69cxI8zjlMZ28Nj2sbsnklDVDj+J
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a binding and a driver for the pin controller of the
Siflower SF19A2890, a MIPS SoC for home routers. Each of its 49 pins has
a register pair of its own: one for bias, input enable, Schmitt trigger
and drive strength, one for the mux.

The driver is based on Chuanhong Guo's OpenWrt driver, which exposed the
four mux modes as functions "func0" to "func3". Here the functions are
named after the peripheral they connect, and each lists the pins it can
use with the mode that selects it there. The tables cover the functions
that the vendor firmware and the OpenWrt port use; the other modes are
not documented.

checkpatch warns about -ENOTSUPP twice. That is what pinconf expects
from pin_config_get() and pin_config_set() for a parameter the hardware
lacks.

The SoC support itself (MACH_SIFLOWER_MIPS) goes through the MIPS tree;
until then the driver builds with COMPILE_TEST.

The MAINTAINERS entry that covers these files comes with the MIPS series
"MIPS: Add support for the Siflower SF19A2890"; this series applies on
its own. That entry is also why checkpatch's question about updating
MAINTAINERS for the new files is left unanswered here.

Tested on a GL.iNet GL-SFT1200: pinmux-pins gives every pin its owner:
SPI, UART0, I2C0, RGMII and MDIO, and the GPIOs for the switch reset, the
mode switch, the SPI chip select and the reset button. The console, the
SPI NAND, the ET6326 on I2C and Ethernet work with the mux this driver
sets.

---
Joseph Telaak (2):
      dt-bindings: pinctrl: Add Siflower SF19A2890 pin controller
      pinctrl: Add Siflower SF19A2890 pin controller driver

 .../pinctrl/siflower,sf19a2890-pinctrl.yaml        | 113 +++++
 drivers/pinctrl/Kconfig                            |  14 +
 drivers/pinctrl/Makefile                           |   1 +
 drivers/pinctrl/pinctrl-sf19a2890.c                | 536 +++++++++++++++++++++
 4 files changed, 664 insertions(+)
---
base-commit: f33a24cc012d34f25bb9942681bd478a1757b806
change-id: 20261102-sf19a2890-pinctrl-c0ad967de156

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

