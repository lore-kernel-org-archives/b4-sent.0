From: Ahmet Zeren <niko3x@proton.me>
Date: Sun, 22 Nov 2026 09:00:38 +0300
Subject: [PATCH rtw-next v2 1/2] wifi: rtl8xxxu: don't report frames sent
 without ACK as acked
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-tx-status-v2-1-bbfdbd880acf@proton.me>
References: <20261122-b4-tx-status-v2-0-bbfdbd880acf@proton.me>
In-Reply-To: <20261122-b4-tx-status-v2-0-bbfdbd880acf@proton.me>
To: Jes Sorensen <Jes.Sorensen@gmail.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ping-Ke Shih <pkshih@realtek.com>, Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795327244; l=1116;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=h6bAHAMFOpj1IhPJ2DluIsvK0mURYFEXBxECpWk1+QY=;
 b=KBSOJIwcXE8mX8ebPNFIL+ro8lLsYELEy9gKfyk645dsMQxfhfMEdXqwbR+Y3dXG8C9YCptQ0
 u1PXSDMiCIsBUa5OeESGFPQ05sGd8itosh1/lTvNL6PzeNzvtJeB24e
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Every frame whose USB transfer succeeded is reported as acked, including
those sent with IEEE80211_TX_CTL_NO_ACK. Report these as
IEEE80211_TX_STAT_NOACK_TRANSMITTED instead.

Reviewed-by: Ping-Ke Shih <pkshih@realtek.com>
Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
 drivers/net/wireless/realtek/rtl8xxxu/core.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/realtek/rtl8xxxu/core.c b/drivers/net/wireless/realtek/rtl8xxxu/core.c
index 604bb1e5b05..ab2818986cc 100644
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

