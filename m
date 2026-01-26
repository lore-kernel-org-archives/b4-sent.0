From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Tue, 27 Jan 2026 01:02:18 +0530
Subject: [PATCH v7 4/6] iio: proximity: rfd77402: Use devm-managed mutex
 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260127-b4-rfd77402_v5-v7-4-3e7f2d452da2@gmail.com>
References: <20260127-b4-rfd77402_v5-v7-0-3e7f2d452da2@gmail.com>
In-Reply-To: <20260127-b4-rfd77402_v5-v7-0-3e7f2d452da2@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: skhan@linuxfoundation.org, david.hunter.linux@gmail.com, 
 raskar.shree97@gmail.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769455974; l=895;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=O017TADCPm7We8ptZ3sfVe3HpHsX8WgePZRWSMO2cOY=;
 b=9q2fvQNYPt8+mTL/6LaSpidrj6knnXaEw49OvM6Eb+pllpWrpj7k4fws6wTdVUaJpuZD+T43D
 JDuQRHZJw+CBlIgilfuL87P5bQ65JSrfW7fD4F8FaG8M4A/3nqlxJgH
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use devm_mutex_init() to tie the mutex lifetime to the device and
improve debugging when CONFIG_DEBUG_MUTEXES is enabled.

Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 drivers/iio/proximity/rfd77402.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/proximity/rfd77402.c b/drivers/iio/proximity/rfd77402.c
index 6b23fb3bfe1d..a374a7389c33 100644
--- a/drivers/iio/proximity/rfd77402.c
+++ b/drivers/iio/proximity/rfd77402.c
@@ -283,7 +283,10 @@ static int rfd77402_probe(struct i2c_client *client)
 
 	data = iio_priv(indio_dev);
 	data->client = client;
-	mutex_init(&data->lock);
+
+	ret = devm_mutex_init(&client->dev, &data->lock);
+	if (ret)
+		return ret;
 
 	indio_dev->info = &rfd77402_info;
 	indio_dev->channels = rfd77402_channels;

-- 
2.43.0

