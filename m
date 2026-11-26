From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 12:24:11 +0000
Subject: [PATCH 6.6.y] wifi: mt76: mt7915: clear wcid mask under mutex
 after RCU pointer clear
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-so1-mt-66-v1-1-429a17b69783@certik.com>
X-B4-Tracking: v=1; b=H4sIAOokCGsC/z2MQQ7CIBAAv9Ls2a2CcaN+xXgAuliMQsOi0TT9u
 6CJx5lMZgbhHFjg2M2Q+RkkpFhBrTpwo4kXxjBUBr3RpJQmlKTwXpAIjdodvN17q2gLtZ8y+/D
 6vk5APfVvOP+0POyVXWmfFlojjDab6MamhONQUrph8+v/H5blA4kzXGmeAAAA
X-Change-ID: 20261126-so1-mt-66-a159fb8fb163
To: stable@vger.kernel.org
Cc: Felix Fietkau <nbd@nbd.name>, Lorenzo Bianconi <lorenzo@kernel.org>, 
 linux-wireless@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795695850; l=2795;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=2Yvt6AJuNvts0+ANo6CU0QtnmDtVLXdldOC/Am3e2gA=;
 b=w+O49ZjIy9egfIJbvByoykDXAcgK+TPmDWIgXps9KXkT+HQlgsgluVsBhtUMsjgUuGRE14I11
 s3n5Sy3qv3eApIubLJz/OVseZUi3g8Z6+GuM348Hf//IpAMb0gzWPZ2
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Felix Fietkau <nbd@nbd.name>

commit 6486e11a6e2f679597af2d5bb48c3b07a2b2a7ba upstream.

mt7915_remove_interface() cleared the wcid mask bit with no lock held and
before clearing the RCU wcid pointer. The mask is a non-atomic RMW shared
with the allocators, which all run under dev->mt76.mutex; on DBDC the two
wiphys share one mt76_dev, so this raced add_interface/sta_add on the
other band and could leak or double-hand-out a wcid. Clearing the bit
before the RCU pointer also let a concurrent allocation reuse the index
and publish its wcid, which the subsequent NULL assignment then wiped.
Move the clear into the existing mutex section, after the RCU pointer is
cleared.

Fixes: f3049b88b2b3 ("wifi: mt76: mt7915: allocate vif wcid in the same range as stations")
Link: https://patch.msgid.link/20260722082610.2699628-8-nbd@nbd.name
Signed-off-by: Felix Fietkau <nbd@nbd.name>
[ adapted to 6.6.y: context only, older mt7915_mcu_add_sta() call ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.12.y and newer already have this fix. The moved line is the same as
upstream; only the surrounding context differs on this branch.

Tested on v6.6.163:
- x86_64 allmodconfig W=1 build of
  drivers/net/wireless/mediatek/mt76/mt7915/main.o, base vs patched,
  no new warnings
- booted the patched kernel with CONFIG_MT7915E=y under QEMU/KVM. I
  don't have mt7915 hardware, so the remove path wasn't run.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/net/wireless/mediatek/mt76/mt7915/main.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/wireless/mediatek/mt76/mt7915/main.c b/drivers/net/wireless/mediatek/mt76/mt7915/main.c
index 864f636666e5..017181c1a2ea 100644
--- a/drivers/net/wireless/mediatek/mt76/mt7915/main.c
+++ b/drivers/net/wireless/mediatek/mt76/mt7915/main.c
@@ -306,7 +306,6 @@ static void mt7915_remove_interface(struct ieee80211_hw *hw,
 
 	mt7915_mcu_add_bss_info(phy, vif, false);
 	mt7915_mcu_add_sta(dev, vif, NULL, false);
-	mt76_wcid_mask_clear(dev->mt76.wcid_mask, mvif->sta.wcid.idx);
 
 	mutex_lock(&dev->mt76.mutex);
 	mt76_testmode_reset(phy->mt76, true);
@@ -322,6 +321,7 @@ static void mt7915_remove_interface(struct ieee80211_hw *hw,
 	mutex_lock(&dev->mt76.mutex);
 	dev->mt76.vif_mask &= ~BIT_ULL(mvif->mt76.idx);
 	phy->omac_mask &= ~BIT_ULL(mvif->mt76.omac_idx);
+	mt76_wcid_mask_clear(dev->mt76.wcid_mask, mvif->sta.wcid.idx);
 	mutex_unlock(&dev->mt76.mutex);
 
 	spin_lock_bh(&dev->mt76.sta_poll_lock);

---
base-commit: e2bb30811e063ce0db964484357973b855b06572
change-id: 20261126-so1-mt-66-a159fb8fb163

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

