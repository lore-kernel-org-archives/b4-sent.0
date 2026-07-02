From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Subject: [PATCH v2 0/6] HID: iio: warning clean up and prefer kernel coding
 style
Date: Thu, 02 Jul 2026 21:47:57 +0530
Message-Id: <20260702-15-jun-hid-iio-alignment-v2-0-b87f01f5efbc@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADWPRmoC/yXMwQqDMBCE4VeRPXfBRhtpX6V4SHSrI+1aEhVBf
 HdTC3P5DvNvFCVAIj2yjYIsiBg1wVwyanqnnTDaZDK5sbm93jhtmJV7tAyM7N7o9CM6cWm9d5W
 p7l4KSvdvkBfWM/2s/46zH6SZfj3a9wO6eN4PfAAAAA==
X-Change-ID: 20260615-15-jun-hid-iio-alignment-46bba7279be3
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>, 
 Maxwell Doose <m32285159@gmail.com>, Zhang Lixu <lixu.zhang@intel.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783009082; l=3144;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=H84tp6VY6Sam5ASd9ZGje9vIpeCKL1iSSCeKb73Z8gI=;
 b=wqIOthKGsiN2FGrNz3Q8Wa0ak//xtQXTL+FMLmzUnGXhvwxvFDN7GEcvPjwKZOyi1qlll0Pgr
 dDOFyxpjheQBywREcauC0R+MIzPgt3bZj5oW2LcWW2W7g94jgU80XO9
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

This series updates HID sensor IIO drivers to address checkpatch
warnings, improves readability and compliance with kernel coding style.

The changes are:
  - replacing explicit NULL comparisons with implicit pointer checks;
  - adjusting indentation and alignment;
  - reformatting multi-line function declarations for improved
    readability and consistency.
  - use common device for devres framework;

While updating alignment and line wrapping, function parameters are
grouped more logically and common callback signatures are formatted
consistently across HID sensor IIO drivers.

Testing:
  - Compiled with W=1 for each patch in the series

---
   Changes in v2:
   - Following input from Joshua and Maxwell squash all related changes
     in single change as this is code churn.
   - Following input from Andy (re-)split function argument/parameter
     logically.
   - Added review tag of Maxwell to implicit NULL check change while
     drop for parenthesis alignemnt to have a fresh review.
   - Link to v1: https://lore.kernel.org/all/20260616-15-jun-hid-iio-alignment-v1-0-0cd544286575@gmail.com

To: Jonathan Cameron <jic23@kernel.org>
To: David Lechner <dlechner@baylibre.com>
To: Nuno Sá <nuno.sa@analog.com>
To: Andy Shevchenko <andy@kernel.org>
To: Jiri Kosina <jikos@kernel.org>
To: Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>
Cc: linux-iio@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-input@vger.kernel.org

---
Sanjay Chitroda (6):
      iio: hid-sensors: add/remove blank line
      iio: hid-sensors: align function parenthesis for readability
      iio: hid-sensors: Use implicit NULL pointer checks
      iio: humidity: hid-sensor-humidity: use common device for devres
      iio: position: hid-sensor-custom-intel-hinge: use common device for devres
      iio: temperature: hid-sensor-temperature: use common device for devres

 drivers/iio/accel/hid-sensor-accel-3d.c            | 48 ++++++------
 .../iio/common/hid-sensors/hid-sensor-attributes.c | 89 +++++++++++-----------
 .../iio/common/hid-sensors/hid-sensor-trigger.c    |  5 +-
 .../iio/common/hid-sensors/hid-sensor-trigger.h    |  2 +-
 drivers/iio/gyro/hid-sensor-gyro-3d.c              | 54 ++++++-------
 drivers/iio/humidity/hid-sensor-humidity.c         | 49 ++++++------
 drivers/iio/light/hid-sensor-als.c                 | 32 ++++----
 drivers/iio/light/hid-sensor-prox.c                | 29 +++----
 drivers/iio/magnetometer/hid-sensor-magn-3d.c      | 76 +++++++++---------
 drivers/iio/orientation/hid-sensor-incl-3d.c       | 33 ++++----
 drivers/iio/orientation/hid-sensor-rotation.c      | 26 +++----
 .../iio/position/hid-sensor-custom-intel-hinge.c   | 15 ++--
 drivers/iio/pressure/hid-sensor-press.c            | 35 ++++-----
 drivers/iio/temperature/hid-sensor-temperature.c   | 42 +++++-----
 14 files changed, 252 insertions(+), 283 deletions(-)
---
base-commit: 16f3a4a21cab16dc9242a2e0749b026e1f2c5706
change-id: 20260615-15-jun-hid-iio-alignment-46bba7279be3

Best regards,
--  
Sanjay Chitroda <sanjayembeddedse@gmail.com>

