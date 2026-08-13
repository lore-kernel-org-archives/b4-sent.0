From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH v3 0/6] Ambarella CV75: bindings, RCT clocks, and DT
Date: Thu, 13 Aug 2026 17:56:11 +0800
Message-Id: <20260813-cv75-v3-a-v3-0-cfdd20b1b4dd@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALuUfWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0Mj3eQyc1PdMmPdRN1kE0tDI8PE5ETLRCMloPqCotS0zAqwWdGxEH5
 xaVJWanIJyACl2loAMuV2+W0AAAA=
X-Change-ID: 20260812-cv75-v3-a-c49121aca9a2
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 soc@lists.linux.dev, Long Zhao <longzhao@ambarella.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786615029; l=2927;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=vZIoz8SRkvQelWw7HwQIV7pR02ZXIQjeTCwUQyR2gNw=;
 b=drpF2zlFCoa1mKfCLbPwXAsC2fQwzR+XcHfjZ0z6pqsAg9IW60wutmdtUY2YSmDLTeU1Vdyh5
 emo06DBL8wMBYmj5eZBI+KZxWLvyrDhRLmQhDj69okgFoMmvLC0fYLg
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is part A of a 3-part CV75 v3 split:

  A: bindings + RCT/CCU clocks + SoC/EVK DT + MAINTAINERS  (this series)
  B: pinctrl + PL061 GPIO variant
  C: 8250_dw UART quirks

B depends on A; C depends on A+B. B and C follow as separate threads.

Link to v2:
https://lore.kernel.org/r/20260806-longzhao-upstream-cv75-v2-v2-0-6b09707c5fe9@ambarella.com

Summary:
- arm / syscon / clock bindings and CV75 RCT CCU driver
- minimal CV75 SoC + EVK DT (UART0, clocks)
- MAINTAINERS entry for Ambarella

Changes since v2 (A scope):
- scratchpad as generic syscon (Krzysztof)
- RCT as dedicated clock-controller binding/header (Krzysztof)
- DT nodes under /soc with unit-address ordering (Krzysztof/Rob)
- clk robustness: div_u64 and mux/div + PLL edge cases (internal review)

Verified on CV75 with A+B+C (boot, UART, clk_summary).

Signed-off-by: Long Zhao <longzhao@ambarella.com>

---
Long Zhao (6):
      dt-bindings: arm: add Ambarella CV75 platforms
      dt-bindings: mfd: syscon: add Ambarella CV75 secure scratchpad
      dt-bindings: clock: add Ambarella CV75 RCT
      clk: ambarella: add CV75 CCU driver
      arm64: ambarella: add ARCH_AMBARELLA and CV75 EVK DT
      MAINTAINERS: add ARM/AMBARELLA SoC support

 .../devicetree/bindings/arm/ambarella.yaml         |  24 ++
 .../bindings/clock/ambarella,cv75-rct.yaml         |  58 ++++
 Documentation/devicetree/bindings/mfd/syscon.yaml  |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |  14 +
 arch/arm64/Kconfig.platforms                       |   9 +
 arch/arm64/boot/dts/Makefile                       |   1 +
 arch/arm64/boot/dts/ambarella/Makefile             |   3 +
 arch/arm64/boot/dts/ambarella/cv75-evk.dts         |  30 ++
 arch/arm64/boot/dts/ambarella/cv75.dtsi            | 178 ++++++++++
 arch/arm64/configs/defconfig                       |   1 +
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/ambarella/Kconfig                      |  13 +
 drivers/clk/ambarella/Makefile                     |   6 +
 drivers/clk/ambarella/ccu-cv75.c                   | 296 ++++++++++++++++
 drivers/clk/ambarella/ccu_common.c                 |  60 ++++
 drivers/clk/ambarella/ccu_common.h                 |  25 ++
 drivers/clk/ambarella/ccu_mux_div.c                | 231 +++++++++++++
 drivers/clk/ambarella/ccu_mux_div.h                |  35 ++
 drivers/clk/ambarella/ccu_pll.c                    | 378 +++++++++++++++++++++
 drivers/clk/ambarella/ccu_pll.h                    |  70 ++++
 include/dt-bindings/clock/ambarella,cv75-rct.h     |  15 +
 23 files changed, 1452 insertions(+)
---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20260812-cv75-v3-a-c49121aca9a2

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

