From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Wed, 29 Apr 2026 17:04:49 +0200
Subject: [PATCH v3 1/8] iio: light: si1133: remove unused macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-si1133-checkup-v3-1-469f21d960eb@gmail.com>
References: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
In-Reply-To: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777475147; l=969;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=Ecef6Lis4KUDy5wkginYFApj5UHLvf6O9wthv94jeNY=;
 b=VOfiDrlq/09SWdsT4tH+FwToLIP84cp1zHZoWoN1tklDogUu705H3koPJEFE1QiG7nuhOzDv5
 cMoZM4DNrlZD9bjZVO80h2qUfB+C+2nbEbN/Ry1vfS3HYYFp1QAkWMy
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove unused macros to improve readability.

No functional change.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/si1133.c | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/drivers/iio/light/si1133.c b/drivers/iio/light/si1133.c
index 44fa152dbd24c26c97cc778cbe641d92ecd56afa..73b0ce21e017cd4ab6c6b280229f417763866502 100644
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

