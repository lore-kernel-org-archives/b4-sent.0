From: Mark Amirkan <markdamirkan@gmail.com>
Date: Sun, 13 Sep 2026 17:14:09 -0700
Subject: [PATCH net] net: lan743x: fix RX checksum use-after-free
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-b4-send-lan743x-uaf-v1-1-73d563d08ba9@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBAAvyJ77kKM2pB+pXiIyWq3lG3Jqgji3
 03b4wzM7KCUmRRu1Q6ZVlZ+S4H6UkF8BJkIORUGa+zV+LrBoUUlSfgK4tpmwyWM6JNzJqQueuu
 hlJ9MI2+/6x2EZuj/UpfhSXH+/uA4Tkf7Y+R8AAAA
X-Change-ID: 20260913-b4-send-lan743x-uaf-9d770ad5c929
To: Bryan Whitehead <bryan.whitehead@microchip.com>, 
 UNGLinuxDriver@microchip.com, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Raju Lakkaraju <Raju.Lakkaraju@microchip.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Mark Amirkan <markdamirkan@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789344881; l=2027;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=+D0VC0g8sC9iwdKy6+YMNFy+J0OscJTzNWqy5rMabrU=;
 b=LsFa/Ck+61ygVbvn3cK3h7HmOLhrEcg+D1fG//LEQbKWreZCnKj8nO8wxZYj6UsX6xLSNuUTz
 HlkaZh5ytQCBUyPHtykaIktIuqlK9S1/z7BTq753h2gi8y86RwMgmTY
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

lan743x_rx_process_buffer() adds each non-first receive buffer to the
head skb's frag_list.  On the last descriptor, lan743x_rx_trim_skb()
linearizes the head and frees the fragment skb metadata.

The checksum-success path then writes ip_summed through the local skb
pointer, which still points to the final fragment.  This causes a
use-after-free write when a packet spans more than one receive buffer.

Set ip_summed on the surviving head skb instead.  Multi-buffer receive
can occur after a live MTU increase because existing ring entries keep
their old buffer size until they are replenished.

A KUnit test invoking lan743x_rx_process_buffer() with a two-buffer
packet produced a one-byte KASAN use-after-free write before this change.
The same test passed after the change.  The driver object also builds
with W=1.  This was not tested on physical LAN743x hardware.

Fixes: cd6910501cfd ("net: lan743x: Add support for Rx IP & TCP checksum offload")
Cc: stable@vger.kernel.org
Assisted-by: LLM Symbolic
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 drivers/net/ethernet/microchip/lan743x_main.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/microchip/lan743x_main.c b/drivers/net/ethernet/microchip/lan743x_main.c
index 24ae56a3c9ed7..82d3ec20ba259 100644
--- a/drivers/net/ethernet/microchip/lan743x_main.c
+++ b/drivers/net/ethernet/microchip/lan743x_main.c
@@ -2604,7 +2604,7 @@ static int lan743x_rx_process_buffer(struct lan743x_rx *rx)
 							rx->adapter->netdev);
 		if (rx->adapter->netdev->features & NETIF_F_RXCSUM) {
 			if (!is_ice && !is_tce && !is_icsm)
-				skb->ip_summed = CHECKSUM_UNNECESSARY;
+				rx->skb_head->ip_summed = CHECKSUM_UNNECESSARY;
 		}
 		netdev_dbg(netdev, "sending %d byte frame to OS",
 			   rx->skb_head->len);

---
base-commit: e6b6078ea1731b05b3b552497b3bce4bf8b014ae
change-id: 20260913-b4-send-lan743x-uaf-9d770ad5c929

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

