From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Tue, 09 Jun 2026 12:50:25 -0700
Subject: [PATCH net v4 2/4] net: ethernet: oa_tc6: No return on rx buffer
 overflow error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260609-level-trigger-v4-2-6f389abdd192@onsemi.com>
References: <20260609-level-trigger-v4-0-6f389abdd192@onsemi.com>
In-Reply-To: <20260609-level-trigger-v4-0-6f389abdd192@onsemi.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>, 
 Andrew Lunn <andrew@lunn.ch>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 devicetree@vger.kernel.org, Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781034634; l=1060;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=yhR8HTXSMQfVHwLvu+hxa/iwF+g3lB6yLmCaf00cLr0=;
 b=+dS5oTqpgsXIpSMF3woxcgZKVCEYPQO5BLXzIGMbTLyg58wC1VGsEVD0iOHPaH2CtXFFhs4Gd
 tGBLwxgZ/lwCHA8goLH4YNWb8E8CdUnQaY5OqI5rPkP4F2rOGj8iCiY
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On RX buffer overflow error, the bad data chunks must
be thrown away and code should look for a data chunk with
"start valid" bit set, which would indicate next valid MAC
frame. In this change, oa_tc6_try_spi_transfer is called
again if it returns error code EAGAIN. This helps to
recover from the error gracefully.

Fixes: 2c6ce5354453 ("net: ethernet: oa_tc6: implement mac-phy interrupt")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

Changes in v4:
   new patch
---
 drivers/net/ethernet/oa_tc6.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index e2c0843207f2..20c9e98d1d60 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -1111,6 +1111,8 @@ static irqreturn_t oa_tc6_macphy_threaded_irq(int irq, void *data)
 
 	while (tc6->int_flag || (tc6->waiting_tx_skb && tc6->tx_credits)) {
 		ret = oa_tc6_try_spi_transfer(tc6);
+		if (ret == -EAGAIN)
+			continue;
 		if (ret)
 			break;
 	}

-- 
2.43.0

