From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Fri, 27 Nov 2026 21:30:13 +0100
Subject: [PATCH 1/4] media: i2c: ov7251: wait for software reset settle in
 power-on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-ov7251-strobe-ncont-v1-1-cefa8c6c020b@gmail.com>
References: <20261127-ov7251-strobe-ncont-v1-0-cefa8c6c020b@gmail.com>
In-Reply-To: <20261127-ov7251-strobe-ncont-v1-0-cefa8c6c020b@gmail.com>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Jacopo Mondi <jacopo@jmondi.org>, Todor Tomov <todor.too@gmail.com>
Cc: Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811412; l=990;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=C+8lmuISbwzysaK9qU8l6di4Xw5u0AVciao8qKMN3LA=;
 b=HPtJUOnuhfsDgAFbXWAgHnbjkJU84yThp3NDuhihxnFHjXQiq2d+nFcFs3q5sTXo4tDa+PHmJ
 QVOC/d9aW5gB94y3CHnk+GLm7uBSycyZYFlbM5gMFIF22xg5FWXSRlF
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ov7251_global_init_setting[] issues a software reset (0x0103 = 0x01) as
part of ov7251_set_power_on(), after which callers immediately issue
further I2C register accesses. Give the sensor 5-10 ms to settle after
global initialization to prevent intermittent I2C errors on rapid power
cycles.

Fixes: d30bb512da3d ("media: Add a driver for the ov7251 camera sensor")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/i2c/ov7251.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov7251.c b/drivers/media/i2c/ov7251.c
index 5b03343a0350c926a34a391af6a338ddf6c3e0bd..77ac60fad62209eda0444015196e52564a0e947d 100644
--- a/drivers/media/i2c/ov7251.c
+++ b/drivers/media/i2c/ov7251.c
@@ -941,7 +941,9 @@ static int ov7251_set_power_on(struct device *dev)
 		return ret;
 	}
 
-	return ret;
+	usleep_range(5000, 10000);
+
+	return 0;
 }
 
 static int ov7251_set_power_off(struct device *dev)

-- 
2.47.3

