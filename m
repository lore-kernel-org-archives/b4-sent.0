From: Joshua Crofts <joshua.crofts1@gmail.com>
Subject: [PATCH v4 00/17] iio: magnetometer: ak8975: modernize and cleanup
 driver
Date: Mon, 04 May 2026 11:48:12 +0200
Message-Id: <20260504-magnetometer-fixes-v4-0-a291c2a7c71a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFxr+GkC/x3LSwqAIBRG4a3EHSeYSmVbiQY9/uoOtFCJINp70
 vDjcB6KCIxIXfFQwMWRD59hyoLmffQbBC/ZpKSqpVFauHHzSIdDQhAr34iiaidrtTRVU2vK4xn
 wh/z1w/t+VSo/CmQAAAA=
X-Change-ID: 20260423-magnetometer-fixes-18b993041763
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777888111; l=2889;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=/5fSpP51PHXB+k25lXRZKfzlV436exQDvCr475uJgGU=;
 b=ehHJSEwzSqsF4f792mQRVAKObHEGtp9kyTu5QWXbyfkf9OkmWerfyyPQLmPyHjVeSVrPEFBlp
 FaN6LPT0QJlAI45okwqC6skYxTTUAdnRrZZ8q90zhy7qAZuoGA5OY1v
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series modernizes and cleans up the ak8975 driver, migrating to
more modern kernel APIs and cleaning up legacy code. Patches 7 through
17 were provided by Andy Shevchenko.

The series was compile-tested and ran in QEMU with i2c-stub and
no issues were found.

The patch regarding switching to devm_* functions might have to
go through an additional revision, otherwise everything else seems
good to go.

Changes include:
 - replacing usleep_range() with fsleep() for optimization
 - migrating to iopoll macros for better device polling
 - removing unused headers and adding new ones
 - checkpatch.pl fixes
 - switching driver to use devm_* functions

v2:
 - PATCH 1: reverted alphabetical header ordering per logical change
   separation
 - PATCH 2: added newline between fsleep() and return
 - PATCH 3: fixed open parenthesis formatting
 - PATCH 4: fixed whitespace issues, added <linux/time.h> for
   USEC_PER_MSEC macro
v3:
 - PATCH 1 & 2: split alphabetical ordering and header removal into two
   separate patches
 - PATCH 4: commit message fix
 - PATCH 5 & 6: split error handling and polling loop replacement into
   two separate patches
v4:
 - PATCH 7-17: am Andy's changes into this series
 - PATCH 2, 5, 6: fixup Andy's changes to existing patches

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
Andy Shevchenko (11):
      iio: magnetometer: ak8975: pass conversion timeouts as arguments
      iio: magnetometer: ak8975: avoid using temporary variable
      iio: magnetometer: ak8975: drop duplicate NULL check
      iio: magnetometer: ak8975: remove duplicate error message
      iio: magnetometer: ak8975: reduce usage of magic lengths of the buffer
      iio: magnetometer: ak8975: unify return code variable name
      iio: magnetometer: ak8975: switch to using managed resources
      iio: magnetometer: ak8975: consistently use 'data' parameter
      iio: magnetometer: ak8975: unify messages with help of dev_err_probe()
      iio: magnetometer: ak8975: use temporary variable for struct device
      iio: magnetometer: ak8975: make use of the macros from bits.h

Joshua Crofts (6):
      iio: magnetometer: ak8975: sort headers alphabetically
      iio: magnetometer: ak8975: update headers per IWYU principle
      iio: magnetometer: ak8975: replace usleep_range() with fsleep()
      iio: magnetometer: ak8975: change 'u8*' to 'u8 *' in cast
      iio: magnetometer: ak8975: fix wrong errno on return
      iio: magnetometer: ak8975: modernize polling loops with iopoll() macros

 drivers/iio/magnetometer/ak8975.c | 375 ++++++++++++++++++--------------------
 1 file changed, 181 insertions(+), 194 deletions(-)
---
base-commit: eade2b843d9b1f668fc1775f15611bb0a1999cd9
change-id: 20260423-magnetometer-fixes-18b993041763

Best regards,
-- 
Joshua Crofts <joshua.crofts1@gmail.com>

