From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v6 0/2] phy: add basic support for NXPs TJA1145 CAN
 transceiver
Date: Tue, 02 Jun 2026 10:25:36 +0200
Message-Id: <20260602-tja1145-support-v6-0-0e0ffc8ee63d@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAICTHmoC/23OzU7DMAzA8VeZciYoceJ8cOI90A5Z4tIgWKukV
 ENT35100gDRHv+W/LOvrFLJVNnT4coKzbnm4dzCPBxY7MP5lXhOrRkIQGHB8OktSKmR189xHMr
 Ek4kxRZ0gBcXa1lioy5eb+HJs3ec6DeXrdmCW6/RuuY01Sy44nZLTXifUGJ/fM516KuUxDh9s5
 Wb4JRz4LQGNMMJ72ylw3vodQv0QUki1JVQjdPAJNHYkjN0h9F8Ct4ReiaRikCo65+QOgXfCCNz
 7AhuhnAURLJFR9I9YluUbmXjhDb0BAAA=
X-Change-ID: 20250726-tja1145-support-d6ccdc4d2da3
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Conor Dooley <conor.dooley@microchip.com>, lee.lockhey@gmail.com, 
 Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780388746; l=2451;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=cHp3nkT0cfcBUKtkYPQ5ueVJrGW1JpdFjs6fxXYP9t8=;
 b=p1me/q6zUuMZYy17fczKcV6f2U8Y8qghF6aQalv6p3RC54NImHNf1nsAXn0PJRtX21EXJhhpH
 IknPafPwXvABnXb3ntP9Z0Qxxd/YYCTXP7un9KI3NOA79jhoFfyh3vS
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add basic driver support for NXPs TJA1145 CAN transceiver which brings the
PHY up/down by switching to normal/standby mode using SPI commands.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v6:
- Added interrupts to bindings and dt example.
- Link to v5: https://lore.kernel.org/r/20260513-tja1145-support-v5-0-38720a7ee63e@liebherr.com

Changes in v5:
- No functional change, basically a resend with added tags
- fixed typo in define TJA1145_MODE_CRTL_STBY to TJA1145_MODE_CTRL_STBY
  and TJA1145_MODE_CRTL_NORMAL to TJA1145_MODE_CTRL_NORMAL
- remove unneeded include -#include <linux/bitfield.h>
- added owner to tja1145_phy_ops
- Link to v4: https://lore.kernel.org/r/20251015-tja1145-support-v4-0-4d3ca13c8881@liebherr.com

Changes in v4:
- Change compatible to: nxp,tja1145 (Connor)
- Mark spi-cpha as required (Connor)
- Switch from unevaluatedProperties: false to
  additionalProperties: false (Connor)
- Remove double newline after tja1145_rd_table (Marc)
- Link to v3: https://lore.kernel.org/r/20251013-tja1145-support-v3-0-4a9d245fe067@liebherr.com

Changes in v3:
- bindings: fix SPI bus unit address format error
- bindings: added resolution of discussion into commit msg
- Checked binding with:
  make dt_binding_check DT_SCHEMA_FILES=nxp,tja1145-can.yaml
  Missed it for V2, didn't do it intentionally. Sorry.
- Link to v2: https://lore.kernel.org/r/20250829-tja1145-support-v2-0-60997f328979@liebherr.com

Changes in v2:
- bindings: Change node name in example to can-phy
- bindings: Fix order of properties, reg property is second
- bindings: Change compatible to match filename
- change compatible to nxp,tja1145-can
- Link to v1: https://lore.kernel.org/r/20250728-tja1145-support-v1-0-ebd8494d545c@liebherr.com

---
Dimitri Fedrau (2):
      dt-bindings: phy: add support for NXPs TJA1145 CAN transceiver
      phy: add basic support for NXPs TJA1145 CAN transceiver

 .../devicetree/bindings/phy/nxp,tja1145.yaml       |  86 ++++++++++
 drivers/phy/Kconfig                                |  10 ++
 drivers/phy/Makefile                               |   1 +
 drivers/phy/phy-nxp-tja1145.c                      | 184 +++++++++++++++++++++
 4 files changed, 281 insertions(+)
---
base-commit: 29b4d8a7637f027b538787896bee520f2dacc904
change-id: 20250726-tja1145-support-d6ccdc4d2da3

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

