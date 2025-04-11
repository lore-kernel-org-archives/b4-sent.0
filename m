From: Remi Buisson <remi.buisson@tdk.com>
Subject: [PATCH 0/8] iio: imu: new inv_icm45600 driver
Date: Fri, 11 Apr 2025 13:28:32 +0000
Message-Id: <20250411-add_newport_driver-v1-0-15082160b019@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAZ+WcC/x3MTQqAIBBA4avErBNSkn6uEiHWTDUbizEsiO6et
 PwW7z0QSZgi9MUDQokj7yFDlwXMmw8rKcZsMJWxVa218ogu0HXscjoUTiTKmm5e7NRo8i3k8BB
 a+P6nw/i+H+nmgslkAAAA
X-Change-ID: 20250411-add_newport_driver-529cf5b71ea8
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, Remi Buisson <remi.buisson@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744378119; l=3510;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=JTFeAmlNUSNT8ZCwFvfBb94G9sBpagRzzlhSQPzjPuQ=;
 b=XoowJUulQzLBGMCFbu7uLJJggxGchQ3Sx0Ejb/SubI1Aw+8gPq5kCr2SuM4vNBpFaQJeoyTX7
 AExoWdEVozADZ3mPgpUSLrb4zbNEWD98RtwTXER1rdmZsalZKQ1TuMc
X-Developer-Key: i=remi.buisson@tdk.com; a=ed25519;
 pk=yDVMi4C7RpXN4dififo42A7fDDt3THYzoZoNq9lUZuo=
X-Endpoint-Received: by B4 Relay for remi.buisson@tdk.com/20250411 with auth_id=372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series add a new driver for managing InvenSense ICM-456xx 6-axis IMUs.
This next generation of chips includes new generations of 3-axis gyroscope
and 3-axis accelerometer, support of I3C in addition to I2C and SPI, and
intelligent MotionTracking features like pedometer, tilt detection, and
tap detection.

This series is delivering a driver supporting gyroscope, accelerometer and
temperature data, with polling and buffering using hwfifo and watermark,
on I2C, SPI and I3C busses.

Gyroscope and accelerometer sensors are completely independent and can have
different ODRs. Since there is only a single FIFO a specific value is used to
mark invalid data. For keeping the device standard we are de-multiplexing data
from the FIFO to 2 IIO devices with 2 buffers, 1 for the accelerometer and 1
for the gyroscope. This architecture also enables to easily turn each sensor
on/off without impacting the other. The device interrupt is used to read the
FIFO and launch parsing of accelerometer and gyroscope data. This driver
relies on the common Invensense timestamping mechanism to handle correctly
FIFO watermark and dynamic changes of settings.

The structure of the driver is quite similar to the inv_icm42600 driver,
however there are significant reasons for adding a different driver for
inv_icm45600, such as:
- A completely different register map.
- Different FIFO management, based on number of samples instead of bytes.
- Different indirect register access mechanism.

Signed-off-by: Remi Buisson <remi.buisson@tdk.com>
---
Remi Buisson (8):
      iio: imu: inv_icm45600: add new inv_icm45600 driver
      iio: imu: inv_icm45600: add I2C driver for inv_icm45600 driver
      iio: imu: inv_icm45600: add SPI driver for inv_icm45600 driver
      iio: imu: inv_icm45600: add I3C driver for inv_icm45600 driver
      iio: imu: inv_icm45600: add buffer support in iio devices
      iio: imu: add Kconfig and Makefile for inv_icm45600 driver
      dt-bindings: iio: imu: Add inv_icm45600 documentation
      MAINTAINERS: add entry for inv_icm45600 6-axis imu sensor

 .../ABI/testing/sysfs-bus-iio-inv_icm45600         |  37 +
 .../bindings/iio/imu/invensense,icm45600.yaml      | 136 +++
 MAINTAINERS                                        |   9 +
 drivers/iio/imu/Kconfig                            |   1 +
 drivers/iio/imu/Makefile                           |   1 +
 drivers/iio/imu/inv_icm45600/Kconfig               |  70 ++
 drivers/iio/imu/inv_icm45600/Makefile              |  17 +
 drivers/iio/imu/inv_icm45600/inv_icm45600.h        | 421 ++++++++++
 drivers/iio/imu/inv_icm45600/inv_icm45600_accel.c  | 902 ++++++++++++++++++++
 drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c | 572 +++++++++++++
 drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.h | 100 +++
 drivers/iio/imu/inv_icm45600/inv_icm45600_core.c   | 906 ++++++++++++++++++++
 drivers/iio/imu/inv_icm45600/inv_icm45600_gyro.c   | 919 +++++++++++++++++++++
 drivers/iio/imu/inv_icm45600/inv_icm45600_i2c.c    | 103 +++
 drivers/iio/imu/inv_icm45600/inv_icm45600_i3c.c    |  84 ++
 drivers/iio/imu/inv_icm45600/inv_icm45600_spi.c    | 110 +++
 drivers/iio/imu/inv_icm45600/inv_icm45600_temp.c   |  82 ++
 drivers/iio/imu/inv_icm45600/inv_icm45600_temp.h   |  31 +
 18 files changed, 4501 insertions(+)
---
base-commit: 1c2409fe38d5c19015d69851d15ba543d1911932
change-id: 20250411-add_newport_driver-529cf5b71ea8

Best regards,
-- 
Remi Buisson <remi.buisson@tdk.com>

