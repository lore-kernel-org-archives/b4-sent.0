From: Jiaheng Zhang <lurenjia534@outlook.com>
Date: Mon, 03 Aug 2026 02:36:52 +0800
Subject: [PATCH wireless v2] wifi: mac80211_hwsim: drop frames with invalid
 channel width
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-mac80211-hwsim-invalid-width-v2-1-73724b7a216d@outlook.com>
X-B4-Tracking: v=1; b=H4sIAEOOb2oC/42Oy27CMBBFfwXNmimxhfJgxX9ULMbOFE9JbOQJS
 RHKvzdJxb6rq/vQ0X2BchZWOO1ekHkUlRQXY/c78IHilVHaxYMtbFnUhcWe/CLGYJhUepQ4Uic
 tTtIOAZuqqo0rmaqyhgVxz/wlPxv+EybJ3LEqXP4afbhv9sNKX7eOlNFlij6s0Xt96Eni2gfRI
 eXn9nQ0G/F/p0aDBptj2zhHlrgszukxdCndPnzq4TLP8y/6W0VnBgEAAA==
X-Change-ID: 20260802-mac80211-hwsim-invalid-width-97781b6ea768
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+435fdb053cf98bfa5778@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Jiaheng Zhang <lurenjia534@outlook.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785695818; l=3238;
 i=lurenjia534@outlook.com; s=20260801; h=from:subject:message-id;
 bh=BEm/DevqbcVuAp+oAP+KtQG1eYVhSPXPqK+tv0Hh/DM=;
 b=MQq4rxQlpM2MuCmPTCClzJxmVSfRJZra+JSNyjW9pAW3QCGdolvJvYKfyK282QfXUKK01AEpH
 m8EG+zVpaS/DcG2rlnsVj7Mh2M+j1rmVKGn7BLFmB2e8Ql3wjlVFEMl
X-Developer-Key: i=lurenjia534@outlook.com; a=ed25519;
 pk=nMa0OcUJYxnaGbhs5f95IwVQ7sPrWI7It3LMsh0BJX4=
X-Endpoint-Received: by B4 Relay for lurenjia534@outlook.com/20260801 with auth_id=906
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A frame injected through a monitor interface can request a VHT transmit
rate wider than the channel configured on the simulated radio.  The rate
comes from userspace-provided radiotap metadata, so it can be invalid.

mac80211_hwsim_tx() currently warns and returns when the requested rate is
wider than the channel.  A warning is inappropriate for invalid userspace
input.  Moreover, hwsim owns the skb after its ->tx() callback is invoked,
so returning without reporting status or freeing the skb leaks it.

Drop frames with an invalid channel width and release their SKBs with
ieee80211_free_txskb().  Frames with valid rates continue through the
existing transmit path.

The reproducer triggered the warning in 20 of 20 unmodified-kernel boots.
With this change, 100 iterations completed without a warning on both the
report baseline and wireless/main.  An E2E control also confirmed that a
valid 20 MHz frame was forwarded while a 160 MHz request on the same
channel was dropped.

Fixes: 585625c955b1 ("mac80211_hwsim: check TX and STA bandwidth")
Reported-by: syzbot+435fdb053cf98bfa5778@syzkaller.appspotmail.com
Closes: https://lore.kernel.org/all/6a441a03.b42ede87.8e801.0009.GAE@google.com/
Tested-by: syzbot+435fdb053cf98bfa5778@syzkaller.appspotmail.com
Cc: stable@vger.kernel.org
Assisted-by: Codex:GPT-5.6 MAX
Signed-off-by: Jiaheng Zhang <lurenjia534@outlook.com>
---
Testing:
- syzbot #syz test on wireless/main: pass
- original syzbot C reproducer: 20/20 report-baseline boots warned;
  unmodified wireless/main warned in 3/3 independent boots
- patched original reproducer: 100/100 iterations clean on both the report
  baseline and wireless/main
- monitor-injection E2E: valid 20 MHz frame forwarded; invalid 160 MHz
  frame dropped
- CONFIG_MAC80211_HWSIM=y/m runtime tests: clean, taint 0
- GCC x86-64 full y/m builds, GCC W=1, sparse, and Clang x86-64/arm64
  target builds: pass
---
Changes in v2:
- Use my real name, Jiaheng Zhang, in the author and Signed-off-by fields
  to comply with kernel submission identity requirements.
- Explicitly target the wireless tree.
- No code changes.
- Link to v1: https://patch.msgid.link/20260802-mac80211-hwsim-invalid-width-v1-1-94d9bba2ae60@outlook.com
---
 drivers/net/wireless/virtual/mac80211_hwsim_main.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/virtual/mac80211_hwsim_main.c b/drivers/net/wireless/virtual/mac80211_hwsim_main.c
index 75caa97bec..2d4bc3cd9a 100644
--- a/drivers/net/wireless/virtual/mac80211_hwsim_main.c
+++ b/drivers/net/wireless/virtual/mac80211_hwsim_main.c
@@ -2256,8 +2256,10 @@ static void mac80211_hwsim_tx(struct ieee80211_hw *hw,
 		else if (rflags & IEEE80211_TX_RC_160_MHZ_WIDTH)
 			bw = NL80211_CHAN_WIDTH_160;
 
-		if (WARN_ON(hwsim_get_chanwidth(bw) > hwsim_get_chanwidth(confbw)))
+		if (hwsim_get_chanwidth(bw) > hwsim_get_chanwidth(confbw)) {
+			ieee80211_free_txskb(hw, skb);
 			return;
+		}
 	}
 
 	/* wmediumd mode check */

---
base-commit: 2812e64e1575e05500a35c405aaa6e99b7d7930b
change-id: 20260802-mac80211-hwsim-invalid-width-97781b6ea768

Best regards,
--  
Jiaheng Zhang <lurenjia534@outlook.com>

