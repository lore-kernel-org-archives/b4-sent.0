From: Andrea Amer <and.amer@gmail.com>
Date: Mon, 12 Oct 2026 10:28:53 +0200
Subject: [PATCH] iio: afe: rescale: always expose offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-iio-rescale-offset-v1-1-14ed15979ff2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAESazGoC/x3MQQqAIBBA0avErBtQMxddJVpYjTUQGk5EIN09a
 fkW/xcQykwCQ1Mg083CKVbotoFl93Ej5LUajDJOK22QOWEmWfxBmEIQutBq01vfdbNbHdTwzBT
 4+afj9L4fl3LXJmQAAAA=
X-Change-ID: 20261012-iio-rescale-offset-41254a33b6d6
To: Peter Rosin <peda@lysator.liu.se>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Liam Beguin <liambeguin@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, Andrea Amer <and.amer@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791793735; l=1309;
 i=and.amer@gmail.com; s=20261012; h=from:subject:message-id;
 bh=Hk6uj82B4NAvd2+YopIwSqouEWeeLPNEDXXoOxHcLoE=;
 b=9wgJsQ5priSB6KspIp9ezCLjdd+eKJ6yEdl0eFIwO5AtSU2ZmmetfbV6Y3AJhL1D6qV5NR610
 6iWVvx3qAv8CrnogKPRqEWXyCSansGopPr2lvig3sqA4uTG62D6Kgk5
X-Developer-Key: i=and.amer@gmail.com; a=ed25519;
 pk=TiMK202FvcPM+yKGkAI4hsAZA7QkwyEgru97PAFa4pg=
X-Endpoint-Received: by B4 Relay for and.amer@gmail.com/20261012 with auth_id=1165
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A rescale channel advertises IIO_CHAN_INFO_OFFSET only when its own
offset is non-zero. A child rescale therefore hides a source offset,
and consumers apply raw * scale and drop it. rescale_read_raw() already
folds the source offset in, so expose the attribute in every case.

Fixes: a29c3283653b ("iio: afe: rescale: add offset support")
Signed-off-by: Andrea Amer <and.amer@gmail.com>
---
 drivers/iio/afe/iio-rescale.c | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/afe/iio-rescale.c b/drivers/iio/afe/iio-rescale.c
index 3a6a09ffa5267ddfd5131fbd04a5df928836589d..52be28cdb0c7e7c16a52329fe5d93459480736e0 100644
--- a/drivers/iio/afe/iio-rescale.c
+++ b/drivers/iio/afe/iio-rescale.c
@@ -301,10 +301,9 @@ static int rescale_configure_channel(struct device *dev,
 	}
 
 	chan->info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
-		BIT(IIO_CHAN_INFO_SCALE);
+		BIT(IIO_CHAN_INFO_SCALE) |
+		BIT(IIO_CHAN_INFO_OFFSET);
 
-	if (rescale->offset)
-		chan->info_mask_separate |= BIT(IIO_CHAN_INFO_OFFSET);
 
 	/*
 	 * Using .read_avail() is fringe to begin with and makes no sense

---
base-commit: a3b3580713f3ac5a32dc2874ee546828977a1d68
change-id: 20261012-iio-rescale-offset-41254a33b6d6

Best regards,
-- 
Andrea Amer <and.amer@gmail.com>

