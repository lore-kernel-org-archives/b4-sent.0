From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 22:19:26 +0200
Subject: [PATCH 08/19] thunderbolt: Allocate ring HopID before requesting
 the ring interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-soc-tbt-v1-8-44bc9348683c@kernel.org>
References: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
In-Reply-To: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1852; i=sven@kernel.org;
 h=from:subject:message-id; bh=RpEpSG63+tBPZuuziz+1veWy6ZIV0qRqo8PjvUS8qJs=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aUCWFH0ybf7Lx1kkX1xuxVUnppiybwLvoz38XszI9pW
 TkLDu7N7ShlYRDjYpAVU2TZvt/e9MnDN4JLN116DzOHlQlkCAMXpwBM5HInw//IjU/LvuZpb8n7
 e7b74Q2+SStY3r/VkJl00EdH/NmFoyuVGP4KHOjh/ms74xn3jHMz/WZ3TXsUY5fvWbby6CedzfL
 966fyAgA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Apple NHI has one interrupt per ring and request_ring_irq picks it
based on ring->hop which is still -1 at this point for rings allocated
with an automatic HopID. Allocate the HopID first and release it again
if the interrupt request fails.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/nhi.c | 23 ++++++++++++++++-------
 1 file changed, 16 insertions(+), 7 deletions(-)

diff --git a/drivers/thunderbolt/nhi.c b/drivers/thunderbolt/nhi.c
index 5809809f64d4..6a97dcd57deb 100644
--- a/drivers/thunderbolt/nhi.c
+++ b/drivers/thunderbolt/nhi.c
@@ -534,6 +534,16 @@ static int nhi_alloc_hop(struct tb_nhi *nhi, struct tb_ring *ring)
 	return ret;
 }
 
+static void nhi_free_hop(struct tb_nhi *nhi, struct tb_ring *ring)
+{
+	guard(spinlock_irq)(&nhi->lock);
+
+	if (ring->is_tx)
+		nhi->tx_rings[ring->hop] = NULL;
+	else
+		nhi->rx_rings[ring->hop] = NULL;
+}
+
 static struct tb_ring *tb_ring_alloc(struct tb_nhi *nhi, u32 hop, int size,
 				     bool transmit, unsigned int flags,
 				     int e2e_tx_hop, u16 sof_mask, u16 eof_mask,
@@ -581,19 +591,18 @@ static struct tb_ring *tb_ring_alloc(struct tb_nhi *nhi, u32 hop, int size,
 	if (!ring->descriptors)
 		goto err_free_ring;
 
+	if (nhi_alloc_hop(nhi, ring))
+		goto err_free_descs;
+
 	if (!(flags & RING_FLAG_NO_INTERRUPT) && nhi->ops->request_ring_irq) {
 		if (nhi->ops->request_ring_irq(ring, flags & RING_FLAG_NO_SUSPEND))
-			goto err_free_descs;
+			goto err_free_hop;
 	}
 
-	if (nhi_alloc_hop(nhi, ring))
-		goto err_release_msix;
-
 	return ring;
 
-err_release_msix:
-	if (nhi->ops->release_ring_irq)
-		nhi->ops->release_ring_irq(ring);
+err_free_hop:
+	nhi_free_hop(nhi, ring);
 err_free_descs:
 	dma_free_coherent(ring->nhi->dev,
 			  ring->size * sizeof(*ring->descriptors),

-- 
2.55.0

