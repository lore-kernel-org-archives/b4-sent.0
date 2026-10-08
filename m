From: Radu Sabau <radu.sabau@analog.com>
Subject: [PATCH v2 0/6] iio: imu: Add support for the ADI ADIS16607
Date: Thu, 08 Oct 2026 11:31:52 +0300
Message-Id: <20261008-adis16607-v2-0-7c94df80878a@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPhUx2oC/03MQQrCMBCF4auUWRuZRJK2rryHdBGn03ZAG0mkK
 CV3N2bl8n88vh0SR+EE52aHyJskCWsJc2iAFr/OrGQsDQaNQ6db5UdJ2jlsFXb9NJGzlvgG5f+
 MPMm7Wteh9CLpFeKn0pv+rVXRiPpP2bRC1VPXE/PJjtZd/OrvYT5SeMCQc/4CNtbCZ6MAAAA=
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Radu Sabau <radu.sabau@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791448342; l=7980;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=wgExskAdbglgz31ok+x5vWdb//tIQQPa12UByAAFggY=;
 b=vslH2gi+d4Z3F/W2fWQUsTIWfBXc3VwRdLMT3iGwnoWATrxIZ1NqB7DfnVJ7a7+HnfxsJhhm1
 ByMVjlzErBHC/bvwFOy3CnNX3jlmzc06iINwA8g314vnHKzgzqfTYVe
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Analog Devices ADIS16607, a precision
MEMS IMU with triaxial gyroscope, triaxial accelerometer, and
temperature sensor, communicating over a non-standard SPI Half-Duplex
protocol.

Patch 1 adds two small adislib (drivers/iio/imu/adis.c) extensions
this series needs:
 - An optional self_test callback for devices whose self-test sequence
   doesn't fit the generic mask-write/sleep/check-status pattern.
 - An optional post_reset_setup callback for devices that need extra
   device-specific bring-up between reset and self-test (SPI mode
   locking, status/bootloader checks, pin or burst-mode configuration,
   etc.) - not all ADIS devices need this, so it's only called when
   set, same as self_test.
Plus a fix to __adis_initial_startup()'s reset fallback, which was
calling __adis_reset() directly instead of dispatching through
adis->ops->reset(). That bug is invisible for every existing adislib
driver (adis_default_ops.reset is __adis_reset() itself), but silently
breaks a driver with fully custom ops - like this one - on any board
without a reset-gpios property. Carries a Fixes tag for the commit
that introduced the hardcoded call; no stable backport is needed since
the bug only manifests for a custom-ops driver, and this is the first
one.

Patch 2 adds the devicetree binding.

Patches 3-6 add the driver in functional groupings, as requested in
v1 review:
 - Patch 3: base driver - probe, raw channel reads, decimation/sample
   frequency, startup and self-test via adislib, debugfs identity
   entries. No buffered capture yet.
 - Patch 4: buffered capture via the device's hardware FIFO.
 - Patch 5: external clock sync support.
 - Patch 6: calibration bias support for gyro/accel.

Notable points for reviewers:

 - The device does not implement the standard ADIS SPI protocol used
   by other parts in the family; reads/writes are done over a custom
   Half-Duplex sequence (see adis16607_spi_read()/adis16607_spi_write()
   and the adis_ops overrides).

 - Startup is split across the two new adislib callbacks rather than a
   driver-private initial_startup(): adis16607_post_reset_setup() does
   SPI Half-Duplex locking, dev_id verification, the bootloader-busy
   check, an optional reset-status GPIO output, and (once FIFO is
   wired up in patch 4) burst-mode and interrupt-pin configuration;
   adis16607_self_test() does only the actual per-axis delta-check.

 - The optional reset-status GPIO output (RESET_GPIO_MASK, part of
   "optional hardware reset via GPIO") is configured in patch 3's
   post_reset_setup, independent of FIFO. Patch 4 later adds the
   DR/DEV_NOK pins to the same USER_GPIO_CFG register via a
   read-modify-write, so it cannot clobber what patch 3 already set.

 - The hardware FIFO is the *only* buffered capture path - there is no
   single-sample direct burst-read trigger mode. The FIFO-pop command
   and the regular burst-read command are genuinely different
   protocols on this device (different payload shapes, no checksum on
   the FIFO side), so this stays driver-private rather than going
   through adislib's generic burst-read helpers.

 - The FIFO-threshold interrupt is signaled via DEV_NOK on the
   device's one physically-wired interrupt pin, which stays asserted
   (level-triggered) until DIAG_STAT is read and cleared - this sets
   has_fifo on adis_data and requests the IRQ through adislib's
   threaded/level path, matching adislib's actual contract for that
   flag.

 - An optional external clock (clocks property) selects between
   SYNC_DIRECT and SYNC_SCALED modes depending on the supplied
   frequency, with the internal 8 kHz clock used as the default when
   no clock is provided (adis16607_config_clk()).

 - spi-max-frequency is corrected to 10 MHz (datasheet maximum), down
   from 15 MHz in v1.

This has been tested on a Raspberry Pi 4 (arm64) with the device wired
over SPI, exercising the FIFO buffered-capture path with the updated
DEV_NOK/level-triggered interrupt wiring.

To: Lars-Peter Clausen <lars@metafoo.de>
To: Michael Hennerich <Michael.Hennerich@analog.com>
To: Jonathan Cameron <jic23@kernel.org>
To: David Lechner <dlechner@baylibre.com>
To: Nuno Sá <nuno.sa@analog.com>
To: Andy Shevchenko <andy@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Alexandru Ardelean <alexandru.ardelean@analog.com>
Cc: linux-iio@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>
Signed-off-by: Radu Sabau <radu.sabau@analog.com>

Changes in v2:
- Split the driver commit into functional groupings per review:
  base, FIFO, external clock sync, calibration bias (Nuno).
- Added adis_data.self_test and adis_data.post_reset_setup callbacks
  to adislib instead of duplicating startup/self-test logic in the
  driver (Nuno). post_reset_setup is a second, honestly-named hook
  added after review feedback that overloading self_test to also mean
  "everything else the device needs at startup" was misleading.
- Fixed __adis_initial_startup()'s reset fallback to dispatch through
  adis->ops->reset() instead of a hardcoded __adis_reset() call -
  found while wiring up this driver's custom reset op. Added a Fixes
  tag for the originating commit.
- Removed the direct single-sample burst-read capture path entirely;
  the hardware FIFO is now the only buffered capture mode. Dropped
  adi,fifo-enable from the binding accordingly.
- Fixed FIFO-threshold interrupt wiring: set has_fifo on adis_data and
  switch the DT interrupt type from edge to level, matching the
  DEV_NOK signal this now uses (previously only the data-ready pulse
  was wired, which never actually generated a FIFO interrupt).
- Moved the optional reset-status GPIO output into the base driver
  patch (where it conceptually belongs) instead of bundling it into
  the FIFO patch's USER_GPIO_CFG write; the FIFO patch now updates
  that register with a read-modify-write instead of a blind write.
- Fixed cover letter: "Three compatible variants (-1, -2, -3)" was
  wrong, there are only two (-2, -3); "configurable data-ready
  interrupt pin (DIO1-4)" was wrong, there's a single fixed pin.
- Corrected spi-max-frequency to 10 MHz (datasheet maximum), from
  15 MHz.
- Renamed ADIS16607_REG_SW_RES to ADIS16607_REG_SOFT_RESET to match
  the datasheet's register name; renamed burst_buf to fifo_buf and
  dropped the redundant "fifo_" prefix from the buffer postenable/
  postdisable/ops names, since FIFO is the only capture mode and
  "burst" no longer described what that scratch buffer is used for.
- Link to v1: https://lore.kernel.org/r/20261001-adis16607-v1-0-9c89cee35d56@analog.com

---
Radu Sabau (6):
      iio: imu: adis: Add optional self_test callback and fix custom reset dispatch
      dt-bindings: iio: imu: Add bindings for ADI ADIS16607
      iio: imu: Add driver for the ADI ADIS16607
      iio: imu: adis16607: Add FIFO-based buffered/triggered capture
      iio: imu: adis16607: Add external clock sync support
      iio: imu: adis16607: Add calibration bias support for gyro/accel

 .../devicetree/bindings/iio/imu/adi,adis16607.yaml |   83 ++
 MAINTAINERS                                        |    8 +
 drivers/iio/imu/Kconfig                            |   13 +
 drivers/iio/imu/Makefile                           |    1 +
 drivers/iio/imu/adis.c                             |   30 +-
 drivers/iio/imu/adis16607.c                        | 1373 ++++++++++++++++++++
 include/linux/iio/imu/adis.h                       |   14 +
 7 files changed, 1515 insertions(+), 7 deletions(-)
---
base-commit: 9c87e61e3c5797277407ba5eae4eac8a52be3fa3
change-id: 20260617-adis16607-089ffc655ceb

Best regards,
-- 
Radu Sabau <radu.sabau@analog.com>

