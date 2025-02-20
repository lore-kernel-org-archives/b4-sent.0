From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH 0/2] Add support for WoM (Wake-on-Motion) feature
Date: Thu, 20 Feb 2025 21:52:05 +0100
Message-Id: <20250220-losd-3-inv-icm42600-add-wom-support-v1-0-9b937f986954@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPWVt2cC/x3NQQrCQAxA0auUrA3EVAt6FXFRm4wNtDPDRGuh9
 O4dXL7N/xu4FlOHe7NB0cXcUqw4nxoYxj6+FU2qgYmvxEw4JRds0eKCNswX7oiwF8FfmtG/Oaf
 yQeqYgoabvLiFWspFg63/y+O57wfxvdgRdQAAAA==
X-Change-ID: 20250220-losd-3-inv-icm42600-add-wom-support-0620fef9db23
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740084731; l=1287;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=5IZYGAvISNec6ODnHDxlFeQmX0TyNdXxPLzJQ8d2UkY=;
 b=zsq5ZXe7IAk9rkJgMfcmnCVKRGLV6umI9+L708Hwc+Tc4B+y47mJA50KuBbjP6Yk9VZ48SWW+
 TGccw6K36AGAaxPCtbUYCGfQd71VGEudpShLkPs9IpLHJbjOB19Vfl1
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
Jean-Baptiste Maneyrol (2):
      iio: imu: inv_icm42600: add WoM support
      iio: imu: inv_icm42600: add wakeup functionality for Wake-on-Motion

 drivers/iio/imu/inv_icm42600/inv_icm42600.h        |  49 +++-
 drivers/iio/imu/inv_icm42600/inv_icm42600_accel.c  | 267 ++++++++++++++++++++-
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c |   2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c   | 125 ++++++++--
 4 files changed, 416 insertions(+), 27 deletions(-)
---
base-commit: c0f115a8d97599623294c8e9ec28530e19c1e85b
change-id: 20250220-losd-3-inv-icm42600-add-wom-support-0620fef9db23

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

