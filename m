From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH v2 00/10] Ambarella CV75 SoC minimal bring-up
Date: Thu, 06 Aug 2026 17:34:08 +0800
Message-Id: <20260806-longzhao-upstream-cv75-v2-v2-0-6b09707c5fe9@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABRVdGoC/yXMQQ6CMBBA0auQWTtJMxGwXsW4KOMINdqSDjREw
 t2puHyL/1dQSV4UrtUKSbJXH0MBnSrgwYVe0D+KgQw15mLO+I6h/w4u4jzqlMR9kHNbYyZkqm3
 LnbUNC5R+TPL0y/G+3f/WuXsJT78hbNsOtCq2FH0AAAA=
X-Change-ID: 20260804-longzhao-upstream-cv75-v2-c2597cb996ce
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-serial@vger.kernel.org, 
 soc@lists.linux.dev, Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786008863; l=4719;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=C9JHKAjPPmXGoQ//B5ouZUxOqyevIxFUeda9hRCDS9I=;
 b=TlVdhCw0rcuc6SGNOvniCQ+KZa7tu6qsNa/S9pG97AAqo54goGd3rssNe33YrrZj7QlPKJpVA
 8LRpmaoz7icBLaUJtwo0d0IFXVpwR4SfflGLqCGJ8iRnk0BdFsw36oZ
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds minimal Ambarella CV75 support sufficient for early
bring-up with a serial console.

It introduces DT bindings and drivers for the RCT clock controller,
pinctrl, and UART, plus ARCH_AMBARELLA, a minimal CV75 EVK device tree,
arm64 defconfig entries, and a MAINTAINERS entry.

The goal remains a small, reviewable console-capable baseline. Further
SoC peripherals can follow in later series.

This is v2. Link to v1:
https://lore.kernel.org/r/20260730104330.81367-1-longzhao@ambarella.com

Changes since v1:
- pinctrl: parent node only describes IOMUX; GPIO bank MMIO and IRQs
  live in gpio child nodes (Rob)
- pinctrl: switch DT/bindings to function + groups; keep pinmux data in
  the driver; drop include/dt-bindings/pinctrl/ambarella,pinctrl.h
  (Linus)
- pinctrl: split CV75 static data into pinctrl-ambarella-cv75.c
- clock binding: drop syscon-common and redundant assigned-clock*
  properties from the schema (Rob)
- serial: keep only SoC-specific compatible ambarella,cv75-uart
  (Krzysztof)
- scratchpad: drop generic ambarella,sec-scratchpad compatible
  (Krzysztof)
- bindings: rename ambarella,uart.yaml and ambarella,sec-scratchpad.yaml
  to SoC-specific ambarella,cv75-*.yaml names
- dts: fix GIC unit-address; add EL2 virtual timer PPI (Marc)
- uart: use container_of and guarded locks; keep break_ctl under the
  port lock; split earlycon putchar from the console path (Jiri)
- uart: convert console to nbcon; stop toggling IER around console
  writes; drain RBR before uart_handle_break()
- misc binding/DTS cleanups from review

Testing:
- Booted to console on CV75 EVK with initramfs
- scripts/checkpatch.pl --strict
- make dt_binding_check DT_SCHEMA_FILES=ambarella
- W=1 arm64 Image build for the new drivers/DTS

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Long Zhao (10):
      dt-bindings: arm: add Ambarella CV75 platforms
      dt-bindings: soc: add Ambarella secure scratchpad
      dt-bindings: clock: add Ambarella CV75 RCT clock controller
      dt-bindings: pinctrl: add Ambarella CV75 pinctrl
      dt-bindings: serial: add Ambarella UART
      clk: ambarella: add CV75 CCU driver
      pinctrl: ambarella: add Ambarella pin controller
      serial: ambarella: add Ambarella UART driver
      arm64: ambarella: add ARCH_AMBARELLA and CV75 EVK DT
      MAINTAINERS: add ARM/AMBARELLA SoC support

 .../devicetree/bindings/arm/ambarella.yaml         |   23 +
 .../bindings/clock/ambarella,cv75-rct.yaml         |   66 +
 .../bindings/pinctrl/ambarella,cv75-pinctrl.yaml   |  175 +++
 .../bindings/serial/ambarella,cv75-uart.yaml       |   45 +
 .../ambarella/ambarella,cv75-sec-scratchpad.yaml   |   39 +
 .../devicetree/bindings/vendor-prefixes.yaml       |    2 +
 MAINTAINERS                                        |   17 +
 arch/arm64/Kconfig.platforms                       |    9 +
 arch/arm64/boot/dts/Makefile                       |    1 +
 arch/arm64/boot/dts/ambarella/Makefile             |    3 +
 arch/arm64/boot/dts/ambarella/cv75-evk.dts         |   30 +
 arch/arm64/boot/dts/ambarella/cv75.dtsi            |  166 +++
 arch/arm64/configs/defconfig                       |    3 +
 drivers/clk/Kconfig                                |    1 +
 drivers/clk/Makefile                               |    1 +
 drivers/clk/ambarella/Kconfig                      |   16 +
 drivers/clk/ambarella/Makefile                     |    6 +
 drivers/clk/ambarella/ccu-cv75.c                   |  296 ++++
 drivers/clk/ambarella/ccu_common.c                 |   60 +
 drivers/clk/ambarella/ccu_common.h                 |   25 +
 drivers/clk/ambarella/ccu_mux_div.c                |  223 +++
 drivers/clk/ambarella/ccu_mux_div.h                |   35 +
 drivers/clk/ambarella/ccu_pll.c                    |  374 +++++
 drivers/clk/ambarella/ccu_pll.h                    |   70 +
 drivers/pinctrl/Kconfig                            |   15 +
 drivers/pinctrl/Makefile                           |    2 +
 drivers/pinctrl/pinctrl-ambarella-cv75.c           |   68 +
 drivers/pinctrl/pinctrl-ambarella.c                | 1510 ++++++++++++++++++++
 drivers/pinctrl/pinctrl-ambarella.h                |   48 +
 drivers/tty/serial/Kconfig                         |   21 +
 drivers/tty/serial/Makefile                        |    1 +
 drivers/tty/serial/ambarella_uart.c                | 1001 +++++++++++++
 include/dt-bindings/clock/ambarella,cv75-clock.h   |   17 +
 33 files changed, 4369 insertions(+)
---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20260804-longzhao-upstream-cv75-v2-c2597cb996ce

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

