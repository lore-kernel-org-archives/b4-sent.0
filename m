From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] support for amlogic the new SPI IP
Date: Wed, 04 Jun 2025 15:40:50 +0800
Message-Id: <20250604-spisg-v1-0-5893dbe9d953@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIL4P2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDMwNj3eKCzOJ0XXOLNCNDMwuj1KTEZCWg2oKi1LTMCrA50bG1tQCIsWq
 JVwAAAA==
To: Sunny Luo <sunny.luo@amlogic.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749022851; l=1058;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=pHr+iNzLv9GxJXJt/p1c4oLkaW7OLQQwQD2ifOprTdk=;
 b=zYbYWKMNv3d0lQCjOkN7LVwChi6psdws+UWgSlWO/xtLIY8JcHtqxIaHqmCGEcRkP5u6l4uxN
 mPd/KhjEPTcBNK2OHN9ffH7JR2kD8r/8Mo2jJr8HnFlCej2L0E4QD0C
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduced support for the new SPI IP (SPISG). The SPISG is
a communication-oriented SPI controller from Amlogic,supporting
three operation modes: PIO, block DMA, and scatter-gather DMA.

Add the drivers and device tree bindings corresponding to the SPISG.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Sunny Luo (2):
      dt-bindings: spi: Add binding document of Amlogic SPISG controller
      spi: Add Amlogic SPISG driver

Xianwei Zhao (1):
      MAINTAINERS: Add an entry for Amlogic spi driver

 .../devicetree/bindings/spi/amlogic,a4-spisg.yaml  |  55 ++
 MAINTAINERS                                        |   9 +
 drivers/spi/Kconfig                                |   9 +
 drivers/spi/Makefile                               |   1 +
 drivers/spi/spi-amlogic-spisg.c                    | 944 +++++++++++++++++++++
 5 files changed, 1018 insertions(+)
---
base-commit: 57cf46cd1fe351846e1b065ca9546eef66675ecd
change-id: 20250603-spisg-78f21682ebac

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

