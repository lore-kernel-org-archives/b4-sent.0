From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 24 Aug 2026 14:58:00 -0700
Subject: [PATCH net v7 3/4] net: ethernet: oa_tc6: Disable tx queues on
 fatal error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-fix-race-condition-and-crash-v7-3-4323279b18f2@onsemi.com>
References: <20260824-fix-race-condition-and-crash-v7-0-4323279b18f2@onsemi.com>
In-Reply-To: <20260824-fix-race-condition-and-crash-v7-0-4323279b18f2@onsemi.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>, 
 Andrew Lunn <andrew@lunn.ch>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787608678; l=1777;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=rupj0zGgOlZK1eLggoH075xcps0FMhyfJaHXp4mXjW4=;
 b=J1EsISlNShSTJoxzP+ndhRIyGJXz8uWSl0mNwLwl480VQPmm/RGH9nme0HGPrM5akmjcAnGT8
 TNZZkgcxNaVCoY53RO6AM8xbivgsy77LflN6P+WH+asKTxDq+FzOEZC
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
changes in v7
  - Changed comment to make it simple on why tx queues are
    disabled
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
 drivers/net/ethernet/oa_tc6.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 657b1c6119da..eea00b41fb8d 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -771,6 +771,10 @@ static void oa_tc6_disable_traffic(struct oa_tc6 *tc6)
 	skb = oa_tc6_detach_waiting_tx_skb(tc6);
 	spin_unlock_bh(&tc6->tx_skb_lock);
 
+	/* disable_traffic, when set, is a point of no return to
+	 * working state. Keeping the TX queues disabled.
+	 */
+	netif_tx_disable(tc6->netdev);
 	oa_tc6_drop_tx_skb(tc6, skb);
 	oa_tc6_free_ongoing_skbs(tc6);
 	oa_tc6_write_register(tc6, OA_TC6_REG_INT_MASK0, regval);

-- 
2.43.0

