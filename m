From: Sven Peter <sven@svenpeter.dev>
Date: Wed, 15 May 2024 18:15:03 +0000
Subject: [PATCH v2 2/3] Bluetooth: hci_bcm4377: Increase boot timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240515-btfix-msgid-v2-2-bb06b9ecb6d1@svenpeter.dev>
References: <20240515-btfix-msgid-v2-0-bb06b9ecb6d1@svenpeter.dev>
In-Reply-To: <20240515-btfix-msgid-v2-0-bb06b9ecb6d1@svenpeter.dev>
To: Hector Martin <marcan@marcan.st>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715796911; l=1118;
 i=sven@svenpeter.dev; s=20240512; h=from:subject:message-id;
 bh=byENbovROROZ6LTg/OZr99a9V8DiMo0qMmjQUs9RxZg=;
 b=U9OQBMfY7bWDNjv5YOB/lQunPI+LOIMFM3a0UzhVjqnHTbEFME1936bVtxWbKi+DIDVIlYqcF
 0so1SLJpV7sBpS2pfElZdkeeOyTLScDMjekuT0kVZMv0y9Y6VFbTIEs
X-Developer-Key: i=sven@svenpeter.dev; a=ed25519;
 pk=jIiCK29HFM4fFOT2YTiA6N+4N7W+xZYQDGiO0E37bNU=
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/20240512 with auth_id=159
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

BCM4388 takes over 2 seconds to boot, so increase the timeout.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Sven Peter <sven@svenpeter.dev>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/bluetooth/hci_bcm4377.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/bluetooth/hci_bcm4377.c b/drivers/bluetooth/hci_bcm4377.c
index caf9b64c8111..5b818a0e33d6 100644
--- a/drivers/bluetooth/hci_bcm4377.c
+++ b/drivers/bluetooth/hci_bcm4377.c
@@ -33,6 +33,7 @@ enum bcm4377_chip {
 #define BCM4387_DEVICE_ID 0x5f71
 
 #define BCM4377_TIMEOUT msecs_to_jiffies(1000)
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

