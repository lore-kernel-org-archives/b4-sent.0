From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH 00/18] riscv: add initial support for Zhihe A210 and Melon
 Pi
Date: Thu, 22 Oct 2026 03:53:20 +0800
Message-Id: <20261022-a210-init-v1-0-5e438f972d24@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDVpBw2uIhZVg7EoaRGJuLti+
 ZKff0EgzxSgTi7wdHDgxUWoNAE7GTeS4D4aUKJWElEYVFKw4030WWm7inReaAOxXz0NfH6vpv0
 d9m4mu70DuO8Hf3JP0m0AAAA=
X-Change-ID: 20261022-a210-init-d38cb9e6456a
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Zhiguo Zhu <zhiguo.zhu@linux.alibaba.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Samuel Holland <samuel.holland@sifive.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Anup Patel <anup@brainfault.org>, Icenowy Zheng <uwu@icenowy.me>, 
 Drew Fustini <fustini@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Paul Walmsley <paul.walmsley@sifive.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792612403; l=3651;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=fdqGEtqurgeviCoJo2v3fz4uafhyyCeIFrfPMJXL25M=;
 b=KF/xmGzB8PxIXqaSFn0Vm3oSvz4qj1fS28kB8b2HzP7/gqxzmDgUh7qKLPq222zC3FZqfkguz
 KszNuI96SoFAF3Izvh+DH9TENK9KRRBE4063hQgjuOSnEeNU8jtqWUv
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial support for the Zhihe A210 SoC and the Melon Pi
V1 and V2 boards.

The A210 features eight RISC-V cores in two clusters: four C908 cores
and four C920 cores.

This series provides UART, clock, reset and pinctrl support, together
with the required bindings and device trees.

It is based on Linux v7.3 and has been boot-tested on a Melon Pi V2
with all eight CPUs online.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Han Gao (6):
      dt-bindings: clock: add Zhihe A210 AON clock controller
      dt-bindings: timer: add Zhihe A210 CLINT
      riscv: dts: zhihe: add A210 module memory
      riscv: dts: zhihe: add Melon Pi V1 and V2
      riscv: defconfig: enable A210 support
      MAINTAINERS: add Zhihe A210

Zhiguo Zhu (12):
      dt-bindings: vendor-prefixes: add Zhihe
      riscv: add Zhihe A210 support
      dt-bindings: clock: add Zhihe A210 clock controllers
      clk: zhihe: add A210 support
      dt-bindings: reset: add Zhihe A210 reset controllers
      reset: zhihe: add A210 support
      dt-bindings: pinctrl: add Zhihe A210 pin controller
      pinctrl: zhihe: add A210 support
      dt-bindings: interrupt-controller: add Zhihe A210 PLIC
      dt-bindings: riscv: add Melon Pi V1 and V2
      riscv: dts: zhihe: add A210 core support
      riscv: dts: zhihe: add A210 UARTs

 .../bindings/clock/zhihe,a210-aon-clk.yaml         |   58 +
 .../devicetree/bindings/clock/zhihe,a210-clk.yaml  |  231 ++
 .../interrupt-controller/sifive,plic-1.0.0.yaml    |    1 +
 .../bindings/pinctrl/zhihe,a210-pinctrl.yaml       |  206 ++
 .../bindings/reset/zhihe,a210-reset.yaml           |   56 +
 Documentation/devicetree/bindings/riscv/zhihe.yaml |   27 +
 .../devicetree/bindings/timer/sifive,clint.yaml    |    1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |    2 +
 MAINTAINERS                                        |   16 +
 arch/riscv/Kconfig.socs                            |   10 +
 arch/riscv/boot/dts/Makefile                       |    1 +
 arch/riscv/boot/dts/zhihe/Makefile                 |    2 +
 arch/riscv/boot/dts/zhihe/a210-melonpi-common.dtsi |   55 +
 arch/riscv/boot/dts/zhihe/a210-melonpi-v1.dts      |    9 +
 arch/riscv/boot/dts/zhihe/a210-melonpi-v2.dts      |    9 +
 arch/riscv/boot/dts/zhihe/a210-som.dtsi            |   11 +
 arch/riscv/boot/dts/zhihe/a210.dtsi                |  645 ++++++
 arch/riscv/configs/defconfig                       |    4 +
 drivers/clk/Kconfig                                |    1 +
 drivers/clk/Makefile                               |    1 +
 drivers/clk/zhihe/Kconfig                          |   12 +
 drivers/clk/zhihe/Makefile                         |    2 +
 drivers/clk/zhihe/clk-a210-aon.c                   |   94 +
 drivers/clk/zhihe/clk-a210-ap.c                    | 2283 ++++++++++++++++++++
 drivers/pinctrl/Kconfig                            |   14 +
 drivers/pinctrl/Makefile                           |    1 +
 drivers/pinctrl/pinctrl-a210.c                     | 1206 +++++++++++
 drivers/reset/Kconfig                              |   11 +
 drivers/reset/Makefile                             |    1 +
 drivers/reset/reset-a210.c                         |  589 +++++
 include/dt-bindings/clock/zhihe,a210-aon-clk.h     |    9 +
 include/dt-bindings/clock/zhihe,a210-clk.h         |  649 ++++++
 include/dt-bindings/reset/zhihe,a210-resets.h      |  351 +++
 33 files changed, 6568 insertions(+)
---
base-commit: c03c1a14507dfaf8b856c2608f9ac216021fc222
change-id: 20261022-a210-init-d38cb9e6456a

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

