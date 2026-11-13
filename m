From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH 00/19] riscv: add initial support for the Allwinner V861
 and Avaota F2
Date: Sat, 14 Nov 2026 06:33:26 +0800
Message-Id: <20261114-v861-v1-0-eb71ec3ee523@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MT3TILM0NdA8M082RjizTLFINUJaDSgqLUtMwKsDHRsRB+cWlSVmp
 yCUivUm0tADdhXRdoAAAA
X-Change-ID: 20261114-v861-01f7c38f9d0e
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guo Ren <guoren@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Han Gao <gaohan@iscas.ac.cn>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Maxime Ripard <mripard@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: Han Gao <rabenda.cn@gmail.com>, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-csky@vger.kernel.org, 
 linux-sunxi@lists.linux.dev, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794609209; l=3323;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=CeY384JrxATDFoc7gV7puzQwq1JBdWH8kbQQH867CU0=;
 b=b8L/R+6anOOByRDUdqRS0Wkwcagw75RMfi0v9/Yxy08unknBX7nd0LHSn54eIFdYaCTWXFt8j
 F48RaAVTvDSDBgP/XQ8HyGipQCS3f4sPLQM4ui6JwIl4yG0vLFZ6QnC
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Allwinner V861 is a camera SoC with two XuanTie C907 harts. This
series adds the clock and pin controllers, the RTC clocks and the
device trees needed to boot the YuzukiHD Avaota F2 board to a serial
console.

Tested on the Avaota F2.

---
Han Gao (19):
      riscv: sunxi: describe the wider Allwinner SoC family
      dt-bindings: riscv: cpus: add the XuanTie C907
      dt-bindings: interrupt-controller: add the Allwinner V861 PLIC
      dt-bindings: timer: add the Allwinner V861 CLINT
      dt-bindings: clock: sunxi-ng: document the Allwinner V861 CCUs
      clk: sunxi-ng: add support for the Allwinner V861 CCU
      clk: sunxi-ng: add support for the Allwinner V861 PRCM CCU
      dt-bindings: rtc: sun6i: add the Allwinner V861 RTC
      clk: sunxi-ng: sun6i-rtc: allow variants without a 32k fanout mux
      clk: sunxi-ng: sun6i-rtc: allow another 24 MHz to 32k divider ratio
      clk: sunxi-ng: sun6i-rtc: add Allwinner V861 support
      dt-bindings: pinctrl: add the Allwinner V861 pin controllers
      pinctrl: sunxi: allow a per-controller IRQ register base
      pinctrl: sunxi: add support for the Allwinner V861 PIO
      pinctrl: sunxi: add support for the Allwinner V861 R-PIO
      riscv: dts: allwinner: add the Allwinner V861 SoC
      dt-bindings: riscv: sunxi: add the YuzukiHD Avaota F2
      riscv: dts: allwinner: add the YuzukiHD Avaota F2 board
      MAINTAINERS: add an entry for the Allwinner V861 SoC

 .../bindings/clock/allwinner,sun252i-v861-ccu.yaml |   99 ++
 .../interrupt-controller/sifive,plic-1.0.0.yaml    |    1 +
 .../pinctrl/allwinner,sun55i-a523-pinctrl.yaml     |   31 +-
 Documentation/devicetree/bindings/riscv/cpus.yaml  |    1 +
 Documentation/devicetree/bindings/riscv/sunxi.yaml |    5 +
 .../bindings/rtc/allwinner,sun6i-a31-rtc.yaml      |    1 +
 .../devicetree/bindings/timer/sifive,clint.yaml    |    1 +
 MAINTAINERS                                        |   12 +
 arch/riscv/Kconfig.socs                            |    6 +-
 arch/riscv/boot/dts/allwinner/Makefile             |    1 +
 .../boot/dts/allwinner/sun252i-v861-avaota-f2.dts  |   43 +
 arch/riscv/boot/dts/allwinner/sun252i-v861.dtsi    |  272 +++++
 drivers/clk/sunxi-ng/Kconfig                       |   20 +
 drivers/clk/sunxi-ng/Makefile                      |    4 +
 drivers/clk/sunxi-ng/ccu-sun252i-v861-r.c          |  110 ++
 drivers/clk/sunxi-ng/ccu-sun252i-v861.c            | 1117 ++++++++++++++++++++
 drivers/clk/sunxi-ng/ccu-sun6i-rtc.c               |   31 +-
 drivers/pinctrl/sunxi/Kconfig                      |   20 +
 drivers/pinctrl/sunxi/Makefile                     |    2 +
 drivers/pinctrl/sunxi/pinctrl-sun252i-v861-r.c     |   48 +
 drivers/pinctrl/sunxi/pinctrl-sun252i-v861.c       |   49 +
 drivers/pinctrl/sunxi/pinctrl-sunxi.h              |    7 +-
 include/dt-bindings/clock/sun252i-v861-ccu.h       |  127 +++
 include/dt-bindings/clock/sun252i-v861-r-ccu.h     |   14 +
 include/dt-bindings/reset/sun252i-v861-ccu.h       |   55 +
 include/dt-bindings/reset/sun252i-v861-r-ccu.h     |   12 +
 26 files changed, 2080 insertions(+), 9 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261114-v861-01f7c38f9d0e

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

