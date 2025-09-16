From: Dang Huynh <dang.huynh@mainlining.org>
Subject: [PATCH 00/25] RDA8810PL Clock, RTC and MMC driver
Date: Wed, 17 Sep 2025 03:24:57 +0700
Message-Id: <20250917-rda8810pl-drivers-v1-0-9ca9184ca977@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJnHyWgC/x3MQQqAIBBA0avErBPUsrKrRAvJqQbCYgQJxLsnL
 d/i/wwRmTDC3GRgTBTpDhWqbWA7XThQkK8GLbWRVg2CvZsmJZ9LeKaEHIV1Ro+qN3roDNTuYdz
 p/Z/LWsoHMTLSk2MAAAA=
X-Change-ID: 20250916-rda8810pl-drivers-9a5271452635
To: Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Sebastian Reichel <sre@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-unisoc@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-rtc@vger.kernel.org, 
 linux-clk@vger.kernel.org, linux-pm@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hardening@vger.kernel.org, 
 linux-mmc@vger.kernel.org, Dang Huynh <dang.huynh@mainlining.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758054322; l=3886;
 i=dang.huynh@mainlining.org; s=20250917; h=from:subject:message-id;
 bh=QGD8kRGBo4syZf/wQP0MSt3nT94Hk5NSzVk+3pfI8QQ=;
 b=9zchpSAFwjr+IQK2dMLrZvsWvEJuMCoEzZv1nMsFWfTxwY7t6r94fNp29tagymUqPmbGLtAjS
 obpQLZLCJPKAv4jwBuj4UgTE75ucWgSclNMjDGj95eHLrisstZxh3Pc
X-Developer-Key: i=dang.huynh@mainlining.org; a=ed25519;
 pk=RyzH4CL4YU/ItXYUurA51EVBidfx4lIy8/E4EKRJCUk=
X-Endpoint-Received: by B4 Relay for dang.huynh@mainlining.org/20250917 with auth_id=526
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series aims to add support for Clock/Reset, Real-Time Clock and
SDMMC on the RDA Micro RDA8810PL platform.

It also adds Intelligent Flow Controller (IOW, a DMA controller) which is
important for working with this MMC IP.

Tested on the Orange Pi 2G-IOT.

Signed-off-by: Dang Huynh <dang.huynh@mainlining.org>
---
Dang Huynh (25):
      ARM: dts: unisoc: rda8810pl: Add label to GPIO nodes
      drivers: gpio: rda: Make IRQ optional
      dt-bindings: gpio: rda: Make interrupts optional
      rtc: Add timestamp for the end of 2127
      dt-bindings: rtc: Add RDA Micro RDA8810PL RTC
      rtc: Add driver for RDA Micro SoC
      ARM: dts: unisoc: rda8810pl: Enable Real-Time Clock
      ARM: dts: unisoc: rda8810pl: Enable ARM PMU
      dt-bindings: clock: Add RDA Micro RDA8810PL clock/reset controller
      drivers: clk: Add Clock and Reset Driver for RDA Micro RDA8810PL SoC
      dts: unisoc: rda8810pl: Enable clock/reset driver
      dts: unisoc: rda8810pl: Add OPP for CPU and define L2 cache
      dts: unisoc: orangepi: Disable UART with no users
      dt-bindings: power: reset: Add RDA Micro Modem Reset
      power: reset: Add basic power reset driver for RDA8810PL
      dts: unisoc: rda8810pl: Enable modem reset
      drivers: gpio: rda: Make direction register unreadable
      dt-bindings: dma: Add RDA IFC DMA
      dmaengine: Add RDA IFC driver
      dts: unisoc: rda8810pl: Enable IFC
      dt-bindings: mmc: Add RDA SDMMC controller
      mmc: host: Add RDA Micro SD/MMC driver
      dts: unisoc: rda8810pl: Add SDMMC controllers
      dts: unisoc: orangepi-2g: Enable SD Card
      dts: unisoc: orangepi-i96: Enable SD Card

 .../bindings/clock/rda,8810pl-apsyscon.yaml        |  44 ++
 Documentation/devicetree/bindings/dma/rda,ifc.yaml |  42 +
 .../devicetree/bindings/gpio/gpio-rda.yaml         |   3 -
 Documentation/devicetree/bindings/mmc/rda,mmc.yaml |  91 +++
 .../bindings/power/reset/rda,md-reset.yaml         |  36 +
 .../devicetree/bindings/rtc/rda,8810pl-rtc.yaml    |  30 +
 MAINTAINERS                                        |  30 +
 .../boot/dts/unisoc/rda8810pl-orangepi-2g-iot.dts  |  24 +-
 .../arm/boot/dts/unisoc/rda8810pl-orangepi-i96.dts |  24 +-
 arch/arm/boot/dts/unisoc/rda8810pl.dtsi            | 115 ++-
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/rda/Kconfig                            |  14 +
 drivers/clk/rda/Makefile                           |   2 +
 drivers/clk/rda/clk-rda8810.c                      | 770 +++++++++++++++++++
 drivers/dma/Kconfig                                |  10 +
 drivers/dma/Makefile                               |   1 +
 drivers/dma/rda-ifc.c                              | 450 +++++++++++
 drivers/gpio/gpio-rda.c                            |   4 +-
 drivers/mmc/host/Kconfig                           |  12 +
 drivers/mmc/host/Makefile                          |   1 +
 drivers/mmc/host/rda-mmc.c                         | 853 +++++++++++++++++++++
 drivers/power/reset/Kconfig                        |   9 +
 drivers/power/reset/Makefile                       |   1 +
 drivers/power/reset/rda-reboot.c                   |  58 ++
 drivers/rtc/Kconfig                                |  11 +
 drivers/rtc/Makefile                               |   1 +
 drivers/rtc/rtc-rda.c                              | 356 +++++++++
 include/dt-bindings/clock/rda,8810pl-apclk.h       |  79 ++
 include/dt-bindings/dma/rda-ifc.h                  |  28 +
 include/linux/rtc.h                                |   1 +
 31 files changed, 3079 insertions(+), 23 deletions(-)
---
base-commit: 590b221ed4256fd6c34d3dea77aa5bd6e741bbc1
change-id: 20250916-rda8810pl-drivers-9a5271452635

Best regards,
-- 
Dang Huynh <dang.huynh@mainlining.org>

