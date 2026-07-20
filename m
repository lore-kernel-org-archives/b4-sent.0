From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Subject: [PATCH 00/10] HID: iio: use local struct device
Date: Mon, 20 Jul 2026 15:10:12 +0530
Message-Id: <20260720-hid-iio-local-struct-device-v1-0-74496fee6327@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPzsXWoC/yXMQQqDMBBA0avIrDsQIzWlV5Eu4mSsU8RIJoog3
 t20Xb7F/wcoJ2GFZ3VA4k1U4lxQ3yqg0c9vRgnFYI1tjbMGRwkoEnGK5CfUnFbKGEpJjHVo/GC
 da+8PD+WwJB5k/92719+69h+m/F3CeV53QnWnfwAAAA==
X-Change-ID: 20260720-hid-iio-local-struct-device-1d3af277658a
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784540423; l=1897;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=4kUvBf5if1nv9lCc3XUy9wkiVtwtLor6LCOjrtnhe6A=;
 b=uI65hJeL5pfBPSyjC0Ga+0XuXNfEHKdMLNm+96nFUUs6pvYwp6QxFycRINUWrLYkJOTvY4yqC
 RkuOxHpLJJ6B/0ZWYzxDDki3gTYIopSCzH1kK6ow0JRv5+V1Z31FYuH
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

Introduce a local struct device pointer derived from &pdev->dev.
This avoids repeated &pdev->dev usage and improves readability.

Prepratory series to convert all HID IIO driver to devm.

Testing:
  - Compiled with W=1 for each patch in series

---
Sanjay Chitroda (10):
      iio: humidity: hid-sensor-humidity: use local struct device
      iio: gyro: hid-sensor-gyro-3d: use local struct device
      iio: accel: hid-sensor-accel-3d: use local struct device
      iio: light: hid-sensor-als: use local struct device
      iio: light: hid-sensor-prox: use local struct device
      iio: magnetometer: hid-sensor-magn-3d: use local struct device
      iio: orientation: hid-sensor-incl-3d: use local struct device
      iio: orientation: hid-sensor-rotation: use local struct device
      iio: position: hid-sensor-custom-intel-hinge: use local struct device
      iio: pressure: hid-sensor-press: use local struct device

 drivers/iio/accel/hid-sensor-accel-3d.c            | 22 +++++------
 drivers/iio/gyro/hid-sensor-gyro-3d.c              | 19 +++++-----
 drivers/iio/humidity/hid-sensor-humidity.c         |  7 ++--
 drivers/iio/light/hid-sensor-als.c                 | 15 ++++----
 drivers/iio/light/hid-sensor-prox.c                | 15 ++++----
 drivers/iio/magnetometer/hid-sensor-magn-3d.c      | 43 ++++++++++------------
 drivers/iio/orientation/hid-sensor-incl-3d.c       | 20 +++++-----
 drivers/iio/orientation/hid-sensor-rotation.c      | 24 ++++++------
 .../iio/position/hid-sensor-custom-intel-hinge.c   | 17 +++++----
 drivers/iio/pressure/hid-sensor-press.c            | 19 +++++-----
 10 files changed, 100 insertions(+), 101 deletions(-)
---
base-commit: 36c12dbda81c284d72f3c64689461647497b643b
change-id: 20260720-hid-iio-local-struct-device-1d3af277658a

Best regards,
--  
Sanjay Chitroda <sanjayembeddedse@gmail.com>

