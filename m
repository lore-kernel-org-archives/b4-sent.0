From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Wed, 21 Jan 2026 02:05:44 +0530
Subject: [PATCH v6 4/5] iio: proximity: rfd77402: Document device private
 data structure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260121-b4-rfd77402_v5-v6-4-5b944d0605dd@gmail.com>
References: <20260121-b4-rfd77402_v5-v6-0-5b944d0605dd@gmail.com>
In-Reply-To: <20260121-b4-rfd77402_v5-v6-0-5b944d0605dd@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: skhan@linuxfoundation.org, david.hunter.linux@gmail.com, 
 raskar.shree97@gmail.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768941363; l=846;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=ZNRXTbMiZ66e9jZOOxYOba5M4vr3u4LqUYpX35UAbzs=;
 b=910QesgCgsLpYFqkQ106kEJ2rfknYxgus4+rk6blMJS3uq/dP0wFmz4FyBF/udrtpJWZg8nlL
 lN0yfK6cy6LCI3RljXnyaXZpA0Ouv5PoRNXjdEw6Q5ob5BFBQ/4hrkU
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add kernel-doc style comments for struct rfd77402_data to describe
the purpose of each member.

Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 drivers/iio/proximity/rfd77402.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/proximity/rfd77402.c b/drivers/iio/proximity/rfd77402.c
index fce85f783ab4..dd57156a7859 100644
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

