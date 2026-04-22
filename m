From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH 00/22] Extend device support for AD5686 driver
Date: Wed, 22 Apr 2026 15:45:34 +0100
Message-Id: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA/f6GkC/x3MMQqAMAxA0atIZgO2oaJeRRyKjZrFllRFEO9uc
 XzD/w9kVuEMQ/WA8iVZ4l5g6grmze8ro4RisI1tG7IOfXBkSFEkYj5Tinpg11kfqCfXsoFSJuV
 F7v86Tu/7AZ1g67FlAAAA
X-Change-ID: 20260325-ad5313r-iio-support-882ad39356e1
To: Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michael Auchter <michael.auchter@ni.com>, linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776869181; l=3288;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=+jyI2fVMyjIivhQsiJU3XcRjwvd0On+YXNM0kRRkZrM=;
 b=GiE3VtANGmnhUKacLVTpE7nQ/MtzrJgeV+U/UQENXckFs3ws6ToShYeSp0T8QsXg2PYUHEMAc
 bupTL1waAPvAe3PDqhZVTuUSHy6RdPm/8aZZW3RE4R2f1+Eq23+utFS
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for multiple nanoDAC parts, adding triggered
buffer and gain control support to the ad5686 DAC driver family, along
with a number of driver cleanups and fixes.

Initial patches update the device-tree bindings:
- Add compatible entries for missing and new parts;
- Add GPIO properties for RESET, GAIN and LDAC pins;
- Add missing power supplies properties.

Driver cleanups and fixes:
- Refactor include headers (IWYU);
- Switch to device managed mutex initialization;
- Drop enum chip id in favor of per-device chip_info structs;
- Fix voltage reference control on single-channel devices;
- Fix powerdown control on dual-channel devices;
- Introduce bus ops struct with a sync() operation for batching
  bus transfers.

New functionality:
- Device support for: AD5316R, AD5675, AD5697R, AD5313R, AD5317R,
  AD5674, AD5679, AD5687, AD5687R, AD5689 and AD5689R;
- Consume optional reset and new power supplies;
- LDAC GPIO handling (active-low, held low when unused);
- SPI bus sync() implementation for batching multiple transfers;
- Triggered buffer support, leveraging LDAC and sync() to flush
  all channel writes atomically;
- Gain control support through the scale property.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Rodrigo Alencar (22):
      dt-bindings: iio: dac: ad5696: extend device support
      dt-bindings: iio: dac: ad5696: add reset/ldac/gain gpio support
      dt-bindings: iio: dac: ad5696: rework on power supplies
      dt-bindings: iio: dac: ad5686: extend device support
      dt-bindings: iio: dac: ad5686: add reset/ldac/gain gpio support
      dt-bindings: iio: dac: ad5686: rework on power supplies
      iio: dac: ad5686: refactor include headers
      iio: dac: ad5686: remove redundant register definition
      iio: dac: ad5686: drop enum id
      iio: dac: ad5686: add of_match table to the spi driver
      iio: dac: ad5686: fix ref bit initialization for single-channel parts
      iio: dac: ad5686: fix powerdown control
      iio: dac: ad5686: fix input raw value check
      iio: dac: ad5686: add support for missing power supplies
      iio: dac: ad5686: create bus ops struct
      iio: dac: ad5686: extend device support with new parts
      iio: dac: ad5686: update device list description
      iio: dac: ad5686: consume optional reset signal
      iio: dac: ad5686: add ldac gpio
      iio: dac: ad5686: implement new sync() op for the spi bus
      iio: dac: ad5686: add triggered buffer support
      iio: dac: ad5686: add gain control support

 .../devicetree/bindings/iio/dac/adi,ad5686.yaml    |  61 +-
 .../devicetree/bindings/iio/dac/adi,ad5696.yaml    |  60 +-
 drivers/iio/dac/Kconfig                            |  18 +-
 drivers/iio/dac/ad5686-spi.c                       | 200 ++++--
 drivers/iio/dac/ad5686.c                           | 775 +++++++++++++--------
 drivers/iio/dac/ad5686.h                           | 144 ++--
 drivers/iio/dac/ad5696-i2c.c                       |  94 +--
 7 files changed, 906 insertions(+), 446 deletions(-)
---
base-commit: eade2b843d9b1f668fc1775f15611bb0a1999cd9
change-id: 20260325-ad5313r-iio-support-882ad39356e1

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

