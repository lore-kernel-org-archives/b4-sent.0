From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 17 Aug 2025 19:09:24 +0200
Subject: [PATCH 5/7] media: i2c: dw9719: Update PM last busy time upon
 close
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250817-dw9719-v1-5-426f46c69a5a@apitzsch.eu>
References: <20250817-dw9719-v1-0-426f46c69a5a@apitzsch.eu>
In-Reply-To: <20250817-dw9719-v1-0-426f46c69a5a@apitzsch.eu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755450582; l=819;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=q/vBSjo9Qq/woAcBDvdCyCNYGx0lB2/sChYnvyiSRpE=;
 b=ShTf9qRg6/Sm4Xrcbbqdp2eN1v94VVjWsY5fBe13VbUi4gs32pfRF8Q6BROFE5g5WAEGVeiUs
 gJ4iRy4n+AXDuFpk7PSJIRxdb6B/gNIEjdN1Iv65coyBc/4L1JYvm9L
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Val Packett <val@packett.cool>

Update the close callback to match other similar drivers like dw9768.

Signed-off-by: Val Packett <val@packett.cool>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/dw9719.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/dw9719.c b/drivers/media/i2c/dw9719.c
index 61758a9450aee20c9226e879a15eccfced9a3e96..2952d8064899e4ac29f3b1af02692fe8043ccfac 100644
--- a/drivers/media/i2c/dw9719.c
+++ b/drivers/media/i2c/dw9719.c
@@ -284,7 +284,8 @@ static int dw9719_open(struct v4l2_subdev *sd, struct v4l2_subdev_fh *fh)
 
 static int dw9719_close(struct v4l2_subdev *sd, struct v4l2_subdev_fh *fh)
 {
-	pm_runtime_put(sd->dev);
+	pm_runtime_mark_last_busy(sd->dev);
+	pm_runtime_put_autosuspend(sd->dev);
 
 	return 0;
 }

-- 
2.50.1

