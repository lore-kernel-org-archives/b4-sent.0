From: David Heidelberg <david@ixit.cz>
Date: Mon, 15 Dec 2025 15:30:01 +0100
Subject: [PATCH 1/4] Input: stmfts - correct wording for the warning
 message
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251215-fts-fixes-v1-1-8c1e3a63ebf1@ixit.cz>
References: <20251215-fts-fixes-v1-0-8c1e3a63ebf1@ixit.cz>
In-Reply-To: <20251215-fts-fixes-v1-0-8c1e3a63ebf1@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Javier Martinez Canillas <javier@osg.samsung.com>, 
 Rob Herring <robh@kernel.org>, Andi Shyti <andi@etezian.org>
Cc: linux-input@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=901; i=david@ixit.cz;
 h=from:subject:message-id; bh=zOdQuMRtwbT9fTBVbDJbgo/FBNojnDOTgGlU+/RFodc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpQBtrMN45yASJj+00VAkGd5xdIZEokXHQ2coVt
 zB6A4cgLICJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUAbawAKCRBgAj/E00kg
 cmt/D/0WqN7Qnefn04HGZtDjWqh6Xd3bFVndWwMvuHkGWgqXin0Zz/PSV9ITNRECWqPY/ijIjzb
 QRs1FjZjoX0fwPn1I32WGLypaGIwk64KWTIY1vegL/Ocrl++34Y2YIBphH6P6uw+n5yzGRK0/Xh
 hAsOWgiN2FwBd1Q3qn98deFk9PJVrPq7YIDeAp7/58aBIUxvdd9kWq/B8bRv2LzufshyTkxNjq0
 LExaY/z3xkYjEwuI2D9mXagWS3doWS4womk7GYxbfcWhTfW9JuLP5X6YxDhXX0efbf34/xet2Yk
 x4t9PEtwiYR53Y0LbJS18egxymFMXJlJezYbUTIxN8OoK+Kcaqceg3CioSQwrOyzxaeRQNizSo2
 hd2sfwAREdCgTfKy9KX7CrGoMvSSxynuHrYP+0785QiwU9+dXb/kV53HQK9hDGqWJ2xTw24zpKF
 hjeGgxU5qQJsr60EzcT8fFnuh3sn7v5EQP3zO3dyCqG3f7RIX4uT5VQnbEO+IEaTq9g+0EdbfbH
 xdtPtlgZ7i9KmKXBNZRGHnKn3HJB9qLBa/K1OgKsLkos6GHp5qLew9HGDlUhouQns6M4qxBT/d7
 cdUy5LSPRkuW+cBEq54O20NMWj/GwWVs7Vfq5x8lGiYfjX3F51KFq90B91xqliZXDkgphc9wqAC
 GPMM7leEGyjXGuQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We're trying to enable regulator, not disable it.

Fixes: 78bcac7b2ae1 ("Input: add support for the STMicroelectronics FingerTip touchscreen")
Suggested-by: Petr Hodina <petr.hodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 119cd26851cf6..9f5609524fef6 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -120,7 +120,7 @@ static int stmfts_brightness_set(struct led_classdev *led_cdev,
 			err = regulator_enable(sdata->ledvdd);
 			if (err) {
 				dev_warn(&sdata->client->dev,
-					 "failed to disable ledvdd regulator: %d\n",
+					 "failed to enable ledvdd regulator: %d\n",
 					 err);
 				return err;
 			}

-- 
2.51.0

