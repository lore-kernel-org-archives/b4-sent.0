From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v3 0/8] clk: hisilicon: add support for Hi3798MV200
Date: Thu, 22 Feb 2024 00:41:03 +0800
Message-Id: <20240222-clk-mv200-v3-0-f30795b50318@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ8n1mUC/22Myw6CMBBFf4XM2poykAKu/A/jooyDNDxKWmw0h
 H+3sMLE5bm55yzg2Rn2cEkWcByMN3aMkJ0SoFaPTxbmERlQYi4xVYL6TgwBpRREJWnOKsUsIf4
 nx415763bPXJr/GzdZ0+HdFv/VUIqpNBYaWKsWGXqal9zb213JjvA1gl4dIuji9GtixI551qpp
 vh113X9AjQVmxTgAAAA
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708533664; l=2791;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=0Cd+VCIeTdBn+L0SAfWXHlwel79wcGcBBMfeVDyDkyU=;
 b=GjURGN5urv/SOzVTLvxeenBm0J574z/T6mXEfzBgt9GMgy5QkFcgmgwWcHZ0pk5+lS1QPTjRY
 6g2DfAVEib+Dmu7ccnTmqV1NQYq4fg76jdJq8XYIuppg8AGNU//mV1N
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This SoC is similar to Hi3798CV200 with a few more clocks in CRG module.

Note this driver is still ongoing, many clocks are not registered in the
driver now. Feedback is welcomed, especially from HiSilicon people.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
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
Yang Xiwen (8):
      dt-bindings: clock: convert hisi-crg.txt to YAML
      ARM: dts: hisilicon: add missing compatibles to CRG node
      dt-bindings: clock: histb-clock: split into two header files
      arm64: dts: hisilicon: fix include path
      clk: hisilicon: fix include path for crg-hi3798cv200
      dt-bindings: clock: hisilicon,clock-reset-controller: add Hi3798MV200 SoC
      dt-bindings: clock: hisilicon: add clock definitions for Hi3798MV200
      clk: hisilicon: add CRG driver for Hi3798MV200 SoC

 .../bindings/clock/hisilicon,hisi-crg.yaml         |  71 ++++
 arch/arm/boot/dts/hisilicon/hi3519.dtsi            |   2 +-
 arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi     |   3 +-
 drivers/clk/hisilicon/Kconfig                      |   8 +
 drivers/clk/hisilicon/Makefile                     |   1 +
 drivers/clk/hisilicon/crg-hi3798cv200.c            |   3 +-
 drivers/clk/hisilicon/crg-hi3798mv200.c            | 462 +++++++++++++++++++++
 .../dt-bindings/clock/hisilicon,hi3798cv200-crg.h  |  62 +++
 .../clock/hisilicon,hi3798cv200-sysctrl.h          |  17 +
 .../dt-bindings/clock/hisilicon,hi3798mv200-crg.h  | 150 +++++++
 .../clock/hisilicon,hi3798mv200-sysctrl.h          |  21 +
 include/dt-bindings/clock/histb-clock.h            |  73 +---
 12 files changed, 805 insertions(+), 68 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240216-clk-mv200-cc8cae396ee0

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

