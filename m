From: Francesco Palmarini <palmarini@unive.it>
Subject: [PATCH 0/2] wifi: mt76: mt7615: fix mt7622 wmac init
Date: Sun, 25 Oct 2026 12:32:30 +0000
Message-Id: <20261025-mt7622-patch-sem-v1-0-e16e31c1face@unive.it>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN723WoC/yXMQQqDMBBA0avIrB3Q0UTwKsVFjJM6Ba1kYimId
 ze2y7f4/wDlKKzQFwdE/ojKe82oywL87NYno0zZQBXZuiKDS+osEW4u+RmVF2ym1pjgg21NgJx
 tkYN8f8vH8Lfu44t9uj9wnhe9z7ZtdAAAAA==
X-Change-ID: 20261025-mt7622-patch-sem-3d455fcf645f
To: Felix Fietkau <nbd@nbd.name>, Lorenzo Bianconi <lorenzo@kernel.org>, 
 Ryder Lee <ryder.lee@mediatek.com>
Cc: Shayne Chen <shayne.chen@mediatek.com>, 
 Sean Wang <sean.wang@mediatek.com>, linux-wireless@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, 
 Francesco Palmarini <palmarini@unive.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792931550; l=1313;
 i=palmarini@unive.it; s=20261025; h=from:subject:message-id;
 bh=TAUeTqoHydFZudstTa347nDclKp24/ne5JhcQ0rYjV4=;
 b=1MCrRsC72ux1oKScKeczk0gvTY//W9FiRMbaJ2xoYyTZ5HEHHkGZ2cClP9U2L4sS4yuGtJd12
 3YdpZXsTYg8Dh/6sGMDhNs2ana+dmoSHpzrSHf4sJSClnGVUYTywOI7
X-Developer-Key: i=palmarini@unive.it; a=ed25519;
 pk=3OQ6zyqkl8a98pNobVtrSRWmLpTk0XEeKGtpd+/yK70=
X-Endpoint-Received: by B4 Relay for palmarini@unive.it/20261025 with auth_id=1317
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On MT7622 the 2.4 GHz wmac fails to come up on most boots with
"Failed to get patch semaphore". The rom does grant the semaphore, but
its reply to the first PATCH_SEM_CONTROL lands on the data ring with an
extra dword in front and gets dropped as tx status, so every retry
finds the semaphore already taken.

Patch 1 handles the shifted event, patch 2 releases the semaphore after
a timeout so a lost reply can't block the init anymore.

Tested on a Xiaomi AX3200 (same hw as Redmi AX6S) running OpenWrt
25.12.6: 0 of 5 boots ok before, 15 of 15 with both patches. Build
tested on wireless-next.

OpenWrt reports of the same failure:
https://github.com/openwrt/openwrt/issues/14874
https://github.com/openwrt/openwrt/issues/17565

Signed-off-by: Francesco Palmarini <palmarini@unive.it>
---
Francesco Palmarini (2):
      wifi: mt76: mt7615: fix lost first mcu event on mt7622
      wifi: mt76: mt7615: release patch semaphore on timeout

 drivers/net/wireless/mediatek/mt76/mt7615/mac.c | 23 +++++++++++++++++++++++
 drivers/net/wireless/mediatek/mt76/mt7615/mcu.c |  4 ++++
 2 files changed, 27 insertions(+)
---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261025-mt7622-patch-sem-3d455fcf645f

Best regards,
--  
Francesco Palmarini <palmarini@unive.it>

