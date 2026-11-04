From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH 0/2] gpio: Add the Siflower SF19A2890 GPIO controller
Date: Wed, 04 Nov 2026 02:21:36 -0500
Message-Id: <20261104-sf19a2890-gpio-v1-0-45e463c48728@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAADd6moC/y2NSwqEQAwFryJZ29AJKK1XGVz4SWtcqNPRYUC8u
 +1nWVCv3g7KQVihTHYI/BOVeYqAaQLtUE89G+kiA1nKES0Z9VjU5Apr+kVm0xBmOXFG3jmIoyW
 wl/8d/FQP69aM3K5X5TUCf7f4tL7acZxdaPaahwAAAA==
X-Change-ID: 20261102-sf19a2890-gpio-b21562e52f88
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Chuanhong Guo <gch981213@gmail.com>, Qingfang Deng <dqfext@gmail.com>, 
 linux-mips@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>, 
 Qingfang Deng <qingfang.deng@siflower.com.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776902; l=1928;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=DORYErdHGchoiOCLr4jUC4YJ5kRuJgSmscAj0YZ7YTQ=;
 b=ut+omEVSXoOq04YQqveTnUO8PT5gudYW27P/e3DiiOtE1V4TB1TvYNHNBFsF627trY8fLg/3k
 z9cSVusBs72Dhwcq0McAo7x3l1hNc9dc9njUDXYHr0ZqgCkba3E1K2P
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a binding and a driver for the GPIO controller of the
Siflower SoCs, starting with the SF19A2890, a MIPS SoC for home routers.
Each line has a register block of its own, and each group of 16 lines an
interrupt.

The binding is Chuanhong Guo's and the driver Qingfang Deng's, both from
Chuanhong's SF19A2890 branch [1], with my changes noted in each. The
same controller is in Siflower's SF21 RISC-V SoCs; the binding has only
the SF19A2890's compatible, the one I can test.

The SoC support itself (MACH_SIFLOWER_MIPS) goes through the MIPS tree;
until then the driver builds with COMPILE_TEST.

The MAINTAINERS entry that covers these files comes with the MIPS series
"MIPS: Add support for the Siflower SF19A2890"; this series applies on
its own. That entry is also why checkpatch's question about updating
MAINTAINERS for the new files is left unanswered here.

Tested on a GL.iNet GL-SFT1200: gpio-keys sees both buttons on both
edges (the reset button on GPIO 27 as KEY_RESTART, the mode slide switch
on GPIO 1 as BTN_0, 1 and 0 per slide); /sys/kernel/debug/gpio lists the
49 lines; the GSW150 switch comes out of reset through GPIO 0 and the
SPI NAND uses GPIO 8 as its chip select.

[1] https://github.com/981213/linux/commits/siflower-7.1

---
Chuanhong Guo (1):
      dt-bindings: gpio: Add Siflower SF19A2890 GPIO controller

Qingfang Deng (1):
      gpio: Add Siflower GPIO controller driver

 .../bindings/gpio/siflower,sf19a2890-gpio.yaml     |  84 ++++++
 drivers/gpio/Kconfig                               |  11 +
 drivers/gpio/Makefile                              |   1 +
 drivers/gpio/gpio-siflower.c                       | 325 +++++++++++++++++++++
 4 files changed, 421 insertions(+)
---
base-commit: d66b6b86d5a6278ca930112c634d03725beb7d9a
change-id: 20261102-sf19a2890-gpio-b21562e52f88

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

