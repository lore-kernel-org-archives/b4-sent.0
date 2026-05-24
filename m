From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v7 0/8] Fixes and cleanups for the AD5686 IIO driver
Date: Sun, 24 May 2026 11:17:00 +0100
Message-Id: <20260524-ad5686-fixes-v7-0-b6bf395d08bd@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABzQEmoC/3XQTU7EMAwF4KuMsiYoThPHYcU9EIv8uDORoEUtq
 kCj3h3PbCitWD5b35Plq5p5ajyrp9NVTby0uY2DhPBwUuWShjPrViUraywaZ1Gn6pFQ9+2LZ40
 dJyQCyDUrIR8T3xciXl4lX9r8OU7f9/YFbtN/ihbQRocSHaYQQnT8nIb0Np4fy/iubk2L3eqw0
 1Y0ELHxEGOHdNDdVtNOd6Jj6fuQK4YE/qDdVseddqJzph6KcGI4aP+rvYGd9qJNtr3zjsjB8XL
 car/TKLrY6uV07mz++7V1XX8AMLaomt8BAAA=
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
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779617840; l=2669;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=iLaDup/VAr36l8p281EDtTj0H41cn1wISQs1uP+345Y=;
 b=pJkDXANbpV/nZm/XAprwdEdj9iuRo9KnSTg6gl4ASWxWVw62KWGqVmi+G5BiVTQAzTUqKhh87
 b5i8YuPrrKYCNLXFFIls7P9lsaCcBxdtsdipclUvkEa6hzxU3GRV1Ab
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the first series of three on updating the AD5686 driver.

A bigger patch series was sent before ("Extend device support for AD5686 driver"):

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
Changes in v7:
- Drop fixes (already accepted).
- Use named fields in device tables.
- Link to v6: https://lore.kernel.org/r/20260505-ad5686-fixes-v6-0-c2d5f7be32be@analog.com

Changes in v6:
- Protect powerdown masks on read access too.
- Minor changes to power down handling and constants.
- Link to v5: https://lore.kernel.org/r/20260501-ad5686-fixes-v5-0-0b2f45488418@analog.com

Changes in v5:
- Drop I2C read operation changes.
- Create helpers for reading and writing powerdown mask bits
- Link to v4: https://lore.kernel.org/r/20260429-ad5686-fixes-v4-0-bb8f1cbd68e1@analog.com

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
Rodrigo Alencar (8):
      iio: dac: ad5686: refactor include headers
      iio: dac: ad5686: remove redundant register definition
      iio: dac: ad5686: drop enum id
      iio: dac: ad5686: add of_match table to the spi driver
      iio: dac: ad5686: add helpers to handle powerdown masks
      iio: dac: ad5686: add control_sync() for single-channel devices
      iio: dac: ad5686: cleanup doc header of local structs
      iio: dac: ad5686: create bus ops struct

 drivers/iio/dac/ad5686-spi.c |  73 ++++--
 drivers/iio/dac/ad5686.c     | 528 +++++++++++++++++++++----------------------
 drivers/iio/dac/ad5686.h     | 133 +++++------
 drivers/iio/dac/ad5696-i2c.c |  80 ++++---
 4 files changed, 418 insertions(+), 396 deletions(-)
---
base-commit: bbc109ae655c8a5d4db117fea01947eb6bf51e71
change-id: 20260426-ad5686-fixes-63ea68811bdb

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

