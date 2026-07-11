From: Miles Krause <mileskrause5200@gmail.com>
Date: Fri, 10 Jul 2026 21:09:02 -0400
Subject: [PATCH] Input: qt1050 - name calibration status bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-qt1050-calibration-status-bit-v1-1-e4f7d1d797b6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAK2XUWoC/yXM0QrCMAxA0V8ZeTaQlunQXxEfmi7ViExtMhHG/
 t2qjwcudwGTqmJw6Bao8lLT+9QQNh3kS5rOgjo2Q6S4oyEQPj3QljCnm3JN3nI0Tz4bsjoSR+m
 HfSljz9AejypF37//8fS3zXyV7N8prOsH7Mwwz4EAAAA=
X-Change-ID: 20260710-qt1050-calibration-status-bit-0b2e479ffd4b
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Miles Krause <mileskrause5200@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783732147; l=1610;
 i=mileskrause5200@gmail.com; s=20260710; h=from:subject:message-id;
 bh=RY4tjQcuZkpaCZPC5GXl5Z5TifqEyJldGFwLCDOhcWQ=;
 b=9osnnSmQILluaI7QKd2YiKmSqP18ai2gyI5pQmalCuXIgu8j1JCIAgj+BT68eMyBOG8O0fTaL
 PporRb9p7oFBANNAeQXzWOLZVUjVp5yRIvaESU7R32vRvPT/qB3qU1B
X-Developer-Key: i=mileskrause5200@gmail.com; a=ed25519;
 pk=QNhNjcQarqig3ColJBIEr3DYfWM1PHpP7z+6thxWXaU=
X-Endpoint-Received: by B4 Relay for mileskrause5200@gmail.com/20260710 with auth_id=861
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Detection status bit 7 indicates that a calibration cycle is in
progress. Define a name for the bit and use it in the polling
condition instead of an open-coded shift and comparison.

No functional change.

Signed-off-by: Miles Krause <mileskrause5200@gmail.com>
---
Compile-tested on x86_64 with:

  make O=out allmodconfig
  make O=out W=1 drivers/input/keyboard/qt1050.o

Sparse-tested with:

  make O=out-sparse allmodconfig
  make O=out-sparse C=1 CHECK=sparse drivers/input/keyboard/qt1050.o
---
 drivers/input/keyboard/qt1050.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/input/keyboard/qt1050.c b/drivers/input/keyboard/qt1050.c
index f9f480c91032..2371ac027aab 100644
--- a/drivers/input/keyboard/qt1050.c
+++ b/drivers/input/keyboard/qt1050.c
@@ -27,7 +27,8 @@
 #define QT1050_FW_VERSION	0x01
 
 /* Detection status */
-#define QT1050_DET_STATUS	0x02
+#define QT1050_DET_STATUS		0x02
+#define QT1050_DET_STATUS_CALIBRATE	BIT(7)
 
 /* Key status */
 #define QT1050_KEY_STATUS	0x03
@@ -498,7 +499,8 @@ static int qt1050_probe(struct i2c_client *client)
 		return err;
 	}
 	err = regmap_read_poll_timeout(ts->regmap, QT1050_DET_STATUS, status,
-				 status >> 7 == 1, 10000, 200000);
+				 status & QT1050_DET_STATUS_CALIBRATE,
+				 10000, 200000);
 	if (err) {
 		dev_err(dev, "Calibration failed: %d\n", err);
 		return err;

---
base-commit: c8f174900926d3b58cd048ac33b4cbb3de419bfe
change-id: 20260710-qt1050-calibration-status-bit-0b2e479ffd4b

Best regards,
--  
Miles Krause <mileskrause5200@gmail.com>

