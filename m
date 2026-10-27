From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH RFC 00/18] riscv: add initial Zhihe A210 support using SCMI
 clocks and resets
Date: Tue, 27 Oct 2026 23:36:51 +0800
Message-Id: <20261027-a210-scmi-v1-0-74d58ce85bd8@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNz3UQjQwPd4uTcTN3UZGOjtJRkIxOzRDMloPqCotS0zAqwWdFKQW7
 OSrEQweLSpKzU5BKQKUq1tQCJqu29cgAAAA==
X-Change-ID: 20261027-a210-scmi-ec32fdc246a6
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 Icenowy Zheng <uwu@icenowy.me>, Inochi Amaoto <inochiama@gmail.com>, 
 Vivian Wang <wangruikang@iscas.ac.cn>, Yao Zi <me@ziyao.cc>, 
 Jiaxun Yang <jiaxun.yang@flygoat.com>
Cc: arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-gpio@vger.kernel.org, 
 Paul Walmsley <paul.walmsley@sifive.com>, linux-clk@vger.kernel.org, 
 linux-serial@vger.kernel.org, Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793115418; l=6057;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=P7Y5z1f6Tkh/Q3KiPBOp/5vmjX4oz+hIamtC2Vo8fak=;
 b=x/DrQ1NmZ2c8zWtjnEHRQ0ZPwH8TsOUeEpjVVZ67VaXGF/F1Aow5MlMFgn4c4fu4Dmv9mIOp1
 HoN+N5uEapaCDub3xsptlnAHkRIXE2XbyBU6Oj3UewA8zxBXfGjLwKv
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds initial support for the Zhihe A210 SoC and the Melon Pi V1
and V2 boards. It replaces the earlier series [1]. The way clocks and
resets are handled changed completely, so I am posting it as a new RFC
rather than as v2.

The A210 has eight RISC-V cores in two clusters, four C908 and four
C920, plus an E902 management core. In [1] Linux drove the clock and
reset registers directly. Review pointed out that those blocks were not
modelled properly, and they are also used by the E902 firmware, which
owns the power, PMIC and CPU DVFS sequencing. This series leaves those
registers to the firmware and uses the standard SCMI clock and reset
protocols instead.

I also looked at RPMI before settling on SCMI. The firmware has to
provide reset domains for the UARTs and pad controllers and sensors for
thermal management, and RPMI has no ratified protocol for either yet.
SCMI covers everything the firmware exposes today: clock, reset, power
domain, performance, voltage, sensor and system power. Linux, U-Boot
and EDK2 already have SCMI clients, so on the Linux side only the
mailbox transport is new. RPMI support in U-Boot is also still being
debated [8].

The SCMI related changes compared to [1]:

- The native clock and reset drivers and their bindings are gone.
- A new mailbox driver for the AP to E902 doorbell. One channel carries
  SCMI requests, the other carries notifications from the firmware. The
  shared memory lives in the AON SRAM.
- arm_scmi transports can be built on RISC-V.
- New dt-bindings headers for the SCMI clock and reset IDs exported by
  the firmware. Only the IDs used here are defined for now. More will
  be appended later without renumbering the existing ones.
- Each UART has separate APB and serial resets, so the UARTs get a
  "zhihe,a210-uart" compatible with two resets, as Philipp suggested.
- The pin controllers take their pad resets from SCMI.

Other changes since [1]: the pinctrl binding explains the SDIO pad names
and the shared SDIO mux bit, pin nodes are ordered as pins, function,
then configuration, and the defconfig commit explains why ten 8250
ports are needed.

The series covers the mailbox, the pin controller, the UARTs and the
bindings and device trees around them. It is based on v7.3 and boots on
a Melon Pi V2 to a shell on the UART console with all eight CPUs online.
I would mostly like feedback on the SCMI approach and the ID headers
before sending the rest of the platform.

The E902 firmware is a Zephyr based SCMI server [2]. The rest of the
boot chain is coreboot [3], OpenSBI [4] and EDK2 [5][6]. The complete
Linux tree with the remaining peripherals is at [7].

[1] https://lore.kernel.org/r/20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn
[2] https://github.com/RevySR/zephyr/tree/xuantie/scmi
[3] https://github.com/revyos/coreboot/tree/a210/scmi
[4] https://github.com/revyos/opensbi/tree/a210/scmi
[5] https://github.com/revyos/edk2/tree/a210/scmi
[6] https://github.com/revyos/ruyiedk2/tree/a210/scmi
[7] https://github.com/RevySR/linux/tree/a210/scmi-bootchain-v7.3
[8] https://lists.u-boot-project.org/pipermail/u-boot/2026-October/635007.html

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Han Gao (10):
      firmware: arm_scmi: Allow SCMI transports on RISC-V
      dt-bindings: mailbox: add the A210 AP to E902 doorbell
      mailbox: add A210 AP to E902 doorbell support
      dt-bindings: timer: add Zhihe A210 CLINT
      dt-bindings: firmware: add A210 SCMI clock and reset IDs
      dt-bindings: serial: snps-dw-apb-uart: add Zhihe A210 UART
      riscv: dts: zhihe: add A210 module memory
      riscv: dts: zhihe: add Melon Pi V1 and V2
      riscv: defconfig: enable A210 support
      MAINTAINERS: add Zhihe A210

Zhiguo Zhu (8):
      dt-bindings: vendor-prefixes: add Zhihe
      riscv: add Zhihe A210 support
      dt-bindings: pinctrl: add Zhihe A210 pin controller
      pinctrl: zhihe: add A210 support
      dt-bindings: interrupt-controller: add Zhihe A210 PLIC
      dt-bindings: riscv: add Melon Pi V1 and V2
      riscv: dts: zhihe: add A210 core support
      riscv: dts: zhihe: add A210 UARTs

 .../interrupt-controller/sifive,plic-1.0.0.yaml    |    1 +
 .../bindings/mailbox/zhihe,a210-ap-mailbox.yaml    |   76 ++
 .../bindings/pinctrl/zhihe,a210-pinctrl.yaml       |  211 ++++
 Documentation/devicetree/bindings/riscv/zhihe.yaml |   27 +
 .../bindings/serial/snps-dw-apb-uart.yaml          |    5 +-
 .../devicetree/bindings/timer/sifive,clint.yaml    |    1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |    2 +
 MAINTAINERS                                        |   14 +
 arch/riscv/Kconfig.socs                            |   10 +
 arch/riscv/boot/dts/Makefile                       |    1 +
 arch/riscv/boot/dts/zhihe/Makefile                 |    2 +
 arch/riscv/boot/dts/zhihe/a210-melonpi-common.dtsi |   55 +
 arch/riscv/boot/dts/zhihe/a210-melonpi-v1.dts      |    9 +
 arch/riscv/boot/dts/zhihe/a210-melonpi-v2.dts      |    9 +
 arch/riscv/boot/dts/zhihe/a210-som.dtsi            |   11 +
 arch/riscv/boot/dts/zhihe/a210.dtsi                |  619 ++++++++++
 arch/riscv/configs/defconfig                       |   10 +
 drivers/firmware/arm_scmi/Kconfig                  |    2 +-
 drivers/mailbox/Kconfig                            |    9 +
 drivers/mailbox/Makefile                           |    2 +
 drivers/mailbox/mailbox-a210.c                     |  205 ++++
 drivers/pinctrl/Kconfig                            |   14 +
 drivers/pinctrl/Makefile                           |    1 +
 drivers/pinctrl/pinctrl-a210.c                     | 1212 ++++++++++++++++++++
 include/dt-bindings/clock/zhihe,a210-scmi.h        |   15 +
 include/dt-bindings/reset/zhihe,a210-scmi.h        |   13 +
 26 files changed, 2534 insertions(+), 2 deletions(-)
---
base-commit: c03c1a14507dfaf8b856c2608f9ac216021fc222
change-id: 20261027-a210-scmi-ec32fdc246a6

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

