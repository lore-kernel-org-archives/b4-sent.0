From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v2 0/6] iio: dac: ad5686: extend device support
Date: Fri, 24 Jul 2026 13:03:10 +0100
Message-Id: <20260724-ad5686-extend-dev-support-v2-0-cfc2b30ce988@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH5UY2oC/42NTQqDMBBGryKz7pSM1L+uvEdxETKjBtpEEhss4
 t2beoIu34PvfTtECVYi3IsdgiQbrXcZyksBZtZuErScGUpV1qqhDjVXdVujbKs4RpaE8b0sPqw
 oipmJupE6A3m/BBntdrYfQ+bZxtWHz3mV6Gf/qSZChe2NxDSVGStue+30009X418wHMfxBXNW6
 hXDAAAA
X-Change-ID: 20260719-ad5686-extend-dev-support-e0ddd119f19c
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784894592; l=2042;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=CTbIuLubVcHoeExFapsNndRTjAZljFGV9jMIvS0w30s=;
 b=c7Sy4WxvnTilIMzYY+6QhAK7JoyiNm4s++OKZB6sIc7NFnO9qfde1qx7x9MxH/0H+/llGlqKI
 636we/zs5L6A+1fcrxc07BoCaygSBTiAqXl1LrSdSWKyQfKlBnjDkdd
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the third series of three on updating the AD5686 driver.

Initially, a big patch series was sent:
https://lore.kernel.org/r/20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com

Then, the first patch series added fixes and cleanups:
https://lore.kernel.org/all/20260524-ad5686-fixes-v7-0-b6bf395d08bd@analog.com/

The second series introduced new features:
https://lore.kernel.org/all/20260716-ad5686-new-features-v8-0-ebb0051af5e5@analog.com/

This series adds support for:
- SPI: AD5313R, AD5317R, AD5674, AD5679, AD5687, AD5687R, AD5689, AD5689R;
- I2C: AD5316R, AD5675, AD5697R

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Changes in v2:
- Missing devices in I2C drivers as cleanup patches.
- Refactor of Kconfig device list as a cleanup patch.
- Link to v1: https://lore.kernel.org/r/20260719-ad5686-extend-dev-support-v1-0-841ec75cf5d8@analog.com

---
Rodrigo Alencar (6):
      dt-bindings: iio: dac: ad5696: add AD5673R/AD5677R support
      iio: dac: ad5696: add AD5673R/AD5677R entries to of_match table
      iio: dac: ad5686: refactor device list and file header comments
      dt-bindings: iio: dac: ad5696: extend device support
      dt-bindings: iio: dac: ad5686: extend device support
      iio: dac: ad5686: extend device support with new parts

 .../devicetree/bindings/iio/dac/adi,ad5686.yaml    | 14 +++++-
 .../devicetree/bindings/iio/dac/adi,ad5696.yaml    |  6 +++
 drivers/iio/dac/Kconfig                            | 31 +++++++++---
 drivers/iio/dac/ad5686-spi.c                       | 21 ++++++--
 drivers/iio/dac/ad5686.c                           | 57 +++++++++++++++++++++-
 drivers/iio/dac/ad5686.h                           |  7 +++
 drivers/iio/dac/ad5696-i2c.c                       | 12 +++--
 7 files changed, 132 insertions(+), 16 deletions(-)
---
base-commit: 1258e8ca13866b1a60895abf0ab8a4dd77bf4bfd
change-id: 20260719-ad5686-extend-dev-support-e0ddd119f19c

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

