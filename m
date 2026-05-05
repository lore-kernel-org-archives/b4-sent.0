From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v6 00/12] Fixes and cleanups for the AD5686 IIO driver
Date: Tue, 05 May 2026 13:35:01 +0100
Message-Id: <20260505-ad5686-fixes-v6-0-c2d5f7be32be@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPXj+WkC/3XOQU7EMAwF0KuMsiYoThPHYcU9EIskdWciQYsaV
 IFGvTue2VBasfzfel++qsZz5aaeTlc181JbnUYJ+HBS5ZLGM+vaS1bWWDTOok69R0I91C9uGjt
 OSASQ+6yEfMx8P4h4eZV8qe1zmr/v6wvc2n+GFtBGhxIdphBCdPycxvQ2nR/L9K5uS4vd6rDTV
 jQQsfEQY4d00N1W0053omMZhpB7DAn8QbutjjvtROdMAxThxHDQ/ld7AzvtRZtsB+cdkYO/n6/
 r+gNvkWNeoQEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777984508; l=2754;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=QTL82xOz4e77lhCganyluulqrithzLwRJgJ+SEVrS0o=;
 b=AFnOwXIcenbvdgaqnoZ1yb05zzlq7l95VJ/zImtkQUMDy/6zycXEv9kNbDp1tkcgBYIJFb2Ft
 gRMGyzynIOZB1HEvY55BZ11NlY/Qd26xyhXyrcmXzTKrZ7S5Cjq+eDb
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
Rodrigo Alencar (12):
      iio: dac: ad5686: fix ref bit initialization for single-channel parts
      iio: dac: ad5686: fix input raw value check
      iio: dac: ad5686: acquire lock when doing powerdown control
      iio: dac: ad5686: fix powerdown control on dual-channel devices
      iio: dac: ad5686: refactor include headers
      iio: dac: ad5686: remove redundant register definition
      iio: dac: ad5686: drop enum id
      iio: dac: ad5686: add of_match table to the spi driver
      iio: dac: ad5686: add helpers to handle powerdown masks
      iio: dac: ad5686: add control_sync() for single-channel devices
      iio: dac: ad5686: cleanup doc header of local structs
      iio: dac: ad5686: create bus ops struct

 drivers/iio/dac/ad5686-spi.c |  73 ++++--
 drivers/iio/dac/ad5686.c     | 542 ++++++++++++++++++++++---------------------
 drivers/iio/dac/ad5686.h     | 132 ++++++-----
 drivers/iio/dac/ad5696-i2c.c |  80 ++++---
 4 files changed, 438 insertions(+), 389 deletions(-)
---
base-commit: 39b80c5c9830d12d2d6531059001301c4265322a
change-id: 20260426-ad5686-fixes-63ea68811bdb

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

