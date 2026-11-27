From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Subject: [PATCH v2 0/7] HID: iio: Unify probe-path logging
Date: Fri, 27 Nov 2026 16:03:55 +0530
Message-Id: <20261127-19-oct-hid-iio-unified-print-framework-v2-0-3f476fe1a940@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAJNcCWsC/42OTQ6CMBSEr2K69pm2CBVX3sOwgP7AU2lJW1BDu
 LsFLmAymy+ZzDczCdqjDuR6mInXEwZ0NgE/HojsattqQJWYcMoLRlkJKU5G6FABooPRokGtYPB
 oIxhf9/rt/BMyeRHiLJiRIiNpbPDa4GcT3audw9g8tIzr+troMETnv9uTia29Xcpo/q90YkCBN
 llBVZnnXJW3tq/xdZKuJ9WyLD8rOCJz7gAAAA==
X-Change-ID: 20261019-19-oct-hid-iio-unified-print-framework-3c877471fc73
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Joshua Crofts <crofts@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795775655; l=3783;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=bpNV8vBzENgP8GtCrU3v7oWc2k9XQlhvPB2UVdV3Xh8=;
 b=CbUH6/t9LfnZL7SYM7siPLQuJzPYug4GGTM2/cUjHt7j7sKOfcQ3f5a2hPrTWNFudMgHMVCiT
 bfDEaIJ2agLATa5lb8CW9zlWUxXNs0EFAUwAC8VdCKNcTqq45MSW6gO
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
Changes in v2:
- Following suggestion of Joshua, remove the comparison and change the
  checks to `if (ret)` as respective devm_*() API `return 0` on success.
- Link to v1: https://patch.msgid.link/20261105-19-oct-hid-iio-unified-print-framework-v1-0-0b360d9552d9@gmail.com

To: Jiri Kosina <jikos@kernel.org>
To: Jonathan Cameron <jic23@kernel.org>
To: Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>
To: David Lechner <dlechner@baylibre.com>
To: Nuno Sá <nuno.sa@analog.com>
To: Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org
Cc: linux-iio@vger.kernel.org

---
Sanjay Chitroda (7):
      iio: Remove redundant probe error messages for HID device drivers
      iio: Remove redundant devm_kmemdup() allocation failure messages
      iio: magnetometer: hid-sensor-magn-3d: drop redundant probe error messages
      iio: Use dev_err_probe() in HID IIO device drivers
      iio: add probe error messages to hid humidity and temperature drivers
      iio: Simplify trigger setup error checks
      iio: Simplify callback registration error checks

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
base-commit: 39508411b82d4dc29dd245bb471ec9ecc1111c9d
change-id: 20261019-19-oct-hid-iio-unified-print-framework-3c877471fc73

Best regards,
--  
Sanjay Chitroda <sanjayembeddedse@gmail.com>

