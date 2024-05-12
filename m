From: Sven Peter <sven@svenpeter.dev>
Date: Sun, 12 May 2024 12:12:08 +0000
Subject: [PATCH 2/2] Bluetooth: hci_bcm4377: Fix msgid release
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240512-btfix-msgid-v1-2-ab1bd938a7f4@svenpeter.dev>
References: <20240512-btfix-msgid-v1-0-ab1bd938a7f4@svenpeter.dev>
In-Reply-To: <20240512-btfix-msgid-v1-0-ab1bd938a7f4@svenpeter.dev>
To: Hector Martin <marcan@marcan.st>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715515936; l=963;
 i=sven@svenpeter.dev; s=20240512; h=from:subject:message-id;
 bh=jmwV6wL7bQ7AC4V+W+yysWv9DtBZLTuAd0ES/PoP/v8=;
 b=7ui0qeOF+oHKDon5u5ak3Eh73AiQcV5LdfOLkQQVlohhDLtZ3KrwJxR+9srljp9ec98oAlQhL
 u3GwBfq3Cr0CPEfC86uW9tBlIhCnUzivu8IAebQ4U/BKta51vjqQsbj
X-Developer-Key: i=sven@svenpeter.dev; a=ed25519;
 pk=jIiCK29HFM4fFOT2YTiA6N+4N7W+xZYQDGiO0E37bNU=
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/20240512 with auth_id=159
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

We are releasing a single msgid, so the order argument to
bitmap_release_region must be zero.

Fixes: 8a06127602de ("Bluetooth: hci_bcm4377: Add new driver for BCM4377 PCIe boards")
Cc: stable@vger.kernel.org
Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Sven Peter <sven@svenpeter.dev>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/bluetooth/hci_bcm4377.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/bluetooth/hci_bcm4377.c b/drivers/bluetooth/hci_bcm4377.c
index 5b818a0e33d6..92d734f02e00 100644
--- a/drivers/bluetooth/hci_bcm4377.c
+++ b/drivers/bluetooth/hci_bcm4377.c
@@ -717,7 +717,7 @@ static void bcm4377_handle_ack(struct bcm4377_data *bcm4377,
 		ring->events[msgid] = NULL;
 	}
 
-	bitmap_release_region(ring->msgids, msgid, ring->n_entries);
+	bitmap_release_region(ring->msgids, msgid, 0);
 
 unlock:
 	spin_unlock_irqrestore(&ring->lock, flags);

-- 
2.34.1

