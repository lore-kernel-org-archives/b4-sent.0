From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 13 Aug 2026 17:26:28 +0200
Subject: [PATCH v4 08/14] usb: ehci: initialize periodic_queue_dma
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-rn102-rn104-series-v4-8-f932ac63efa0@gmail.com>
References: <20260813-rn102-rn104-series-v4-0-f932ac63efa0@gmail.com>
In-Reply-To: <20260813-rn102-rn104-series-v4-0-f932ac63efa0@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786634824; l=886;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=I07P005oeTflIN7rJ7Zu0lr6XpKNNqIvnRvWet2vk98=;
 b=FqCLORTArGu3hPsJfvH3VBMNXTzGwTGl24GwQXkpKJ9rXy4ds4icSeDGqrVLQfLviqYinvqlh
 cm0LBn5YhP3CQv9NahIrQ+iJgOdXX1p3GMkeIZj/2ZOQrEewO21fsjg
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Store the DMA address of the periodic queue head in
ehci->periodic_queue_dma. Without this initialization the periodic
schedule may reference an invalid address.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/usb/host/ehci-hcd.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/usb/host/ehci-hcd.c b/drivers/usb/host/ehci-hcd.c
index 51b9e52a4f..c060d09c64 100644
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

-- 
2.47.3

