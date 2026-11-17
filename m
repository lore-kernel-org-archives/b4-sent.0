From: yy-Local-LLM <yogo.0917.sabu@gmail.com>
Subject: [PATCH RFC 0/6] SiRF AT550 / YPL514si initial RAM-boot platform
 support
Date: Tue, 17 Nov 2026 22:06:50 +0900
Message-Id: <20261117-at550-rfc-v1-v1-0-5879573cb825@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Nz3cQSU1MD3aK0ZN0yQ10jU0tDQwvTRKO0VAsloJaCotS0zAqwcdF
 KQW7OSrEQweLSpKzU5BKQQUq1tQBphOzAdQAAAA==
X-Change-ID: 20261117-at550-rfc-v1-2591185a2fe8
To: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Ulf Hansson <ulfh@kernel.org>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-doc@vger.kernel.org, soc@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794920817; l=5303;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=2VJuHtWvJ/6kBBAKkOQqaxVnf8LunGjT3BvQbOpAQfM=;
 b=TqlrSuhkixWIR2lMSrU1nGDY+ADJU4gjIR3CMH3zWTCgohhAVNsc4WHccWXgrO6bUMFtL6UWE
 irl8pnb2GR4D1jPLdZS1FC97ZoM/BZRsaNtgzdRlcZRgSrzz+BDGTh1
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This RFC adds initial SiRF AT550 support for the ARM1136-based Yupiteru
YPL514si navigation device. It splits the working 6.12.60 bring-up into
normal kernel subsystems and ports it to the 7.4-rc3 development tree.

The device owner has now booted this 7.4-rc3 candidate on the YPL514si
through the JWM desktop, with the console and screen keyboard. The CE
handoff record confirms a 32 MiB Linux-owned allocation, all 8192 PFNs,
and a counter rate of 124387750 Hz. The deployed EXE/DLL hashes match the
prepared kit. The WM result is reported by the device owner, rather than
being inferred from the CE pre-handoff log.

The kernel uses standard IRQCHIP_DECLARE, TIMER_OF_DECLARE, common clock,
input polling, SDHCI PIO and simplefb paths. Generic ARM head.S, init/main.c,
MMU and RealView execution code are unchanged. The CE RAM allocator,
page-table checks, handoff bridge, DT fixups and GUI software are not part
of this kernel series.

Firmware must initialize SDRAM, peripheral clocks, pin multiplexing and
the LCD. The bootloader supplies the actual usable RAM and post-divider
counter rate in the DT, and enables only peripherals handed to Linux.
Memory/clock zero values in the source DTS are explicit fixup placeholders.
The timer driver preserves the divider and rejects a running watchdog.

Validation:
- AT550-only defconfig Image/DTB build, plus built-in/module leaf drivers.
- W=1 on the new drivers, dt_binding_check with examples/yamllint, scoped
  dtbs_check, and ARM32 tests of the actual loader DT fixups.
- ARM1136 QEMU at 16/24/32 MiB through JWM, five-point calibration,
  screen-keyboard input into rxvt/PTY/ash and a readonly SD fixture.
- Physical YPL514si boot through WM, reported by the device owner.
QEMU uses GIC/SP804/PL181 and synthetic touch, so it is not being presented
as validation of the physical AT550 controllers. The no-VFP defconfig also
produces an existing unused-variable W=1 warning in unmodified signal.c;
there are no reported new-driver warnings.

Initial limits: firmware clock/pin setup is inherited; cold initialization,
clock-tree control, DMA translation and board suspend are not implemented.
The board DT limits SD to 25 MHz, no 1.8 V, no MMC and no SDIO. SD writes,
card removal and suspend/resume have not been separately validated. The
AT551 draft was cross-checked with AT550 CE mappings and prior hardware
behavior; it is not claimed to be a complete AT550 specification.

I would appreciate early feedback on the initial platform scope and the
firmware/DT handoff contract before extending clock, pinctrl or DMA support.

Signed-off-by: yy-Local-LLM <yogo.0917.sabu@gmail.com>

---
yy-Local-LLM (6):
      dt-bindings: add SiRF AT550 and Yupiteru YPL514si descriptions
      irqchip: add the SiRF AT550 interrupt controller
      clocksource: add the SiRF AT550 counter and match timer
      Input: add polled SiRF AT550 resistive touch support
      mmc: sdhci: add SiRF AT550 programmed-I/O support
      ARM: add the SiRF AT550 platform and YPL514si board

 Documentation/arch/arm/at550.rst                   |  55 +++++++++
 Documentation/arch/arm/index.rst                   |   1 +
 .../devicetree/bindings/arm/sirf,at550.yaml        |  22 ++++
 .../bindings/input/touchscreen/sirf,at550-ts.yaml  |  36 ++++++
 .../interrupt-controller/sirf,at550-intc.yaml      |  46 +++++++
 .../devicetree/bindings/mmc/sirf,at550-sdhci.yaml  |  51 ++++++++
 .../bindings/timer/sirf,at550-timer.yaml           |  47 ++++++++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |  17 +++
 arch/arm/Kconfig                                   |   1 +
 arch/arm/Makefile                                  |   1 +
 arch/arm/boot/dts/Makefile                         |   2 +
 arch/arm/boot/dts/sirf/Makefile                    |   2 +
 arch/arm/boot/dts/sirf/at550-ypl514si.dts          |  52 ++++++++
 arch/arm/boot/dts/sirf/at550.dtsi                  |  66 ++++++++++
 arch/arm/configs/at550_defconfig                   |  34 ++++++
 arch/arm/mach-at550/Kconfig                        |  13 ++
 arch/arm/mach-at550/Makefile                       |   2 +
 arch/arm/mach-at550/at550.c                        |  11 ++
 drivers/clocksource/Kconfig                        |   6 +
 drivers/clocksource/Makefile                       |   2 +
 drivers/clocksource/timer-at550.c                  | 134 +++++++++++++++++++++
 drivers/input/touchscreen/Kconfig                  |  10 ++
 drivers/input/touchscreen/Makefile                 |   2 +
 drivers/input/touchscreen/at550-ts.c               | 108 +++++++++++++++++
 drivers/irqchip/Kconfig                            |   5 +
 drivers/irqchip/Makefile                           |   2 +
 drivers/irqchip/irq-at550.c                        | 110 +++++++++++++++++
 drivers/mmc/host/Kconfig                           |  10 ++
 drivers/mmc/host/Makefile                          |   2 +
 drivers/mmc/host/sdhci-at550.c                     |  62 ++++++++++
 31 files changed, 914 insertions(+)
---
base-commit: 666539eecdf4db623f5e3c3e55cf9f2dfad24aa4
change-id: 20261117-at550-rfc-v1-2591185a2fe8

Best regards,
--  
yy-Local-LLM <yogo.0917.sabu@gmail.com>

