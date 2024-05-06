From: Nikita Shubin <nikita.shubin@maquefel.me>
Subject: [PATCH RESEND v2 0/4] DONOTMERGE: ep93xx-clk from ep93xx device
 tree conversion
Date: Mon, 06 May 2024 12:49:47 +0300
Message-Id: <20240408-ep93xx-clk-v2-0-adcd68c13753@maquefel.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, Nikita Shubin <nikita.shubin@maquefel.me>, 
 Arnd Bergmann <arnd@arndb.de>, Linus Walleij <linus.walleij@linaro.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714988988; l=2237;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=LZLJVc9pYCHgTinDxt8jQL+ros/h+Mn8XlRPuxpUeDk=;
 b=9/KPOFB2kj4JSUtGN0bBC7dHnMlQlJqzK/pDgy7CTZDdR9V+cRVzCJkONlJD5eMoVdbmyTREbuZ5
 hV34J+NzD4cLl+KcCoX+Qx5xMqmQxA3uexviasO3qQ1DhWvc8BmM
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The goal is to recieve ACKs.

This is a fraction of v9 "ep93xx device tree conversion" series:

https://lore.kernel.org/all/20240326-ep93xx-v9-0-156e2ae5dfc8@maquefel.me/

The clk driver for ep93xx was converted to AUX device, as suggested
originally by Stephen Boyd.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
Changes in v2:
- soc: Add SoC driver for Cirrus ep93xx:
  - added __init for ep93xx_adev_alloc(), ep93xx_controller_register()
  - added static, __initconst for pinctrl_names[]
  - clk revision for SPI is now resolved here through differently named
    clk device
  - more verbose Kconfig description

  NOTE: "of" includes are required unfortunately.

- clk: ep93xx: add DT support for Cirrus EP93xx:
  - dropped includes
  - dropped ep93xx_soc_table[]
  - add different named clk and dropped involved includes
  - moved pll's and fclk, hclk, pclk init to separate function
  - fixed ep93xx_clk_ids[] explicit lines

  NOTE: clk_hw_register_div() is clk-ep9xx internal function which uses
  devm.

---
Nikita Shubin (4):
      ARM: ep93xx: add regmap aux_dev
      clk: ep93xx: add DT support for Cirrus EP93xx
      dt-bindings: soc: Add Cirrus EP93xx
      soc: Add SoC driver for Cirrus ep93xx

 .../bindings/arm/cirrus/cirrus,ep9301.yaml         |  38 +
 .../bindings/soc/cirrus/cirrus,ep9301-syscon.yaml  |  94 +++
 drivers/clk/Kconfig                                |   8 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/clk-ep93xx.c                           | 834 +++++++++++++++++++++
 drivers/soc/Kconfig                                |   1 +
 drivers/soc/Makefile                               |   1 +
 drivers/soc/cirrus/Kconfig                         |  17 +
 drivers/soc/cirrus/Makefile                        |   2 +
 drivers/soc/cirrus/soc-ep93xx.c                    | 252 +++++++
 include/dt-bindings/clock/cirrus,ep9301-syscon.h   |  46 ++
 include/linux/soc/cirrus/ep93xx.h                  |  26 +
 12 files changed, 1320 insertions(+)
---
base-commit: fec50db7033ea478773b159e0e2efb135270e3b7
change-id: 20240408-ep93xx-clk-657a1357de67

Best regards,
-- 
Nikita Shubin <nikita.shubin@maquefel.me>

