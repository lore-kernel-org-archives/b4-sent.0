From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 00/22] iio: make masklength __private (round 2)
Date: Thu, 18 Jul 2024 15:37:46 +0200
Message-Id: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAKoamWYC/x3MQQqAIBAAwK/EnltQC6y+Eh0kV1sqCw0Jor8nH
 ecyDySKTAmG6oFImRMfoUDWFcyLCZ6QbTEooVqhpURLGZkP3E1aNwr+WvCMnM1FCmfb2b5xQut
 OQhnOSI7vfx+n9/0AX84PzW0AAAA=
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=3113;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=8Uli0ChG4jZLPPsbSQ3WXP2ht09wW1DHRmGxM4Samzg=;
 b=cmILg206q4j7X+2olECakoOHFPVX8RRrsI9OejMsj1+KHl7qkF6qeu22+m8ZxTkNrE2qqjw3q
 B7XY/7xuo0tBDuUpEARKmVDUPzv1AI+9ii6sisI0fjG/vt5kPrhO1Yj
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Jonathan,

Here it goes the second round about annotating .masklength as __private.

Again, only compile tested for arm with allyesconfig.

---
Nuno Sa (22):
      iio: adc: cc10001_adc: make use of iio_for_each_active_channel()
      iio: adc: dln2-adc: use new '.masklength' accessors
      iio: adc: hx711: make use of iio_for_each_active_channel()
      iio: dummy: iio_simple_dummy_buffer: use iio_for_each_active_channel()
      iio: health: afe4403: make use of iio_for_each_active_channel()
      iio: health: max30102: make use of iio_get_masklength()
      iio: health: afe4404: make use of iio_for_each_active_channel()
      iio: humidity: am2315: make use of iio_for_each_active_channel()
      iio: imu: bmi160_core: make use of iio_for_each_active_channel()
      iio: imu: bno055: make use of iio_get_masklength()
      iio: imu: kmx61: make use of iio_for_each_active_channel()
      iio: light: adjd_s311: make use of iio_for_each_active_channel()
      iio: light: gp2ap020a00f: make use of iio_for_each_active_channel()
      iio: light: isl29125: make use of iio_for_each_active_channel()
      iio: light: si1145: use new '.masklength' accessors
      iio: light: tcs3414: make use of iio_for_each_active_channel()
      iio: light: tcs3472: make use of iio_for_each_active_channel()
      iio: magnetometer: rm3100-core: make use of iio_get_masklength()
      iio: pressure: dlhl60d: make use of iio_for_each_active_channel()
      iio: proximity: hx9023s: make use of iio_for_each_active_channel()
      iio: proximity: sx9500: make use of iio_for_each_active_channel()
      iio: proximity: sx_common: make use of iio_for_each_active_channel()

 drivers/iio/adc/cc10001_adc.c               | 4 +---
 drivers/iio/adc/dln2-adc.c                  | 8 +++-----
 drivers/iio/adc/hx711.c                     | 5 +----
 drivers/iio/dummy/iio_simple_dummy_buffer.c | 2 +-
 drivers/iio/health/afe4403.c                | 3 +--
 drivers/iio/health/afe4404.c                | 3 +--
 drivers/iio/health/max30102.c               | 2 +-
 drivers/iio/humidity/am2315.c               | 3 +--
 drivers/iio/imu/bmi160/bmi160_core.c        | 3 +--
 drivers/iio/imu/bno055/bno055.c             | 2 +-
 drivers/iio/imu/kmx61.c                     | 3 +--
 drivers/iio/light/adjd_s311.c               | 3 +--
 drivers/iio/light/gp2ap020a00f.c            | 9 +++------
 drivers/iio/light/isl29125.c                | 3 +--
 drivers/iio/light/si1145.c                  | 7 +++----
 drivers/iio/light/tcs3414.c                 | 3 +--
 drivers/iio/light/tcs3472.c                 | 3 +--
 drivers/iio/magnetometer/rm3100-core.c      | 2 +-
 drivers/iio/pressure/dlhl60d.c              | 3 +--
 drivers/iio/proximity/hx9023s.c             | 4 ++--
 drivers/iio/proximity/sx9500.c              | 3 +--
 drivers/iio/proximity/sx_common.c           | 6 ++----
 22 files changed, 30 insertions(+), 54 deletions(-)
---
base-commit: 986da024b99a72e64f6bdb3f3f0e52af024b1f50
change-id: 20240711-dev-iio-masklength-private2-cd8d93f07781
--

Thanks!
- Nuno Sá

