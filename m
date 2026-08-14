From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH v4 0/4] Ambarella CV75: pinctrl and PL061 GPIO
Date: Fri, 14 Aug 2026 14:25:40 +0800
Message-Id: <20260814-cv75-v4-b-v4-0-ef2e83ec0eac@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOS0fmoC/yXMQQ5AMBBA0avIrE1SUjSuIhaMKWOBtDQScXfF8
 iU//wLPTthDnVzgOIiXdYnQaQI0dcvIKEM05Covlck0UqgKDBp7tDxoRYUhU1qI/ebYyvm9mva
 3P/qZaX8HcN8PrZkruG0AAAA=
X-Change-ID: 20260814-cv75-v4-b-fed40c58c86f
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786688763; l=1967;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=ksEsRtK1EuKSLayoctPBxaWWqqFtM9SYIX6VyZQVJqg=;
 b=lNb4uc4U78G3ALpbbxIU5sLX9QzDdu2+7huKuU4+wK7iDdIDUSBZB97DtGKOe3WYD3EhfRV20
 4W9sLQBYqj6BJY80ElTpLdj4hIR3K3HEy+BygtSx5JxhOqwNCl+p8gd
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is part B of a 3-part CV75 split:

  A: bindings + RCT/CCU clocks + SoC/EVK DT + MAINTAINERS
  B: pinctrl + PL061 GPIO variant  (this series)
  C: 8250_dw UART quirks

Depends on series A:
https://lore.kernel.org/r/20260813-cv75-v3-a-v3-0-cfdd20b1b4dd@ambarella.com

Link to v3:
https://lore.kernel.org/r/20260813-cv75-v3-b-v3-0-1d82e18da09b@ambarella.com

Link to v2:
https://lore.kernel.org/r/20260806-longzhao-upstream-cv75-v2-v2-0-6b09707c5fe9@ambarella.com

Summary:
- CV75 pinctrl binding and driver
- Ambarella register-layout variant for gpio-pl061
  (DT binding and driver in separate patches) 

Changes since v3:
- Split pl061 DT binding and driver into separate patches (Bartosz)

Changes since v2 (B scope):
- reuse PL061 instead of a duplicated GPIO implementation (Linus)
- complete function/groups enums in the binding (Krzysztof)

Verified on CV75 with A+B+C.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Long Zhao (4):
      dt-bindings: pinctrl: add Ambarella CV75 pinctrl
      dt-bindings: gpio: pl061: add Ambarella CV75 variant
      gpio: pl061: add Ambarella CV75 register layout variant
      pinctrl: ambarella: add CV75 pin controller

 .../devicetree/bindings/gpio/pl061-gpio.yaml       |  35 +-
 .../bindings/pinctrl/ambarella,cv75-pinctrl.yaml   | 240 ++++++
 drivers/gpio/gpio-pl061.c                          | 280 +++++--
 drivers/pinctrl/Kconfig                            |  13 +
 drivers/pinctrl/Makefile                           |   2 +
 drivers/pinctrl/pinctrl-ambarella-cv75.c           | 561 ++++++++++++++
 drivers/pinctrl/pinctrl-ambarella.c                | 839 +++++++++++++++++++++
 drivers/pinctrl/pinctrl-ambarella.h                |  50 ++
 8 files changed, 1949 insertions(+), 71 deletions(-)
---
base-commit: 18bf29fba8d0bdd0db5a0497ecf06f404bc740d1
change-id: 20260814-cv75-v4-b-fed40c58c86f

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

