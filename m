From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RFC v2 0/5] clk: hisilicon: add support for Hi3798MV200
Date: Sat, 17 Feb 2024 20:52:05 +0800
Message-Id: <20240217-clk-mv200-v2-0-b782e4eb66f7@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPWr0GUC/22MywrCMBBFf6XM2kgylWBcCQU/wK10EcbRhj4iS
 Q1Kyb8bsnZ57j2cDSIHxxFOzQaBk4vOLwVw1wANdnmycPfCgBIPEpUWNI1iTiilIDqS5dZoZgn
 FfwV+uE9t3eB66aAv4+Di6sO39pOq159UUkIKi8YSo2Hd6rN/r5P34578DH3O+QeVpxlfqQAAA
 A==
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708174332; l=2029;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=26asYT9Pch/6BET0RjGLiuk5j1AaaNkgzH3IDcRoKJQ=;
 b=nAb9AVMdHX/f2z6emI9t8+7+o1w6aec07MJGqfIwL1KkyGN24rLI+xipHXWAwSujd6wAkehaT
 LmxTY8U6EHqAw16+re/9sQioCZs9wNFOYgI4J4DnapxnjZuWOEZIpl8
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This SoC is similar to Hi3798CV200 with a few more clocks in CRG module.

Note this driver is still ongoing, many clocks are not registered in the
driver now. Feedback is welcomed, especially from HiSilicon people.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- s/dt-binding/dt-bindings in commit logs: (Krzysztof Kozlowski)
- fix bot error by adding "hisilicon,hisi-sdmmc-dll" to syscon.yaml (Rob
  Herring)
- hi3798mv200-crg: assign fixed rate parents to some gates
- hi3798mv200-crg: s/ETH/FEMAC, add GMAC ctrl clock
- Link to v1: https://lore.kernel.org/r/20240216-clk-mv200-v1-0-a29ace29e636@outlook.com

---
Yang Xiwen (5):
      dt-bindings: clock: histb-clock: Add missing common clock and Hi3798MV200 specific clock definition
      clk: hisilicon: add CRG driver for Hi3798MV200 SoC
      dt-bindings: clock: merge all hisilicon clock bindings to hisilicon,clock-reset-generator
      dt-bindings: mfd: syscon: Add hisilicon,sdmmc-sap-dll compatible
      dt-bindings: clock: hisilicon,clock-reset-controller: add Hi3798MV200 SoC support

 .../devicetree/bindings/clock/hi3660-clock.txt     |  47 ---
 .../devicetree/bindings/clock/hi3670-clock.txt     |  43 --
 .../devicetree/bindings/clock/hi6220-clock.txt     |  52 ---
 .../devicetree/bindings/clock/hisi-crg.txt         |  50 ---
 .../clock/hisilicon,clock-reset-generator.yaml     | 175 +++++++++
 .../clock/hisilicon,hi3559av100-clock.yaml         |  59 ---
 Documentation/devicetree/bindings/mfd/syscon.yaml  |   1 +
 drivers/clk/hisilicon/Kconfig                      |   8 +
 drivers/clk/hisilicon/Makefile                     |   1 +
 drivers/clk/hisilicon/crg-hi3798mv200.c            | 436 +++++++++++++++++++++
 include/dt-bindings/clock/histb-clock.h            |  21 +
 11 files changed, 642 insertions(+), 251 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240216-clk-mv200-cc8cae396ee0

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

