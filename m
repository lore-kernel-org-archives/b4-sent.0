From: Radu Sabau <radu.sabau@analog.com>
Subject: [PATCH v3 0/6] iio: imu: Add support for the ADI ADIS16607
Date: Thu, 15 Oct 2026 12:32:57 +0300
Message-Id: <20261015-adis16607-v3-0-f972d4efee85@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMmd0GoC/1WMyw7CIBQFf6VhLeZC5eXK/zAuEC4tiRYDhmia/
 ru0q7qckzMzk4I5YiHnbiYZaywxTQ36Q0fcaKcBafSNCQcuQTJFrY+FSQmKgjYhOCmEwztp/1f
 GED9b63prPMbyTvm7pStb163CANiuUhkFapw2DrEXXsiLnewjDUeXnmTNVL5X9V7lTVXOnHzQo
 JW2f+qyLD/p4w6J3gAAAA==
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Radu Sabau <radu.sabau@analog.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792056783; l=10599;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=yqD/9+CrvO1EK4sHo+hCa3W2BZSv0Mf4fR9oR/ZR8Mo=;
 b=1F63EGoSh5V9V838WuFAkVeeoC8vTq3surEqRxp4B/ZX/o3tv928cx5An5k1vZzGUUwxl5p7A
 VY42VHMrLdqAPbRGfMp10hbej1GbLsFClCMH3VUBt7hWxK0nxP4jPc6
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
Plus a fix to the reset dispatch: both __adis_initial_startup()'s reset
fallback and the public adis_reset() wrapper were calling __adis_reset()
directly instead of dispatching through adis->ops->reset(). That bug is
invisible for every existing adislib driver (adis_default_ops.reset is
__adis_reset() itself), but silently breaks a driver with fully custom
ops - like this one - on any board without a reset-gpios property, or
any caller of adis_reset() on a device like adis16550 whose custom
reset op needs a different write size than __adis_reset()'s hardcoded
8-bit one. Carries a Fixes tag for the commit that introduced the
hardcoded call; no stable backport is needed since the bug only
manifests for a custom-ops driver, and this is the first one.

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

Changes in v3:
- Fixed the public adis_reset() wrapper (adis.h) to also dispatch
  through adis->ops->reset() instead of hardcoding __adis_reset() -
  the same bug class as the v2 __adis_initial_startup() fix, just a
  second call site that was missed. Switched both checks from
  comparing against adis_default_ops to adis->ops->reset != __adis_reset,
  which also works from the header, where adis_default_ops isn't
  visible (Sashiko).
- Fixed dt-binding wording: dropped "compatible" from the variant
  description (reads as a DT compatible-string fallback claim, which
  doesn't exist here - the two variants aren't interchangeable) and
  dropped a Linux-driver-specific sentence from reset-gpios's
  description (Conor); removed a stale commit-message bullet claiming
  a FIFO watermark property that was never in the binding (Sashiko).
- Dropped a redundant <linux/mod_devicetable.h> include -
  <linux/spi/spi.h> already provides it (Uwe, Andy); switched
  adis16607_id[] to named initializers (Uwe).
- Fixed FIFO sample timestamps: they were projected forward from the
  IRQ-fire time instead of back-dated, so the newest sample in a batch
  ended up timestamped in the future. Now back-dated so the newest
  sample lands on the IRQ-fire time and earlier ones count back from
  it (Sashiko).
- Added a comment explaining why disabling the FIFO during drain, and
  the flush afterward, don't lose in-flight samples - no new samples
  are enqueued at all while disabled, so nothing can arrive in that
  window for the flush to drop (Sashiko asked twice, independently).
- Reworked external clock sync configuration (adis16607_config_clk())
  so every mode (default/direct/scaled) explicitly writes its own
  complete SYNC_GPIO_MASK/USER_SYNC state, instead of only writing
  conditionally when enabling non-default sync (Sashiko x2); switched
  the sync scale factor from truncating to rounding division (Sashiko);
  fixed a real bug where SCALED mode's effective clock was hardcoded
  to the nominal internal rate instead of the actual achieved rate
  (ext_clk_hz * sync_scale), which would have caused FIFO timestamps
  to drift whenever the external clock didn't divide the internal
  clock exactly (Sashiko).
- Added range validation before writing calibration bias - out-of-
  range values were silently truncated to 16 bits instead of being
  rejected (Sashiko).
- Link to v2: https://lore.kernel.org/r/20261008-adis16607-v2-0-7c94df80878a@analog.com

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

 .../devicetree/bindings/iio/imu/adi,adis16607.yaml |   82 ++
 MAINTAINERS                                        |    8 +
 drivers/iio/imu/Kconfig                            |   13 +
 drivers/iio/imu/Makefile                           |    1 +
 drivers/iio/imu/adis.c                             |   30 +-
 drivers/iio/imu/adis16607.c                        | 1405 ++++++++++++++++++++
 include/linux/iio/imu/adis.h                       |   32 +-
 7 files changed, 1563 insertions(+), 8 deletions(-)
---
base-commit: 9c87e61e3c5797277407ba5eae4eac8a52be3fa3
change-id: 20260617-adis16607-089ffc655ceb

Best regards,
-- 
Radu Sabau <radu.sabau@analog.com>

