From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Thu, 01 Jan 2026 21:47:40 +0530
Subject: [PATCH v4 3/4] iio: proximity: rfd77402: Use kernel helper for
 result polling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-b4-rfd77402_irq-v4-3-42cd54359e9f@gmail.com>
References: <20260101-b4-rfd77402_irq-v4-0-42cd54359e9f@gmail.com>
In-Reply-To: <20260101-b4-rfd77402_irq-v4-0-42cd54359e9f@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: raskar.shree97@gmail.com, skhan@linuxfoundation.org, 
 david.hunter.linux@gmail.com, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767284290; l=1779;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=LS/GSeSQrtkZGeuXrepvOA1K2RRvlQ1qjhZCkwokVvE=;
 b=C+NrC31Xzpph97j24fL29MGZ28F+Z2CvCubZfv7JLjNSG9Ci3juEc5vysFpIQLqcfPxmMljCG
 SFWfDAnHZkkBuN+smeYYMuOxwmAFeLN6ib8bO9ZMQXWWhlTvc8u3j/g
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the manually written polling loop with read_poll_timeout(),
the kernel's standard helper for waiting on hardware status.
This makes the code easier to read and avoids repeating the same
polling code in the driver.

Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 drivers/iio/proximity/rfd77402.c | 22 +++++++++-------------
 1 file changed, 9 insertions(+), 13 deletions(-)

diff --git a/drivers/iio/proximity/rfd77402.c b/drivers/iio/proximity/rfd77402.c
index 3262af6f6882..496c1412ebf8 100644
--- a/drivers/iio/proximity/rfd77402.c
+++ b/drivers/iio/proximity/rfd77402.c
@@ -13,6 +13,7 @@
 #include <linux/module.h>
 #include <linux/i2c.h>
 #include <linux/delay.h>
+#include <linux/iopoll.h>
 
 #include <linux/iio/iio.h>
 
@@ -113,7 +114,6 @@ static int rfd77402_set_state(struct i2c_client *client, u8 state, u16 check)
 static int rfd77402_measure(struct i2c_client *client)
 {
 	int ret;
-	int tries = 10;
 
 	ret = rfd77402_set_state(client, RFD77402_CMD_MCPU_ON,
 				 RFD77402_STATUS_MCPU_ON);
@@ -126,19 +126,15 @@ static int rfd77402_measure(struct i2c_client *client)
 	if (ret < 0)
 		goto err;
 
-	while (tries-- > 0) {
-		ret = i2c_smbus_read_byte_data(client, RFD77402_ICSR);
-		if (ret < 0)
-			goto err;
-		if (ret & RFD77402_ICSR_RESULT)
-			break;
-		msleep(20);
-	}
-
-	if (tries < 0) {
-		ret = -ETIMEDOUT;
+	/* Poll ICSR until RESULT bit is set */
+	ret = read_poll_timeout(i2c_smbus_read_byte_data, ret,
+				ret & RFD77402_ICSR_RESULT,
+				10000,    /* sleep: 10ms */
+				100000,   /* timeout: 100ms */
+				false,
+				client, RFD77402_ICSR);
+	if (ret < 0)
 		goto err;
-	}
 
 	ret = i2c_smbus_read_word_data(client, RFD77402_RESULT_R);
 	if (ret < 0)

-- 
2.43.0

