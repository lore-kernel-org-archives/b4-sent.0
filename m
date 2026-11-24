From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH 0/2] iio: light: add support for ams OSRAM TCS3430
Date: Tue, 24 Nov 2026 23:46:56 +0100
Message-Id: <20261124-iio-tcs3430-v1-0-0f2a38a6a4c1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDXRqf+riAU1GAukg0jE3RXLb
 /HeBUKOSaAMLnB0sPAye+gwADs280CKO2/ACFOtMVbMi9qsmNhECvvE5FmRYEYd+GJ11PP53ar
 6t+ztRHZ7F3DfDxcKWmlvAAAA
X-Change-ID: 20261124-iio-tcs3430-2f53879527ed
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795560418; l=1023;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=LG2ewCo1AW0swjfSDYupyXwfkuTjQvVui6Y094td8Y0=;
 b=aeT5Ovy9UV5sBRx5TnlnZJ85IXHLGjZCaVNRFzuXR14XS5g6PMqzdDmos4mS3XTs2yTrua7Fc
 xouJsr5bsyEDG0KsPjnGh/ha+OpfMRQT2IZJleZOu73/SU60fbprAha
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Devicetree binding documentation and an IIO driver for the ams OSRAM
TCS3430 ambient light and CIE 1931 XYZ tristimulus color sensor.

Tested on Microsoft Surface Pro X SQ2 (SC8180X), where the sensor is
connected on I2C at 0x39 and used for ambient light sensing.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Robert Ijtsma (2):
      dt-bindings: iio: light: add ams OSRAM TCS3430
      iio: light: add ams OSRAM TCS3430 XYZ and ambient light sensor driver

 .../devicetree/bindings/iio/light/ams,tcs3430.yaml |  52 ++++
 MAINTAINERS                                        |   7 +
 drivers/iio/light/Kconfig                          |  10 +
 drivers/iio/light/Makefile                         |   1 +
 drivers/iio/light/tcs3430.c                        | 345 +++++++++++++++++++++
 5 files changed, 415 insertions(+)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261124-iio-tcs3430-2f53879527ed

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

