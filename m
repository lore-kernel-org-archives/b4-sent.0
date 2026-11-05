From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Subject: [PATCH 0/5] HID: iio: Unify probe-path logging
Date: Thu, 05 Nov 2026 18:11:42 +0530
Message-Id: <20261105-19-oct-hid-iio-unified-print-framework-v1-0-0b360d9552d9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIZ57GoC/yXNwQrCMBCE4Vcpe3ahacWoryIearKxo5iUTapC6
 bsbFebyXf5ZKItCMh2bhVSeyEixwmwacuMQr8Lw1dS13c605sB1yRUe4RlIPEcEiOdJEQsHHR7
 ySnrn3u2t3VoTnO2pxiaVgPfv6HT+O8+Xm7jyrdO6fgBS4dcKigAAAA==
X-Change-ID: 20261019-19-oct-hid-iio-unified-print-framework-3c877471fc73
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793882513; l=3071;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=KUIwC7C4lmG/Hcha3xTeg2sd4BInW8QwNzzTWWfozpA=;
 b=w1TLm6HD6ssb/ttsKDr0UeUvh0swdJPOkFXTyVI2ZLAV41S+CqJuxk6MtDwqzKZG+O5ehR8/N
 NSmC4YFukw9DwdCxexByvcrQrLOiZWCVnbHoEbzQt2xCk9y5Xr1G5CM
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series provides consistent support for logs in probe() path for
HID IIO drivers with suggestion and input from Jonathan.

This is followup series on top of multiple sub-series submitted for HID
IIO device drivers which included fixes, devm support, cleanup and using
preferred kernel coding style. This series adopts a common logging
approach throughout the HID IIO device drivers in probe path.

The result is more consistent error reporting and improved
maintainability across the HID IIO subsystem for following drivers:
find drivers/iio/ -name "*hid*.c"
drivers/iio/orientation/hid-sensor-rotation.c
drivers/iio/orientation/hid-sensor-incl-3d.c
drivers/iio/gyro/hid-sensor-gyro-3d.c
drivers/iio/pressure/hid-sensor-press.c
drivers/iio/temperature/hid-sensor-temperature.c
drivers/iio/common/hid-sensors/hid-sensor-trigger.c
drivers/iio/common/hid-sensors/hid-sensor-attributes.c
drivers/iio/humidity/hid-sensor-humidity.c
drivers/iio/light/hid-sensor-prox.c
drivers/iio/light/hid-sensor-als.c
drivers/iio/magnetometer/hid-sensor-magn-3d.c
drivers/iio/position/hid-sensor-custom-intel-hinge.c
drivers/iio/accel/hid-sensor-accel-3d.c

Additionally, I have kept changes specific to logical diff instead of
driver specific and covered all HID IIO device drivers.

Testing:
  - Compiled with W=1 for each patch in series
PS:
- Sashiko reported an issue in a different driver and noted that it is not
  introduced by this series. I have taken this feedback into account and
  will address the actual issue in a separate series focus on that driver.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
Sanjay Chitroda (5):
      iio: Remove redundant probe error messages for HID device drivers
      iio: Remove redundant devm_kmemdup() allocation failure messages
      iio: magnetometer: hid-sensor-magn-3d: drop redundant probe error messages
      iio: Use dev_err_probe() in HID IIO device drivers
      iio: add probe error messages to hid humidity and temperature drivers

 drivers/iio/accel/hid-sensor-accel-3d.c            | 27 +++++---------
 drivers/iio/gyro/hid-sensor-gyro-3d.c              | 24 ++++---------
 drivers/iio/humidity/hid-sensor-humidity.c         |  4 +--
 drivers/iio/light/hid-sensor-als.c                 | 20 ++++-------
 drivers/iio/light/hid-sensor-prox.c                | 20 ++++-------
 drivers/iio/magnetometer/hid-sensor-magn-3d.c      | 41 ++++++----------------
 drivers/iio/orientation/hid-sensor-incl-3d.c       | 24 ++++---------
 drivers/iio/orientation/hid-sensor-rotation.c      | 20 ++++-------
 .../iio/position/hid-sensor-custom-intel-hinge.c   | 20 ++++-------
 drivers/iio/pressure/hid-sensor-press.c            | 24 ++++---------
 drivers/iio/temperature/hid-sensor-temperature.c   |  4 +--
 11 files changed, 69 insertions(+), 159 deletions(-)
---
base-commit: 20ce8ef9c9e04cd6c5ae0422e251a9b5936c6b7c
change-id: 20261019-19-oct-hid-iio-unified-print-framework-3c877471fc73

Best regards,
--  
Sanjay Chitroda <sanjayembeddedse@gmail.com>

