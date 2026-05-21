From: Joshua Crofts <joshua.crofts1@gmail.com>
Subject: [PATCH v3 0/7] iio: light: opt3001: driver cleanup
Date: Thu, 21 May 2026 11:55:37 +0200
Message-Id: <20260521-opt3001-cleanup-v3-0-820169dec8c3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJnWDmoC/3WNwQqDMBAFf0X23JRsojV66n+UHkKMuqBGEhtax
 H9v9CSUHufBzFshWE82QJ2t4G2kQG5KIC8ZmF5PnWXUJAbBxY0XiMzNi+QcmRmsnl4zM5gjNhZ
 zWQlI1uxtS++j+Hgm7ikszn+Og4j7+r8VkXHWlqqsGiPzojD3btQ0XI0bYW9FcfbFry+Srzgq0
 0qtNNdnf9u2L/2iPifuAAAA
X-Change-ID: 20260511-opt3001-cleanup-c1411de14392
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Alexander Koch <mail@alexanderkoch.net>, 
 Michael Hornung <mhornung.linux@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, Sashiko <sashiko-bot@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>, 
 Maxwell Doose <m32285159@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779357341; l=2320;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=+qVy/VEiV6aWMIQfz0KhAEFfds0UKkgkJir8yJUDAmc=;
 b=dYMNm1aBsbzIl2yV7fBNsQ5XFgkQhmMUyDbril7YGcSwwdCoWbVMpr90SSR3eKQy0ITRpqiZL
 DkUrZz+DxK6Cqtv4Q//XiUTi40l0MRtRgmnc8ez7tjHTGBv6onR7khA
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series deals with cleaning up the TI OPT3001 sensor driver,
moving it to more modern kernel practices and improving the code style.

While reviewing, Jonathan Cameron (and eventually Sashiko) found a race
condition where userspace could start interacting with the device
before the hardware IRQ was set up.

Changes include:
- moving the driver to use devm_* functions
- IWYU cleanups
- removal of unnecessary macros and comments
- using dev_err_probe() in probe and probe path functions
- checkpatch.pl warning cleanups
- fixing a race condition found in opt3001_probe() function

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
Changes in v3:
- PATCH 1: fix build error
- PATCH 2: remove struct device member from struct opt3001
- PATCH 6: edit return statements
- Pull additional trailers from previous version's reviews
- Edit commit messages
- Link to v2: https://lore.kernel.org/r/20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com

Changes in v2:
- PATCH 1: added patch that fixes race condition
- PATCH 3: remove wrong usage of GENMASK()
- PATCH 4: add patch that moves driver to use local structs
- PATCH 5: add patch that ensures correct parenthesis alignment
- PATCH 6: change int to unsigned int
- PATCH 7: moved opt3001_read_id() function to use dev_err_probe()
- PATCH 9: removed unnecessary dev_err_probe() calls, reordering
- PATCH 10: added patch that adds a comment to mutex declaration
- Link to v1: https://lore.kernel.org/r/20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com

---
Joshua Crofts (7):
      iio: light: opt3001: move device registration to end of probe()
      iio: light: opt3001: use local struct device and i2c_client variables
      iio: light: opt3001: ensure correct parenthesis alignment
      iio: light: opt3001: localize for loop iterator
      iio: light: opt3001: prefer dev_err_probe()
      iio: light: opt3001: move driver to guard(mutex)() use
      iio: light: opt3001: add comment to mutex

 drivers/iio/light/opt3001.c | 378 +++++++++++++++++++++-----------------------
 1 file changed, 179 insertions(+), 199 deletions(-)
---
base-commit: 8678fb54958893818ddeccd05fea560a4e1fc759
change-id: 20260511-opt3001-cleanup-c1411de14392

Best regards,
-- 
Joshua Crofts <joshua.crofts1@gmail.com>

