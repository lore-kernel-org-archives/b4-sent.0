From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH v3 0/3] Ambarella CV75: pinctrl and PL061 GPIO
Date: Thu, 13 Aug 2026 18:19:35 +0800
Message-Id: <20260813-cv75-v3-b-v3-0-1d82e18da09b@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADiafWoC/yXMQQ5AMBBA0avIrE1CJ0pcRSy0BmOBtDQScXfF8
 iU//wLPTthDnVzgOIiXdYmgNAE7dcvIKH00qEzprMoJbSgLDIQGq0LlWlNHWjHEfnM8yPm9mva
 3P8zMdn8HcN8PipT8HG0AAAA=
X-Change-ID: 20260813-cv75-v3-b-8521663a362e
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786616380; l=1753;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=SJDE1Y6wyBQ85Y66UA/dDM+xt1Anlk6x3sBOuqBhgZU=;
 b=7wMvdXyZV5AuuFfYWy35sAWu8p8pkJOi8yy9vOlUwmaSxl+eTcRezkGRSI91D4KoReHb5Hd/s
 Yk4w3TsxwQnCXpY+avWuyCTi1JdsMGpIFPBU8ryO9QYyUJgNPswJstu
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is part B of a 3-part CV75 v3 split:

  A: bindings + RCT/CCU clocks + SoC/EVK DT + MAINTAINERS
  B: pinctrl + PL061 GPIO variant  (this series)
  C: 8250_dw UART quirks

Depends on series A:
https://lore.kernel.org/r/20260813-cv75-v3-a-v3-0-cfdd20b1b4dd@ambarella.com

Link to v2:
https://lore.kernel.org/r/20260806-longzhao-upstream-cv75-v2-v2-0-6b09707c5fe9@ambarella.com

Summary:
- CV75 pinctrl binding and driver
- Ambarella register-layout variant for gpio-pl061

Changes since v2 (B scope):
- reuse PL061 with Ambarella register-layout variant (Linus)
- model each GPIO bank as a separate DT/AMBA primecell node (Linus)
- complete function/groups enums in the pinctrl binding (Krzysztof)

Verified on CV75 with A+B+C.

Signed-off-by: Long Zhao <longzhao@ambarella.com>

---
Long Zhao (3):
      dt-bindings: pinctrl: add Ambarella CV75 pinctrl
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
change-id: 20260813-cv75-v3-b-8521663a362e

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

