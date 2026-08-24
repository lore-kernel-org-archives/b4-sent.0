From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 24 Aug 2026 17:16:58 +0200
Subject: [PATCH] iio: inv_sensors: fix estimated value larger than
 interrupt timestamp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-iio-common-inv-sensors-fix-estimated-use-v1-1-6e93506e7e93@tdk.com>
X-B4-Tracking: v=1; b=H4sIAGlgjGoC/yXN0QrCMAyF4VcZuTawlTmrryJebG3UCE2k6YYw9
 u6revnB4T8rGGUmg0uzQqaFjVUqukMD4TnKg5BjNbjWDa13PTIrBk1JBVkWNBLTbHjnD5IVTmO
 hiLMRdv0pDmcfnT96qLl3pjr6XV1vf9s8vSiUbx+2bQchNBsyjAAAAA==
X-Change-ID: 20260824-iio-common-inv-sensors-fix-estimated-use-147d698d2858
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787584621; l=1816;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=mt7gKJjjBCMn9wytqWTTXgvzfjqGHjP0xJ6dO7I7gEo=;
 b=mc/DmUjy1+bHfZNxWZm68zom2oxgTMovN+/tw02V1vmZWyi9yXJ7jSkPbXXFf+N387Yl2gHEi
 fSkCYbfSajtDeWqLebB7FMS0Vnk+8dmHUb1scbaBlLHXCLn1GHHV48P
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When interrupt timestamp interval is not valid, we use an estimated value
that can in rare case be bigger than the interrupt timestamp. This is
obviously wrong, so better use interrupt timestamp in this case.

Fixes: 8f4b627656fa ("iio: inv_sensors: better timestamp alignment when using watermark")
Cc: stable@vger.kernel.org
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/common/inv_sensors/inv_sensors_timestamp.c | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c b/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
index 88a82d1370c5..8c9e81a77e68 100644
--- a/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
+++ b/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
@@ -167,11 +167,16 @@ void inv_sensors_timestamp_interrupt(struct inv_sensors_timestamp *ts,
 		valid = inv_validate_period(ts, period);
 	}
 
-	/* if interrupt interval is valid, sync with interrupt timestamp */
+	/*
+	 * If interrupt interval is valid, sync with interrupt timestamp.
+	 * Otherwise, use estimated value while ensuring interrupt timestamp
+	 * remains the maximum possible value.
+	 */
+	period = inv_align_timestamp_it(ts, sample_nb);
 	if (valid)
-		ts->period = inv_align_timestamp_it(ts, sample_nb);
+		ts->period = period;
 	else
-		ts->period = ts->mult * ts->chip_period.val;
+		ts->period = min(ts->mult * ts->chip_period.val, period);
 }
 EXPORT_SYMBOL_NS_GPL(inv_sensors_timestamp_interrupt, "IIO_INV_SENSORS_TIMESTAMP");
 

---
base-commit: 22359083a9e74d538ce383d5c0ee30cc20182187
change-id: 20260824-iio-common-inv-sensors-fix-estimated-use-147d698d2858

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

