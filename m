From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH 0/7] iio: amplifiers: ad8366: driver update and dt support
Date: Mon, 19 Jan 2026 14:36:54 +0000
Message-Id: <20260119-iio-ad8366-update-v1-0-8044e23e964a@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIZBbmkC/x3MQQqAIBBA0avErBtIQ4muEi1GnWo2KVoRRHdPW
 r7F/w8UzsIFxuaBzJcUiXuFahvwG+0ro4Rq0J02SmmFIhEpDL21eKZAB6Ox5MibwTlPULuUeZH
 7f07z+345fOTvYwAAAA==
X-Change-ID: 20251121-iio-ad8366-update-56abac58bbca
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768833448; l=1845;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=dwwTpaKA7gIHT3p11HWy39HHGkQKNmQErjgBN0eXz+Q=;
 b=LwuV+V5aYEDkwYsj9rglG1B7ZsDII5mtBFR12tzQcMRm+1C2kxTWOxd6djNG598KOCIjXorFu
 jL2l9tl6Fn1Brj93UiGuB2mdUsEEK5clqbTsMtC9fUla2TZjjahuTTT
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series updates the AD8366 amplifier/attenuator driver with
modern resource management, including support for additional device
variants.

Device Support Expansion:
- Adds support for multiple digital step attenuators:
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
Rodrigo Alencar (7):
      MAINTAINERS: Add missing maintainer entry for AD8366 driver
      dt-bindings: iio: amplifiers: Add AD8366 support
      iio: amplifiers: ad8366: consume enable gpio for applicable parts
      iio: amplifiers: ad8366: Update device support
      iio: amplifiers: ad8366: use cleanup.h mutex guard
      iio: amplifiers: ad8366: simplify resource management
      iio: amplifiers: ad8366: add device tree support

 .../bindings/iio/amplifiers/adi,ad8366.yaml        |  85 +++++
 MAINTAINERS                                        |   9 +
 drivers/iio/amplifiers/Kconfig                     |   6 +
 drivers/iio/amplifiers/ad8366.c                    | 351 +++++++++++----------
 4 files changed, 285 insertions(+), 166 deletions(-)
---
base-commit: c30e80d68a7afb334fde7147ee0106f25dd58d3a
change-id: 20251121-iio-ad8366-update-56abac58bbca

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

