From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH v2 0/2] pinctrl: Add the Siflower SF19A2890 pin controller
Date: Mon, 23 Nov 2026 23:42:05 -0500
Message-Id: <20261123-sf19a2890-pinctrl-v2-0-a10af32bc844@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ4VBWsC/22Oyw6CMBBFf4V0bU1bEcGV/2FY9DGVUQLYlkZD+
 HcLaty4PJN775mJeHAInhyziTiI6LHvEohNRnQjuwtQNImJYKLgnAnqLa+kKCtGB+x0cC3VTJq
 qOBjg+4Kk3uDA4mPdPNdv9qO6gg7L0Cfh4D4mWfjFGvShd8/1k8iX61ea/5FGThnNlSp30holt
 T0FaKW8bQ1EUs/z/AKXBjQD2gAAAA==
X-Change-ID: 20261102-sf19a2890-pinctrl-c0ad967de156
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Chuanhong Guo <gch981213@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 linux-mips@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795495327; l=2900;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=UI+HFCzlwsuHPDNUiBDjhxu5Nits6H2tsgExW6YLYlA=;
 b=lBf91TEU2OD9oLixUJ+GxBp5O6s4duspTqvuAyIzenYsZPfXCYGenr+7O5vR+xSVFto02pExG
 Vs+vIe8r+bfCVxs0I4poRlC59KUDYyfZiXwbhZoEcc1IjiDfwLAdBir
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

Tested on a GL.iNet GL-SFT1200: pinmux-pins gives every pin its owner:
SPI, UART0, I2C0, RGMII and MDIO, and the GPIOs for the switch reset, the
mode switch, the SPI chip select and the reset button. The console, the
SPI NAND, the ET6326 on I2C and Ethernet work with the mux this driver
sets. For all 49 pins, the bias, input enable, Schmitt trigger and drive
strength in debugfs pinconf-pins match the pin configuration registers
read with devmem; this board uses 6 and 27 mA, the two ends of the drive
strength field.

---
Changes in v2:
- Order the example's child nodes and properties by name, for
  dt-check-style --mode=strict.
- Add a MAINTAINERS entry for the driver and its binding.
- Include <linux/device-id/of.h> instead of <linux/mod_devicetable.h>
  (Uwe).
- Prefix the register macros with SF19A2890_: REG_PC clashed with an SH
  ptrace header (kernel test robot). Convert the drive strength in one
  helper, to keep the longer names within 80 columns.
- Reference pincfg-node.yaml and pinmux-node.yaml the same way, both
  under allOf (Conor).
- Keep the named pins and the per-pin groups: the generic
  dt_node_to_map helpers take pin numbers (Conor).
- Link to v1: https://patch.msgid.link/20261104-sf19a2890-pinctrl-v1-0-4bb83afdbacf@telaak.dev

---
Joseph Telaak (2):
      dt-bindings: pinctrl: Add Siflower SF19A2890 pin controller
      pinctrl: Add Siflower SF19A2890 pin controller driver

 .../pinctrl/siflower,sf19a2890-pinctrl.yaml        | 113 +++++
 MAINTAINERS                                        |   7 +
 drivers/pinctrl/Kconfig                            |  14 +
 drivers/pinctrl/Makefile                           |   1 +
 drivers/pinctrl/pinctrl-sf19a2890.c                | 549 +++++++++++++++++++++
 5 files changed, 684 insertions(+)
---
base-commit: f33a24cc012d34f25bb9942681bd478a1757b806
change-id: 20261102-sf19a2890-pinctrl-c0ad967de156

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

