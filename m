From: Dang Huynh <dang.huynh@mainlining.org>
Subject: [PATCH 00/10] RDA8810PL SD/MMC support
Date: Fri, 19 Sep 2025 01:48:40 +0700
Message-Id: <20250919-rda8810pl-mmc-v1-0-d4f08a05ba4d@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAhUzGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDS0ML3aKURAsLQ4OCHN3c3GRd4zRj4yQL42RjQ+MUJaCegqLUtMwKsHn
 RsbW1ANyU/p1fAAAA
X-Change-ID: 20250918-rda8810pl-mmc-3f33b83c313d
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-unisoc@lists.infradead.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Dang Huynh <dang.huynh@mainlining.org>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758221395; l=2690;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=kZ31Cj+9SlIwCue4nf87udZAy0O4rgTArK6cH8v5gE0=;
 b=qOqMjxWy0QtL3Ogxpb8gkzjO7d5vmQGyKe+kb/6NkDaSg1BsYLRsnjbZgBDstvASeAx0n2d2c
 3shNDl4Z4C4Bf3HZJfK9hqW3+uGf3bq50x8EsDU0gvAu95HssYcfjYM
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series aims to add SDMMC driver and various drivers required
for SDMMC controller to function.

This also fixed a bug where all the GPIO switched from INPUT to OUTPUT
after the GPIO driver probed or by reading the GPIO debugfs.

This patch series is a split from [1] to ease the maintainers.

Tested on Orange Pi 2G-IOT using a Buildroot environment.

[1]: https://lore.kernel.org/all/20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org/

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
Dang Huynh (10):
      dt-bindings: gpio: rda: Make interrupts optional
      dt-bindings: clock: Add RDA Micro RDA8810PL clock/reset controller
      dt-bindings: dma: Add RDA IFC DMA
      dt-bindings: mmc: Add RDA SDMMC controller
      gpio: rda: Make IRQ optional
      gpio: rda: Make direction register unreadable
      clk: Add Clock and Reset Driver for RDA Micro RDA8810PL SoC
      dmaengine: Add RDA IFC driver
      mmc: host: Add RDA Micro SD/MMC driver
      ARM: dts: unisoc: rda8810pl: Add SDMMC controllers

 .../bindings/clock/rda,8810pl-apsyscon.yaml        |  43 ++
 Documentation/devicetree/bindings/dma/rda,ifc.yaml |  45 ++
 .../devicetree/bindings/gpio/gpio-rda.yaml         |   3 -
 Documentation/devicetree/bindings/mmc/rda,mmc.yaml |  92 +++
 MAINTAINERS                                        |  18 +
 .../boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts  |  20 +
 .../arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts |  20 +
 arch/arm/boot/dts/unisoc/rda8810pl.dtsi            |  47 +-
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/rda/Kconfig                            |  14 +
 drivers/clk/rda/Makefile                           |   2 +
 drivers/clk/rda/clk-rda8810.c                      | 769 +++++++++++++++++++
 drivers/dma/Kconfig                                |  10 +
 drivers/dma/Makefile                               |   1 +
 drivers/dma/rda-ifc.c                              | 450 +++++++++++
 drivers/gpio/gpio-rda.c                            |   4 +-
 drivers/mmc/host/Kconfig                           |  12 +
 drivers/mmc/host/Makefile                          |   1 +
 drivers/mmc/host/rda-mmc.c                         | 853 +++++++++++++++++++++
 include/dt-bindings/clock/rda,8810pl-apclk.h       |  70 ++
 include/dt-bindings/dma/rda-ifc.h                  |  28 +
 22 files changed, 2495 insertions(+), 9 deletions(-)
---
base-commit: ae2d20002576d2893ecaff25db3d7ef9190ac0b6
change-id: 20250918-rda8810pl-mmc-3f33b83c313d

Best regards,
-- 
Dang Huynh <dang.huynh@mainlining.org>

