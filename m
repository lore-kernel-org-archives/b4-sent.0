From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 28 Apr 2026 15:18:34 +0200
Subject: [PATCH v2 2/5] iio: light: si1133: remove unused macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-si1133-checkup-v2-2-70ad14bfefe2@gmail.com>
References: <20260428-si1133-checkup-v2-0-70ad14bfefe2@gmail.com>
In-Reply-To: <20260428-si1133-checkup-v2-0-70ad14bfefe2@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777382314; l=1486;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=sAJi4jzXAC1/xkjwpgVBUUVE/UZJLoyjyYEoIQrqUtw=;
 b=hPVVeDLOV8wrvYmDq+tIMEfeaEYl3ptAXJXt/LGS8G4hR7bHtDT6SgrepOeucxG+w8S5nHxEV
 KiaO7yM1vORCirhyPsnG4yM1RPbaSDeHj8v3VzvuhG7O541lVtSoj/t
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove unused macros to improve readability.

No functional change.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/si1133.c | 7 -------
 1 file changed, 7 deletions(-)

diff --git a/drivers/iio/light/si1133.c b/drivers/iio/light/si1133.c
index 52e4269dc35014b87b7c46a120e64723be716768..ada8da122b76c9a0a55751baa6522a145f0fc7e8 100644
--- a/drivers/iio/light/si1133.c
+++ b/drivers/iio/light/si1133.c
@@ -22,8 +22,6 @@
 #define SI1133_REG_PART_ID		0x00
 #define SI1133_REG_REV_ID		0x01
 #define SI1133_REG_MFR_ID		0x02
-#define SI1133_REG_INFO0		0x03
-#define SI1133_REG_INFO1		0x04
 
 #define SI1133_PART_ID			0x33
 
@@ -40,7 +38,6 @@
 #define SI1133_CMD_RESET_CTR		0x00
 #define SI1133_CMD_RESET_SW		0x01
 #define SI1133_CMD_FORCE		0x11
-#define SI1133_CMD_START_AUTONOMOUS	0x13
 #define SI1133_CMD_PARAM_SET		0x80
 #define SI1133_CMD_PARAM_QUERY		0x40
 #define SI1133_CMD_PARAM_MASK		0x3F
@@ -86,13 +83,9 @@
 #define SI1133_CMD_MINSLEEP_US_LOW	5000
 #define SI1133_CMD_MINSLEEP_US_HIGH	7500
 #define SI1133_CMD_TIMEOUT_MS		25
-#define SI1133_CMD_LUX_TIMEOUT_MS	5000
-#define SI1133_CMD_TIMEOUT_US		(SI1133_CMD_TIMEOUT_MS * 1000)
 
 #define SI1133_REG_HOSTOUT(x)		((x) + 0x13)
 
-#define SI1133_MEASUREMENT_FREQUENCY 1250
-
 #define SI1133_X_ORDER_MASK            0x0070
 #define SI1133_Y_ORDER_MASK            0x0007
 #define si1133_get_x_order(m)          (((m) & SI1133_X_ORDER_MASK) >> 4)

-- 
2.47.3

