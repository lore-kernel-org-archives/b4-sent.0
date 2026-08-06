From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Subject: [PATCH v5 00/13] HID: iio: Introduce devm_ APIs for HID sensors
Date: Thu, 06 Aug 2026 17:55:46 +0530
Message-Id: <20260806-28-apr-iio-redundant-argument-v5-temp-v5-0-f1f92c1d830f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEt9dGoC/yXNywqDMBSE4VeRs+6BEDXYvkrpIjWjPQVjyEUE8
 d2btrv5Nv8clBAFiW7NQRGbJFl9RX9paHxZP4PFVZNW2iijWtYD2xBZZOUIV7yzPrONc1lQx9Z
 zxhK4Q3cF3GBaO1FthYhJ9t/P/fF3Ks83xvyN03l+ADEExK+JAAAA
X-Change-ID: 20260603-28-apr-iio-redundant-argument-v5-temp-4e49eed863af
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Zhang Lixu <lixu.zhang@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786019201; l=4907;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=DfjdwMIzg3OAVxzDZ8MAQUpgXBwQf4rJVCbZ/FlrV28=;
 b=QyDfZ5gaMB5Zz/DpqD2Y/mSYIwZYCJliiu3/io9hmI+hLoOro51V/bBklk33PMPDLEPGCfaZ4
 oo1XGuqesicCF7PcA6SDaVZlEuLia3r1bGVLmR7IskJQ0a5eRP+dzDN
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Following feedback from reviewers and Srinivas, v4 series was split
into two additional sub-series to perform cleanup and preparatory work
before adding devm support:
- HID: iio: warning clean up and prefer kernel coding style
  https://lore.kernel.org/all/20260707-15-jun-hid-iio-alignment-v3-0-8791574ad0fe@gmail.com/
- HID: iio: basic clean up for usage_id
  https://lore.kernel.org/all/20260610-6-june-hid-iio-correct-usage-id-v2-0-c3c5f0720493@gmail.com/

Both series have been merged into IIO tree. This series introduces
device-managed APIs and converts HID IIO sensor drivers to use the new
devm-managed resources.

changes in v5:
- With input from Jonathan, convert all HID IIO drivers to use
  fully devm instead of partial or specific API; this is potential
  goal and validation on that will reduce multiple validation cycle.
- Rebase changes on latest iio/testing tree and resolve merge conflict
- Resolve mail client issue as v4 series was splitted into sub-series
- v4 series -> https://lore.kernel.org/all/20260524192059.1193716-1-sanjayembedded@gmail.com/
changes in v4:
- Extend the series to cover remaining HID IIO drivers with devm API usage
- Reorder patches to place cleanup and warning fix at beginning and,
  devm-related changes toward the end based on feedback from David
- v3 series -> https://lore.kernel.org/all/20260509101040.791404-1-sanjayembedded@gmail.com/
changes in v3:
- Added cleanup and prepratory changes before adding devm_ API
  conversion based on self review: 0002, 0004, 0006, 0007 and 0008
- Address andy's review comment on commit message and coding style
- v2 series -> https://lore.kernel.org/all/20260429175918.2541914-1-sanjayembedded@gmail.com/
changes in v2:
- Following input from Jonathan and Andy, squash initial patch v1
  series in single change as individual change should not break anything
- Add devm API support and two driver using the same
- v1 series -> https://lore.kernel.org/all/20260428071613.1134053-1-sanjayembedded@gmail.com/

Testing:
  - Compiled with W=1 for each patch in series
  - Build-tested on QEMU x86_64

PS:
- Sashiko reported an issue in a different driver and noted that it is not
  introduced by this series. I have taken this feedback into account and
  will address the actual issue in a separate series focus on that driver.

---
Sanjay Chitroda (13):
      iio: hid-sensors: remove unused iio_dev argument
      iio: hid-sensors: introduce device managed API
      HID: hid-sensor-hub: introduce device managed API
      iio: gyro: hid-sensor-gyro-3d: convert probe and teardown to devm-managed resources
      iio: accel: hid-sensor-accel-3d: convert probe and teardown to devm-managed resources
      iio: humidity: hid-sensor-humidity: convert probe and teardown to devm-managed resources
      iio: light: hid-sensor-prox: convert probe and teardown to devm-managed resources
      iio: light: hid-sensor-als: convert probe and teardown to devm-managed resources
      iio: magnetometer: hid-sensor-magn-3d: convert probe and teardown to devm-managed resources
      iio: orientation: hid-sensor-incl-3d: convert probe and teardown to devm-managed resources
      iio: orientation: hid-sensor-rotation: convert probe and teardown to devm-managed resources
      iio: position: hid-sensor-custom-intel-hinge: convert probe and teardown to devm-managed resources
      iio: pressure: hid-sensor-press: convert probe and teardown to devm-managed resources

 drivers/hid/hid-sensor-hub.c                       | 32 +++++++++++++++++
 drivers/iio/accel/hid-sensor-accel-3d.c            | 40 +++++----------------
 .../iio/common/hid-sensors/hid-sensor-trigger.c    | 21 +++++++++--
 .../iio/common/hid-sensors/hid-sensor-trigger.h    |  5 +--
 drivers/iio/gyro/hid-sensor-gyro-3d.c              | 41 +++++----------------
 drivers/iio/humidity/hid-sensor-humidity.c         | 38 +++++---------------
 drivers/iio/light/hid-sensor-als.c                 | 39 +++++---------------
 drivers/iio/light/hid-sensor-prox.c                | 40 +++++----------------
 drivers/iio/magnetometer/hid-sensor-magn-3d.c      | 41 +++++----------------
 drivers/iio/orientation/hid-sensor-incl-3d.c       | 42 +++++-----------------
 drivers/iio/orientation/hid-sensor-rotation.c      | 40 +++++----------------
 .../iio/position/hid-sensor-custom-intel-hinge.c   | 38 ++++----------------
 drivers/iio/pressure/hid-sensor-press.c            | 41 +++++----------------
 drivers/iio/temperature/hid-sensor-temperature.c   |  4 +--
 include/linux/hid-sensor-hub.h                     | 24 +++++++++++++
 15 files changed, 163 insertions(+), 323 deletions(-)
---
base-commit: 350d1fb9204b13c5f95e511e98b8bcb47574d425
change-id: 20260603-28-apr-iio-redundant-argument-v5-temp-4e49eed863af

Best regards,
--  
Sanjay Chitroda <sanjayembeddedse@gmail.com>

