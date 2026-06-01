From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 01 Jun 2026 09:07:18 -0700
Subject: [PATCH net v3 1/2] net: ethernet: oa_tc6: Interrupt is active low,
 level triggered.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-level-trigger-v3-1-da73e7010532@onsemi.com>
References: <20260601-level-trigger-v3-0-da73e7010532@onsemi.com>
In-Reply-To: <20260601-level-trigger-v3-0-da73e7010532@onsemi.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Andrew Lunn <andrew@lunn.ch>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 devicetree@vger.kernel.org, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780330051; l=994;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=PqRuuDbw4zLWSskW8G1FH424GyCxxpkBl/f2rNkAlbg=;
 b=qGXpWOEDACG/EIW3bVEn/p3fl4bx4qiapy453UbY4aGCkOdU/2LuQ5xi60yy22fYnE0nEZ/4k
 9YS5rBnV20YAKtBwalaGBnNDqAbQoQblWs99VomGhEiy4prdX7dwz0O
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According OPEN Alliance 10BASET1x MAC-PHY Serial Interface
specification, interrupt is active low, level triggered.

Fixes: 2c6ce5354453 ("net: ethernet: oa_tc6: implement mac-phy interrupt")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
 drivers/net/ethernet/oa_tc6.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 91a906a7918a..667faf155405 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -1323,7 +1323,7 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev)
 	sched_set_fifo(tc6->spi_thread);
 
 	ret = devm_request_irq(&tc6->spi->dev, tc6->spi->irq, oa_tc6_macphy_isr,
-			       IRQF_TRIGGER_FALLING, dev_name(&tc6->spi->dev),
+			       IRQF_TRIGGER_LOW, dev_name(&tc6->spi->dev),
 			       tc6);
 	if (ret) {
 		dev_err(&tc6->spi->dev, "Failed to request macphy isr %d\n",

-- 
2.43.0

