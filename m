From: Arturs Artamonovs <arturs.artamonovs@analog.com>
Subject: [PATCH 00/21] Adding support of ADI ARMv8 ADSP-SC598 SoC.
Date: Thu, 12 Sep 2024 19:24:45 +0100
Message-Id: <20240912-test-v1-0-458fa57c8ccf@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO0x42YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDSwNL3ZLU4hJdi9Rk0zRzs7RUsxQjJaDSgqLUtMwKsDHRsbW1ACfUB0l
 WAAAA
X-Change-ID: 20240909-test-8ec5f76fe6d2
To: Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Greg Malysa <greg.malysa@timesys.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Utsav Agarwal <Utsav.Agarwal@analog.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Thomas Gleixner <tglx@linutronix.de>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Olof Johansson <olof@lixom.net>, soc@kernel.org
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, adsp-linux@analog.com, 
 Arturs Artamonovs <Arturs.Artamonovs@analog.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726165513; l=5160;
 i=arturs.artamonovs@analog.com; s=20240909; h=from:subject:message-id;
 bh=w0yUEeGO5zWa5Zok2P2rOyXgtDKvVgmOUJ+a/Az1hj4=;
 b=zbt6V9124O55F0SjvPefnGSMeoqnQ6n0nQAX5r5d9ePtZmwiyfZElo/Gxg9IU9a3CrDXAI7ll
 FFhs3bUdzCqBvTjA8ZWx3jPfHROQJaT88gsBroCxlNiuQ/0z7ZsVUF8
X-Developer-Key: i=arturs.artamonovs@analog.com; a=ed25519;
 pk=UXODIid/MrmBXvqkX4PeEfetDaNAw9xKMINHIc5oZCk=
X-Endpoint-Received: by B4 Relay for arturs.artamonovs@analog.com/20240909 with auth_id=206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This set of patches based on ADI fork of Linux Kerenl that support family of ADSP-SC5xx
SoC's and used by customers for some time . Patch series contains minimal set
of changes to add ADSP-SC598 support to upstream kernel. This series include
UART,I2C,IRQCHIP,RCU drivers and device-tree to be able boot on EV-SC598-SOM
board into serial shell and able to reset the board. Current SOM board
requires I2C expander to enable UART output.

UART,I2C and PINCTRL drivers are based on old Blackfin drivers with
ADSP-SC5xx related bug fixes and improvments.

Signed-off-by: Arturs Artamonovs <arturs.artamonovs@analog.com>
---
Arturs Artamonovs (21):
      arm64: Add ADI ADSP-SC598 SoC
      reset: Add driver for ADI ADSP-SC5xx reset controller
      dt-bindigs: arm64: adi,sc598 bindings
      dt-bindings: arm64: adi,sc598: Add ADSP-SC598 SoC bindings
      clock:Add driver for ADI ADSP-SC5xx PLL
      include: dt-binding: clock: add adi clock header file
      clock: Add driver for ADI ADSP-SC5xx clock
      dt-bindings: clock: adi,sc5xx-clocks: add bindings
      gpio: add driver for ADI ADSP-SC5xx platform
      dt-bindings: gpio: adi,adsp-port-gpio: add bindings
      irqchip: Add irqchip for ADI ADSP-SC5xx platform
      dt-bindings: irqchip: adi,adsp-pint: add binding
      pinctrl: Add drivers for ADI ADSP-SC5xx platform
      dt-bindings: pinctrl: adi,adsp-pinctrl: add bindings
      i2c: Add driver for ADI ADSP-SC5xx platforms
      dt-bindings: i2c: add i2c/twi driver documentation
      serial: adi,uart: Add driver for ADI ADSP-SC5xx
      dt-bindings: serial: adi,uart4: add adi,uart4 driver documentation
      arm64: dts: adi: sc598: add device tree
      arm64: defconfig: sc598 add minimal changes
      MAINTAINERS: add adi sc5xx maintainers

 .../devicetree/bindings/arm/analog/adi,sc5xx.yaml  |   24 +
 .../bindings/clock/adi,sc5xx-clocks.yaml           |   65 ++
 .../bindings/gpio/adi,adsp-port-gpio.yaml          |   69 ++
 Documentation/devicetree/bindings/i2c/adi,twi.yaml |   71 ++
 .../interrupt-controller/adi,adsp-pint.yaml        |   51 +
 .../bindings/pinctrl/adi,adsp-pinctrl.yaml         |   83 ++
 .../devicetree/bindings/serial/adi,uart.yaml       |   85 ++
 .../bindings/soc/adi/adi,reset-controller.yaml     |   38 +
 MAINTAINERS                                        |   22 +
 arch/arm64/Kconfig.platforms                       |   13 +
 arch/arm64/boot/dts/Makefile                       |    1 +
 arch/arm64/boot/dts/adi/Makefile                   |    2 +
 arch/arm64/boot/dts/adi/sc598-som-ezkit.dts        |   14 +
 arch/arm64/boot/dts/adi/sc598-som.dtsi             |   58 ++
 arch/arm64/boot/dts/adi/sc59x-64.dtsi              |  367 +++++++
 arch/arm64/configs/defconfig                       |    6 +
 drivers/clk/Kconfig                                |    9 +
 drivers/clk/Makefile                               |    1 +
 drivers/clk/adi/Makefile                           |    4 +
 drivers/clk/adi/clk-adi-pll.c                      |  151 +++
 drivers/clk/adi/clk-adi-sc598.c                    |  329 ++++++
 drivers/clk/adi/clk.h                              |   99 ++
 drivers/gpio/Kconfig                               |    8 +
 drivers/gpio/Makefile                              |    1 +
 drivers/gpio/gpio-adi-adsp-port.c                  |  145 +++
 drivers/i2c/busses/Kconfig                         |   17 +
 drivers/i2c/busses/Makefile                        |    1 +
 drivers/i2c/busses/i2c-adi-twi.c                   |  940 ++++++++++++++++++
 drivers/irqchip/Kconfig                            |    9 +
 drivers/irqchip/Makefile                           |    2 +
 drivers/irqchip/irq-adi-adsp.c                     |  310 ++++++
 drivers/pinctrl/Kconfig                            |   12 +
 drivers/pinctrl/Makefile                           |    1 +
 drivers/pinctrl/pinctrl-adsp.c                     |  919 +++++++++++++++++
 drivers/reset/Makefile                             |    1 +
 drivers/soc/Makefile                               |    1 +
 drivers/soc/adi/Makefile                           |    5 +
 drivers/soc/adi/system.c                           |  257 +++++
 drivers/tty/serial/Kconfig                         |   19 +-
 drivers/tty/serial/Makefile                        |    1 +
 drivers/tty/serial/adi_uart.c                      | 1045 ++++++++++++++++++++
 include/dt-bindings/clock/adi-sc5xx-clock.h        |   93 ++
 include/dt-bindings/pinctrl/adi-adsp.h             |   19 +
 include/linux/soc/adi/adsp-gpio-port.h             |   85 ++
 include/linux/soc/adi/cpu.h                        |  107 ++
 include/linux/soc/adi/rcu.h                        |   55 ++
 include/linux/soc/adi/sc59x.h                      |  147 +++
 include/linux/soc/adi/system_config.h              |   65 ++
 include/uapi/linux/serial_core.h                   |    3 +
 49 files changed, 5829 insertions(+), 1 deletion(-)
---
base-commit: da3ea35007d0af457a0afc87e84fddaebc4e0b63
change-id: 20240909-test-8ec5f76fe6d2

Best regards,
-- 
Arturs Artamonovs <arturs.artamonovs@analog.com>

