From: David Heidelberg <david@ixit.cz>
Date: Mon, 15 Dec 2025 15:30:02 +0100
Subject: [PATCH 2/4] Input: stmfts - Make comments correct
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251215-fts-fixes-v1-2-8c1e3a63ebf1@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1218; i=david@ixit.cz;
 h=from:subject:message-id; bh=+8T1xTsOJVjn1XL+OiuDFzpjTwMdaheaKiJkn4uzNC0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpQBtrVk+/KB6coTqNYuMnIBrB/vm2/YxgSKgeO
 8D5TYOcCq2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUAbawAKCRBgAj/E00kg
 covAEACkdHFzLF0RrJb2jwOKLvgWbj8IznAZvFQpIEQkeIU5AwcTJ1W9s2KF9wToGtq0+B0VWj+
 fhPAsSz1iFl5SYfbBL56CuJp821p0Yn4QY0SyNrahuGyu9n6i900VLzcvB0rWqrR4RV4Bc9UOio
 VUmytGFM0q3f2/tY2pvHMsjhV9bD3DsUOc5e9WiXBViDmgnr7WCIjtTpFyhGRJ4jMw+bA14Y2TC
 07emPYv7j8L2Eq+9sQ4dNmQnP08J4XVlT1049ul3d5gfTNebtKcKoEDQ4rpcSIClPU1ODnMITnu
 rcWLOekQH4/CgsX62gA7rUqVISQJ0O+2XQmHaIdj6/pDLU+iQNaXcaDI7v/moY03HVuDQBpqrJ3
 JD8QnHAjwIRiKKG6EDj+i72lrQ21a3w4MMMSnoGTx3k4uJP8/AE3DLzyIaYf107Hrw0hDyC5ji7
 CbSlohpGYP8vOfzJccv1RnhhfoZeSmVWMPEa6G5mvuHCooAz2qT0d/tWqM3ML1Q2JAfPK6BHfK8
 rgAfBlxaUqI3lwDntbn9r3fNCuGvQwiaYIZiWGuGFEoBMJbANQuULYQEXDf1kY8o0UMfNb+Qx9C
 mS8D/VtdQl5WRPVB2YeSpQZgUf9UMQaa6G+oZaS41jzFGqvw/Di6gFm94TxnUW14NK2BbmeCcIw
 hVftWP6lsLGmQUQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

No functional change.

Fixes: 78bcac7b2ae1 ("Input: add support for the STMicroelectronics FingerTip touchscreen")
Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 5 +----
 1 file changed, 1 insertion(+), 4 deletions(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 9f5609524fef6..ad363b3c344cd 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -141,7 +141,7 @@ static enum led_brightness stmfts_brightness_get(struct led_classdev *led_cdev)
 
 /*
  * We can't simply use i2c_smbus_read_i2c_block_data because we
- * need to read more than 255 bytes (
+ * need to read 256 bytes, which exceeds the 255-byte SMBus block limit.
  */
 static int stmfts_read_events(struct stmfts_data *sdata)
 {
@@ -594,9 +594,6 @@ static void stmfts_power_off(void *data)
 						sdata->regulators);
 }
 
-/* This function is void because I don't want to prevent using the touch key
- * only because the LEDs don't get registered
- */
 static int stmfts_enable_led(struct stmfts_data *sdata)
 {
 	int err;

-- 
2.51.0

