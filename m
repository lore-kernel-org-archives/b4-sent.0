From: Ahmet Zeren <niko3x@proton.me>
Date: Fri, 27 Nov 2026 21:53:18 +0300
Subject: [PATCH rtw-next 2/2] wifi: rtl8xxxu: limit the retry count in the
 TX report
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-rtl8xxxu-retry-v1-2-b263ab1e0d1b@proton.me>
References: <20261127-b4-rtl8xxxu-retry-v1-0-b263ab1e0d1b@proton.me>
In-Reply-To: <20261127-b4-rtl8xxxu-retry-v1-0-b263ab1e0d1b@proton.me>
To: Ping-Ke Shih <pkshih@realtek.com>, 
 Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, Luka Gejak <luka.gejak@linux.dev>, 
 Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795805597; l=1373;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=p5FTsoJ9noLxhCIkMxA45ERXVm6ZAc1DxPHWHtYohRo=;
 b=LbC6WJwlYG4iyCD+M6OcUCwlabMQbxV3vWe7zLF4t4FW68uBBzN3fBUdrdGvbR39mso3aHzIl
 D6Mt9Rlr5EXCYoRVqfC7vlHT29QGhVospjLPCdE0O4G2zbrSmqJREJm
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CCX TX report has a 6-bit retry count, but the count passed to
mac80211 is only 5 bits wide. A frame sent with the default retry limit
of 48 is reported with 16 retries.

Limit the reported count to IEEE80211_MAX_TX_RETRY.

Tested on RTL8192CU (0bda:8178): a frame to an absent station sent with
the default retry limit is now reported with 30 retries instead of 16.

Fixes: 8b29fd95e2d3 ("wifi: rtl8xxxu: report real TX status on RTL8188CU/RTL8192CU")
Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index c42bb3666c8..f923983bd44 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -5240,7 +5240,8 @@ static void rtl8xxxu_tx_report_poll_work(struct work_struct *work)
 	ieee80211_tx_info_clear_status(tx_info);
 	if (!(tx_info->flags & IEEE80211_TX_CTL_INJECTED))
 		tx_info->status.rates[0].idx = -1;
-	tx_info->status.rates[0].count = (retry & CCX_RETRY_CNT_MASK) + 1;
+	tx_info->status.rates[0].count = min((retry & CCX_RETRY_CNT_MASK) + 1,
+					     IEEE80211_MAX_TX_RETRY);
 	if (status & CCX_PKT_OK)
 		tx_info->flags |= IEEE80211_TX_STAT_ACK;
 

-- 
2.56.1

