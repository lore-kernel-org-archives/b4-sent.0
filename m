From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v3 0/2] Add support for WoM (Wake-on-Motion) feature
Date: Fri, 18 Apr 2025 18:19:01 +0200
Message-Id: <20250418-losd-3-inv-icm42600-add-wom-support-v3-0-7a180af02bfe@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHV7AmgC/5XNsQ6CMBSF4Vcxnb2m3BawTr6HcQB6K41CSYtVQ
 3h3Cwurjv8ZvjOxQN5SYKfdxDxFG6zrU4j9jjVt1d8IrE7NkGPOETk8XNAgwPYRbNNJLDiHSmt
 4uQ7CcxicH4EXyA0ZpWsULEmDJ2Pf68vlmrq1YXT+s57GbFn/82MGHFStRGnUsVC5PI/6fmhcx
 xY94ibKLP9NxCRqUlKbWmFd0ibO8/wF2XyP9CYBAAA=
X-Change-ID: 20250220-losd-3-inv-icm42600-add-wom-support-0620fef9db23
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744993145; l=1697;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=I9rqPEmih+WGjr4eCnBNMkrmqHo+NChbgbYmv45VSAg=;
 b=GPV7ryHOqM2AW7JlcGoNgdjFCjP9uDm5KlQVMxRi2Rwd+w5C4E+i+zmbW1/w4Y48icXzoiA2O
 gtEEOcCI2sACA0LYHGV/Gm6+P9PtDhjiS1zA14vH97bKhXEXHkWTnzl
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Similar to feature present in older chip, it compares the magnitude of
the last 2 accel samples against a threshold and returns an interrupt
even if the value is higher.

WoM maps best to accel x|y|z ROC event. This series add system wakeup
functionality if WoM is on and wakeup is enabled when system suspends.

This series also prepare the driver for supporting further APEX
features like pedometer, tilt, ... It introduces an apex structure that
will hold all APEX settings and track the enable state.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Changes in v3:
- Rewrites following code review
- Link to v2: https://lore.kernel.org/r/20250415-losd-3-inv-icm42600-add-wom-support-v2-0-de94dfb92b7e@tdk.com

Changes in v2:
- change struct order to avoir DMA overflow
- separate wom enable/disable in 2 functions
- delete mutex rework
- Link to v1: https://lore.kernel.org/r/20250220-losd-3-inv-icm42600-add-wom-support-v1-0-9b937f986954@tdk.com

---
Jean-Baptiste Maneyrol (2):
      iio: imu: inv_icm42600: add WoM support
      iio: imu: inv_icm42600: add wakeup functionality for Wake-on-Motion

 drivers/iio/imu/inv_icm42600/inv_icm42600.h        |  56 +++-
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c  | 282 ++++++++++++++++++++-
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c |   2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c   |  97 ++++++-
 4 files changed, 423 insertions(+), 14 deletions(-)
---
base-commit: 3159d40a2ca0ae14e69e1cae8b12f04c933d0445
change-id: 20250220-losd-3-inv-icm42600-add-wom-support-0620fef9db23

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

