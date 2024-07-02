From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 00/20] iio: make masklength __private (round 1)
Date: Tue, 02 Jul 2024 18:02:32 +0200
Message-Id: <20240702-dev-iio-masklength-private-v1-0-98193bf536a6@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAJgkhGYC/x3MSw5AMBAA0KvIrE1SRX2uIhbFYIKSVhpJ4+4ay
 7d5ARxZJgdtEsCSZ8enicjSBMZVm4WQp2iQQhZCZRVO5JH5xEO7bSez3Ctelr2+CYXMx0E2pa5
 qBTG4LM38/HnXv+8H5PZxCGwAAAA=
To: linux-iio@vger.kernel.org, chrome-platform@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Cosmin Tanislav <cosmin.tanislav@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Benson Leung <bleung@chromium.org>, Guenter Roeck <groeck@chromium.org>, 
 Dmitry Rokosov <ddrokosov@sberdevices.ru>, 
 Nicolas Ferre <nicolas.ferre@microchip.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936156; l=3395;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=dYNF6iO2wfFDcJE7eHk31m6ISxbwFVT9boKTTNa+uX8=;
 b=dYayS/sYzYBMk3LDN5MD+QUI9w92ZbUDruyAqtEdvLcUf2ukXZglMWK/T9YrXjvcpEoybuZez
 o4HfrGK/hPaBZK9VUZnwEcX3u3uaHqvVLIvaotmLg8apkuK8x2WJA0s
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Jonathan,

Here it goes the first round of what we discussed in [1] about
annotating .masklength as __private. Patches should be fairly simple so
hopefully I did not messed up much...

Note that in core, there's one place where we're still directly writing
into .masklength (when it's effectively set). The plan is then to
directly use ACCESS_PRIVATE() in there in the same patch where we mark
.masklength as __private.

Note this was only compile tested for arm with allyesconfig.

[1]: https://lore.kernel.org/linux-iio/20240612-dev-iio-scan-private-v1-0-7c75c8e3d30b@analog.com/

---
Nuno Sa (20):
      iio: core: add accessors  'masklength'
      iio: core: make use of iio_get_masklength()
      iio: buffer: make use of iio_get_masklength()
      iio: accel: adxl367: make use of iio_get_masklength()
      iio: accel: adx1372: make use of iio_get_masklength()
      iio: accel: bma180: make use of iio_for_each_active_channel()
      iio: accel: bmc150-accel-core: make use of iio_for_each_active_channel()
      iio: accel: cros_ec_accel_legacy: make use of iio_get_masklength()
      iio: accel: fxls8962af-core: make use of iio_for_each_active_channel()
      iio: accel: msa311: make use of iio_for_each_active_channel()
      iio: accel: sca3300: make use of iio_for_each_active_channel()
      iio: accel: stk8312: make use of iio_for_each_active_channel()
      iio: accel: stk8ba50: make use of iio_for_each_active_channel()
      iio: adc: ad7266: make use of iio_get_masklength()
      iio: adc: ad7298: make use of iio_get_masklength()
      iio: adc: ad799x: make use of iio_get_masklength()
      iio: adc: ad_sigma_delta: use new '.masklength' accessors
      iio: adc: at91_adc: make use of iio_for_each_active_channel()
      iio: imu: adis16475: make use of iio_for_each_active_channel()
      iio: imu: adis16480: make use of iio_for_each_active_channel()

 drivers/iio/accel/adxl367.c                   |  2 +-
 drivers/iio/accel/adxl372.c                   |  2 +-
 drivers/iio/accel/bma180.c                    |  3 +-
 drivers/iio/accel/bmc150-accel-core.c         |  3 +-
 drivers/iio/accel/cros_ec_accel_legacy.c      |  2 +-
 drivers/iio/accel/fxls8962af-core.c           |  3 +-
 drivers/iio/accel/msa311.c                    |  3 +-
 drivers/iio/accel/sca3300.c                   |  3 +-
 drivers/iio/accel/stk8312.c                   |  3 +-
 drivers/iio/accel/stk8ba50.c                  |  3 +-
 drivers/iio/adc/ad7266.c                      |  3 +-
 drivers/iio/adc/ad7298.c                      |  3 +-
 drivers/iio/adc/ad799x.c                      |  3 +-
 drivers/iio/adc/ad_sigma_delta.c              |  6 ++--
 drivers/iio/adc/at91_adc.c                    |  4 +--
 drivers/iio/buffer/industrialio-buffer-cb.c   |  2 +-
 drivers/iio/buffer/industrialio-hw-consumer.c |  4 +--
 drivers/iio/imu/adis16475.c                   |  3 +-
 drivers/iio/imu/adis16480.c                   |  2 +-
 drivers/iio/industrialio-buffer.c             | 50 ++++++++++++---------------
 drivers/iio/industrialio-core.c               |  2 +-
 include/linux/iio/iio.h                       | 18 ++++++++++
 22 files changed, 67 insertions(+), 60 deletions(-)
---
base-commit: 21ab030b8f8b4704c299435e167824ec90c8bab5
change-id: 20240617-dev-iio-masklength-private-023cb295a786
--

Thanks!
- Nuno Sá

