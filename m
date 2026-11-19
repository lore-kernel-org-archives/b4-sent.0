From: Ahmet Zeren <niko3x@proton.me>
Date: Fri, 20 Nov 2026 01:12:45 +0300
Subject: [PATCH rtw-next 1/2] wifi: rtl8xxxu: don't report frames sent
 without ACK as acked
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-b4-tx-status-v1-1-abdab21c77fe@proton.me>
References: <20261120-b4-tx-status-v1-0-abdab21c77fe@proton.me>
In-Reply-To: <20261120-b4-tx-status-v1-0-abdab21c77fe@proton.me>
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795126366; l=1066;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=4nTmHPGR7iLtAHTLFXXQzLy8duSl4o0+8WyF/8dmXhA=;
 b=jBoTLsc2fFyN0SNXky+4ebR1ue0dbb2q/e8Co86WNwNcJd7IFRrkEGPBAZJGsKWrc3kAE141d
 8H7s9MrJ3HbDgKGkS2eDknFVTM1mf/7PdqtnYaTDLHpUwgHtGFl8kBf
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Every frame whose USB transfer succeeded is reported as acked, including
those sent with IEEE80211_TX_CTL_NO_ACK. Report these as
IEEE80211_TX_STAT_NOACK_TRANSMITTED instead.

Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 604bb1e5b0..ab2818986c 100644
--- a/drivers/net/wireless/realtek/rtl8xxxu/core.c
+++ b/drivers/net/wireless/realtek/rtl8xxxu/core.c
@@ -5167,8 +5167,12 @@ static void rtl8xxxu_tx_complete(struct urb *urb)
 	tx_info->status.rates[0].idx = -1;
 	tx_info->status.rates[0].count = 0;
 
-	if (!urb->status)
-		tx_info->flags |= IEEE80211_TX_STAT_ACK;
+	if (!urb->status) {
+		if (tx_info->flags & IEEE80211_TX_CTL_NO_ACK)
+			tx_info->flags |= IEEE80211_TX_STAT_NOACK_TRANSMITTED;
+		else
+			tx_info->flags |= IEEE80211_TX_STAT_ACK;
+	}
 
 	ieee80211_tx_status_irqsafe(hw, skb);
 

-- 
2.56.1

