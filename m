From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Wed, 12 Aug 2026 20:00:11 -0700
Subject: [PATCH net v6 3/4] net: ethernet: oa_tc6: Disable tx queues on
 fatal error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-fix-race-condition-and-crash-v6-3-6cf90f4a271a@onsemi.com>
References: <20260812-fix-race-condition-and-crash-v6-0-6cf90f4a271a@onsemi.com>
In-Reply-To: <20260812-fix-race-condition-and-crash-v6-0-6cf90f4a271a@onsemi.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786590011; l=1843;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=QEbclI3MVrLiGQYLCknmELxAQxPOBDuJXfAlWYmfMyE=;
 b=2VfDC+V5c/knrnosiBAlzjlOoVLGftfR7YVREB1L4E+rBU3bWpKDq5aQ8beJlnXQ+BXTSudX0
 tm++ez3HR2rDUH3I+LiOrUz90GkkmX3aBw2eP4trDuuTfNYYyiFn1qM
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Previously, TX queue interface was stopped when
disable_traffic flag was set, which would indicate fatal
error. It is more appropriate to disable the queue as,
unless driver is unloaded and reloaded, there is no recovery
after disable_traffic is set.

Queues may be re-enabled inadvertently by other layers.
Intention of disable_traffic is only to stop the traffic
from flowing on fatal error.

Fixes: b542d13fab0f ("net: ethernet: oa_tc6: Interrupt is active low, level triggered.")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v6
  - Updated the comment and commit message to reflect the
    usage of disable_traffic
changes in v5
  - Changed the commit message to accurately reflect the
    changes
changes in v4
  - Reverted the change that turned carrier off on disable_traffic,
    as it may have side effects
changes in v3
  - New patch. Carrier marked off once disable_traffic is set
---
 drivers/net/ethernet/oa_tc6.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 09bc293fb75b..5354ed3ece7e 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -730,6 +730,12 @@ static void oa_tc6_disable_traffic(struct oa_tc6 *tc6)
 	skb = oa_tc6_detach_waiting_tx_skb(tc6);
 	spin_unlock_bh(&tc6->tx_skb_lock);
 
+	/* disable_traffic, when set, is a point of no return to working
+	 * state. TX queues are disabled. In some cases, upper layer or
+	 * vendor code may inadvertently enable the queue. Intention of
+	 * the disable_traffic flag is to stop traffic from flowing.
+	 */
+	netif_tx_disable(tc6->netdev);
 	oa_tc6_drop_tx_skb(tc6, skb);
 	oa_tc6_free_ongoing_skbs(tc6);
 	oa_tc6_write_register(tc6, OA_TC6_REG_INT_MASK0, regval);

-- 
2.43.0

