From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 16 Dec 2024 22:00:58 +0100
Subject: [PATCH v4 12/13] media: i2c: imx214: Fix clock handling on probe
 error or remove
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241216-imx214-v4-12-8cbda160fbce@apitzsch.eu>
References: <20241216-imx214-v4-0-8cbda160fbce@apitzsch.eu>
In-Reply-To: <20241216-imx214-v4-0-8cbda160fbce@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>, 
 Vincent Knecht <vincent.knecht@mailoo.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734382889; l=1153;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=ClL94X4s2eV905yGjnxIxBW7JXrrqHRlT04Ut/i9afE=;
 b=n2aw+dUZqV/HRpAw2CK/KHXkfeYT038EHThcHbYPkHIAQYGFyAhEKWL0JS9WLYSIsL+87molz
 EjVk5ws56iPB463adylOXVoTkAg6PZczhuSwaR/rqJqZvRVCF95CbmY
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
index d15422873e7ba0588914d78d3d26374d2769541c..0e587f0a44d941bd7d9230b56df18c08250e679e 100644
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

