From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v9 00/10] ARM: Add support for Cortina Systems CS75xx and
 Securifi Almond+
Date: Sun, 22 Nov 2026 00:35:45 +0300
Message-Id: <20261122-b4-cs75xx-v9-0-1fc1b90bd097@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XPTU7DMBAF4KtUXmM09tgeuyvugVg4/mmNaIPiE
 gVVvTtOkSANdDnS+97MnFlNQ0mVbTdnNqSx1NIf2+AeNizs/XGXeIltZhKkAYfAO8VDJT1NHBC
 9DKBIg2Ut/z6kXKZr1/PL91w/utcUTnPBnNiXeuqHz+uyUcy5/3pHwYErIygoZVBL97Q7+PL2G
 PoDm3tH/JEChFxKbBISREEenA15LdVdqZqMWWqIDtBYuZZ6KXEp9XxtIuk9Woz451pzV5omkZL
 N6IzrKKwl/Uoh1FJSkzYLymitFJ1aS7uQ8uZP26TOjkQHMRh3s/NyuXwBd3DXlBACAAA=
X-Change-ID: 20260930-b4-cs75xx-033a2c047508
To: Arnd Bergmann <arnd@arndb.de>, Linus Walleij <linusw@kernel.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Russell King <linux@armlinux.org.uk>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Drew Fustini <fustini@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jason Li <jason.li@cortina-access.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Fil Dunsky <filipp.dunsky@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795296958; l=13340;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=sjbRWJrrjYIsLf+cl3Cet4o+naH/xVo+rg3FkI/W6iA=;
 b=/fWJ9ds7ZaV+Pkcg3DtnbAA9L0pjD2pRlxmnhVZnfRpIiCZkg3Q9YcI7L6zHZ48ofVqf1uIlZ
 ZqQrC/lbwyJD7LsXdOcuffkoAvkXJgH5UEjZFMJd2pe3GxMezhSH2qU
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial support for the Cortina Systems CS75xx
("Goldengate G2") network processors and the first board using one, the
Securifi Almond+ touchscreen Wi-Fi router (CS7542, 2x Cortex-A9 r2p1,
PL310 r3p1, 512 MiB DDR3, 512 MiB NAND).

There is no public documentation for the SoC. The register information
comes from the GPL vendor kernels (Linux 2.6.36 for the Almond+, Linux
4.9 for the Verizon FiOS G1100 which uses the same SoC) and from
disassembly of the stock U-Boot 2009.11. A full out-of-tree port
(clock, irqchip, GPIO, I2C, RTC, NAND, PCIe, MDIO and the packet engine)
runs on Linux 6.18 in OpenWrt; this series is the first, minimal step to
get the platform into mainline:

  - bindings: vendor prefix, SoC/board compatibles, an SMP enable method
    and the UART,
  - the platform Kconfig and SMP bring-up (the generic DT machine is
    used, there is no DT_MACHINE_START),
  - DEBUG_LL for UART0,
  - a UART driver with console and earlycon support,
  - SoC dtsi and board dts describing the CPUs, GIC, SCU, timers, L2,
    UARTs and memory,
  - multi_v7_defconfig and MAINTAINERS updates.

The serial binding and driver (patches 6-7) are meant to go through the
soc tree together with the rest of the series rather than through the
tty tree, with an Ack from the tty maintainers.

Testing: component builds from multi_v7_defconfig with GCC 14 and
Clang 21, W=1 (UART built-in and module, SMP code, plus DEBUG_LL and the
board DTB with GCC), and dt_binding_check/dtbs_check. On a Securifi
Almond+ this series boots v7.4-rc1 to an initramfs shell with
both CPUs online ("smp: Brought up 1 node, 2 CPUs"; IPIs and the TWD
timer tick on both cores); the L2C-310, the global and TWD timers and
the UART driver (ttyCS0) come up. The kernel was started from a
running OpenWrt system with a small kexec-style loader rather than
from the stock U-Boot, because U-Boot enters the kernel with the MMU
on (see 1 below). The same patches on Linux 6.18 in OpenWrt, with the
head.S workaround from 1, also boot from NAND through the stock U-Boot;
that is how the secondary CPU wake-up fix in v4 was found.

The boot watchdog and restart support are handled by the separate ARM
TWD watchdog driver, using CPU0 as the system watchdog. Guenter Roeck
has applied v9 to his watchdog-next branch:
https://git.kernel.org/pub/scm/linux/kernel/git/groeck/linux-staging.git/commit/?id=52d91ea73e05c349669fe5c87a09df9476bbbf55
That driver is not included here and has not yet reached the current linux-next or mainline snapshot. The stock
bootloader leaves the watchdog armed, so without that driver enabled
this minimal platform series still resets after roughly five minutes
and has no restart handler. For normal operation it should be integrated with that driver and
CONFIG_ARM_TWD_WATCHDOG enabled.

The UART source used in the latest RAM tests on 21 November, in a
combined platform/peripheral test tree on v7.4-rc1, predates the v9
probe error-handling fix. The latter was checked with a host regression
harness executing the actual probe with mocked kernel APIs: deferred,
missing and invalid IRQ errors, successful registration, and failed
serial-core registration (five checks). No new hardware test was run
for this error-path change. Those tests brought up two CPUs and ttyCS0 with
PROVE_LOCKING and returned to OpenWrt after watchdog expiry and restart.
They are additional evidence for the platform and UART path, not tests
of direct stock U-Boot entry or of system suspend.

AI assistance: coding assistants were used to develop and revise this
series. Codex performed the current preflight checks and cover update.

Open questions:

1. The same U-Boot enters the kernel with the MMU and data cache
   enabled (identity map with XN set, dirty lines left in the D-cache),
   which breaks the decompressor. The OpenWrt port carries a small
   workaround at the start of arch/arm/boot/compressed/head.S that
   cleans the cache and turns the MMU off. It is not part of this series.
   Replacing the bootloader is possible but risky for users of this
   (discontinued) device. Would a quirk of that kind be acceptable in
   head.S at all, or should this be solved outside the kernel (e.g. a
   chain-loaded bootloader)? For the tests below the kernel was started
   from a running Linux with the MMU off, so this was not an issue.

2. The APB clock is 100, 150 or 170 MHz depending on the boot strap pins.
   It is modelled as a fixed-clock with the rate set in the board dts.
   A clock driver for the global control block, which also contains the
   strap, pinmux and reset registers, will follow and replace it.

3. The Cortex-A9 r2p1 is also affected by errata 742230, 742231, 743622
   and 751472, whose workarounds are not available on multiplatform
   kernels because they are expected to be applied by the bootloader.
   The stock U-Boot does not apply them. Is there a preferred way to
   deal with this?

4. The UART ports are named ttyCS to avoid clashing with the 8250 driver
   in multi_v7_defconfig, and PORT_GENERIC is used instead of a new port
   type. The FIFO depth is not documented; the driver assumes 16.

5. The top 64 MiB of RAM are reserved: the vendor firmware gives them to
   the packet engine queue manager and the stock kernel is booted with
   mem=448M. The reservation will be referenced by the network driver
   later; I kept it now so that the memory is not handed out and later
   claimed.

Planned follow-ups, as separate series: the peripheral interrupt
controller, GPIO and I2C drivers (posted separately, one series per
subsystem, with their device tree nodes to follow once this series is
merged), the global control block/clock, RTC, NAND,
PCIe (DesignWare glue), MDIO, the Ethernet/packet engine and a fix for
the SX8650 touchscreen.

---
Changes in v9:
- serial: check the signed platform_get_irq() return value before
  assigning it to the unsigned uart_port.irq, preserving negative
  errors including -EPROBE_DEFER (sashiko-bot)
- serial binding: put clocks before interrupts in properties, required
  and the example (sashiko-bot)
- repeat GCC 14 built-in and Clang 21 module object builds with W=1,
  the UART binding and board DT checks; check five probe paths with
  mocked kernel APIs (the old probe fails the three IRQ error cases)
- Reports: https://lore.kernel.org/all/sashiko-outbox-227384@kernel.org/
  https://lore.kernel.org/all/sashiko-outbox-227370@kernel.org/
- Link to v8: https://patch.msgid.link/20261122-b4-cs75xx-v8-0-5f971b0dc69c@gmail.com

Changes in v8:
- collect Linus Walleij's Reviewed-by for the platform/SMP patch
- update watchdog status: v9 is applied in Guenter's watchdog-next;
  the driver uses CPU0 and remains a separate runtime prerequisite
- serial: drop SysRq, which needs uart_handle_break() while the UART
  does not report a break; only run the RX and TX paths for the
  enabled causes that are pending and return IRQ_NONE otherwise; drop a
  stale TX empty event before enabling it (sashiko-bot)
- Link to v7: https://patch.msgid.link/20261114-b4-cs75xx-v7-0-8f17f38821b4@gmail.com

Changes in v7:
- rebase on v7.4-rc1
- cpus binding: the boot loader parks the secondary core in a WFI loop
  that polls the release register, not in a WFE loop
- goldengate: drop Linus' Reviewed-by, the patch changed in v4 and v5
  (wakeup IPI for the secondary core, PL310 erratum 769419); Linus,
  could you have another look?
- board dts: drop the ramoops region, it is only useful for development
- cover: the serial patches go with the rest of the series, not through
  the tty tree on their own (Krzysztof)
- move Signed-off-by after the other trailers
- collect Reviewed-by tags
- Link to v6: https://patch.msgid.link/20261013-b4-cs75xx-v6-0-37e8f3969b7c@gmail.com

Changes in v6:
- serial: also ignore overruns when CREAD is cleared, everything received
  is dropped then (sashiko-bot)
- Link to v5: https://patch.msgid.link/20261013-b4-cs75xx-v5-0-4e72aa383d39@gmail.com

Changes in v5:
- goldengate: select PL310_ERRATA_769419, the PL310 is r3p1-50rel0
  (CACHE_ID 0x410000c7), not r3p2 as v4 said; fix the revision in the
  commit message and here
- serial: scale the TX FIFO wait in putchar with the frame time, 10 ms is
  shorter than one character below 1200 baud (sashiko-bot)
- serial: no change for the other two sashiko-bot points on v4:
  uart_port_tx() checks tx_ready before it sends x_char, and SysRq is
  reachable through MAGIC_SYSRQ_SERIAL_SEQUENCE; the UART has no break
  indication that the driver could use
- Link to v4: https://patch.msgid.link/20261012-b4-cs75xx-v4-0-df250d903682@gmail.com

Changes in v4:
- serial: use guard()/scoped_guard() for the port lock and the port
  table mutex (Jiri Slaby)
- serial: honour INPCK/IGNPAR: report parity and framing errors with
  TTY_PARITY/TTY_FRAME and insert the overrun marker after the characters
  still in the FIFO (sashiko-bot)
- goldengate: also send a wakeup IPI to the secondary core: the stock
  U-Boot parks it in WFI, SEV alone only worked when it was parked by
  another kernel (found booting from NAND instead of from RAM); the
  change is small, I kept Linus' Reviewed-by
- drop the RFC prefix
- Link to v3: https://patch.msgid.link/20261012-b4-cs75xx-v3-0-0e0d17a098cf@gmail.com

Changes in v3:
- serial: do not put the console setup callback in .init.text, it is
  called from a probe that may be deferred past boot (sashiko-bot)
- collect Reviewed-by tags
- Link to v2: https://patch.msgid.link/20261006-b4-cs75xx-v2-0-b7d6e1e24d44@gmail.com

Changes in v2:
- serial: drop the empty break_ctl, request_port and release_port
  callbacks, comment why set_mctrl stays, add a copyright line (Greg)
- serial: take the port lock around all IE accesses in startup, flush
  stale RX data on startup and disable the receiver on shutdown
- serial: bound the RX loop per interrupt, check RXDAT_VALID in
  poll_get_char, scale the console TX drain timeout with the frame time
- serial: serialise port index allocation, reject too low clock rates
- serial: name the driver after the vendor (cortina-uart.c,
  SERIAL_CORTINA), as the same block is used in the Cortina Access SoCs
  (Linus Walleij, Arnd Bergmann); the binding and the help text name
  the Cortina Systems CS75xx and Cortina Access parts (Jason Li)
- serial binding: describe the CS7542 only; other SoCs get their own
  compatible with "cortina,cs7542-uart" as fallback (Conor Dooley)
- debug: keep the character register intact on BE8 in senduart
- platform: move arch/arm/mach-cortina to arch/arm/mach-goldengate, as
  mach-gemini is a Cortina SoC too, and use one ARCH_CORTINA_ACCESS
  symbol for the whole family, as for the 64-bit Cortina Access parts,
  with the rationale in the commit message (Linus Walleij, Krzysztof
  Kozlowski, Arnd Bergmann); mach-goldengate vs. mach-cortina is still
  open, I am happy to rename the directory if mach-cortina is preferred
- collect Reviewed-by and Acked-by tags
- Link to v1: https://patch.msgid.link/20260930-b4-cs75xx-v1-0-4617c4463529@gmail.com

---
Fil Dunsky (10):
      dt-bindings: vendor-prefixes: Add Securifi
      dt-bindings: arm: Add Cortina Systems CS7542 and Securifi Almond+
      dt-bindings: arm: cpus: Add Cortina Systems CS7542 enable method
      ARM: goldengate: Add support for the CS75xx SoC family
      ARM: debug: Add Cortina Systems CS75xx UART0 support
      dt-bindings: serial: Add Cortina Systems CS7542 UART
      tty: serial: Add Cortina UART driver
      ARM: dts: cortina: Add CS7542 SoC and Securifi Almond+ board
      ARM: multi_v7_defconfig: Enable Cortina Systems CS75xx support
      MAINTAINERS: Add entry for Cortina Systems CS75xx

 Documentation/devicetree/bindings/arm/cortina.yaml |  31 ++
 Documentation/devicetree/bindings/arm/cpus.yaml    |   2 +
 .../bindings/serial/cortina,cs7542-uart.yaml       |  52 ++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |  11 +
 arch/arm/Kconfig                                   |   2 +
 arch/arm/Kconfig.debug                             |  16 +-
 arch/arm/Makefile                                  |   1 +
 arch/arm/boot/dts/Makefile                         |   1 +
 arch/arm/boot/dts/cortina/Makefile                 |   3 +
 .../dts/cortina/cs7542-securifi-almondplus.dts     |  46 ++
 arch/arm/boot/dts/cortina/cs7542.dtsi              | 127 +++++
 arch/arm/configs/multi_v7_defconfig                |   3 +
 arch/arm/include/debug/cs75xx.S                    |  37 ++
 arch/arm/mach-goldengate/Kconfig                   |  19 +
 arch/arm/mach-goldengate/Makefile                  |   2 +
 arch/arm/mach-goldengate/platsmp.c                 |  72 +++
 drivers/tty/serial/Kconfig                         |  24 +
 drivers/tty/serial/Makefile                        |   1 +
 drivers/tty/serial/cortina-uart.c                  | 613 +++++++++++++++++++++
 20 files changed, 1063 insertions(+), 2 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20260930-b4-cs75xx-033a2c047508

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

