From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v4 0/7] clk: hisilicon: add support for Hi3798MV200
Date: Fri, 23 Feb 2024 03:40:10 +0800
Message-Id: <20240223-clk-mv200-v4-0-3e37e501d407@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABqj12UC/23MTQ6CMBCG4auQrq0ZplDAlfcwLkodpOGnpsVGQ
 7i7hRVGl99knndmnpwhz07JzBwF440d48gOCdOtGu/EzS1uhoAZYCq57js+BATgWpdakagkEbD
 4/3DUmNfWulzjbo2frHtv6ZCu13+VkHLgCiulCSuSQp7tc+qt7Y7aDmztBNzbYm8x2rookTKqp
 WyKXyt2FnFvRbSNgKLK6xxEWn7bZVk+buBEsBwBAAA=
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708630834; l=3178;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=aEJwhXImnZlG7CDsaIYX4SI0jp1bWvk6d41It98Jybs=;
 b=YqA4nNJSTfz8MeqQJgmJun8HZaAauoycAGFJWjwwixURnZVnFlg2+MRVianFBm/fcLTPkf6lp
 HbcUiBhCC9pCi8cLOgmwKIH80zVuMFLF365iowbQg2Upp7eAls+Rzn4
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This SoC is similar to Hi3798CV200 with a few more clocks in CRG module.

Note this driver is still ongoing, many clocks are not registered in the
driver now. Feedback is welcomed, especially from HiSilicon people.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v4:
- dt-bindings: hisi-crg: add reg and #reset-cells to required, add reset-controller to required for cv200
- dt-bindings: hisi-crg: do not add "simple-mfd" and "syscon" for hi3519 (Krzysztof Kozlowski)
- dt-bindings: hi3798mv200: replace spaces with tabs (Krzysztof Kozlowski)
- dt-bindings: s/DTS/DT_BINDINGS_CLOCK (Krzysztof Kozlowski)
- Link to v3: https://lore.kernel.org/r/20240222-clk-mv200-v3-0-f30795b50318@outlook.com

Changes in v3:
- remove RFC (Krzysztof Kozlowski)
- rearrange patches so dt-binding comes before drivers (Krzysztof Kozlowski)
- dt-bindings: Remove lots of properties
- dt-bindings: stop merging all hisi-clock bindings, only convert hisi-crg.txt for now.
- dt-bindings: remove hisilicon,hisi-sdmmc-dll subnode (Rob Herring, Krzysztof Kozlowski)
- split histb-clock.h into two files, deprecate this header file
- fix all users (hi3798cv200.dtsi and hi3798cv200 CRG driver)
- hi3798mv200-crg: add a few missing clocks
- Link to v2: https://lore.kernel.org/r/20240217-clk-mv200-v2-0-b782e4eb66f7@outlook.com

Changes in v2:
- s/dt-binding/dt-bindings in commit logs: (Krzysztof Kozlowski)
- fix bot error by adding "hisilicon,hisi-sdmmc-dll" to syscon.yaml (Rob Herring)
- hi3798mv200-crg: assign fixed rate parents to some gates
- hi3798mv200-crg: s/ETH/FEMAC, add GMAC ctrl clock
- Link to v1: https://lore.kernel.org/r/20240216-clk-mv200-v1-0-a29ace29e636@outlook.com

---
Yang Xiwen (7):
      dt-bindings: clock: convert hisi-crg.txt to YAML
      dt-bindings: clock: histb-clock: split into two header files
      arm64: dts: hisilicon: fix include path
      clk: hisilicon: fix include path for crg-hi3798cv200
      dt-bindings: clock: hisilicon,clock-reset-controller: add Hi3798MV200 SoC
      dt-bindings: clock: hisilicon: add clock definitions for Hi3798MV200
      clk: hisilicon: add CRG driver for Hi3798MV200 SoC

 .../devicetree/bindings/clock/hisi-crg.txt         |  50 ---
 .../bindings/clock/hisilicon,hisi-crg.yaml         |  76 ++++
 arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi     |   3 +-
 drivers/clk/hisilicon/Kconfig                      |   8 +
 drivers/clk/hisilicon/Makefile                     |   1 +
 drivers/clk/hisilicon/crg-hi3798cv200.c            |   3 +-
 drivers/clk/hisilicon/crg-hi3798mv200.c            | 462 +++++++++++++++++++++
 .../dt-bindings/clock/hisilicon,hi3798cv200-crg.h  |  62 +++
 .../clock/hisilicon,hi3798cv200-sysctrl.h          |  17 +
 .../dt-bindings/clock/hisilicon,hi3798mv200-crg.h  | 150 +++++++
 .../clock/hisilicon,hi3798mv200-sysctrl.h          |  21 +
 include/dt-bindings/clock/histb-clock.h            |  70 +---
 12 files changed, 810 insertions(+), 113 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240216-clk-mv200-cc8cae396ee0

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

