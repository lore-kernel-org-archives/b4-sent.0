From: Shrikant Raskar <raskar.shree97@gmail.com>
Date: Thu, 15 Jan 2026 13:57:40 +0530
Subject: [PATCH v5 4/5] iio: proximity: rfd77402: Use devm-managed mutex
 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260115-rfd77402_v5-v5-4-594eb57683e4@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768465693; l=818;
 i=raskar.shree97@gmail.com; s=20260101; h=from:subject:message-id;
 bh=k49VHFrDJjFFj/mgpbeRdvQKWZLsslBIKwH8rf7C0xA=;
 b=MXcNHdrkfwXyMt0tXfP3jClJ8j7XUeEIoX8XU60MwpRiDF+eQGxH3/WpDGOi4iVrDowaM4yv5
 S89IXle5RaJC6xq67Kwwt1K2+f/7WYeSCJ8s40M6y1izmK+a/SHIOlP
X-Developer-Key: i=raskar.shree97@gmail.com; a=ed25519;
 pk=4m2wXDvY0vlXefvRRzawNcNAif88Cy4XvbLkU6iMG/Y=
X-Endpoint-Received: by B4 Relay for raskar.shree97@gmail.com/20260101 with auth_id=589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use devm_mutex_init() to tie the mutex lifetime to the device and
simplify resource lifetime management.

Signed-off-by: Shrikant Raskar <raskar.shree97@gmail.com>
---
 drivers/iio/proximity/rfd77402.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/proximity/rfd77402.c b/drivers/iio/proximity/rfd77402.c
index dd79c9ee838b..43ace2beef7e 100644
--- a/drivers/iio/proximity/rfd77402.c
+++ b/drivers/iio/proximity/rfd77402.c
@@ -359,7 +359,10 @@ static int rfd77402_probe(struct i2c_client *client)
 
 	data = iio_priv(indio_dev);
 	data->client = client;
-	mutex_init(&data->lock);
+	ret = devm_mutex_init(&client->dev, &data->lock);
+	if (ret)
+		return ret;
+
 	init_completion(&data->completion);
 	i2c_set_clientdata(client, indio_dev);
 

-- 
2.43.0

