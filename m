From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH 0/4] inv_icm42600 driver enhancements
Date: Thu, 20 Aug 2026 21:02:36 +0200
Message-Id: <20260820-inv-icm42600-enhacements-v1-0-075a881db557@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAExPh2oC/yXMQQrCQAxG4auUrA1kioyjVxEXdfxrIzTKpC1C6
 d0ddfkt3lvJURROp2algkVdn1YRdg3lobM7WG/V1Eob5SBHVltY87ivFIYNXcYIm5wDBCEh9ik
 mqvmroNf3b32+/O3z9YE8fX+0bR+r9bR5fAAAAA==
X-Change-ID: 20260709-inv-icm42600-enhacements-1e0e18e6f868
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787252562; l=1371;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=lrkb5DHW4nekBm62Ptn6gdrtseZG3P/khBB49osjqIk=;
 b=z2r01HbY7zKX1LD8h1H8bd6vdUs1Q9v5pDWgsZlihr0aSoKmfN7NY7fMlBq5t2eexTsxiwfn+
 p1mb8TdnTPIApzKDAPfzDAyjME0nJREF58RrUjpr04xhqIUppZPqd85
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series add enhancements patches to inv_icm42600 driver.

It includes:
1. Move of MEMS stabilization sleep before FIFO configuration to avoid
   pushing incorrect data.
2. Use a fixed FIFO frame of 16 bits to avoid a bug of dynamic FIFO
   configuration changed triggered by the sleep move.
3. Simplify watermark computation using gcd.
4. Enhance support of high frequency streaming by avoiding read of FIFO
   count for watermark interrupt.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Jean-Baptiste Maneyrol (4):
      iio: imu: inv_icm42600: sleep before enabling FIFO data
      iio: imu: inv_icm42600: use 2 sensors fixed packet size of 16 bytes
      iio: imu: inv_icm42600: simplify watermark computation by using gcd
      iio: imu: inv_icm42600: do not read FIFO count for watermark it

 drivers/iio/imu/inv_icm42600/inv_icm42600.h        |   4 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c  |  12 ++-
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 109 +++++++++------------
 drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c   |  12 ++-
 4 files changed, 62 insertions(+), 75 deletions(-)
---
base-commit: 53c022f51fbe540fffee2121ce9ed3e15266c9a4
change-id: 20260709-inv-icm42600-enhacements-1e0e18e6f868

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

