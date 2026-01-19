From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH 0/4] iio: proximity: vl53l0x: power sequencing, optional
 VDDIO, raw I2C ID read
Date: Mon, 19 Jan 2026 18:19:54 +0100
Message-Id: <20260119-vl53l0x-v1-0-cf71715a1353@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALpnbmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDIyML3bIcU+McgwpdU3NjUxPDVAPjNIMUJaDqgqLUtMwKsEnRsbW1ANV
 5BkpZAAAA
X-Change-ID: 20251228-vl53l0x-573541e03f0d
To: Song Qiang <songqiang1304521@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768843207; l=1309;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=v3If7khaoVa8/stoqUkdZXkFNHufWZUfyfb/J2p7VVM=;
 b=JnT1c7WAoLWRO4MGX2Wz5wMnYHdcY/2xR1OV0jNPWqSFWofL9q5ASYhwg9Xd12B8M5pS/H6Hs
 mQpw6SZc5L1CsPxqtOWmZklNuoZsGkMVSGTc/xG9MnAx/hlv8FtbHQU
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

this series improves robustness and hardware compatibility of the
VL53L0X IIO proximity driver.

Patch 1 and 2 adds support for an optional VDDIO (vio) regulator and documents
it in the device tree binding.

Patch 3 fixes the reset and power-up sequencing. The previous logic drove
the reset GPIO in a way that does not match the datasheet timing and
level requirements.

Patch 4 switches the initial device identification from SMBus helpers to
raw I2C transfers and reads the full 16-bit model and revision IDs.

The series has been tested on hardware - Sony Xperia XZ3 (akatsuki).

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (4):
      iio: proximity: vl53l0x-i2c: Add optional vddio regulator
      iio: proximity: vl53l0x-i2c: Add optional vddio supply
      iio: proximity: vl53l0x-i2c: Fix reset sequence
      iio: proximity: vl53l0x-i2c: Use raw I2C access and read full device ID

 .../bindings/iio/proximity/st,vl53l0x.yaml         |  2 +
 drivers/iio/proximity/vl53l0x-i2c.c                | 71 +++++++++++++++++++---
 2 files changed, 63 insertions(+), 10 deletions(-)
---
base-commit: 46fe65a2c28ecf5df1a7475aba1f08ccf4c0ac1b
change-id: 20251228-vl53l0x-573541e03f0d

Best regards,
-- 
Petr Hodina <petr.hodina@protonmail.com>

