From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v2 0/4] inv_icm42600 driver enhancements
Date: Mon, 24 Aug 2026 14:30:06 +0200
Message-Id: <20260824-inv-icm42600-enhacements-v2-0-0040837fde12@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAE45jGoC/3WNQQ6CMBBFr0K6dsy0EaiuvIdhAWWQ0dCatjYaw
 t0tsHb5kv/fm0UgzxTEpZiFp8SBnc2gDoUwY2vvBNxnFgpVhTWegW0CNtMpIwLZsTU0kY0BJCF
 JTdWgKy3y/eVp4M+mvjU7h3f3IBNX37oYOUTnv1s7yXW3Z7TC/5kkAQHrstVa9l1Z1tfYP4/GT
 aJZluUH/uzZYNAAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787574695; l=1889;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=KT6Pf5qqHIW+9eGHA62X1LADJ5xfPm/G15BUFan5T/0=;
 b=Q7B7t1VJDwwaO7S7p5M4XGfgE4R4YzLhgDwS3kuQ4g1IuEc7BMCaRaiMsFAI7gHO2/Y4MwLRR
 IDNs7b/5n14DhdjvjYjiWW5l8Js2OJ8YRdFDo6pI6vueYwdL4DHuyA6
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
Changes in v2:
- Add commentaries for easing understanding of changes.
- Reword commit messages with better explanations.
- Link to v1: https://patch.msgid.link/20260820-inv-icm42600-enhacements-v1-0-075a881db557@tdk.com

To: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>
To: David Lechner <dlechner@baylibre.com>
To: Nuno Sá <nuno.sa@analog.com>
To: Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Jean-Baptiste Maneyrol (4):
      iio: imu: inv_icm42600: sleep before enabling FIFO data
      iio: imu: inv_icm42600: use 2 sensors fixed packet size of 16 bytes
      iio: imu: inv_icm42600: simplify watermark computation by using GCD
      iio: imu: inv_icm42600: do not read FIFO count for watermark it

 drivers/iio/imu/inv_icm42600/inv_icm42600.h        |   4 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c  |  16 ++-
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 112 +++++++++------------
 drivers/iio/imu/inv_icm42600/inv_icm42600_gyro.c   |  16 ++-
 4 files changed, 73 insertions(+), 75 deletions(-)
---
base-commit: 53c022f51fbe540fffee2121ce9ed3e15266c9a4
change-id: 20260709-inv-icm42600-enhacements-1e0e18e6f868

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

