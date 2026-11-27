From: Ahmet Zeren <niko3x@proton.me>
Date: Fri, 27 Nov 2026 21:53:17 +0300
Subject: [PATCH rtw-next 1/2] wifi: rtl8xxxu: limit max_rate_tries to what
 mac80211 can pass
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-rtl8xxxu-retry-v1-1-b263ab1e0d1b@proton.me>
References: <20261127-b4-rtl8xxxu-retry-v1-0-b263ab1e0d1b@proton.me>
In-Reply-To: <20261127-b4-rtl8xxxu-retry-v1-0-b263ab1e0d1b@proton.me>
To: Ping-Ke Shih <pkshih@realtek.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, Luka Gejak <luka.gejak@linux.dev>, 
 Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795805597; l=1352;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=7rDvRyAZq7izG3XCkldF+vIaKytmFeA6a8qQUUZnYrU=;
 b=dCidGzEhc3O2c6oo19xVa5KgLvPHJFNtwGNZSII82xe0QqR1TDssQBY7/vMVjGbLPvWWj9MLM
 /UelML0INFcC3EOBI4HLrtk+QR0F8lBynIvCNNtQqIwU+Z/3ICsGAAo
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The retry count of a rate is a 5-bit field in mac80211, so it cannot
hold the 64 tries set as max_rate_tries. Radiotap retry counts above 30
wrap around: 31 retries fall back to the default retry limit and 40
retries become 8.

Limit max_rate_tries by IEEE80211_MAX_TX_RETRY as well.

Tested on RTL8192CU (0bda:8178) with injected frames to an absent
station, reading the retry count from the TX report: 31 and 40
requested retries are now capped at 30.

Fixes: b2ccb6a04761 ("wifi: rtl8xxxu: honour the retry count of injected frames on gen1 chips")
Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index f10397294a5..c42bb3666c8 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -8131,7 +8131,7 @@ static int rtl8xxxu_probe(struct usb_interface *interface,
 	SET_IEEE80211_PERM_ADDR(hw, priv->mac_addr);
 
 	hw->extra_tx_headroom = priv->fops->tx_desc_size;
-	hw->max_rate_tries = TXDESC32_RETRY_LIMIT_MAX + 1;
+	hw->max_rate_tries = min(TXDESC32_RETRY_LIMIT_MAX + 1, IEEE80211_MAX_TX_RETRY);
 	ieee80211_hw_set(hw, SIGNAL_DBM);
 
 	/*

-- 
2.56.1

