From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 04 Nov 2025 15:35:15 +0000
Subject: [PATCH v4 10/12] iio: dac: ad5446: Refactor header inclusion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251104-dev-add-ad5542-v4-10-6fe35458bf8c@analog.com>
References: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
In-Reply-To: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762270508; l=1206;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=7C0UVf31WzfqNv7L6REiRCtSkEXLZj16kckBYexNtTE=;
 b=pge2lvMbktdrZHRURX7wjAa1HfFNg6U4jQUamMzgft+u7cauDLuloCSw7RKx8YgWtOHlv7cIO
 W50FxGTCP7dCb+vitjmxyY6FcGRP9HqbG8MVmcqFSAuroul/H3UOeXP
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure include files are given in alphabetical order and that we include
the ones that were missing and remove the ones we don't really use.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446.c | 18 +++++++-----------
 1 file changed, 7 insertions(+), 11 deletions(-)

diff --git a/drivers/iio/dac/ad5446.c b/drivers/iio/dac/ad5446.c
index 1943e8014990..0556ce78c2f6 100644
--- a/drivers/iio/dac/ad5446.c
+++ b/drivers/iio/dac/ad5446.c
@@ -5,21 +5,17 @@
  * Copyright 2010 Analog Devices Inc.
  */
 
+#include <linux/array_size.h>
 #include <linux/cleanup.h>
-#include <linux/export.h>
-#include <linux/interrupt.h>
-#include <linux/workqueue.h>
 #include <linux/device.h>
-#include <linux/kernel.h>
-#include <linux/slab.h>
-#include <linux/sysfs.h>
-#include <linux/list.h>
-#include <linux/regulator/consumer.h>
 #include <linux/err.h>
-#include <linux/module.h>
-
+#include <linux/export.h>
 #include <linux/iio/iio.h>
-#include <linux/iio/sysfs.h>
+#include <linux/kstrtox.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/regulator/consumer.h>
+#include <linux/sysfs.h>
 
 #include "ad5446.h"
 

-- 
2.51.0

