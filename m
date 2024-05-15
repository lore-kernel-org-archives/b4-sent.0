From: Sven Peter <sven@svenpeter.dev>
Date: Wed, 15 May 2024 18:15:04 +0000
Subject: [PATCH v2 3/3] Bluetooth: hci_bcm4377: Fix msgid release
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240515-btfix-msgid-v2-3-bb06b9ecb6d1@svenpeter.dev>
References: <20240515-btfix-msgid-v2-0-bb06b9ecb6d1@svenpeter.dev>
In-Reply-To: <20240515-btfix-msgid-v2-0-bb06b9ecb6d1@svenpeter.dev>
To: Hector Martin <marcan@marcan.st>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>, stable@vger.kernel.org, 
 Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715796911; l=1005;
 i=sven@svenpeter.dev; s=20240512; h=from:subject:message-id;
 bh=S7xKEZCg+8p3UVaw49Z8FtTJmOjvz1UbYciOj2+ura0=;
 b=Ozstng7yF96uysi12zXuTli9Av64oDUsLQGnA5QC7XKF+rkN/vFAN8YmgOFkBAkzcgLMw+oG8
 v1/n4dTc7moC9rw82K6I7tGXE6vhBtG/SHGdxQJmXK/iIGr0pvp3Djb
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
Reviewed-by: Neal Gompa <neal@gompa.dev>
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

