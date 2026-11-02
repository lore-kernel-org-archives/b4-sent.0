From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH RFC v3 00/17] riscv: add initial Zhihe A210 support using
 SCMI clocks and resets
Date: Tue, 03 Nov 2026 03:45:03 +0800
Message-Id: <20261103-a210-scmi-v3-0-ee6b31580808@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NzQqCQBRGX0XuupGZ8ZdWQdADtA0X451r3kCNu
 SaF+O6pbVuej8P5ZhAKTALHaIZAEwsP/QrJIQJsXX8nxX5lsNrmRttCOWu0EuxYESa28WjT3OW
 w+s9ADb/31g2ulzNUv1Fe9YNw3Cqb1rKMQ/jsj5PZ5T/xySititRnJVKZ1b48saCT2GGMPVTLs
 nwBTHa3R7sAAAA=
X-Change-ID: 20261027-a210-scmi-ec32fdc246a6
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>, 
 Michal Simek <michal.simek@amd.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Linus Walleij <linusw@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
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
 linux-serial@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793648705; l=6929;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=qJnpOKYgSY+CxvvdscVQfHlmE8/VuKqhLVuhLq3Ax30=;
 b=oL9F7FE3HXj7HVFebcOJhByBbwziul9m3Bk09rFP/ffuYVyXoih5Jxi7YcqKrY0E3qoTot39e
 ZTGO3GEKrk8CCZE/ASC6Xv2b4p2uCZT4RlEQtgwqQr/6cSlcukdh3QL
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds initial support for the Zhihe A210 SoC and the Melon Pi V1
and V2 boards.

The A210 has four C908V and four C920V2 cores, plus an E902 management
core. The E902 firmware handles clocks, resets, power, the PMIC and
CPU DVFS, so Linux uses SCMI for clocks and resets. The only new SCMI
piece is the mailbox to the E902. [2] explains why I picked SCMI over
RPMI.

The series adds the mailbox, the pin controller, the UARTs and their
bindings and DTs. On v7.4-rc1 with the riscv defconfig, a Melon Pi V2
boots to a shell on the serial console with all eight CPUs online.

The numbering follows [1], as Bartosz asked, so the RFC [2] is v2 and
this is v3.

Conor asked about vendor firmware. We are talking to Zhihe about SCMI
support in their firmware. Until that is settled, mainline needs the
firmware below, so this is still an RFC.

The E902 runs a Zephyr based SCMI server [3]. The rest of the boot
chain is coreboot [4], OpenSBI [5] and EDK2 [6][7]. The full Linux tree
with the other peripherals is at [8].

[1] https://lore.kernel.org/r/20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn
[2] https://lore.kernel.org/r/20261027-a210-scmi-v1-0-74d58ce85bd8@iscas.ac.cn
[3] https://github.com/RevySR/zephyr/tree/xuantie/scmi-v3
[4] https://github.com/revyos/coreboot/tree/a210/scmi-v3
[5] https://github.com/revyos/opensbi/tree/a210/scmi-v3
[6] https://github.com/revyos/edk2/tree/a210/scmi-v3
[7] https://github.com/revyos/ruyiedk2/tree/a210/scmi-v3
[8] https://github.com/RevySR/linux/tree/a210/scmi-v3

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Changes in v3:
- Rebase on v7.4-rc1, and add zhihe,a210-uart to the list of DW APB
  UARTs with two resets.
- arm_scmi: drop the ARM dependency instead of adding RISCV (Michal).
  Build tested on x86_64 without OF, i386, loongarch64, ppc64le and
  riscv64 (Sudeep).
- Move the SCMI clock and reset IDs from dt-bindings to headers next
  to the DTS, as the firmware assigns them (Conor).
- mailbox binding: use fixed "local" and "remote" regions and add blank
  lines between properties (Conor). Drop the clocks, as the firmware
  keeps the mailboxes running, and call it a mailbox, not a doorbell.
- mailbox driver: don't request a shared interrupt.
- pinctrl: rename to pinctrl-zhihe-a210.c and PINCTRL_ZHIHE_A210, drop
  the 64BIT dependency and a forward declaration, comment the register
  layout and the ____ placeholder, and round drive strength up (Linus).
  Don't include mod_devicetable.h (Uwe).
- pinctrl: drop PERI3. It comes back with the SDIO controller, as pins
  and function, with the shared mux handled in the driver (Conor).
- pinctrl: use one function name per kind, like gpio, spi or pwm, and
  number them only where a pad can pick an instance, as for the UARTs
  (Conor).
- pinctrl: use pm_sleep_ptr() instead of #ifdef CONFIG_PM_SLEEP, and
  don't use dev_err_probe() in resume.
- defconfig: drop SRAM, the SCMI mailbox transport and the SCMI reset
  driver. SCMI maps its shared memory itself, and the other two are
  enabled by default with SCMI. Shorten the NR_UARTS explanation.
- dts: use 0x1000 regions for uart0 and uart4, like the other UARTs.
- dts: describe the PLIC M-mode contexts with 11 instead of -1.
- Spell the vendor name Zhihe everywhere.
- Add Conor's acks.
- Link to v2 (sent as RFC): https://patch.msgid.link/20261027-a210-scmi-v1-0-74d58ce85bd8@iscas.ac.cn

Changes in v2 (sent as RFC):
- Replace the native clock and reset drivers with SCMI. Conor pointed
  out that the clock blocks were not modelled right, and the E902
  firmware uses those registers too.
- Add the AP to E902 mailbox driver as the SCMI transport, and allow
  arm_scmi transports on RISC-V.
- Add dt-bindings headers for the SCMI clock and reset IDs.
- Add zhihe,a210-uart with separate APB and serial resets (Philipp).
- pinctrl: take the pad resets from SCMI, explain the SDIO pad names
  and the shared SDIO mux bit, and order pin nodes as pins, function,
  then config (Conor).
- defconfig: explain why SERIAL_8250_NR_UARTS is 10 (Conor).
- Link to v1: https://patch.msgid.link/20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn

---
Han Gao (9):
      firmware: arm_scmi: Drop the ARM architecture dependency
      dt-bindings: mailbox: add Zhihe A210 AP to E902 mailbox
      mailbox: add Zhihe A210 AP to E902 mailbox driver
      dt-bindings: timer: add Zhihe A210 CLINT
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

 .../interrupt-controller/sifive,plic-1.0.0.yaml    |   1 +
 .../bindings/mailbox/zhihe,a210-ap-mailbox.yaml    |  67 ++
 .../bindings/pinctrl/zhihe,a210-pinctrl.yaml       | 146 +++
 Documentation/devicetree/bindings/riscv/zhihe.yaml |  27 +
 .../bindings/serial/snps-dw-apb-uart.yaml          |   6 +-
 .../devicetree/bindings/timer/sifive,clint.yaml    |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |  12 +
 arch/riscv/Kconfig.socs                            |  10 +
 arch/riscv/boot/dts/Makefile                       |   1 +
 arch/riscv/boot/dts/zhihe/Makefile                 |   2 +
 arch/riscv/boot/dts/zhihe/a210-clock.h             |  15 +
 arch/riscv/boot/dts/zhihe/a210-melonpi-common.dtsi |  55 ++
 arch/riscv/boot/dts/zhihe/a210-melonpi-v1.dts      |   9 +
 arch/riscv/boot/dts/zhihe/a210-melonpi-v2.dts      |   9 +
 arch/riscv/boot/dts/zhihe/a210-reset.h             |  13 +
 arch/riscv/boot/dts/zhihe/a210-som.dtsi            |  11 +
 arch/riscv/boot/dts/zhihe/a210.dtsi                | 593 ++++++++++++
 arch/riscv/configs/defconfig                       |   7 +
 drivers/firmware/arm_scmi/Kconfig                  |   1 -
 drivers/mailbox/Kconfig                            |   9 +
 drivers/mailbox/Makefile                           |   2 +
 drivers/mailbox/mailbox-a210.c                     | 176 ++++
 drivers/pinctrl/Kconfig                            |  13 +
 drivers/pinctrl/Makefile                           |   1 +
 drivers/pinctrl/pinctrl-zhihe-a210.c               | 996 +++++++++++++++++++++
 26 files changed, 2183 insertions(+), 2 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261027-a210-scmi-ec32fdc246a6

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

