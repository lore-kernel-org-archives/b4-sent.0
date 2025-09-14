From: Sven Peter <sven@kernel.org>
Date: Sun, 14 Sep 2025 12:56:15 +0000
Subject: [PATCH 10/11] usb: typec: tipd: Read data status in probe and
 cache its value
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250914-apple-usb3-tipd-v1-10-4e99c8649024@kernel.org>
References: <20250914-apple-usb3-tipd-v1-0-4e99c8649024@kernel.org>
In-Reply-To: <20250914-apple-usb3-tipd-v1-0-4e99c8649024@kernel.org>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1585; i=sven@kernel.org;
 h=from:subject:message-id; bh=SEqFsdZj9wQbFtYLraoDyZILplcZKiIw4Wc/CN9A6bM=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8ax3R3KDnc5D/soHDFte8ez7pDPf1GvbN65wT4Mj0Mll
 u659+lbRykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAi7w0ZGfYv3iFd9mtTW2v9
 0d1Lth41ipia1Tzt+f5U+4Ucgb+uHFdkZJjUeyaPZcEPpqe1lQECrt+ktZJ+vuW5/cLsyNqzh/b
 /i2ADAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Just like for power status we also need to keep track of data status to
be able to detect mode changes once we introduce de-bouncing for CD321x.
Read it during probe and keep a cached copy of its value.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Heikki Krogerus <heikki.krogerus@linux.intel.com>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index f546f4ae563af3d411ec6591fe9c3b122e4efaab..f347e5bc625497ddff270e3e9e4d2ddaf3ca6bc1 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -176,6 +176,7 @@ struct tps6598x {
 
 	int wakeup;
 	u32 status; /* status reg */
+	u32 data_status;
 	u16 pwr_status;
 	struct delayed_work	wq_poll;
 
@@ -538,6 +539,7 @@ static bool tps6598x_read_data_status(struct tps6598x *tps)
 		dev_err(tps->dev, "failed to read data status: %d\n", ret);
 		return false;
 	}
+	tps->data_status = data_status;
 
 	if (tps->data->trace_data_status)
 		tps->data->trace_data_status(data_status);
@@ -1551,6 +1553,8 @@ static int tps6598x_probe(struct i2c_client *client)
 	if (status & TPS_STATUS_PLUG_PRESENT) {
 		if (!tps6598x_read_power_status(tps))
 			goto err_unregister_port;
+		if (!tps->data->read_data_status(tps))
+			goto err_unregister_port;
 		ret = tps6598x_connect(tps, status);
 		if (ret)
 			dev_err(&client->dev, "failed to register partner\n");

-- 
2.34.1

