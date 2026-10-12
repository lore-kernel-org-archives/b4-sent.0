From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH 00/11] Cortina Systems CS75xx: interrupt controller, GPIO,
 I2C and TWD watchdog
Date: Mon, 12 Oct 2026 20:32:55 +0300
Message-Id: <20261012-b4-cs75xx-s2-v1-0-8a7641b7b79c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22Nyw7CIBBFf6VhLWagULAxxv8wLhg6KMb66FTTx
 Pjv4mPp8iT3nvMQTEMmFm31EAPdM+fzqYCaVSLuw2lHMneFhQbdKFBaopGRnZ0myVraZI03C52
 sIlEul4FSnj66zfbLfMMDxfHt+C0Gut5KZ/zORE/M4dNpq+WfzN1IkF3SFroF1I3X610f8nEez
 /3qbcTAJAv0eWyrxjiTAjhIGj2oGg16V1tA5yz6WCM15EOIYvt8vgAMdjPc/AAAAA==
X-Change-ID: 20261012-b4-cs75xx-s2-5f548492f51e
To: Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-i2c@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791826375; l=9559;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=bblr4iJ7bFYxTuBV4u7to5ZuAY4HVOaNlZrTUeaXdpY=;
 b=7QoafjQdXqzp2JAbEA04w6GuyuVqp/xTLTZbQgaMomy2D+QTOlp6mf7CYyim3woyAtY5Sw2tO
 VEGHT4qYpfsDUtfkVgZTDN89GxwCrQbYkJo0/VpEh8p3uCrmU+SUmR3
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the second step of the Cortina Systems CS75xx ("Goldengate G2")
/ Securifi Almond+ support. It applies on top of the platform series
"ARM: Add support for Cortina Systems CS75xx and Securifi Almond+"
v4 [1] and adds:

  - a driver for the per-CPU private watchdog of the ARM11 MPCore,
    Cortex-A5 and Cortex-A9 ("arm,cortex-a9-twd-wdt"),
  - the peripheral interrupt controller that combines the interrupts of
    the low speed peripherals into one GIC interrupt,
  - the GPIO banks,
  - the I2C controller,
  - the device tree nodes, including the reset button of the Almond+,
    and the multi_v7_defconfig and MAINTAINERS updates.

As in the first series there is no public documentation; register
layouts come from the GPL vendor kernels (2.6.36 for the Almond+, 4.9
for the Verizon FiOS G1100 with the same SoC) and were checked on the
board with the out-of-tree OpenWrt port these drivers are based on.

The patches go to different trees and only depend on each other through
the device tree: the irqchip (1-2), GPIO (3-4), I2C (5-6) and watchdog
(7) patches can be picked up independently, the dts, defconfig and
MAINTAINERS patches (8-11) need the platform series.

TWD watchdog:

The binding "arm,cortex-a9-twd-wdt" (watchdog/arm,twd-wdt.yaml) exists
and several dtsi files use it, but there has been no driver since
mpcore_wdt was deleted in v3.11 ("watchdog: delete mpcore_wdt driver").
The reasons given then were that the watchdog is banked per CPU while
the driver only programmed the CPU that happened to run the ioctl, that
it used request_irq() for a per-CPU interrupt, and that it had no users.

This driver does not use the interrupt at all (the watchdog runs in
reset mode) and programs, pings and stops the watchdogs of all online
CPUs with on_each_cpu() under cpus_read_lock(). A CPU hotplug state
arms the watchdog of a CPU coming online while the device is active and
stops it on a CPU going offline, since an offline CPU cannot ping it.
A watchdog found running at probe time on any CPU is reported as
WDOG_HW_RUNNING and reprogrammed with the driver's timeout without
being stopped; the reset flag sets WDIOF_CARDRESET.

On the Almond+ the stock U-Boot arms the watchdog and the board resets
after ~300 s unless it is serviced. With this driver the watchdog core
pings it until userspace takes over.

The driver also registers a restart handler: the CPU that restarts the
system lets its own watchdog expire right away. The platform series has
no other way to restart the CS75xx, so without it "reboot" hangs.

Interrupt controller:

A status register shows the level of 15 sources and an enable register
masks them; the sources are acknowledged in the peripherals. The driver
uses a generic chip on a linear domain and a chained handler. There is
a second status/enable pair right behind it whose purpose I do not know;
it is not described.

GPIO and pin muxing:

Each pin is either a GPIO line or belongs to a peripheral (NAND,
Ethernet, UART, I2C, PCIe reset, ...). The choice is made per pin in one
GPIO_MUX register per bank, and these registers live in the global
control block at 0xf0000000, which also holds the boot straps, the
clock and PLL settings, peripheral resets and the other pin mux
registers.

In this version the GPIO node gets its bank's GPIO_MUX register as a
second reg entry. A line is switched to GPIO when it is requested as a
GPIO or as an interrupt and switched back to the setting found at probe
time when it is released. This keeps the driver self-contained, but it
means that requesting a line that is in use by a peripheral silently
takes the pin away from it; on this board exporting all lines through
sysfs hangs it (NAND and Ethernet pins lose their function). Boards can
list such lines in gpio-reserved-ranges.

I think the proper model is a pin controller for the global control
block: the block becomes a syscon (it is also needed by the clock driver
that will replace the fixed-clock), a pinctrl driver on top of it
describes the pins, the GPIO function and the peripheral groups, the
GPIO nodes get gpio-ranges and the GPIO driver uses
gpiochip_generic_request()/gpiochip_generic_free(). Pinmux ownership
then refuses GPIO requests for pins claimed by a peripheral's pinctrl
state. The remaining pin mux registers of the block are only partially
understood, which is why I did not start with that. Would you accept
the GPIO driver in this form first, with the pinctrl conversion (and a
binding change to gpio-ranges) later, or should the pin controller come
first?

I2C:

The controller transfers one byte per command with an OpenCores-like
command register. The driver supports plain I2C and emulated SMBus
without quick commands (every message carries at least one data byte)
and without 10-bit addresses.

Testing:

Tested on a Securifi Almond+ with next-20260929 plus series 1 v4 and
this series, both CPUs online. The watchdog found the TWD armed by the boot
loader on both CPUs and took it over ("running on CPU0-1, taking
over"); pinged for 60 s from userspace and then left alone, it reset
the board when timeleft reached zero. The I2C and GPIO interrupts are
delivered through the new peripheral interrupt controller; the reset
button (GPIO 37) is claimed by gpio-keys as an active-low input and
reports KEY_RESTART; an I2C read of the touch controller at 0x48 is
ACKed and an empty address returns -ENXIO without timeouts. reboot(2)
issued from CPU1 restarted the board through the restart handler.
The same drivers also run in an OpenWrt image on Linux 6.18 booted from
NAND through the stock U-Boot, where the SX8650 touchscreen uses a
level-triggered GPIO interrupt.

Build tested with multi_v7_defconfig (GCC 14 and Clang 21, W=1),
dt_binding_check and dtbs_check. Not tested: CPU hotplug of the
watchdog (the platform has no cpu_die yet), repeated START between
messages on I2C (only single-message transfers were run), GPIO
interrupts with real edges.

Open questions:

1. GPIO muxing, see above.
2. The TWD watchdog binding marks clocks as optional, the driver
   requires them (the rate is needed to compute the timeout). Should
   the binding be tightened, or should the driver fall back to
   something when there is no clock?
3. Is a separate MAINTAINERS entry for the TWD watchdog driver the
   right thing, or should it be listed under the watchdog subsystem?

[1] https://lore.kernel.org/all/20261012-b4-cs75xx-v4-0-df250d903682@gmail.com/

---
Fil Dunsky (11):
      dt-bindings: interrupt-controller: Add Cortina Systems CS7542 peripheral interrupt controller
      irqchip: Add Cortina Systems CS75xx peripheral interrupt controller
      dt-bindings: gpio: Add Cortina Systems CS7542 GPIO controller
      gpio: Add Cortina Systems CS75xx GPIO driver
      dt-bindings: i2c: Add Cortina Systems CS7542 I2C controller
      i2c: Add Cortina Systems CS75xx I2C controller driver
      watchdog: Add ARM TWD (MPCore private) watchdog driver
      ARM: dts: cortina: cs7542: Add interrupt controller, GPIO and I2C
      ARM: dts: cortina: almondplus: Add reset button and enable I2C
      ARM: multi_v7_defconfig: Enable Cortina Systems CS75xx GPIO, I2C and TWD watchdog
      MAINTAINERS: Add Cortina Systems CS75xx interrupt controller, GPIO and I2C

 .../bindings/gpio/cortina,cs7542-gpio.yaml         |  68 ++++
 .../bindings/i2c/cortina,cs7542-i2c.yaml           |  56 +++
 .../interrupt-controller/cortina,cs7542-intc.yaml  |  57 +++
 MAINTAINERS                                        |  12 +
 .../dts/cortina/cs7542-securifi-almondplus.dts     |  19 +
 arch/arm/boot/dts/cortina/cs7542.dtsi              |  75 ++++
 arch/arm/configs/multi_v7_defconfig                |   3 +
 drivers/gpio/Kconfig                               |  12 +
 drivers/gpio/Makefile                              |   1 +
 drivers/gpio/gpio-cs75xx.c                         | 332 ++++++++++++++++++
 drivers/i2c/busses/Kconfig                         |  11 +
 drivers/i2c/busses/Makefile                        |   1 +
 drivers/i2c/busses/i2c-cs75xx.c                    | 354 +++++++++++++++++++
 drivers/irqchip/Kconfig                            |  12 +
 drivers/irqchip/Makefile                           |   1 +
 drivers/irqchip/irq-cs75xx.c                       | 103 ++++++
 drivers/watchdog/Kconfig                           |  15 +
 drivers/watchdog/Makefile                          |   1 +
 drivers/watchdog/arm_twd_wdt.c                     | 387 +++++++++++++++++++++
 19 files changed, 1520 insertions(+)
---
base-commit: 6474fa070f2b8013b4b87350b775b8c3be6e8aac
change-id: 20261012-b4-cs75xx-s2-5f548492f51e
prerequisite-message-id: <20261012-b4-cs75xx-v4-0-df250d903682@gmail.com>
prerequisite-patch-id: 104c6fb668f30ac8c2c5b3b6c524c18caa8808c4
prerequisite-patch-id: e7d503348cbec7558cd084162133f8e34df1c1bc
prerequisite-patch-id: 1d5770db02b983d012f6c58806fbf3f5291a06c9
prerequisite-patch-id: c2815f506d2df1c84cd50111220b938a41d29050
prerequisite-patch-id: 6c0137d52f201d8ec085ee6cc7b2d49af15583d8
prerequisite-patch-id: 24e110f3c8c008deffdda079bdc27db729b5014d
prerequisite-patch-id: cb09693a5d51be6b24bdf66e112b9dd40fc25dbe
prerequisite-patch-id: 15c11a668a1a281649fa0713371e7f07ee44917e
prerequisite-patch-id: 9b4a468b7b74861017ef533ba0a5574bc14b212e
prerequisite-patch-id: 1f232c94dd3fc0d862203b7c0c1449e6ba9a6859

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

