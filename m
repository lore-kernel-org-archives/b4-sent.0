From: Joshua Crofts <joshua.crofts1@gmail.com>
Subject: [PATCH 0/8] iio: magnetometer: ak8975: driver cleanup
Date: Thu, 07 May 2026 16:35:49 +0200
Message-Id: <20260507-magnetometer-fixes-post-pickup-v1-0-37827ca68fb3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEWj/GkC/x3MQQrDIBBG4auEWXfAhsZCr1K6sPonHUpUHFMKk
 rtHsvzg8RopikDpMTQq+IlKih3Xy0D+4+ICltBNoxmtmcydV7dE1LSiovAsfyjnpJWz+O+W2dv
 g3iFYO0836pNccEb98Xzt+wFpEQVYcAAAAA==
X-Change-ID: 20260507-magnetometer-fixes-post-pickup-c6dabdd66f54
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778164567; l=1319;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=gbLkSW4l1FISiUVd0zkqtnIJxWy4VPWhr3yQiYSqkNA=;
 b=SPGwRFy1d/APvdUuHk+jVct1YlcqLZzLFmqSeo7g5pBePTAcgeQfkwssqRBgFlR3CgroR9HvS
 rYpGg3uu5d8DNWiT1H7Ez7NtcDI2ClcAug2EQ2jlMxXmEURdrBki9lD
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series is a continuation of the previous ak8975 driver cleanup
effort, as most of the patches were picked.

Changes include:
- using BIT() and GENMASK() macros
- moving to devm_* resource management
- adding a scan index enum
- moving from using wait loops to iopoll functions
- various code style changes

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
Andy Shevchenko (5):
      iio: magnetometer: ak8975: switch to using managed resources
      iio: magnetometer: ak8975: consistently use 'data' parameter
      iio: magnetometer: ak8975: unify messages with help of dev_err_probe()
      iio: magnetometer: ak8975: use temporary variable for struct device
      iio: magnetometer: ak8975: make use of the macros from bits.h

Joshua Crofts (3):
      iio: magnetometer: ak8975: modernize polling loops with iopoll() macros
      iio: magnetometer: ak8975: check if gpiod read was successful
      iio: magnetometer: ak8975: add scan mask index enum

 drivers/iio/magnetometer/ak8975.c | 268 +++++++++++++++++++-------------------
 1 file changed, 134 insertions(+), 134 deletions(-)
---
base-commit: 74d173f29572951629d1e0b7456b424006e51b87
change-id: 20260507-magnetometer-fixes-post-pickup-c6dabdd66f54

Best regards,
-- 
Joshua Crofts <joshua.crofts1@gmail.com>

