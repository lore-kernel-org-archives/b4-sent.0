From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Wed, 28 Jan 2026 23:21:52 +0530
Subject: [PATCH v8 5/6] iio: proximity: rfd77402: Document device private
 data structure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260128-b4-rfd77402_v5-v8-5-36388fe7b95e@gmail.com>
References: <20260128-b4-rfd77402_v5-v8-0-36388fe7b95e@gmail.com>
In-Reply-To: <20260128-b4-rfd77402_v5-v8-0-36388fe7b95e@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: skhan@linuxfoundation.org, david.hunter.linux@gmail.com, 
 raskar.shree97@gmail.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769622737; l=906;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=x84MD8DpzwahLxBpvUlfo99iVRVFury7i1rHYa+sduo=;
 b=P/tqTbXhP+XXS2nSgtTJISHiwU1xgrW9Kn9FpKcfuEKETylRr6xgxYAl5T1slvCR+yhAwfknn
 JbhhuS0SQjcCixop4SDsz6XXHdydfrSefC+K5oslLGz+2D055NCCTGp
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add kernel-doc style comments for struct rfd77402_data to describe
the purpose of each member.

Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 drivers/iio/proximity/rfd77402.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/proximity/rfd77402.c b/drivers/iio/proximity/rfd77402.c
index a374a7389c33..c29ae9af4a90 100644
--- a/drivers/iio/proximity/rfd77402.c
+++ b/drivers/iio/proximity/rfd77402.c
@@ -77,9 +77,13 @@ static const struct {
 	{RFD77402_HFCFG_3,	0x45d4},
 };
 
+/**
+ * struct rfd77402_data - device-specific data for the RFD77402 sensor
+ * @client: I2C client handle
+ * @lock: mutex to serialize sensor reads
+ */
 struct rfd77402_data {
 	struct i2c_client *client;
-	/* Serialize reads from the sensor */
 	struct mutex lock;
 };
 

-- 
2.43.0

