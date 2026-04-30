From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Thu, 30 Apr 2026 17:04:23 +0200
Subject: [PATCH v4 3/8] iio: light: si1133: remove unused macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260430-si1133-checkup-v4-3-fb3e9dce41bf@gmail.com>
References: <20260430-si1133-checkup-v4-0-fb3e9dce41bf@gmail.com>
In-Reply-To: <20260430-si1133-checkup-v4-0-fb3e9dce41bf@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777561514; l=1046;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=7K9lqxMczl9Rl1iwkxbifs2o+8+pT5IUZAPJUPkp9dE=;
 b=RGBqxLa2//dYpN21QvMHjOUEJCtWMfCZ6+bysFAEKKbNizFuvdmLGd3wNluu51lvaSZ8xTX1k
 gAaI/DWlOTOCbSO/gQcce0xL/uIhpl7NmyvpQuPh/TU8CF1KE3/Igab
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove unused macros unrelated to hardware definition.

No functional change.

Suggested-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/si1133.c | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/drivers/iio/light/si1133.c b/drivers/iio/light/si1133.c
index bf7bf0f1631d49a1d04b89f172646e4afaf46438..ed9b3e0a12d66d749f09f570de1ccdda2174b6ba 100644
--- a/drivers/iio/light/si1133.c
+++ b/drivers/iio/light/si1133.c
@@ -86,13 +86,9 @@
 #define SI1133_CMD_MINSLEEP_US_LOW	5000
 #define SI1133_CMD_MINSLEEP_US_HIGH	7500
 #define SI1133_CMD_TIMEOUT_MS		25
-#define SI1133_CMD_LUX_TIMEOUT_MS	5000
-#define SI1133_CMD_TIMEOUT_US		SI1133_CMD_TIMEOUT_MS * 1000
 
 #define SI1133_REG_HOSTOUT(x)		(x) + 0x13
 
-#define SI1133_MEASUREMENT_FREQUENCY 1250
-
 #define SI1133_X_ORDER_MASK            0x0070
 #define SI1133_Y_ORDER_MASK            0x0007
 #define si1133_get_x_order(m)          ((m) & SI1133_X_ORDER_MASK) >> 4

-- 
2.47.3

