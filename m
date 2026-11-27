From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v5 0/6] soc: cortina: Add CS7542 global clocks, reset
 controller and pinctrl
Date: Fri, 27 Nov 2026 23:50:25 +0300
Message-Id: <20261127-cs7542-syscon-v5-0-d5a373c72b05@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6CMBCF4auYrq1pZ6YUXXkP44KWFmsUDEWiM
 dzdghvF6PIl8/3zYNG1wUW2WTxY6/oQQ1OnoZYLZg9FXTkeyrQZCMikBOQ2akXA4z3apuagsVS
 krC48sGQurfPhNvV2+9eOV3N0thsj48UhxK5p79PDXo53v9q95ILTOle5y1ASrbfVuQinlW3Ob
 Gz38FdD0tKWmgwoAP+l8a/GpL20QhdSC/T5XNO7VnNNSSOiNkaUaOhDD8PwBCDD1Bp2AQAA
X-Change-ID: 20261123-cs7542-syscon-273d545c7af2
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795812625; l=4219;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=LKT0ZdEPrI0e86I7NHg3yxfQRlaUYUC+x/f2lAMoCoI=;
 b=BGh+iEkGCfRMeFsWmQsYxehsmgWZqwiDmArsRn+m4MwCj6IRt+538ZKbvZ6KDmedjW96Mt4Ja
 +VfI2Ojy2tWCfUMv23okesLvP21eYmXKTKhfSac3ARy7bdrIZIVF+7e
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CS7542 global register block selects the CPU and bus clocks, gates
the three PCIe ports and provides the PCIe and network reset lines. Its
pinctrl child selects GPIO or peripheral functions on the same pads.
This series includes the clock changes previously posted in the global
controls series together with the original clock and pinctrl patches.

The early clock provider supplies timer clocks before platform devices
probe. A separate platform driver in drivers/reset/ uses the same
syscon regmap. The PCIe and Ethernet consumers control the timing and
ordering of their own resets.

The global reset provider also exposes the separate flash reset at
RESET bit 14, for NAND consumers to acquire without asserting a pulse.

Validation: both binding commits pass dt_binding_check independently.
The clock driver builds in, and the reset and pinctrl drivers build both
built-in and as modules on ARM with W=1/-Werror, COMPILE_TEST disabled and
without the platform series. The equivalent OpenWrt backport has been
exercised on Almond+; these checks do not claim fault injection on hardware.

Changes in v5:
- Treat failed regmap reads as unprepared in the PCIe gate state callback.
- Use devm_kzalloc_obj() for the native reset controller allocation.
- Describe the separate flash reset and add its reset identifier.
- Retain Linus Walleij's Reviewed-by on the unchanged pinctrl driver.
- Link to v4: https://patch.msgid.link/20261125-cs7542-syscon-v4-0-3337bb0d3b48@gmail.com

Changes in v4:
- Combine the strap-selected clocks and PCIe gates in one clock driver.
- Move reset registration to a separate driver in drivers/reset/.
- Expose the seven network-engine reset lines individually. Leave the
  PCIe reset pulse timing to the PCIe driver.
- Fold in the global-controls binding and its clock and reset IDs.
- Global-controls v1: https://lore.kernel.org/all/20261124-b4-cs7542-global-controls-v1-0-12548785df2c@gmail.com/
- Link to v3: https://lore.kernel.org/all/20261123-cs7542-syscon-v3-0-f1c07a1703f8@gmail.com/

Changes in v3:
- Introduce the parent pinctrl property and schema reference together with
  the pinctrl binding in patch 2, so patch 1 validates independently.
- Re-run dt_binding_check and examples at both binding commits. The final
  source tree and driver code are unchanged from v2.
- Link to v2: https://patch.msgid.link/20261123-cs7542-syscon-v2-0-1cd74b2522f9@gmail.com

Changes in v2:
- Identify GPIO mux functions with function_is_gpio so strict ownership
  allows a GPIO consumer after the default GPIO state; UART stays exclusive.
- Link to v1: https://patch.msgid.link/20261123-cs7542-syscon-v1-0-49858e631449@gmail.com

---
Fil Dunsky (6):
      dt-bindings: soc: Add Cortina Systems CS7542 global controls
      dt-bindings: pinctrl: Add Cortina Systems CS7542 pin mux
      clk: Add Cortina Systems CS7542 clocks
      reset: Add Cortina Systems CS7542 global reset controller
      pinctrl: Add Cortina Systems CS7542 pin multiplexer
      MAINTAINERS: Add CS7542 global control support

 .../bindings/pinctrl/cortina,cs7542-pinctrl.yaml   |  84 +++++++++
 .../soc/cortina/cortina,cs7542-syscon.yaml         |  60 +++++++
 MAINTAINERS                                        |  12 ++
 drivers/clk/Kconfig                                |   9 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/clk-cs7542.c                           | 161 +++++++++++++++++
 drivers/pinctrl/Kconfig                            |  13 ++
 drivers/pinctrl/Makefile                           |   1 +
 drivers/pinctrl/pinctrl-cs7542.c                   | 195 +++++++++++++++++++++
 drivers/reset/Kconfig                              |  10 ++
 drivers/reset/Makefile                             |   1 +
 drivers/reset/reset-cs7542.c                       | 135 ++++++++++++++
 include/dt-bindings/clock/cortina,cs7542-clock.h   |  13 ++
 include/dt-bindings/reset/cortina,cs7542-reset.h   |  20 +++
 14 files changed, 715 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-cs7542-syscon-273d545c7af2

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

