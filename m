From: David Heidelberg <david@ixit.cz>
Date: Sat, 08 Mar 2025 21:00:59 +0100
Subject: [PATCH 2/4] iio: light: al3000a: Use DRV_NAME
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250308-al3010-iio-regmap-v1-2-b672535e8213@ixit.cz>
References: <20250308-al3010-iio-regmap-v1-0-b672535e8213@ixit.cz>
In-Reply-To: <20250308-al3010-iio-regmap-v1-0-b672535e8213@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1248; i=david@ixit.cz;
 h=from:subject:message-id; bh=OztXp4B+Ou/RwdPOQioIug1hZ1oOyPA0zbFHMaWwpTA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBnzKJUrEM0E1z5B6zdsevZMBPtg5f0lVFPsD1Jo
 IU2gNgblVmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ8yiVAAKCRBgAj/E00kg
 cmqDD/49ajNvfw4bP7MWvD/QQ0yRsdD47903cCoa5kt/iuVpdL+E4m9TsUnBoNqV9P877afkspN
 xWyDbnm0w04tenzbVNKduFOwU5gFOzFkXA62PVGjO7K1EbaPzbojVcmwTwz7eNXIa+dtkdivyMR
 97ucGVvT9awYNRobTo5IL1Y8swyEXtcDtHOdxovY045POFdaCyYylii5OXl2g7658aWcJmV3ZMK
 mQ25VT9EhTxjfJMDtKjSrrEqUoXXBymQRo1rVl+wBH9m0rZqih/fdJHGttGjeimTnRFRFOz6gHY
 c/5ROacg0SHHmUip0N+oftd+Q5zvm1loaaKSe/kxeG64Q1S8NGGNzv6+zlcnXbVU7hrMuBY0q7G
 7MidBjLn8BSTyGQ7sWOrvKmKlixhVbzpDXMZflX5bwbYKfozBk5T2H02CXaMlVki/p55bzLWUPA
 LW29MT8XkZLYm7hSaBN4SttCp5D7ZNA+XpYzz2st8a0RVLfWgguNo2PJAO4Tyvy+5B6nNffgYCu
 RSdJUvya5hNvEJrCSpVHvaBoX1K+rsn6G0ACFxSR9+Le1dEvqooi0x+sQPbSReabF2+NU4odnW4
 lKrjG2ztrvVxj2JnbgUoU5xXUvsy15dKCMrtihIpZblG3hAUcBm8BFCez9HMhaqXCQYTAkkAPT0
 swYCZDFrIFJlEww==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sync syntax with other similar drivers.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3000a.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/light/al3000a.c b/drivers/iio/light/al3000a.c
index e2fbb1270040f43d9f0a97838861818a8eaef813..e1fa4543f336cec61140b5c44d3794df1fa485cd 100644
--- a/drivers/iio/light/al3000a.c
+++ b/drivers/iio/light/al3000a.c
@@ -13,6 +13,8 @@
 
 #include <linux/iio/iio.h>
 
+#define AL3000A_DRV_NAME "al3000a"
+
 #define AL3000A_REG_SYSTEM		0x00
 #define AL3000A_REG_DATA		0x05
 
@@ -148,7 +150,7 @@ static int al3000a_probe(struct i2c_client *client)
 				     "failed to get vdd regulator\n");
 
 	indio_dev->info = &al3000a_info;
-	indio_dev->name = "al3000a";
+	indio_dev->name = AL3000A_DRV_NAME;
 	indio_dev->channels = al3000a_channels;
 	indio_dev->num_channels = ARRAY_SIZE(al3000a_channels);
 	indio_dev->modes = INDIO_DIRECT_MODE;
@@ -195,7 +197,7 @@ MODULE_DEVICE_TABLE(of, al3000a_of_match);
 
 static struct i2c_driver al3000a_driver = {
 	.driver = {
-		.name = "al3000a",
+		.name = AL3000A_DRV_NAME,
 		.of_match_table = al3000a_of_match,
 		.pm = pm_sleep_ptr(&al3000a_pm_ops),
 	},

-- 
2.47.2

