From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Tue, 17 Dec 2024 22:39:24 +0100
Subject: [PATCH v5 12/13] media: i2c: imx214: Fix clock handling on probe
 error or remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241217-imx214-v5-12-387f52adef4d@apitzsch.eu>
References: <20241217-imx214-v5-0-387f52adef4d@apitzsch.eu>
In-Reply-To: <20241217-imx214-v5-0-387f52adef4d@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Vincent Knecht <vincent.knecht@mailoo.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734471561; l=1153;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=bYmYbnNYMd1Ygg42XXpBTqqAKdKjV0T0XBXy4t5yHyw=;
 b=Jw0eXjd06hvXwE3Pis8kr3vun2GNiWXO2Z85OpBxhza9htN8Cavq8dq400Y1e1/nmpXzi0+lD
 RRwMxc/yQomC8GztsJhZk/Xhds4SEwXdPudaWywfqUYXmnPQUpZz9xj
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver should disable or unprepare the clock on probe error and on
removing the module.

Remove regulator_bulk_disable(), because it is called by
imx214_power_off().

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 96d05acfeb66480770bb6291027dd023fdccb649..e8d35f8b0f8b57d64f03ff6f5ed9eac51a671e8e 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -1340,7 +1340,7 @@ static int imx214_probe(struct i2c_client *client)
 	v4l2_ctrl_handler_free(&imx214->ctrls);
 error_power_off:
 	pm_runtime_disable(imx214->dev);
-	regulator_bulk_disable(IMX214_NUM_SUPPLIES, imx214->supplies);
+	imx214_power_off(dev);
 
 	return ret;
 }
@@ -1356,6 +1356,8 @@ static void imx214_remove(struct i2c_client *client)
 	v4l2_ctrl_handler_free(&imx214->ctrls);
 
 	pm_runtime_disable(&client->dev);
+	if (!pm_runtime_status_suspended(&client->dev))
+		imx214_power_off(&client->dev);
 	pm_runtime_set_suspended(&client->dev);
 }
 

-- 
2.47.1

