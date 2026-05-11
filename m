From: Jian Hu <jian.hu@amlogic.com>
Subject: [PATCH 00/10] Add support for A9 family clock controller
Date: Mon, 11 May 2026 20:47:22 +0800
Message-Id: <20260511-b4-a9_clk-v1-0-41cb4071b7c9@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANvPAWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDU0ND3SQT3UTL+OScbF0zczNTo2TDxFRTs1QloPqCotS0zAqwWdGxtbU
 AQ6L9iVsAAAA=
X-Change-ID: 20260511-b4-a9_clk-67652c1ae56e
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778503655; l=3503;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=d/bn89pQhI2eZfLETFYCMIW9bPsVZbUfOMIG98dS5ow=;
 b=LlCL2gW0AbGiMXgURqP5wwCamriSIUD5Er+NKhm9/SMSQrpiAR/13zXTQ2VlPl/eICNq37nPq
 5A9qDf5T7EmBFn5HX3ZqZb76Rgaz5RkDb4nFutBsWItSUe9zONYQfk9
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are 4 clock controllers in A9 SoC:
- SCMI clock controller: these clocks are managed by the
  Trusted Firmware-A(TF-A) and handled through SCMI.
- PLL clock controller.
- peripheral clock controller.
- AO clock controller.

There are reserved register regions placed between individual PLLs, so a
separate driver is implemented for each PLL, similar to T7.

Compared to previous SoCs PLLs, the A9 PLL controller introduces 4 new features:
1.PLL l_detect signal supports active-high configuration.
  Previous A7 and T7 l_detect signals are active-low.
2.PLL reset signal supports active-low configuration.
  Previous reset signals are active-high.
3.Support POWER_OF_TWO for the PLL pre-divider N;
  the N pre-divider follows the same calculation rule as OD.
4.The PLL input path includes an inherent divide-by-2 divider.

Implement the first three features in clk-pll.c (verified on A9 and T7),
with no impact to PLL logic on existing SoCs. Add a fixed divide-by-2 to
A9 PLL driver for the fourth feature.
 
A9 PLL is composed as follows:
 
                       PLL
          +---------------------------------+
          |                                 |
          |             +--+                |
   in/2 >>---[ /2^N ]-->|  |      +-----+   |
          |             |  |------| DCO |----->> out
          |  +--------->|  |      +--v--+   |
          |  |          +--+         |      |
          |  |                       |      |
          |  +--[ *(M + (F/Fmax) ]<--+      |
          |                                 |
          +---------------------------------+
 
  out = in / 2  * (m + frac / frac_max) / 2^n

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
Jian Hu (10):
      dt-bindings: clock: Add Amlogic A9 SCMI clock controller
      dt-bindings: clock: Add Amlogic A9 PLL clock controller
      dt-bindings: clock: Add Amlogic A9 peripherals clock controller
      dt-bindings: clock: Add Amlogic A9 AO clock controller
      clk: amlogic: PLL l_detect signal supports active-high configuration
      clk: amlogic: PLL reset signal supports active-low configuration
      clk: amlogic: Support POWER_OF_TWO for PLL pre-divider
      clk: amlogic: Add A9 PLL clock controller driver
      clk: amlogic: Add A9 peripherals clock controller driver
      clk: amlogic: Add A9 AO clock controller driver

 .../bindings/clock/amlogic,a9-aoclkc.yaml          |   76 +
 .../clock/amlogic,a9-peripherals-clkc.yaml         |  150 ++
 .../bindings/clock/amlogic,a9-pll-clkc.yaml        |  110 +
 drivers/clk/meson/Kconfig                          |   28 +
 drivers/clk/meson/Makefile                         |    2 +
 drivers/clk/meson/a9-aoclk.c                       |  494 +++++
 drivers/clk/meson/a9-peripherals.c                 | 2317 ++++++++++++++++++++
 drivers/clk/meson/a9-pll.c                         |  831 +++++++
 drivers/clk/meson/clk-pll.c                        |   79 +-
 drivers/clk/meson/clk-pll.h                        |    6 +
 include/dt-bindings/clock/amlogic,a9-aoclkc.h      |   76 +
 .../clock/amlogic,a9-peripherals-clkc.h            |  352 +++
 include/dt-bindings/clock/amlogic,a9-pll-clkc.h    |   55 +
 include/dt-bindings/clock/amlogic,a9-scmi-clkc.h   |   51 +
 14 files changed, 4609 insertions(+), 18 deletions(-)
---
base-commit: ca89c88bcf69daca829044c638a8163d5ce47af0
change-id: 20260511-b4-a9_clk-67652c1ae56e

Best regards,
-- 
Jian Hu <jian.hu@amlogic.com>

