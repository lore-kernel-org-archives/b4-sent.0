From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] support for Amlogic SPI Flash Controller IP
Date: Fri, 08 Aug 2025 10:00:33 +0800
Message-Id: <20250808-spifc-v1-0-ff4e30e26a6b@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEFalWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCwMT3eKCzLRkXVNzM8NUY9O0pFTDNCWg2oKi1LTMCrA50bG1tQBFzYk
 0VwAAAA==
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liang Yang <liang.yang@amlogic.com>, 
 Feng Chen <feng.chen@amlogic.com>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754618434; l=1178;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=Q9TvXkCZZFK5X+atV+OgJiaaH15TABP2XLM2/bN3sx4=;
 b=0P/Gz33Pfi1wslGAfGII4PqKRTTYGefeUIhLu62F6trfQX8GwyFjb3ZT1BSiGIS4QiVjJ6FFb
 1eXhkxn4fdWDMSRI5/MsRJG9DnEXScg1SETR5SvYmi7hzyOyDZo3wHl
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This Flash Controller is derived by adding an SPI path to the original
raw NAND controller. This controller supports two modes: raw mode and
SPI mode. The raw mode has already been implemented in the community
(drivers/mtd/nand/raw/meson_nand.c).
This submission supports the SPI mode.

Add the drivers and bindings corresponding to the SPI Flash Controller.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Feng Chen (2):
      spi: dt-bindings: add doc for Amlogic A113L2 SFC
      spi: amlogic: add driver for Amlogic SPI Flash Controller

Xianwei Zhao (1):
      MAINTAINERS: Add an entry for Amlogic spifc driver

 .../devicetree/bindings/spi/amlogic,a4-spifc.yaml  |  104 ++
 MAINTAINERS                                        |   10 +
 drivers/spi/Kconfig                                |   10 +
 drivers/spi/Makefile                               |    1 +
 drivers/spi/spi-amlogic-spifc-a4.c                 | 1328 ++++++++++++++++++++
 5 files changed, 1453 insertions(+)
---
base-commit: 60fcf916e06250108143a993bd803c6b12ad8d02
change-id: 20250804-spifc-5761e35fbe1f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

