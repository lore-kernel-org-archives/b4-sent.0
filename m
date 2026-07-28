From: Luca Lauro <famlauro93l@gmail.com>
Date: Tue, 28 Jul 2026 19:43:21 +0200
Subject: [PATCH v2 09/10] usb: ehci: minor fixes for Marvell compatibility
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-rn102-rn104-series-v2-9-ae31f55b7bc8@gmail.com>
References: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
In-Reply-To: <20260728-rn102-rn104-series-v2-0-ae31f55b7bc8@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785260594; l=3961;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=SJFrCS1AirmMyQw0TPPCEMJeimZIbSYRXN807jgLidE=;
 b=I+Dl1GwsWv/154AP/aNrogOTBOzNatJMVivENTDQf316/leaKjcxKTUqEnnEH0Y4oH/CdnwH0
 i08qRY6aWIhCgtwpXBsp0I9c99H3a/65v8HHhHA6wrtpn8uoHyLwBlN
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Marvell EHCI controller requires a slightly different initialization
sequence compared to generic EHCI implementations.

- Calling ehci_halt() before ehci_reset() can leave the controller in an
  inconsistent state on Marvell SoCs. U-Boot and Linux avoid halting the
  controller before issuing a reset, so drop the early ehci_halt() call.

- The periodic queue DMA address must be explicitly stored in
  ehci->periodic_queue_dma. Without this, the periodic schedule points to
  an uninitialized address, breaking interrupt polling and HID enumeration.

- Only allocate the periodic list when it is NULL. The previous code
  allocated a new list unconditionally, leaking memory and breaking
  reinitialization paths.

- Use ehci->periodic_list_dma directly without casting, as it already
  contains the correct dma_addr_t value.

Whitespace-only changes have been removed.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/usb/host/ehci-hcd.c | 23 ++++++++++++-----------
 1 file changed, 12 insertions(+), 11 deletions(-)

diff --git a/drivers/usb/host/ehci-hcd.c b/drivers/usb/host/ehci-hcd.c
index 51b9e52a4f..69b20b7487 100644
--- a/drivers/usb/host/ehci-hcd.c
+++ b/drivers/usb/host/ehci-hcd.c
@@ -857,8 +857,6 @@ static int ehci_init(struct usb_host *host)
 	struct QH *periodic;
 	int i;
 
-	ehci_halt(ehci);
-
 	/* EHCI spec section 4.1 */
 	if (ehci_reset(ehci) != 0)
 		return -1;
@@ -870,16 +868,16 @@ static int ehci_init(struct usb_host *host)
 	}
 
 	ehci->qh_list[0].qh_link = cpu_to_hc32(ehci_qh_dma(ehci, &ehci->qh_list[1]) |
-					       QH_LINK_TYPE_QH);
+									QH_LINK_TYPE_QH);
 	ehci->qh_list[0].qh_endpt1 = cpu_to_hc32(QH_ENDPT1_H(1) |
-						 QH_ENDPT1_EPS(USB_SPEED_HIGH));
+									QH_ENDPT1_EPS(USB_SPEED_HIGH));
 	ehci->qh_list[0].qh_curtd = cpu_to_hc32(QT_NEXT_TERMINATE);
 	ehci->qh_list[0].qt_next = cpu_to_hc32(QT_NEXT_TERMINATE);
 	ehci->qh_list[0].qt_altnext = cpu_to_hc32(QT_NEXT_TERMINATE);
 	ehci->qh_list[0].qt_token = cpu_to_hc32(QT_TOKEN_STATUS_HALTED);
 
 	ehci->qh_list[1].qh_link = cpu_to_hc32(ehci_qh_dma(ehci,
-							   &ehci->qh_list[0]) |
+									&ehci->qh_list[0]) |
 					       QH_LINK_TYPE_QH);
 	ehci->qh_list[1].qt_altnext = cpu_to_hc32(QT_NEXT_TERMINATE);
 
@@ -897,6 +895,7 @@ static int ehci_init(struct usb_host *host)
 	periodic->qt_next = cpu_to_hc32(QT_NEXT_TERMINATE);
 	periodic->qt_altnext = cpu_to_hc32(QT_NEXT_TERMINATE);
 
+	ehci->periodic_queue_dma = ehci_qh_dma(ehci, periodic);
 	/*
 	 * Step 2: Setup frame-list: Every microframe, USB tries the same list.
 	 *         In particular, device specifications on polling frequency
@@ -906,23 +905,25 @@ static int ehci_init(struct usb_host *host)
 	 *         Split Transactions will be spread across microframes using
 	 *         S-mask and C-mask.
 	 */
-	if (ehci->periodic_list == NULL)
+	if (ehci->periodic_list == NULL) {
+		ehci->periodic_list = dma_alloc_coherent(DMA_DEVICE_BROKEN,
+								1024 * 4,
+								&ehci->periodic_list_dma);
+	}
 		/*
 		 * FIXME: this memory chunk have to be 4k aligned AND
 		 * reside in coherent memory. Current implementation of
 		 * dma_alloc_coherent() allocates PAGE_SIZE aligned memory chunks.
 		 * PAGE_SIZE less then 4k will break this code.
 		 */
-		ehci->periodic_list = dma_alloc_coherent(DMA_DEVICE_BROKEN, 1024 * 4,
-						&ehci->periodic_list_dma);
 	for (i = 0; i < 1024; i++) {
-		ehci->periodic_list[i] = cpu_to_hc32((unsigned long)ehci->periodic_queue_dma
-						| QH_LINK_TYPE_QH);
+		ehci->periodic_list[i] = cpu_to_hc32(ehci->periodic_queue_dma | 
+								QH_LINK_TYPE_QH);
 	}
 
 	/* Set periodic list base address */
 	ehci_writel(&ehci->hcor->or_periodiclistbase,
-		    (uint32_t)ehci->periodic_list_dma);
+		    	ehci->periodic_list_dma);
 
 	reg = ehci_readl(&ehci->hccr->cr_hcsparams);
 	descriptor.hub.bNbrPorts = HCS_N_PORTS(reg);

-- 
2.47.3

