From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v5 0/3] Add support for WoM (Wake-on-Motion) feature
Date: Mon, 23 Jun 2025 14:55:51 +0200
Message-Id: <20250623-losd-3-inv-icm42600-add-wom-support-v5-0-4b3b33e028fe@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANdOWWgC/5XNsVLEIBSF4VfZofY6lwskwcr3cLYIAVxGEzIQW
 Z2dvLtkm6hVLP9TfOfGskvBZfZ0urHkSsghTjXUw4kNl356dRBsbUZICokQ3mO2ICBMBcIwSmo
 QobcWrnGE/DHPMS2ADaF3XltDglVpTs6Hz/vLy7n2JeQlpq/7aeHb+j+/cEDQRovW667RSj4v9
 u1xiCPb9EK7KLk6JlIVrdPSeqPJtO63KH6K3TFRVLHteYe9RzL+jyh3seHimCg30SmvlCTkxu/
 iuq7frFYfIsoBAAA=
X-Change-ID: 20250220-losd-3-inv-icm42600-add-wom-support-0620fef9db23
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750683359; l=2368;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=GBV2qWzAZqKcjRCN2BdJiqj86LQYUfioaIFvJYlsEh8=;
 b=mTJkw36Z40Py6pxEwzAIWTCqZzU9opJo1o8b3zv1vdjo9+uw4TUv2tDEBjWxUOFbsGyk5P6fK
 SPJWKwmeFB6Aqxr/D/Rs3FLd3YRXyFmj8kDHFHeEuJaG2FSoiHseHrY
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
Changes in v5:
- Add preliminary patch to move DMA buffers at end of structure.
- Check return code of devm_device_init_wakeup()
- Rebase and rework series to use kernel types
- Link to v4: https://lore.kernel.org/r/20250613-losd-3-inv-icm42600-add-wom-support-v4-0-7e5f554201bf@tdk.com

Changes in v4:
- Avoid mix of gotos and scoped_guard()
- Invert conditionals for better code readability
- Switch to use devm_device_init_wakeup()
- Several code readabilities improvements
- Link to v3: https://lore.kernel.org/r/20250418-losd-3-inv-icm42600-add-wom-support-v3-0-7a180af02bfe@tdk.com

Changes in v3:
- Rewrites following code review
- Link to v2: https://lore.kernel.org/r/20250415-losd-3-inv-icm42600-add-wom-support-v2-0-de94dfb92b7e@tdk.com

Changes in v2:
- change struct order to avoir DMA overflow
- separate wom enable/disable in 2 functions
- delete mutex rework
- Link to v1: https://lore.kernel.org/r/20250220-losd-3-inv-icm42600-add-wom-support-v1-0-9b937f986954@tdk.com

---
Jean-Baptiste Maneyrol (3):
      iio: imu: inv_icm42600: move structure DMA buffers at the end
      iio: imu: inv_icm42600: add WoM support
      iio: imu: inv_icm42600: add wakeup functionality for Wake-on-Motion

 drivers/iio/imu/inv_icm42600/inv_icm42600.h        |  56 +++-
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c  | 294 ++++++++++++++++++++-
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c |   2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c   |  97 ++++++-
 4 files changed, 435 insertions(+), 14 deletions(-)
---
base-commit: b57cb7c47e31244bef6612f271c5dc390f761e17
change-id: 20250220-losd-3-inv-icm42600-add-wom-support-0620fef9db23

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

