From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Thu, 15 Jan 2026 13:57:41 +0530
Subject: [PATCH v5 5/5] iio: proximity: rfd77402: Document device private
 data structure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260115-rfd77402_v5-v5-5-594eb57683e4@gmail.com>
References: <20260115-rfd77402_v5-v5-0-594eb57683e4@gmail.com>
In-Reply-To: <20260115-rfd77402_v5-v5-0-594eb57683e4@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: skhan@linuxfoundation.org, david.hunter.linux@gmail.com, 
 raskar.shree97@gmail.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768465693; l=1014;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=syP1cm34ZXh86vqwrGpgNSQse/6+lSSS0BKSNLhKPRA=;
 b=oibpHuX+teA2H+P/KXELrdZmcO+PBGhxDxww3biLMzBD1aIdbHw6U1NEY9MZsqEadHLne+3vj
 zhVxhqOzWIBBVRjZsfNJTgub0wKzcXYkEvHRlVJ3NapC+NfFd/5wjSJ
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add kernel-doc style comments for struct rfd77402_data to describe
the purpose of each member.

Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 drivers/iio/proximity/rfd77402.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/proximity/rfd77402.c b/drivers/iio/proximity/rfd77402.c
index 43ace2beef7e..e6a499cfb232 100644
--- a/drivers/iio/proximity/rfd77402.c
+++ b/drivers/iio/proximity/rfd77402.c
@@ -86,9 +86,15 @@ static const struct {
 	{RFD77402_HFCFG_3,	0x45d4},
 };
 
+/*
+ * struct rfd77402_data - device-specific data for the RFD77402 sensor
+ * @client: I2C client handle
+ * @lock: mutex to serialize sensor reads
+ * @completion: completion used for interrupt-driven measurements
+ * @irq_en: indicates whether interrupt mode is enabled
+ */
 struct rfd77402_data {
 	struct i2c_client *client;
-	/* Serialize reads from the sensor */
 	struct mutex lock;
 	struct completion completion;
 	bool irq_en;

-- 
2.43.0

