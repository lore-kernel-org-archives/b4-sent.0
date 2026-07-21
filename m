From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 20 Jul 2026 19:20:37 -0700
Subject: [PATCH net v4 3/3] net: ethernet: oa_tc6: Disabled tx queues when
 disable_traffic is set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-fix-race-condition-and-crash-v4-3-8273e2f38a1f@onsemi.com>
References: <20260720-fix-race-condition-and-crash-v4-0-8273e2f38a1f@onsemi.com>
In-Reply-To: <20260720-fix-race-condition-and-crash-v4-0-8273e2f38a1f@onsemi.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Andrew Lunn <andrew@lunn.ch>, 
 Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784600442; l=1302;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=G5SfllbV/PC7FsuuOcRTYnuvtsbR0nxTKy7i93ghP+4=;
 b=/61oGyRTdppdnWwmvQewbMjpmLAPT1+acCoE67og71xTheZQwqpEWQ/NRgoOCuCAqlG1nChZk
 LMvjluVFg6TAv/+EiIsK09amwYSrTbao1ZeAjtrgVHjOm5AosbpzzZB
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Previously, TX queue interface was stopped when
disable_traffic flag was set. It is more appropriate to
disable the queue as there is no recovery, once
disable_traffic is set. Carrier is also marked off

Fixes: b542d13fab0f ("net: ethernet: oa_tc6: Interrupt is active low, level triggered.")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

changes in v4
  - Reverted the the statement that turned carrier off on
    disble_traffic, as it may have side effects
changes in v3
  - New patch. Carrier marked off once disable_traffic is set
---
 drivers/net/ethernet/oa_tc6.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 9e6850ccfe6c..4b8f6280be51 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -730,6 +730,11 @@ static void oa_tc6_disable_traffic(struct oa_tc6 *tc6)
 	skb = oa_tc6_detach_waiting_tx_skb(tc6);
 	spin_unlock_bh(&tc6->tx_skb_lock);
 
+	/* disable_traffic, when set, is a point of no
+	 * return to working state. TX queues are
+	 * disabled.
+	 */
+	netif_tx_disable(tc6->netdev);
 	oa_tc6_drop_tx_skb(tc6, skb);
 	oa_tc6_free_ongoing_skbs(tc6);
 	oa_tc6_write_register(tc6, OA_TC6_REG_INT_MASK0, regval);

-- 
2.43.0

