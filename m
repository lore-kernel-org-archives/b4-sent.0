From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v5 00/11] iio: amplifiers: ad8366: driver update and dt
 support
Date: Mon, 16 Feb 2026 17:10:44 +0000
Message-Id: <20260216-iio-ad8366-update-v5-0-7e6091357d02@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJRPk2kC/23OwQ7CIAyA4VcxnMVQoLh58j2MhwJVSXQsmy4as
 3eXeVHjjn+Tfu1T9Nwl7sVm8RQdD6lPuSmBy4UIJ2qOLFMsLbTSCKBBppQlxco4J29tpCtLdOQ
 pYOV9IFH22o4P6f42d/vSp9Rfc/d4nxhgmk6aUwD1jDaAVLJS1rI2XDtLW2ronI+rkC9i4gb9R
 Wg3R+hChJpsNEDsFfwR5kNoZeYIUwiM6IzzCBX8f2G/CFBzhC0EICo8rD2gtz/EOI4vLD4wrnw
 BAAA=
X-Change-ID: 20251121-iio-ad8366-update-56abac58bbca
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771261851; l=3134;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Olf/VDLJhhSeV5DTXf2NCG4rihN5dnjKW9gQCyqFtKE=;
 b=zObDgaAqkiIy1SlDAA4FyA8zRvq9fngqhETRkt/rlUoIe2rqGQBDefLIyw5AJizLonVYCxSfC
 sc2PF6SuiprDpN87QHjtbKpADT/CliivU/aZhNVds9TsYSb1AFEyYU1
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series updates the AD8366 amplifier/attenuator driver with
modern device resource management, including support for additional
device variants.

Adds support for multiple digital step attenuators:
- ADRF5720: 0.5 dB LSB, 6-Bit, Digital Attenuator, 9 kHz to 40 GHz
- ADRF5730: 0.5 dB LSB, 6-Bit, Digital Attenuator, 100 MHz to 40 GHz
- ADRF5731: 2 dB LSB, 4-Bit, Digital Attenuator, 100 MHz to 40 GHz
- HMC271A: 1 dB LSB, 5-bit, Digital Attenuator, 0.7 - 3.7 GHz
- HMC1018A: 1.0 dB LSB GaAs MMIC 5-BIT DIGITAL ATTENUATOR, 0.1 - 30 GHz
- HMC1019A: 0.5 dB LSB GaAs MMIC 5-BIT DIGITAL ATTENUATOR, 0.1 - 30 GHz

Device Tree Support:
- Adds device tree binding documentation
- Adds device tree compatible strings for all supported devices
- Favor chip info tables over device type.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Changes in v5:
- Another review of include headers.
- Reset changes going before regulator changes
- Chip info table adjustments.
- Consume enable gpio before the reset.
- Link to v4: https://lore.kernel.org/r/20260210-iio-ad8366-update-v4-0-15505f7b15b4@analog.com

Changes in v4:
- Review of included headers.
- Split of device-tree support patch.
- Consume reset controller rather than gpio.
- Link to v3: https://lore.kernel.org/r/20260203-iio-ad8366-update-v3-0-5d5636b5181a@analog.com

Changes in v3:
- Add compatible checks for dt-binding gpio properties.
- Remove reset and enable gpio from device state struct.
- Split refactoring commits.
- Drop part of the refactoring in favor of a cleaner diff.
- Get included header files sorted.
- Link to v2: https://lore.kernel.org/r/20260126-iio-ad8366-update-v2-0-c9a4d31aeb01@analog.com

Changes in v2:
- Reorganize commits with cleanups before features.
- Link to v1: https://lore.kernel.org/r/20260119-iio-ad8366-update-v1-0-8044e23e964a@analog.com

---
Rodrigo Alencar (11):
      MAINTAINERS: Add missing maintainer entry for AD8366 driver
      dt-bindings: iio: amplifiers: Add AD8366 support
      iio: amplifiers: ad8366: refactor include headers
      iio: amplifiers: ad8366: add local dev pointer to the probe function
      iio: amplifiers: ad8366: use devm_mutex_init() and drop mutex_init()
      iio: amplifiers: ad8366: refactor device resource management
      iio: amplifiers: ad8366: replace reset-gpio with reset controller
      iio: amplifiers: ad8366: prepare for device-tree support
      iio: amplifiers: ad8366: add device tree support
      iio: amplifiers: ad8366: consume enable gpio
      iio: amplifiers: ad8366: update device support

 .../bindings/iio/amplifiers/adi,ad8366.yaml        |  97 ++++++
 MAINTAINERS                                        |   9 +
 drivers/iio/amplifiers/Kconfig                     |   6 +
 drivers/iio/amplifiers/ad8366.c                    | 387 +++++++++++----------
 4 files changed, 321 insertions(+), 178 deletions(-)
---
base-commit: cce8de7f9744a210a4441ca8a667a9950515eea7
change-id: 20251121-iio-ad8366-update-56abac58bbca

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

