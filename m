From: Francesco Palmarini <palmarini@unive.it>
Date: Sun, 25 Oct 2026 12:32:32 +0000
Subject: [PATCH 2/2] wifi: mt76: mt7615: release patch semaphore on timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-mt7622-patch-sem-v1-2-e16e31c1face@unive.it>
References: <20261025-mt7622-patch-sem-v1-0-e16e31c1face@unive.it>
In-Reply-To: <20261025-mt7622-patch-sem-v1-0-e16e31c1face@unive.it>
To: Felix Fietkau <nbd@nbd.name>, Lorenzo Bianconi <lorenzo@kernel.org>, 
 Ryder Lee <ryder.lee@mediatek.com>
Cc: Shayne Chen <shayne.chen@mediatek.com>, 
 Sean Wang <sean.wang@mediatek.com>, linux-wireless@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, 
 Francesco Palmarini <palmarini@unive.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792931550; l=1053;
 i=palmarini@unive.it; s=20261025; h=from:subject:message-id;
 bh=gm2VLBwmfqY23pExgMK+uypJiAwiosMBXJDOkm1v6RE=;
 b=gWZ0YAfCqwHipQdYCe6q71ZgHMHe1mMQ6A9PlotTC2QPDjExNWI4VCZ1S7D+l/2Dny3W0dlzV
 6Jnn8EGxvgtCUSUgWwZN+YlMNVY2Tuh9JwCE+tBub5kvNawUGHYewi6
X-Developer-Key: i=palmarini@unive.it; a=ed25519;
 pk=3OQ6zyqkl8a98pNobVtrSRWmLpTk0XEeKGtpd+/yK70=
X-Endpoint-Received: by B4 Relay for palmarini@unive.it/20261025 with auth_id=1317
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the PATCH_SEM_CONTROL reply gets lost, the rom may still have granted
the semaphore and every following attempt fails with
PATCH_NOT_DL_SEM_FAIL. Release it on timeout so the next retry can get
it again.

Signed-off-by: Francesco Palmarini <palmarini@unive.it>
---
 drivers/net/wireless/mediatek/mt76/mt7615/mcu.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7615/mcu.c b/drivers/net/wireless/mediatek/mt76/mt7615/mcu.c
index aab4303fe..5f5e29f49 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7615/mcu.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7615/mcu.c
@@ -1259,6 +1259,10 @@ static int mt7615_load_patch(struct mt7615_dev *dev, u32 addr, const char *name)
 		goto release_fw;
 	case PATCH_NOT_DL_SEM_SUCCESS:
 		break;
+	case -ETIMEDOUT:
+		/* rom might have granted the semaphore anyway */
+		mt76_connac_mcu_patch_sem_ctrl(&dev->mt76, false);
+		fallthrough;
 	default:
 		dev_err(dev->mt76.dev, "Failed to get patch semaphore\n");
 		ret = -EAGAIN;

-- 
2.39.5

