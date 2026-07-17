From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH 0/2] iio: common: improve InvenSense sample timestamping
Date: Fri, 17 Jul 2026 14:39:39 +0200
Message-Id: <20260717-iio-common-inv-sensors-timestamp-rework-v1-0-d1afee2805cd@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIsiWmoC/yXNTQrCQAxA4auUrA3MFH/Aq4iLOGY0ykxKMq1C6
 d2tuvw2783gbMIOx24G40lctK6Imw7SneqNUa6roQ/9PhziDkUUk5aiFaVO6FxdzbFJYW9UBjR
 +qT2RUo4UiELIW1hrg3GW9+90Ov/t4+XBqX3zsCwfFvNuyIsAAAA=
X-Change-ID: 20260715-iio-common-inv-sensors-timestamp-rework-acf1a0aa00f4
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784291993; l=1194;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=eJ/ZhnSqtVnhlW2YrlsssveGtVix22fBl3oGwtL5XoU=;
 b=VB8/qYpScMTlTMLfFT1t48xXhay/BKoM2YSuoDG2Fwh6e4RZ339UXz1CctLpfA10eOYRxOxTk
 JY9AGd1XFh4CDsthxokfTeDw+V8H4EjkD4ABSH5HIrjnIGKbQGqvf1h
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series improves the InvenSense timestamping mechanism for 2 cases:
when using watermark and for high frequency sampling.

Data arriving by batch because of FIFO watermark will now be all aligned
correctly with the interrupt timestamp and the chip period measurement
will use a minimal period of 20ms to ensure that system latency is
not preventing measurement when using high frequency sampling.

This was tested using inv_icm42600 driver when using maximum FIFO
watermark and when using 1kHz sampling frequency.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Jean-Baptiste Maneyrol (2):
      iio: invensense: better timestamp alignment when using watermark
      iio: invensense: improve period measurement by using a longer delay

 .../iio/common/inv_sensors/inv_sensors_timestamp.c | 86 +++++++++++-----------
 include/linux/iio/common/inv_sensors_timestamp.h   |  6 ++
 2 files changed, 51 insertions(+), 41 deletions(-)
---
base-commit: aa58ecc73466d0cb8c418de98e2225490bf600e3
change-id: 20260715-iio-common-inv-sensors-timestamp-rework-acf1a0aa00f4

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

