From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 28 Apr 2026 15:18:36 +0200
Subject: [PATCH v2 4/5] iio: light: si1133: group generic <linux/*> headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-si1133-checkup-v2-4-70ad14bfefe2@gmail.com>
References: <20260428-si1133-checkup-v2-0-70ad14bfefe2@gmail.com>
In-Reply-To: <20260428-si1133-checkup-v2-0-70ad14bfefe2@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777382314; l=901;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=Hvej5eqSWeD7xV4MQtx/PHfw5MbA/CGHl9BhtamspOQ=;
 b=Jq6Mm6BMuxPeRSM/zgyQQlhBls3VQKeMNzAmuCPCkeqSIrBztw1/V0FZ5zaPc4Un2nzcNBwSP
 S5pD6WHm1qSAwPpXC38Plocga5bLjyIq36kw6o7eBLVti2OJCrAQw1m
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
index 5c5c5ae0535a9592522c0b21496f47068044c6ff..f2a79675c026c86bb56d85a65cd035d7540d0ef8 100644
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

