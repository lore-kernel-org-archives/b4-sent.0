From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH 00/12] New features for the AD5686 IIO driver
Date: Tue, 02 Jun 2026 17:33:47 +0100
Message-Id: <20260602-ad5686-new-features-v1-0-691e01883d27@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOsFH2oC/x3MQQqDMBBG4avIrB1Igg7qVcRFNL/tbNKSqC2Id
 ze4/BbvnZSRFJmG6qSEQ7N+YoGtK1rePr7AGorJGSdGjGMfWumEI368wm97QmZYK4tp5hDmnkr
 5TVj1/1zH6bpuO9vkBWUAAAA=
X-Change-ID: 20260602-ad5686-new-features-e116c04bddb9
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780418030; l=2210;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=dcsHKAoQP64Fz4xl/KKbSuqrRQCZoXXSHYxQq69uwEQ=;
 b=YQcJxhCXAdZjqbq0PTcmgbJdHmJnFTw39NM1lD/TLpGichFY1mMwDrXvtgKJ2VlDpv4FCv3Jf
 i7Dl/EGxMwjDyAXWpJpZHuXkvGyqfUarsn9FKHyCzvbc+foBztTPR+T
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the second series of three on updating the AD5686 driver.

Initially, a big patch series was sent:
https://lore.kernel.org/r/20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com

Then, the first patch series added fixes and cleanups:
https://lore.kernel.org/linux-iio/20260524-ad5686-fixes-v7-0-b6bf395d08bd@analog.com/

This one is introducing new features:
- Consume optional reset and correct power supplies;
- LDAC GPIO handling (active-low, held low when unused);
- SPI bus sync() implementation for batching multiple transfers;
- Triggered buffer support, leveraging LDAC and sync() to flush
  all channel writes atomically;
- Gain control support through the scale property.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Rodrigo Alencar (12):
      dt-bindings: iio: dac: ad5696: add reset/ldac/gain gpio support
      dt-bindings: iio: dac: ad5696: rework on power supplies
      dt-bindings: iio: dac: ad5686: add reset/ldac/gain gpio support
      dt-bindings: iio: dac: ad5686: rework on power supplies
      iio: dac: ad5686: add support for missing power supplies
      iio: dac: ad5686: consume optional reset signal
      iio: dac: ad5686: add ldac gpio
      iio: dac: ad5686: introduce sync operation
      iio: dac: ad5686: implement new sync() op for the spi bus
      iio: dac: ad5686: add triggered buffer support
      iio: dac: ad5686: write_raw: use guard(mutex)()
      iio: dac: ad5686: add gain control support

 .../devicetree/bindings/iio/dac/adi,ad5686.yaml    |  62 +++++-
 .../devicetree/bindings/iio/dac/adi,ad5696.yaml    |  65 ++++++-
 drivers/iio/dac/Kconfig                            |   2 +
 drivers/iio/dac/ad5686-spi.c                       | 109 ++++++++---
 drivers/iio/dac/ad5686.c                           | 212 +++++++++++++++++++--
 drivers/iio/dac/ad5686.h                           |  29 ++-
 drivers/iio/dac/ad5696-i2c.c                       |   2 +-
 7 files changed, 422 insertions(+), 59 deletions(-)
---
base-commit: 3dee3cddb9b2f78447bf1077f3eb8ae0b8251247
change-id: 20260602-ad5686-new-features-e116c04bddb9

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

