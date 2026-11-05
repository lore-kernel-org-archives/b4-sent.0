From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH v11 0/5] arm64: add Ambarella CV75 SoC support
Date: Thu, 05 Nov 2026 19:06:34 +0800
Message-Id: <20261105-cv75-soc-v11-0-aa6ee0b2380d@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADpj7GoC/12OwQ7CIAyGX8VwFgNsMObJ9zAeGHQOsw0Dk2iWv
 buwxWhMemn7f187owDeQkDH3Yw8RBusG1ND6X6HdKfGK2Br0gAxwgQlpMI6VhwHpzEIJtuCVy0
 RAqX43UNrn6vrfNn68GhuoKfM50Rnw+T8az0W65z7aOmmjalqTHAphdZM1qps5EkNjfLQ9+qg3
 YCyOVLyA9P6+1PaJNwUUhDBgRnD//FlWd4F6klB9QAAAA==
X-Change-ID: 20261007-cv75-soc-e628f357f066
To: Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, soc@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: Jerome Brunet <jbrunet@baylibre.com>, linux-clk@vger.kernel.org, 
 Brian Masney <masneyb@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 devicetree@vger.kernel.org, Long Zhao <longzhao@ambarella.com>, 
 Long Zhao <zl020895@163.com>, linux-kernel@vger.kernel.org, 
 Linus Walleij <linusw@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793876823; l=3501;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=AVzwdrPqmXDKIIAxlOumBsj3BZ0AuGGaxyVMdRkHk20=;
 b=8UWLdjRv/iksvX+vRoXqsIjzNdNyzojvgDsrJYb0Tin0Z1ymhEd1Jq9z4hI2Cd7nCZly4x/Z1
 CirGO7XBDt8DbT4724QX/nTjOwrwBt7TSqTjPPT/dcvYyveRrmyTPI2
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Ambarella CV75 SoC and EVK support: the board binding, the
RCT clock binding and driver, ARCH_AMBARELLA, the devicetree and
MAINTAINERS.

The clock ID header is added before the devicetree that includes it,
so patch 2 (the clock binding) has to be applied before patch 4 (the
devicetree).

The ambarella vendor prefix and the CV75 secure scratchpad syscon
binding are already in linux-next. This series does not repeat
either of them.

GPIO, UART and pinctrl bindings and drivers are separate series.
This devicetree references those compatibles.

Tested on the CV75 EVK. The board boots. That boot used a local tree
that also includes the GPIO, UART and pinctrl patches.

To: Arnd Bergmann <arnd@arndb.de>
To: Krzysztof Kozlowski <krzk@kernel.org>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
To: soc@lists.linux.dev
To: linux-arm-kernel@lists.infradead.org
To: Michael Turquette <mturquette@baylibre.com>
To: Stephen Boyd <sboyd@kernel.org>
Cc: Jerome Brunet <jbrunet@baylibre.com>
Cc: linux-clk@vger.kernel.org
Cc: Brian Masney <masneyb@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Rob Herring <robh@kernel.org>
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Cc: Conor Dooley <conor+dt@kernel.org>
Cc: Catalin Marinas <catalin.marinas@arm.com>
Cc: Will Deacon <will@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: Long Zhao <longzhao@ambarella.com>
Cc: Long Zhao <zl020895@163.com>
Cc: linux-kernel@vger.kernel.org

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Changes in v11:
- clk: use builtin_platform_driver(). The Kconfig symbol is bool. (Brian)
- clk: drop CLK_IS_CRITICAL from the core PLL. It has no enable op. (Brian)
- clk: drop the misleading (u64) cast in the div_u64() call. (Brian)
- clk: add .suppress_bind_attrs = true to block sysfs unbind. (Brian)
- clk: drop MODULE_AUTHOR. (Brian)
- Link to v10:
  https://patch.msgid.link/20261019-cv75-soc-v10-0-d386065e2dd5@ambarella.com

---
Long Zhao (5):
      dt-bindings: arm: add Ambarella CV75 platforms
      dt-bindings: clock: add Ambarella CV75 RCT
      clk: ambarella: add CV75 RCT clock controller
      arm64: ambarella: add ARCH_AMBARELLA and CV75 EVK DT
      MAINTAINERS: add ARM/AMBARELLA SoC support

 .../devicetree/bindings/arm/ambarella.yaml         |  24 ++
 .../bindings/clock/ambarella,cv75-rct.yaml         |  64 ++++
 MAINTAINERS                                        |  14 +
 arch/arm64/Kconfig.platforms                       |   6 +
 arch/arm64/boot/dts/Makefile                       |   1 +
 arch/arm64/boot/dts/ambarella/Makefile             |   3 +
 arch/arm64/boot/dts/ambarella/cv75-evk.dts         |  30 ++
 arch/arm64/boot/dts/ambarella/cv75.dtsi            | 177 ++++++++++
 arch/arm64/configs/defconfig                       |   1 +
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/ambarella/Kconfig                      |   8 +
 drivers/clk/ambarella/Makefile                     |   3 +
 drivers/clk/ambarella/clk-cv75.c                   | 361 +++++++++++++++++++++
 include/dt-bindings/clock/ambarella,cv75-rct.h     |  14 +
 15 files changed, 708 insertions(+)
---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20261007-cv75-soc-e628f357f066

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

