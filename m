From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:24 +0200
Subject: [PATCH v3 08/15] usb: ehci: initialize periodic_queue_dma
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-8-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=1288;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=LadACguLYd6pPy3mJPh6y+HI9qrWJWEg5Y0e7JJa35o=;
 b=DygitD0EtBcFXt7tKdC87mBxWVMjSirr6EbiMtWBFuIbnlH2VzNRTIAaYFVNo2cOlOtMdf6KR
 9tysw43bNrjB/KwmPtPBpm1D/lPg2Wqbb6CfQvMAbijdXta59+Zxmm+
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Store the DMA address of the periodic queue head in
ehci->periodic_queue_dma. Without this initialization the periodic
schedule may reference an invalid address.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/usb/host/ehci-hcd.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/host/ehci-hcd.c b/drivers/usb/host/ehci-hcd.c
index 51b9e52a4f..a4832bb3ff 100644
--- a/drivers/usb/host/ehci-hcd.c
+++ b/drivers/usb/host/ehci-hcd.c
@@ -897,6 +897,8 @@ static int ehci_init(struct usb_host *host)
 	periodic->qt_next = cpu_to_hc32(QT_NEXT_TERMINATE);
 	periodic->qt_altnext = cpu_to_hc32(QT_NEXT_TERMINATE);
 
+	ehci->periodic_queue_dma = ehci_qh_dma(ehci, periodic);
+
 	/*
 	 * Step 2: Setup frame-list: Every microframe, USB tries the same list.
 	 *         In particular, device specifications on polling frequency
@@ -1442,11 +1444,14 @@ static int ehci_probe(struct device *dev)
 	if (ret)
 		return ret;
 
-	ret = clk_bulk_get_all_enabled(dev, &clks);
+	ret = clk_bulk_get_all(dev, &clks);
 	if (ret < 0)
 		return ret;
 
 	num_clocks = ret;
+	ret = clk_bulk_enable(num_clocks, clks);
+	if (ret)
+		return ret;
 
 	iores = dev_request_mem_resource(dev, 0);
 	if (IS_ERR(iores))

-- 
2.47.3

