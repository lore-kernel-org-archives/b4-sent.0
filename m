From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v4 0/2] iio: imu: inv_icm42600: add hwfifo watermark
 attributes
Date: Thu, 25 Jun 2026 14:24:51 +0200
Message-Id: <20260625-inv-icm42600-add-buffer-hwfifo_attributes-v4-0-8b4c8bfa96d7@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABMePWoC/52OwU7EIBRFf2XC2mceFLB15X8YYyg87NNMa4CiZ
 tJ/l44x6nJcnuTmnHsSmRJTFreHk0hUOfMyN9BXB+EnNz8RcGgsFCqLVinguQL7o26I4EKAcY2
 REkxvkePy6EpJPK6FMjhPAbU01Gkpmu81UeT3c+v+4YvzOj6TL3tgX0ycy5I+zmeq3Hff3e6Cb
 pUgIcgBe0SyGOiuhJdrvxzFXq3qt1df4lXNK5W9McoMZPv+r7f7t7cDBBMGp721Khr88W7b9gn
 b6OgnogEAAA==
X-Change-ID: 20260622-inv-icm42600-add-buffer-hwfifo_attributes-aced0415e341
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782390310; l=2106;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=6rma1kTZbSPPl/oep7CF0HWuRcH1fnVvL/CiMdexe64=;
 b=PSZoOvlVZvLa5HUvoc4JN/BJQ4uf8xxzAcFA5yb0drcyRdSGq9TAiF0k28zHPLuzPWrxAbF/c
 XRTyhT4U9w9BTcWnnIwpLu2D3Dg5H0y+oTCWNHkdfmPx65/nilloC12
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add hwfifo_watermark_* buffer attributes.

There is a preliminary patch for reordering includes first.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Changes in v4:
- Rework headers fix to just reorder includes but for all driver
  sources.
- Link to v3: https://patch.msgid.link/20260624-inv-icm42600-add-buffer-hwfifo_attributes-v3-0-5d9a4c662f50@tdk.com

Changes in v3:
- Add a preparatory patch for reordering includes.
- Use IIO_DEVICE_ATTR_RO.
- Link to v2: https://patch.msgid.link/20260624-inv-icm42600-add-buffer-hwfifo_attributes-v2-1-12675259e688@tdk.com

Changes in v2:
- Delete trailing comma after NULL terminator
- Link to v1: https://patch.msgid.link/20260623-inv-icm42600-add-buffer-hwfifo_attributes-v1-1-d190800e60de@tdk.com

To: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>
To: David Lechner <dlechner@baylibre.com>
To: Nuno Sá <nuno.sa@analog.com>
To: Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Jean-Baptiste Maneyrol (2):
      iio: imu: inv_icm42600: reorder all driver headers
      iio: imu: inv_icm42600: add buffer hwfifo watermark attributes

 drivers/iio/imu/inv_icm42600/inv_icm42600.h        | 10 +++--
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c  | 18 +++++----
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 43 ++++++++++++++++++++--
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h |  3 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c   | 12 +++---
 drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c   | 16 ++++----
 drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c    |  8 ++--
 drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c    |  8 ++--
 drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c   |  3 +-
 9 files changed, 84 insertions(+), 37 deletions(-)
---
base-commit: cc746297b23e89bd5df9f91f3a0ca209e8991763
change-id: 20260622-inv-icm42600-add-buffer-hwfifo_attributes-aced0415e341

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

