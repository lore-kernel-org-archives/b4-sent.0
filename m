From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v3 0/2] iio: imu: inv_icm42600: add hwfifo watermark
 attributes
Date: Wed, 24 Jun 2026 18:21:17 +0200
Message-Id: <20260624-inv-icm42600-add-buffer-hwfifo_attributes-v3-0-5d9a4c662f50@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAP0DPGoC/5WOwQ6CMBAFf8X07Jq2QEVP/ocxBtqtrEYwbakaw
 79bMEavHCd5mXkv5tERerZdvJjDSJ66NkG2XDDdVO0JgUxiJrlUXEkJ1EYgfc0TcqiMgbq3Fh0
 0d0u2O1YhOKr7gB4qjYbnosAsFyz5bg4tPabW/vBh39dn1GEMjIuGfOjcczoTxbj7drMZ3ShAg
 BEbXnKOihvcBXNZ6e7KxmqU/958jlcmr5BqXchig6osf95hGN57p+ppSgEAAA==
X-Change-ID: 20260622-inv-icm42600-add-buffer-hwfifo_attributes-aced0415e341
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782318086; l=1633;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=SH+iQf/6jCyuH7OTIUTPgiXthvl1nWhouagizAV6EYk=;
 b=QDn7tFWxHFnQ1ZExnLlw2mJygw79rADQ7g0xUtMSmFLFkB2i7vu4UWrRFRJtuqA/Fsco/OTTb
 al+jgH0CMjLA1c3/3qdAMW55NJIiep3G8fTX8OHHtwoYCBCJCpYu6N3
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add hwfifo_watermark_* buffer attributes.

There is a preliminary patch for reordering includes first.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
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
      iio: imu: inv_icm42600: reorder includes for buffer module
      iio: imu: inv_icm42600: add buffer hwfifo watermark attributes

 drivers/iio/imu/inv_icm42600/inv_icm42600.h        |  2 ++
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c  |  5 +--
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 42 ++++++++++++++++++++--
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h |  1 +
 drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c   |  5 +--
 5 files changed, 48 insertions(+), 7 deletions(-)
---
base-commit: cc746297b23e89bd5df9f91f3a0ca209e8991763
change-id: 20260622-inv-icm42600-add-buffer-hwfifo_attributes-aced0415e341

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

