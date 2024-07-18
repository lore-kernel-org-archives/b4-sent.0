From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:56 +0200
Subject: [PATCH 10/22] iio: imu: bno055: make use of iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-10-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=875;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=1/XFhtVL5DGGEIfobJIiiBmxQTyc/mcom9KHRuSBMrA=;
 b=m3bFh284R2Gbd8u35dz8a4JhrMysfAJFI0MrGa2s8veAnk2+7opnBOFka/X4WIVTrSjmj78QH
 MTlzRQEAIK5CfZrWJN8lmaoeXtcFckO/r9rfCuXoEznZBHV5OC0eu7P
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/imu/bno055/bno055.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/imu/bno055/bno055.c b/drivers/iio/imu/bno055/bno055.c
index 52744dd98e65b..ea6519b22b2f3 100644
--- a/drivers/iio/imu/bno055/bno055.c
+++ b/drivers/iio/imu/bno055/bno055.c
@@ -1458,7 +1458,7 @@ static irqreturn_t bno055_trigger_handler(int irq, void *p)
 	 * then we split the transfer, skipping the gap.
 	 */
 	for_each_set_bitrange(start, end, iio_dev->active_scan_mask,
-			      iio_dev->masklength) {
+			      iio_get_masklength(iio_dev)) {
 		/*
 		 * First transfer will start from the beginning of the first
 		 * ones-field in the bitmap

-- 
2.45.2

