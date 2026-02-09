From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 00/13] clk: amlogic: Introduce A9 PLL and CCU driver
 support
Date: Mon, 09 Feb 2026 13:48:46 +0800
Message-Id: <20260209-a9_clock_driver-v1-0-a9198dc03d2a@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD51iWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQ2MD3UTL+OSc/OTs+JSizLLUIt2UlBRLA2NTcwsTi2QloK6CotS0zAq
 widGxtbUA4Ft7hWEAAAA=
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770616142; l=3749;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=ebLbpj1aW+Kz/xR5J14ie4MaN19ZepOR5F1hDJBpNPo=;
 b=lzoDOte3b+xv8Lht85pzHNT4bc9SCKzSJHu3j0g+C54rxft4OKN9wVoNSGsq/aF0aeGhuWILt
 HJSKa4eJLVkAudSDfO5EnhD0iLLehuVlS/aMg3Z+WdGdcWiSCsCcqap
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds driver support for Phase-Locked Loop (PLL) controllers
and Clock Control Units (CCUs) in A9 SoC family.

In the A9 SoC architecture, PLLs and clock control units are implemented
as standardized hardware instances to reduce unnecessary differentiation
across individual units.

All A9 PLLs and CCUs are exposed as device tree nodes, providing an
accurate representation of the SoC's internal clock hardware structure.

These drivers are designed for reuse in subsequent SoC generations,
guaranteeing code inheritance and maximizing reusability.

Makefile rules compile A9 PLL and CCU drivers into clk-amlogic.o (see
drivers/clk/amlogic/Makefile), simplifying deployment and enhancing load
efficiency (single insmod for kernel module).

Since the foundational A9 DTS hasn't been upstreamed yet, I'm temporarily
pushing the PLL/CCU DTS files to github for driver comprehension [1].
These patches will be included in a later release after the base A9 DTS
is merged.

[1] https://github.com/torvalds/linux/commit/d6a82e4cce675fa5146c5f638c2a926c1c8cb1d9

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (13):
      dt-bindings: clock: Add Amlogic A9 standardized model clock control units
      dt-bindings: clock: Add Amlogic A9 PLL controllers
      dt-bindings: clock: Add Amlogic A9 misc clock control units
      clk: amlogic: Add basic clock driver
      clk: amlogic: Add composite clock driver
      clk: amlogic: Add noglitch clock driver
      clk: amlogic: Add duandiv clock driver
      clk: amlogic: Add PLL driver
      clk: amlogic: Add DT-based clock registration functions
      clk: amlogic: Add A9 standardized model clock control units driver
      clk: amlogic: Add A9 PLL controllers driver
      clk: amlogic: Add A9 misc clock control units driver
      clk: amlogic: Add support for building as combined kernel module

 .../bindings/clock/amlogic,a9-misc-ccu.yaml        | 523 +++++++++++
 .../bindings/clock/amlogic,a9-model-ccu.yaml       | 435 +++++++++
 .../devicetree/bindings/clock/amlogic,a9-pll.yaml  | 134 +++
 drivers/clk/Kconfig                                |   1 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/amlogic/Kconfig                        |  52 ++
 drivers/clk/amlogic/Makefile                       |  23 +
 drivers/clk/amlogic/a9-misc-ccu.c                  | 970 +++++++++++++++++++++
 drivers/clk/amlogic/a9-model-ccu.c                 | 475 ++++++++++
 drivers/clk/amlogic/a9-pll.c                       | 156 ++++
 drivers/clk/amlogic/clk-basic.c                    | 219 +++++
 drivers/clk/amlogic/clk-basic.h                    |  39 +
 drivers/clk/amlogic/clk-composite.c                | 280 ++++++
 drivers/clk/amlogic/clk-composite.h                |  20 +
 drivers/clk/amlogic/clk-dualdiv.c                  | 365 ++++++++
 drivers/clk/amlogic/clk-dualdiv.h                  |  27 +
 drivers/clk/amlogic/clk-module.c                   |  42 +
 drivers/clk/amlogic/clk-module.h                   |  53 ++
 drivers/clk/amlogic/clk-noglitch.c                 | 584 +++++++++++++
 drivers/clk/amlogic/clk-noglitch.h                 |  29 +
 drivers/clk/amlogic/clk-pll.c                      | 701 +++++++++++++++
 drivers/clk/amlogic/clk-pll.h                      |  43 +
 drivers/clk/amlogic/clk.c                          | 464 ++++++++++
 drivers/clk/amlogic/clk.h                          |  56 ++
 include/dt-bindings/clock/amlogic,a9-misc-ccu.h    |  53 ++
 25 files changed, 5745 insertions(+)
---
base-commit: 4d310797262f0ddf129e76c2aad2b950adaf1fda
change-id: 20260130-a9_clock_driver-ddd90357848c

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

