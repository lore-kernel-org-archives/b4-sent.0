From: Remi Buisson <remi.buisson@tdk.com>
Subject: [PATCH v2 0/8] iio: imu: new inv_icm45600 driver
Date: Thu, 10 Jul 2025 08:57:55 +0000
Message-Id: <20250710-add_newport_driver-v2-0-bf76d8142ef2@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJOAb2gC/32NQQ6CMBBFr0JmbU2nsQquuIchpNBBJkZKpqRqC
 He3cgCX7yX//RUiCVOEa7GCUOLIYcpgDgX0o5vupNhnBqON1SdE5bxvJ3rNQZbWCycSZU3VD7a
 7ILkS8nAWGvi9R29N5pHjEuSzfyT82b+5hEortLo0eNadxqpe/OPYhyc027Z9ASjzPRGyAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752137881; l=4432;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=JJ1bAzS6PXXHWE+UebUwFRQDunzJtFYqocYHPygbTf0=;
 b=PO+xKYb2foSTz3nJYusbnfSjW6nXZi9Gn+0futiCmELYcQVqb8h/RASzMNrOOw8dPaQh0wiaS
 DLpY5u7Ml75Bos5+BlstzqfzPvZPGRVNXPO2DRL722KJJooOBkyfnsl
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
Changes in v2:
- Reworked patches order and content to ease review and make sure everything compiles
- Reworked gyro and accel FSR as 2D arrays
- Moved temperature processed sensor to core module
- Use latest API to claim/release device
- Implemented chip_info structure instead of relying on an enum
- Removed power-mode ABI, only relying on ODR to switch power_mode
- Reworked regulator control to use devm_ API where relevant
- Reworked inv_icm45600_state.buffer as a union to avoid casts, using getter/setter instead of memcpy
- Fixed dt-binding error and moved patch at the beginning of the patch-set
- Reworked macros to use FIELD_PREP inline instead of inside the header
- Fixed comment's grammar
- Removed extra blank lines
- Reordered part numbers alphanumerically
- Removed useless default/error fallbacks
- Typed accel, gyro and timestamp data when parsing FIFO
- Fixed I2C module return code
- Use Linux types instead of C standard
- Reviewed headers inclusion to remove useless #include and to add missing ones
- Link to v1: https://lore.kernel.org/r/20250411-add_newport_driver-v1-0-15082160b019@tdk.com

---
Remi Buisson (8):
      dt-bindings: iio: imu: Add inv_icm45600
      iio: imu: inv_icm45600: add new inv_icm45600 driver
      iio: imu: inv_icm45600: add buffer support in iio devices
      iio: imu: inv_icm45600: add IMU IIO devices
      iio: imu: inv_icm45600: add I2C driver for inv_icm45600 driver
      iio: imu: inv_icm45600: add SPI driver for inv_icm45600 driver
      iio: imu: inv_icm45600: add I3C driver for inv_icm45600 driver
      MAINTAINERS: add entry for inv_icm45600 6-axis imu sensor

 .../bindings/iio/imu/invensense,icm45600.yaml      | 138 +++
 MAINTAINERS                                        |   8 +
 drivers/iio/imu/Kconfig                            |   1 +
 drivers/iio/imu/Makefile                           |   1 +
 drivers/iio/imu/inv_icm45600/Kconfig               |  70 ++
 drivers/iio/imu/inv_icm45600/Makefile              |  16 +
 drivers/iio/imu/inv_icm45600/inv_icm45600.h        | 377 ++++++++
 drivers/iio/imu/inv_icm45600/inv_icm45600_accel.c  | 798 +++++++++++++++++
 drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.c | 585 ++++++++++++
 drivers/iio/imu/inv_icm45600/inv_icm45600_buffer.h | 101 +++
 drivers/iio/imu/inv_icm45600/inv_icm45600_core.c   | 991 +++++++++++++++++++++
 drivers/iio/imu/inv_icm45600/inv_icm45600_gyro.c   | 809 +++++++++++++++++
 drivers/iio/imu/inv_icm45600/inv_icm45600_i2c.c    |  98 ++
 drivers/iio/imu/inv_icm45600/inv_icm45600_i3c.c    |  82 ++
 drivers/iio/imu/inv_icm45600/inv_icm45600_spi.c    | 106 +++
 15 files changed, 4181 insertions(+)
---
base-commit: f8f559752d573a051a984adda8d2d1464f92f954
change-id: 20250411-add_newport_driver-529cf5b71ea8

Best regards,
-- 
Remi Buisson <remi.buisson@tdk.com>

