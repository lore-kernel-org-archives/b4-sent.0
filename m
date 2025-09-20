From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 20 Sep 2025 14:03:46 +0200
Subject: [PATCH v2 7/8] media: i2c: dw9719: Update PM last busy time upon
 close
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250920-dw9719-v2-7-028cdaa156e5@apitzsch.eu>
References: <20250920-dw9719-v2-0-028cdaa156e5@apitzsch.eu>
In-Reply-To: <20250920-dw9719-v2-0-028cdaa156e5@apitzsch.eu>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Daniel Scally <djrscally@gmail.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Val Packett <val@packett.cool>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758369833; l=778;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=VbfafRxdOY0QSTO5ZHN0pYfZbUgGkIdRhbekGlrCdzU=;
 b=3eJJI02EOCQhEH1NiwouP1tDE6ONH5nW8FLORTih5gRb/z/IqGU+QhtxL38eIA9vZ6K2D4x/f
 grSdvIcxAcMDBg32/o157DOYrjdqelerYOGmHNHw06VJ2Dmakqe236P
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Val Packett <val@packett.cool>

Update the close callback to match other similar drivers like dw9768.

Signed-off-by: Val Packett <val@packett.cool>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/dw9719.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/i2c/dw9719.c b/drivers/media/i2c/dw9719.c
index 5e3a200db3b5df8bf49547fc842c1cfd74322a40..a24594523030df7df7fb60afb5248472b4a8ea13 100644
--- a/drivers/media/i2c/dw9719.c
+++ b/drivers/media/i2c/dw9719.c
@@ -284,7 +284,7 @@ static int dw9719_open(struct v4l2_subdev *sd, struct v4l2_subdev_fh *fh)
 
 static int dw9719_close(struct v4l2_subdev *sd, struct v4l2_subdev_fh *fh)
 {
-	pm_runtime_put(sd->dev);
+	pm_runtime_put_autosuspend(sd->dev);
 
 	return 0;
 }

-- 
2.51.0

