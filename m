From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v4 0/2] Add support for WoM (Wake-on-Motion) feature
Date: Fri, 13 Jun 2025 09:34:25 +0200
Message-Id: <20250613-losd-3-inv-icm42600-add-wom-support-v4-0-7e5f554201bf@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIHUS2gC/5XNvQ7CIBSG4VsxzB5zeqA/OHkfxqEUUKItDVTUm
 N676KJuOr7f8Hx3Fk1wJrL14s6CSS46P+QQywXrDu2wN+B0bkZIJRIhnHzUwMENCVzXC6oQodU
 aLr6HeB5HHybAitAaK7UizrI0BmPd9fWy3eU+uDj5cHudpuK5/uenAhCkkry2sqlkKTaTPq463
 7OnnugtiqL8TaQsaiOFtkqSqs23yD/F5jeRZ7FuiwZbi6TshzjP8wO80NbpeAEAAA==
X-Change-ID: 20250220-losd-3-inv-icm42600-add-wom-support-0620fef9db23
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749800071; l=2005;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=TwO64dudIgSMsHCJyLSriUaJU7jxFNj2lwY1rcJ4tMI=;
 b=Pmoj3isAVCMsHd+CoUSknvOHXDcqng1pbj168wEOv4VwC4WH0CffPaQ+h59eUfroh23ux1DkL
 MTpT4/X8u6vA8XkIbHdpWLAUCoP2m50YmEL+gnHUMcvaUysmaZLS0FV
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
Jean-Baptiste Maneyrol (2):
      iio: imu: inv_icm42600: add WoM support
      iio: imu: inv_icm42600: add wakeup functionality for Wake-on-Motion

 drivers/iio/imu/inv_icm42600/inv_icm42600.h        |  56 +++-
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c  | 292 ++++++++++++++++++++-
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c |   2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c   |  97 ++++++-
 4 files changed, 433 insertions(+), 14 deletions(-)
---
base-commit: 4c6073fec2fee4827fa0dd8a4ab4e6f7bbc05ee6
change-id: 20250220-losd-3-inv-icm42600-add-wom-support-0620fef9db23

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

