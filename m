From: Sven Peter <sven@svenpeter.dev>
Date: Sun, 12 May 2024 12:12:07 +0000
Subject: [PATCH 1/2] Bluetooth: hci_bcm4377: Increase boot timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240512-btfix-msgid-v1-1-ab1bd938a7f4@svenpeter.dev>
References: <20240512-btfix-msgid-v1-0-ab1bd938a7f4@svenpeter.dev>
In-Reply-To: <20240512-btfix-msgid-v1-0-ab1bd938a7f4@svenpeter.dev>
To: Hector Martin <marcan@marcan.st>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715515936; l=1230;
 i=sven@svenpeter.dev; s=20240512; h=from:subject:message-id;
 bh=l5zSo1PIT3qiMZokOHqlZSiHEp61gw9G4TR1ydgJdn8=;
 b=n9bTv01yWWAEQyW+jcLjnXCkBT8m4v+1sdLTdkCYA3JsdBqYIW4HWVo/du2TPgpdY0+vEtEB4
 T1TnR3JSZ2OAgeOOqyVSTnayjE6KuEhWnqjURCkz09+JQZmZBnRmMWq
X-Developer-Key: i=sven@svenpeter.dev; a=ed25519;
 pk=jIiCK29HFM4fFOT2YTiA6N+4N7W+xZYQDGiO0E37bNU=
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/20240512 with auth_id=159
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

BCM4388 takes over 2 seconds to boot, so increase the timeout (and also
fix the units while we're here).

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Sven Peter <sven@svenpeter.dev>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/bluetooth/hci_bcm4377.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/bluetooth/hci_bcm4377.c b/drivers/bluetooth/hci_bcm4377.c
index 9a7243d5db71..5b818a0e33d6 100644
--- a/drivers/bluetooth/hci_bcm4377.c
+++ b/drivers/bluetooth/hci_bcm4377.c
@@ -32,7 +32,8 @@ enum bcm4377_chip {
 #define BCM4378_DEVICE_ID 0x5f69
 #define BCM4387_DEVICE_ID 0x5f71
 
-#define BCM4377_TIMEOUT 1000
+#define BCM4377_TIMEOUT msecs_to_jiffies(1000)
+#define BCM4377_BOOT_TIMEOUT msecs_to_jiffies(5000)
 
 /*
  * These devices only support DMA transactions inside a 32bit window
@@ -1857,7 +1858,7 @@ static int bcm4377_boot(struct bcm4377_data *bcm4377)
 	dev_dbg(&bcm4377->pdev->dev, "waiting for firmware to boot\n");
 
 	ret = wait_for_completion_interruptible_timeout(&bcm4377->event,
-							BCM4377_TIMEOUT);
+							BCM4377_BOOT_TIMEOUT);
 	if (ret == 0) {
 		ret = -ETIMEDOUT;
 		goto out_dma_free;

-- 
2.34.1

