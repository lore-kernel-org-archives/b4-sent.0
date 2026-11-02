From: Radu Sabau <radu.sabau@analog.com>
Subject: [PATCH v5 0/8] iio: imu: Add support for the ADI ADIS16607
Date: Mon, 02 Nov 2026 11:25:36 +0200
Message-Id: <20261102-adis16607-v5-0-4f98b0d271ac@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABFX6GoC/2XMTQ7CIBCG4asY1mIY/nHlPYwLhKGSaGuKaTRN7
 y52henym8zzzqTgmLGQ424mI0655KGvQ+13JNx83yHNsW7CGddMg6E+5gJaM0OZdSkFrVTAK6n
 /zxFTfq+t86XuWy6vYfys6Ql+17UCjEFTmYAy6oJ1AVGoqPTJ9/4+dIcwPMgvM/GW2pbySk1wM
 ibLrLF+Q0VDQbVUVJqc4VFiQrRqQ2VDuWiprNTLqCTgNUUQf3RZli8DsiaRVAEAAA==
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Radu Sabau <radu.sabau@analog.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux@analog.com, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793611539; l=18900;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=FjTO2tiI1e5qktpojbNw8zgE5SHleC7iSkvcDlqNNDY=;
 b=hFZN5PepQ4cv3fo21W4SlzXoovxrpMBVikyPAQb4HmGhDHs4alE/+PSDlmgoQOgwMTj3FdQOh
 4xtfQ/V8UAfD10xJpeNxfF721vOh2b5ZNl98+8EKOXplJdl+Cr6xiIc
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Analog Devices ADIS16607, a precision
MEMS IMU with triaxial gyroscope, triaxial accelerometer, and
temperature sensor, communicating over a non-standard SPI Half-Duplex
protocol.

Patch 1 fixes the reset dispatch: both __adis_initial_startup()'s reset
fallback and the public adis_reset() wrapper were calling
__adis_reset() directly instead of dispatching through
adis->ops->reset(). That bug is invisible for every existing adislib
driver (adis_default_ops.reset is __adis_reset() itself), but silently
breaks a driver with fully custom ops - like this one - on any board
without a reset-gpios property, or any caller of adis_reset() on a
device like adis16550 whose custom reset op needs a different write
size than __adis_reset()'s hardcoded 8-bit one. Carries a Fixes tag for
the commit that introduced the hardcoded call; no stable backport is
needed since the bug only manifests for a custom-ops driver, and this
is the first one.

Patch 2 adds an optional self_test callback to adislib, for devices
whose self-test sequence doesn't fit the generic
mask-write/sleep/check-status pattern.

Patch 3 adds an optional init callback to adislib, for devices that
need extra device-specific bring-up between reset and self-test (SPI
mode locking, status/bootloader checks, pin or burst-mode
configuration, etc.) - not all ADIS devices need this, so it's only
called when set, same as self_test.

Patch 4 adds the devicetree binding.

Patches 5-8 add the driver in functional groupings, as requested in
v1 review:
 - Patch 5: base driver - probe, raw channel reads, decimation/sample
   frequency, startup and self-test via adislib, debugfs identity
   entries. No buffered capture yet.
 - Patch 6: buffered capture via the device's hardware FIFO.
 - Patch 7: external clock sync support.
 - Patch 8: calibration bias support for gyro/accel.

Notable points for reviewers:

 - The device does not implement the standard ADIS SPI protocol used
   by other parts in the family; reads/writes are done over a custom
   Half-Duplex sequence (see adis16607_spi_read()/adis16607_spi_write()
   and the adis_ops overrides). Half-Duplex is also what gives access
   to the device's burst read, which pops or reads a whole set of
   samples in a single CS-held transfer.

 - Startup is split across the two new adislib callbacks rather than a
   driver-private initial_startup(): adis16607_init() does SPI
   Half-Duplex locking, dev_id verification, the bootloader-busy
   check, and (once FIFO is wired up in patch 6) burst-mode and
   DR/DEV_NOK interrupt-pin configuration; adis16607_self_test() does
   the actual per-axis delta-check, clearing the SELF_TEST register on
   every exit path (not just success) so a failure doesn't leave the
   sensor sitting in its self-test/force state.

 - GPIO0's reset-pin routing (RESET_GPIO_MASK in USER_GPIO_CFG) is
   runtime-writable on this part, so a prior write (bug, firmware,
   direct register access) could leave it de-routed, silently
   defeating reset-gpios. Patch 5's probe() forces it back to the
   reset function over SPI before relying on toggling the pin -
   warning rather than erroring out on failure, so a still-responsive
   device still gets a real chance at reset. Patch 6 adds the
   DR/DEV_NOK pins to the same USER_GPIO_CFG register via a
   read-modify-write, so it can't clobber what probe() already set.

 - The hardware FIFO is the *only* buffered capture path - there is no
   single-sample direct burst-read trigger mode. The device offers its
   burst read on two registers: DIAG_STAT returns a single set of the
   most recent samples directly from the sensor, bypassing the FIFO,
   while FIFO_DATA pops one set from the FIFO. They are genuinely
   different commands with different payload shapes, so the FIFO pop
   stays driver-private rather than going through adislib's generic
   burst-read helpers.

 - The FIFO drain in the trigger handler reads DIAG_STAT (which
   clears FIFO_THRESH_MET as a side effect) and pops however many
   complete samples are available - no disabling, flushing, or
   re-enabling around the drain, since the datasheet's dual-port FIFO
   architecture means reads and writes don't contend. The FIFO is
   flushed and DIAG_STAT cleared once, when the buffer is disabled, so
   that the next session starts clean.

 - The FIFO-threshold interrupt is signaled via DEV_NOK on the
   device's one physically-wired interrupt pin, which stays asserted
   (level-triggered) until DIAG_STAT is read and cleared - this sets
   has_fifo on adis_data and requests the IRQ through adislib's
   threaded/level path, matching adislib's actual contract for that
   flag. probe() rejects any other interrupt type.

 - An optional external clock (clocks property) selects between
   SYNC_DIRECT and SYNC_SCALED modes depending on the supplied
   frequency, with the internal 8 kHz clock used as the default when
   no clock is provided (adis16607_config_clk()). The clock rate is
   requested as exclusive. In scaled mode the sync scale is picked
   when sampling_frequency is set; as that and the decimation can't
   change while capturing, such writes return -EBUSY with the buffer
   enabled.

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

Changes in v5:
- Reordered the adislib patches so the reset-dispatch fix comes first
  and the self_test callback second (Nuno).
- Renamed the post_reset_setup callback to init (Jonathan).
- Dropped Rob Herring's Reviewed-by tag on the dt-bindings patch - the
  binding's GPIO-handling description changed substantially since v3
  (Jonathan).
- Base driver: unit-aware names (int_clk_Hz, clk_freq_mHz) and
  MILLIHZ_PER_HZ/MICROHZ_PER_HZ instead of bare 1000s; the sample
  period is now computed through a u64 temporary, so it stays correct
  on 32-bit; GENMASK()/FIELD_PREP()/FIELD_GET() in the register
  accessors, with a firmware revision struct and a shift-accumulated
  serial number; unsigned loop counters scoped to their loops;
  MODULE_DESCRIPTION() matching Kconfig; reworked channel macro
  indentation and wrapped over-long comments (Andy).
- Base driver: dev_err_probe() for probe-only errors, dropped the log
  lines duplicating what __adis_check_status() already prints, min()
  instead of min_t(), removed stray blank lines in read_raw(), dropped
  the protocol comment above adis16607_spi_read() and the redundant
  bits_per_word/tx zeroing, get_freq() uses the locked helper and
  set_freq() takes the lock only around the register writes (Nuno).
- Base driver: a negative sampling_frequency is now rejected instead
  of wrapping around (Sashiko).
- Base driver: channel .address is now an index into a per-channel
  register table instead of a raw register number, with a
  static_assert() against the channel enum; the calibration bias patch
  extends the same table instead of indexing by scan_index (Jonathan).
- Base driver: DEC_RATE is reset to 0 before a new value is written,
  as the datasheet recommends.
- FIFO: iio_for_each_active_channel() instead of reading the mask
  directly (Nuno, Jonathan, Sashiko); the scan buffer is sized with
  IIO_DECLARE_BUFFER_WITH_TS() and pushed with
  iio_push_to_buffers_with_ts() (Jonathan); the trigger handler uses
  the locking helper (Nuno).
- FIFO: the interrupt type is validated at probe and irq_flag is set
  to level-high, which was never set before (Sashiko); the FIFO is
  flushed and DIAG_STAT cleared when the buffer is disabled, so a
  stale session can't leak into the next (Sashiko).
- FIFO: fixed the FIFO_DATA transfer, whose header is 2 bytes and not
  4; samples were read 2 bytes late. Writing sampling_frequency while
  the buffer is enabled now returns -EBUSY.
- Sync: requested an exclusive clock rate instead of a notifier
  (Nuno), which also covers a controllable clock (Jonathan); the sync
  scale is now picked per requested sampling frequency (Nuno).
- Sync: corrected the accepted external clock ranges to the datasheet
  (direct 1 kHz to 8 kHz, scaled up to 400 Hz); the initial scale now
  keeps the multiplied clock at or below the internal rate; loss of
  sync or PLL lock is warned about from the trigger handler. Reverse
  xmas tree declarations and a loop-scoped unsigned counter
  (Jonathan).
- Link to v4: https://lore.kernel.org/r/20261023-adis16607-v4-0-a4d541ebfd13@analog.com

Changes in v4:
- Split the combined adislib commit into three: self_test callback,
  the reset-dispatch fix, and post_reset_setup callback, each its own
  patch - the original bundled all three under one "Also..." (Jonathan).
- Simplified the reset-dispatch fix: removed the internal settle-time
  sleep from __adis_reset() entirely and made both call sites
  (__adis_initial_startup(), adis_reset()) sleep unconditionally after
  dispatching through adis->ops->reset() - no more comparing against
  __adis_reset() to decide whether to sleep (Jonathan).
- dt-bindings: commit message now states how adis16607-2/-3 actually
  differ (gyro full-scale range only) instead of just asserting two
  variants exist (Jonathan). Narrowed reset-gpios's description to
  just itself, and expanded the top-level description to explain the
  device's five GPIO pins and where each one's function is actually
  modeled (clocks, interrupts, or not exposed) (Jonathan).
- Base driver: moved the RESET_GPIO_MASK force-write from after reset
  to before it, in probe() - a previously-defeated reset-pin routing
  (buggy driver, direct reg access) now gets a chance to be corrected
  before relying on the GPIO toggle, instead of too late to matter;
  only warns rather than erroring out on failure, so a still-live
  device keeps its chance at a real reset (Jonathan). Removed the
  now-redundant duplicate of that same write from
  adis16607_post_reset_setup() (Andy).
- Base driver: large style/cleanup batch - dropped an unneeded
  <linux/kernel.h> include, reordered struct adis16607 so struct adis
  is first (cheaper container_of(), measured -0.41% code size via
  bloat-o-meter), use spi_message_init_with_transfers() instead of
  repeated spi_message_add_tail(), ARRAY_SIZE() instead of hardcoded
  loop bounds, put_unaligned_be16(), combined the firmware/revision
  debugfs files into one "major.minor"-formatted entry, dropped an
  unnecessary #ifdef CONFIG_DEBUG_FS wrapper, guard()/
  adis_dev_auto_lock() instead of manual mutex lock/unlock, -ENODATA
  instead of -EINVAL for an unmatched chip_info, unit-suffixed
  clk_freq_mhz/int_clk_hz field names with MILLI from <linux/units.h>
  instead of a bare magic 1000, de-duplicated/inlined several
  single- or two-use macros (Andy, Jonathan).
- Base driver: the self-test startup delay now cites the actual
  datasheet value (Inertial Settling Time, 40ms) instead of an
  unexplained 100ms that didn't match anything in the datasheet
  (Andy). Self-test now clears the SELF_TEST register on every
  failure path, not just on success (Sashiko AI).
- FIFO: dropped disabling the FIFO before draining and the
  flush-and-re-enable afterward entirely - the datasheet confirms
  overflow-only overwrite (not overwrite-during-read) and a dual-port
  architecture with no read/write contention, so there was nothing
  for the disable step to protect against, and it was costing real
  samples during its own disabled window (Jonathan). fifo_buf is now
  a fixed-size array instead of a heap allocation reallocated on
  every scan-mode change; deleted the now-unnecessary
  update_scan_mode() and its devm cleanup entirely (Jonathan).
  guard()/adis_dev_auto_lock() and direct returns in buffer
  postenable/postdisable (Jonathan). clamp() instead of clamp_t() -
  confirmed by building that the forced cast wasn't needed (Jonathan).
- Sync: adis16607_config_clk() now reads DEC_RATE live instead of
  assuming it's 0 after reset, the same way adis16607_get_freq()
  already does - consistent with how USER_SYNC is already written
  explicitly rather than relying on its own reset default (Jonathan).
- Link to v3: https://lore.kernel.org/r/20261015-adis16607-v3-0-f972d4efee85@a

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
Radu Sabau (8):
      iio: imu: adis: Fix custom reset dispatch in adislib
      iio: imu: adis: Add optional self_test callback
      iio: imu: adis: Add optional init callback
      dt-bindings: iio: imu: Add bindings for ADI ADIS16607
      iio: imu: Add driver for the ADI ADIS16607
      iio: imu: adis16607: Add FIFO-based buffered/triggered capture
      iio: imu: adis16607: Add external clock sync support
      iio: imu: adis16607: Add calibration bias support for gyro/accel

 .../devicetree/bindings/iio/imu/adi,adis16607.yaml |   94 ++
 MAINTAINERS                                        |    8 +
 drivers/iio/imu/Kconfig                            |   13 +
 drivers/iio/imu/Makefile                           |    1 +
 drivers/iio/imu/adis.c                             |   15 +-
 drivers/iio/imu/adis16607.c                        | 1496 ++++++++++++++++++++
 include/linux/iio/imu/adis.h                       |   26 +-
 7 files changed, 1648 insertions(+), 5 deletions(-)
---
base-commit: 0fcb05b72344f40806cbe810de8872f1698bf053
change-id: 20260617-adis16607-089ffc655ceb

Best regards,
-- 
Radu Sabau <radu.sabau@analog.com>

