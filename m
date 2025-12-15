From: David Heidelberg <david@ixit.cz>
Date: Mon, 15 Dec 2025 15:30:04 +0100
Subject: [PATCH 4/4] Input: stmfts - use client to make future code cleaner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251215-fts-fixes-v1-4-8c1e3a63ebf1@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=999; i=david@ixit.cz;
 h=from:subject:message-id; bh=roHV704aaY9rcMfaAuaHi+mzFaL37M4mv+RVt1dZ7JA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpQBtrW0Sc0TA1KAN4LrhLHI2SDk8w1khRX2x3I
 BJwsriezd6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUAbawAKCRBgAj/E00kg
 choAD/9+4C7jcAftRIQrmL5PLcMe0RuAWm3WOJFJAENwF817DbTZ1B+tnoDmaq4JHk6tiS+koRK
 3UflGChw68pIVdGkPMb46OmqKMJDnMynFu0J4I924oEfXtIOBygHbGn9xYuD3QdX0YiaPJFFuw4
 O/OLlxo5UGd8ADmNvKnJZh+G9yeKrYnRj+hCW/cXex8+mJsPLILQTPWX0ct48oVfO6kAYF36jgZ
 6BlxX0mnl+7X36LhV8nbj5mh2/3ucXyJHw90gjQXS/AwbF9Ltgmfxc0G2CHrsu/8MzoeB9ZBlhW
 PfEctdTDsaDOhZYDRM8D4DE4MrTQPsgDsZTKaDZjoZXawdooPQ33nJCWIyRxBgIaNUcJvNbZ7B1
 cbsmz+RakyxukqjY6Ori/Jkfq99jL2IAihPjPVy20FWiVAS/NgyeRKMhuSh1Q5hwJPqc8MWAQCq
 1a2u7SexBs2sx/BeQ14OuEJOBphYTKjDaymVVPbV2/24pADHQFl73+9XdLiaqogU4Tk45ts9mzx
 NwAtPN5nIpQLX4g3F7X2diyHKHH5XrspYM30IozfcRsEN+hNH1/y8jLhkZ47f6Rze4WUUcHBo/i
 j1ajLbNS9B40ZPjanNwzbW4uaNPmTTNBvuqygoURHJV5kZi0a3BSLUWh533P7/3dKWAW1qz5gqt
 Lx2twOZKVbNUeBA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Make code cleaner, compiler will optimize it away anyway.

Preparation for FTM5 support, where more steps are needed.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/touchscreen/stmfts.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/stmfts.c b/drivers/input/touchscreen/stmfts.c
index 4b166b0a9a5a6..06845a00348cc 100644
--- a/drivers/input/touchscreen/stmfts.c
+++ b/drivers/input/touchscreen/stmfts.c
@@ -747,9 +747,10 @@ static int stmfts_runtime_suspend(struct device *dev)
 static int stmfts_runtime_resume(struct device *dev)
 {
 	struct stmfts_data *sdata = dev_get_drvdata(dev);
+	struct i2c_client *client = sdata->client;
 	int ret;
 
-	ret = i2c_smbus_write_byte(sdata->client, STMFTS_SLEEP_OUT);
+	ret = i2c_smbus_write_byte(client, STMFTS_SLEEP_OUT);
 	if (ret)
 		dev_err(dev, "failed to resume device: %d\n", ret);
 

-- 
2.51.0

