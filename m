From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v3 00/12] New features for the AD5686 IIO driver
Date: Tue, 16 Jun 2026 09:21:06 +0100
Message-Id: <20260616-ad5686-new-features-v3-0-f829fb7e9262@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHIHMWoC/33NTQ6CMBCG4auQWVvTHyjgynsYF6UdoIm2psWqI
 dzdwkoT4/L9knlmhojBYoRDMUPAZKP1LofYFaBH5QYk1uQGTrmkknKiTCUbSRw+SI9qugeMBBm
 TmpadMV0L+fIWsLfPTT2dc482Tj68tieJret/LzFCiWwZUtY0wvD6qJy6+GGv/RVWMPFPpP2N8
 IzUtCu56CtdS/OFLMvyBhZ/ni/8AAAA
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
 Conor Dooley <conor.dooley@microchip.com>, 
 Maxwell Doose <m32285159@gmail.com>, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781598070; l=2775;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=0K2xAOUEUd6OJytadlo69+09JQ9vsecAOvXvGOp5mkM=;
 b=oA8k08wG4lB9+JIFlq4UGC0rbvnpmMGTO163L/J0H8IClDcBdVWJRTIsJXVPYQwx/rof4hcpM
 YbZ1hFsYuhYC5G0N0TRjO9NzjEGtQ4+IkTmVkgXA3z6u9NUi4JVgMTW
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
Changes in v3:
- Add range-double property.
- Acquire reset control after power-up delay.
- Include cleanup.h and use guard(mutex)() in read_raw().
- Link to v2: https://lore.kernel.org/r/20260609-ad5686-new-features-v2-0-70b423f5c76d@analog.com

Changes in v2:
- Get reset control deasserted.
- Update entire spi_transfer struct rather than individual fields.
- Replace udelay() for fsleep() in probe().
- Minor changes addressing further feedback.
- Link to v1: https://lore.kernel.org/r/20260602-ad5686-new-features-v1-0-691e01883d27@analog.com

---
Rodrigo Alencar (12):
      dt-bindings: iio: dac: ad5696: add reset/ldac/gain support
      dt-bindings: iio: dac: ad5696: rework on power supplies
      dt-bindings: iio: dac: ad5686: add reset/ldac/gain support
      dt-bindings: iio: dac: ad5686: rework on power supplies
      iio: dac: ad5686: add support for missing power supplies
      iio: dac: ad5686: consume optional reset signal
      iio: dac: ad5686: add ldac gpio
      iio: dac: ad5686: introduce sync operation
      iio: dac: ad5686: implement new sync() op for the spi bus
      iio: dac: ad5686: add triggered buffer support
      iio: dac: ad5686: read_raw/write_raw: use guard(mutex)()
      iio: dac: ad5686: add gain control support

 .../devicetree/bindings/iio/dac/adi,ad5686.yaml    |  72 +++++-
 .../devicetree/bindings/iio/dac/adi,ad5696.yaml    |  75 ++++++-
 drivers/iio/dac/Kconfig                            |   2 +
 drivers/iio/dac/ad5686-spi.c                       | 121 +++++++---
 drivers/iio/dac/ad5686.c                           | 249 +++++++++++++++++++--
 drivers/iio/dac/ad5686.h                           |  33 ++-
 drivers/iio/dac/ad5696-i2c.c                       |   2 +-
 7 files changed, 492 insertions(+), 62 deletions(-)
---
base-commit: ae696dfa47c30016cd429b9db5e70b259b8f509e
change-id: 20260602-ad5686-new-features-e116c04bddb9

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

