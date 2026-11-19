From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH v12 0/6] arm64: add Ambarella CV75 SoC support
Date: Thu, 19 Nov 2026 18:13:18 +0800
Message-Id: <20261119-cv75-soc-v12-0-e5a03cca8b05@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL7L/moC/22OwQ7CIAyGX8VwFlPYYODJ9zAeGHSKUWdAiWbZu
 wtbjMaY9NL2/752IBGDx0jWi4EETD76/pIbxpcLYg/mskfqXR4QDlwygIba1Agae0tRctVVoul
 ASpLj14Cdf0yu7W7u4709or0VviQOPt768JyOJV1yby2btSmXpkBrJa3lSpu6VRtzbk3A08msb
 H8mxZwYfMFMf37Km4y7SkmQArlz4i/OPjgD8Y2zjBsjEaHllQL3i4/j+AJQCLxyNAEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795083209; l=3925;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=XHnHiRFW/cpvMx3MDiecpOA+CTWKmRfU9ZlUEb77ms8=;
 b=UL3C/etXCyjfdrK/JlXgcrfA53b2Qv/EwDLNiV8ZHb+DYG9fF2Y18bClwzunZwiSRhUjRAlGn
 urnyrkfixO5AXihSn7YDc3hrI+WI1yoGgMmfd/FAcLjoYKVvQfh9ymY
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Ambarella CV75 SoC and EVK support: the board binding, the
RCT clock binding and driver, ARCH_AMBARELLA, the devicetree and
MAINTAINERS.

Apply the patches in this order:

1. board binding
2. RCT clock binding and clock ID header
3. ARCH_AMBARELLA
4. RCT clock driver
5. CV75 SoC and EVK device tree, plus defconfig
6. MAINTAINERS

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
Changes in v12:
- Split ARCH_AMBARELLA out of the EVK DT patch into its own patch,
  right after the two dt-bindings, so an immutable branch can carry
  the bindings and this symbol. The CV75 device tree and defconfig
  stay a separate patch. (Brian)
- Link to v11:
  https://patch.msgid.link/20261105-cv75-soc-v11-0-aa6ee0b2380d@ambarella.com

Changes in v11:
- clk: use builtin_platform_driver(). The Kconfig symbol is bool. (Brian)
- clk: drop CLK_IS_CRITICAL from the core PLL. It has no enable op. (Brian)
- clk: drop the misleading (u64) cast in the div_u64() call. (Brian)
- clk: add .suppress_bind_attrs = true to block sysfs unbind. (Brian)
- clk: drop MODULE_AUTHOR. (Brian)
- Link to v10:
  https://patch.msgid.link/20261019-cv75-soc-v10-0-d386065e2dd5@ambarella.com

---
Long Zhao (6):
      dt-bindings: arm: add Ambarella CV75 platforms
      dt-bindings: clock: add Ambarella CV75 RCT
      arm64: add ARCH_AMBARELLA
      clk: ambarella: add CV75 RCT clock controller
      arm64: dts: ambarella: add CV75 SoC and EVK
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

