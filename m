From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Thu, 30 Apr 2026 17:04:26 +0200
Subject: [PATCH v4 6/8] iio: light: si1133: group generic <linux/*> headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260430-si1133-checkup-v4-6-fb3e9dce41bf@gmail.com>
References: <20260430-si1133-checkup-v4-0-fb3e9dce41bf@gmail.com>
In-Reply-To: <20260430-si1133-checkup-v4-0-fb3e9dce41bf@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777561514; l=901;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=ONajTyOwYWFLpIXERWtWPSYo2OZuZwtQVCrvlP4IvVA=;
 b=zFQ9q4yHzYzchaZOHJ0HpqICQ+p88AI00TjJdoTLw5icaEP6DfGiKfK1hsrfjbDjdi6MGht+C
 mq1U5aXqqi/Bm0uAKHMXplGuaj7r1J60acP1QUw4qmX2izffuaf0pMm
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Group generic <linux/*> include headers to improve code style.

No functional change.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/si1133.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/light/si1133.c b/drivers/iio/light/si1133.c
index ab66a5a9ffb4a89bbba7474b6e984ddb61cfeebe..fdffdee16e493277d95c369ec2f6c0678cf9f61c 100644
--- a/drivers/iio/light/si1133.c
+++ b/drivers/iio/light/si1133.c
@@ -21,14 +21,12 @@
 #include <linux/mutex.h>
 #include <linux/regmap.h>
 #include <linux/types.h>
+#include <linux/unaligned.h>
+#include <linux/util_macros.h>
 
 #include <linux/iio/iio.h>
 #include <linux/iio/sysfs.h>
 
-#include <linux/util_macros.h>
-
-#include <linux/unaligned.h>
-
 #define SI1133_REG_PART_ID		0x00
 #define SI1133_REG_REV_ID		0x01
 #define SI1133_REG_MFR_ID		0x02

-- 
2.47.3

