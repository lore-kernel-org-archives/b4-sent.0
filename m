From: Sven Peter <sven@svenpeter.dev>
Date: Wed, 15 May 2024 18:15:02 +0000
Subject: [PATCH v2 1/3] Bluetooth: hci_bcm4377: Use correct unit for
 timeouts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240515-btfix-msgid-v2-1-bb06b9ecb6d1@svenpeter.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715796911; l=839;
 i=sven@svenpeter.dev; s=20240512; h=from:subject:message-id;
 bh=7gQn02PYjfQWipM5wmSh7cRXbC3rcrKdfUfT0gxlvsA=;
 b=5vuT3iBepkv/NY4S5torbyPLDbQY84+ans4BusJj/uJoM6EIqY5izWUCJv/R9gWadUKYhg+sU
 pnvq3oniF36ArujjWEGXIvjbZukR6B/RB7+8A1jxROyY4DQpNkQcJra
X-Developer-Key: i=sven@svenpeter.dev; a=ed25519;
 pk=jIiCK29HFM4fFOT2YTiA6N+4N7W+xZYQDGiO0E37bNU=
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/20240512 with auth_id=159
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BCM4377_TIMEOUT is always used to wait for completitions and their API
expects a timeout in jiffies instead of msecs.

Fixes: 8a06127602de ("Bluetooth: hci_bcm4377: Add new driver for BCM4377 PCIe boards")
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/bluetooth/hci_bcm4377.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/bluetooth/hci_bcm4377.c b/drivers/bluetooth/hci_bcm4377.c
index 9a7243d5db71..caf9b64c8111 100644
--- a/drivers/bluetooth/hci_bcm4377.c
+++ b/drivers/bluetooth/hci_bcm4377.c
@@ -32,7 +32,7 @@ enum bcm4377_chip {
 #define BCM4378_DEVICE_ID 0x5f69
 #define BCM4387_DEVICE_ID 0x5f71
 
-#define BCM4377_TIMEOUT 1000
+#define BCM4377_TIMEOUT msecs_to_jiffies(1000)
 
 /*
  * These devices only support DMA transactions inside a 32bit window

-- 
2.34.1

