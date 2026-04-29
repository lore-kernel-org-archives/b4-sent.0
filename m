From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v4 00/13] Fixes and cleanups for the AD5686 IIO driver
Date: Wed, 29 Apr 2026 14:07:30 +0100
Message-Id: <20260429-ad5686-fixes-v4-0-bb8f1cbd68e1@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJMC8mkC/3XM0Q6CIBTG8VdxXEcDxAN01Xu0LhCOylbapLGa8
 91Dr8zW5XfOfv+JRBwDRnIqJjJiCjEMfR7yUBDX2b5FGnzeRDABTAqg1leggTbhhZFCiRa05rz
 2NcnkMeL6yOJyzbsL8TmM77We+HL9E0qcMqqckWCVUkbi2fb2NrRHN9zJUkpiq9VOi6y51sgqb
 kwJ+keXW613uszauKZRtQdlefWl53n+AMetmPMlAQAA
X-Change-ID: 20260426-ad5686-fixes-63ea68811bdb
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Stefan Popa <stefan.popa@analog.com>, Jonathan Cameron <jic23@cam.ac.uk>, 
 Greg Kroah-Hartman <gregkh@suse.de>, 
 Michael Auchter <michael.auchter@ni.com>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>, 
 Rodrigo Alencar <rdealencar@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777468056; l=2426;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=PuiIpU+Ax2bnVFiBydUv+NptiuYYg0kGR4hs6vHFVNQ=;
 b=h4bdcsdiSSPEQpwI0W4uEKKuCXNInOi7kFEi12myLiqogKIwfSYIt46c8r1dbBG5pqws9+uzX
 Vr5d9D2ogffDcNQJwo5CjdPdy99Q+5kGZvtDyW4GNgB4aBEJbR/qF1T
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the first series of three on updating the AD5686 driver.

A bigger patch series was sent before ("Extend device support for AD5686 driver"),
but this is not exactly a v2:

https://lore.kernel.org/r/20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com

This one adds a number of cleanups and fixes, like:
- Refactor include headers (IWYU);
- Remove redundant register definition;
- Drop enum chip id in favor of per-device chip_info structs;
- Fix internal voltage reference control for single-channel devices;
- Acquire lock when doing power down control;
- Fix powerdown control for dual-channel devices;

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Changes in v4:
- Address issues spotted by sashiko.
- Link to v3: https://lore.kernel.org/r/20260428-ad5686-fixes-v3-0-9cff7bd67a15@analog.com

Changes in v3:
- Misc changes like parenthesis removal and line breaks
- Link to v2: https://lore.kernel.org/r/20260427-ad5686-fixes-v2-0-188e05199368@analog.com

Changes in v2:
- Bring fixes first and cleanups later
- Link to v1: https://lore.kernel.org/r/20260426-ad5686-fixes-v1-0-7c946a77794e@analog.com

---
Rodrigo Alencar (13):
      iio: dac: ad5686: fix ref bit initialization for single-channel parts
      iio: dac: ad5686: fix input raw value check
      iio: dac: ad5686: acquire lock when doing powerdown control
      iio: dac: ad5686: fix powerdown control on dual-channel devices
      iio: dac: ad5686: fix overlapping DMA buffers in I2C read
      iio: dac: ad5686: refactor include headers
      iio: dac: ad5686: remove redundant register definition
      iio: dac: ad5686: drop enum id
      iio: dac: ad5686: add of_match table to the spi driver
      iio: dac: ad5686: remove powerdown mask magic number
      iio: dac: ad5686: add control_sync() for single-channel devices
      iio: dac: ad5686: cleanup doc header of local structs
      iio: dac: ad5686: create bus ops struct

 drivers/iio/dac/ad5686-spi.c |  73 ++++--
 drivers/iio/dac/ad5686.c     | 526 +++++++++++++++++++++----------------------
 drivers/iio/dac/ad5686.h     | 120 +++++-----
 drivers/iio/dac/ad5696-i2c.c |  84 +++----
 4 files changed, 419 insertions(+), 384 deletions(-)
---
base-commit: d86db1905add39f905cf9f04252804b359914ed6
change-id: 20260426-ad5686-fixes-63ea68811bdb

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

