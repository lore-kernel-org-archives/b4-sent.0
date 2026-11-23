From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH 0/5] soc: cortina: Add CS7542 global clocks and pin
 multiplexer
Date: Mon, 23 Nov 2026 21:41:11 +0300
Message-Id: <20261123-cs7542-syscon-v1-0-49858e631449@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAxA0asgz41EDCFSr4I6pMaAOwQU0wqEu
 HsDjG/4fwflJKzwLHZI/BOVKWbYRwE0hjiwkS4bsMTGWqwMqXc1Gt2UpmjQV52rHfnQI+RmTtz
 Lev3a1239vj9MyzmB4/gDnpSg8HEAAAA=
X-Change-ID: 20261123-cs7542-syscon-273d545c7af2
To: Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Linus Walleij <linusw@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Arnd Bergmann <arnd@arndb.de>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459271; l=5783;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=S35UkrNFrlQex9/2aBwHnbLGqIK7v0fFjmBC7JaKmXw=;
 b=xkmVuEGdHIbZ3A5YRniy+6A9wBiqwaJI0BU3lsSLFQcxSuagpN7C3lTzhz+GCIDWQ627wtkH/
 T6O3L3i0VNIDU/FTXxf/oseTa1S42JaobYMfF6Z2tBV+Cs7LIkDlxLw
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CS7542 global control block contains boot strap status and five
GPIO/peripheral mux registers, alongside reset and SMP controls. Add a
shared syscon binding, an early strap-selected clock provider, and a
pinctrl child using that same regmap.

The source material is the GPL vendor kernel and the existing OpenWrt
port. OpenWrt previously used a board-fixed APB clock and a temporary
machine initcall to select GPIO37 and the UART1-3 pins. An older port
read the strap to publish APB, CPU and AXI fixed clocks. This series
replaces those mechanisms with subsystem drivers, without moving mux
writes back into the GPIO controller.

The clock provider only reports the seven known strap configurations;
it does not program PLLs, dividers or gates, and does not implement
DVFS. Reserved encoding 7 is rejected. It is initialized before ARM
timer discovery, while keeping the syscon node available to populate
the pinctrl child.

The pin mux driver supports GPIO on the five 32-line banks and the six
UART pins (72-77) used by the OpenWrt workaround. Other peripheral
functions, pulls and drive strengths are intentionally not exposed.
A GPIO/peripheral selection updates only its own bit through regmap.

These five patches are based on v7.4-rc4 and do not depend on the
pending platform, GPIO or INTC series. A separate peripheral DTS series,
based on platform v9, adds the syscon node, replaces the fixed APB clock,
connects CPU clocks and selects GPIO37 and UART1-3 on the Almond+. The existing SMP
release register remains accessed by the platform code.

Validation:
- full ARM multi_v7_defconfig vmlinux and modules builds with W=1:
  GCC 14.2 clock=y/pinctrl=y and Clang 21.1.8 clock=y/pinctrl=m,
  COMPILE_TEST=n, without the pending platform series; both passed
- final linked kernel symbols and pinctrl module/modpost checked;
  no warnings in the new drivers (other kernel code emits warnings)
- dt_binding_check including both examples; positive GPIO/UART cases
  and rejection of invalid UART37, GPIO160 and unsupported pin config
- host harnesses running the actual clock init and mux routines with
  failure-injecting mocked APIs: all strap settings, registration/error
  cleanup, every mux pin/bank boundary, neighbour preservation
- component and DTB/schema checks of the separate integration tree

The exact new clock and pinctrl sources have now booted on a Securifi
Almond+ in an OpenWrt 6.18.64 RAM kernel. Before entry, GPIO37 and UART72-77
were deliberately set to the opposite mux state; the default pinctrl
state restored them. APB/CPU/AXI rates were 150/750/150 MHz. The test
recorded a physical reset-button press/release with matching IRQ-backed
hotplug events, opened UART1-3 at 115200, read the I2C device at 0x48,
received the expected NACK at 0x49, and exercised watchdog calls from CPU1
and 20-second expiry. All 27 checks passed. Raw I2C checks used a test DTB
with the touchscreen consumer disabled; production OpenWrt keeps it
enabled. The device returned to installed OpenWrt 6.18.60 with unchanged
configuration hashes. This is hardware evidence for these driver sources
on 6.18.64, not a boot test of the standalone v7.4-rc4 series or of DVFS
and suspend.

The production OpenWrt 6.18.64 image has also been installed, preserving
configuration. The default mux and clock rates were confirmed after
boot; GPIO37 press/release and IRQ-backed hotplug events, UART1-3 termios
configuration and watchdog keepalives/20-second expiry reset passed.
The protected bootloader/environment, retained UBI volumes and
configuration hashes were unchanged after the upgrade and reset.

The same clock/pinctrl sources additionally booted in a Linux 7.4-rc4
RAM integration kernel with platform v9, the accepted watchdog and
local RTC/TRNG drafts. Both CPUs came online; the final RTC calendar,
TRNG and watchdog harness passed 16 checks and returned to OpenWrt.
This is an integration boot, not a repeated physical-button or UART1-3
test on 7.4; those source-level hardware checks above used 6.18.64.

To: Linus Walleij <linusw@kernel.org>
To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney+clk@redhat.com>
To: Jerome Brunet <jbrunet+clk@baylibre.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: Arnd Bergmann <arnd@arndb.de>
Cc: linux-gpio@vger.kernel.org
Cc: linux-clk@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-kernel@vger.kernel.org

---
Fil Dunsky (5):
      dt-bindings: soc: Add Cortina Systems CS7542 global control block
      dt-bindings: pinctrl: Add Cortina Systems CS7542 pin mux
      clk: Add Cortina Systems CS7542 strap-selected clocks
      pinctrl: Add Cortina Systems CS7542 pin multiplexer
      MAINTAINERS: Add CS7542 global control support

 .../bindings/pinctrl/cortina,cs7542-pinctrl.yaml   |  84 +++++++++
 .../soc/cortina/cortina,cs7542-syscon.yaml         |  49 ++++++
 MAINTAINERS                                        |  10 ++
 drivers/clk/Kconfig                                |   9 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/clk-cs7542.c                           |  90 ++++++++++
 drivers/pinctrl/Kconfig                            |  13 ++
 drivers/pinctrl/Makefile                           |   1 +
 drivers/pinctrl/pinctrl-cs7542.c                   | 188 +++++++++++++++++++++
 include/dt-bindings/clock/cortina,cs7542-clock.h   |   9 +
 10 files changed, 454 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-cs7542-syscon-273d545c7af2

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

