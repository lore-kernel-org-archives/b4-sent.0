From: Marc Kleine-Budde <mkl@pengutronix.de>
Date: Wed, 05 Jul 2023 11:39:55 +0200
Subject: [PATCH 4/6] can: gs_usb: gs_usb_receive_bulk_callback(): make use
 of netdev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230705-gs_usb-rx-offload-v1-4-8e7e46e40137@pengutronix.de>
References: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
In-Reply-To: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
To: linux-can@vger.kernel.org
Cc: kernel@pengutronix.de, Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.13-dev-099c9
X-Developer-Signature: v=1; a=openpgp-sha256; l=983; i=mkl@pengutronix.de;
 h=from:subject:message-id; bh=zz+nwXmpKwhnMzawf01FuKz+6ARnpv+x4HcZTBNnWBg=;
 b=owEBbQGS/pANAwAKAb5QHEoqigToAcsmYgBkpTp5xh6MS+Vi5+6emmBSy+0xA5bo0XTWpnhLV
 T7sUsVKHkuJATMEAAEKAB0WIQQOzYG9qPI0qV/1MlC+UBxKKooE6AUCZKU6eQAKCRC+UBxKKooE
 6CMcCACKom74WEQ+ZPXd5GOnby36AODdI7XaV+NvXtCf6D0guHCaZ9ZQ0E3dCbbEx/jI+65Fstg
 TUfYKYfkFaNHhS5CS65x1a7xmcz40t44hyHy3B0oAuOGnqXrBalrLSzUcbuFUw9rAKvKa6tsdqB
 dULYSNN0LCkR8rlc1eiuSRqqfIkcFYi1nD41yyhdI6a10nridwgPHStsCv9hEPaZz1xAn/dKfsC
 T2ibdWmLVegpXNOChCcuXGEDCrBepME6NCcIya8NmsPuR0hkaUKj4kLPG+/6B2XFPHDH9RfmXRe
 LlBYnm9aB9Id9sbaltL0oR3XxwnSRI6GMJaWgf1/i/FYlxBe
X-Developer-Key: i=mkl@pengutronix.de; a=openpgp;
 fpr=C1400BA0B3989E6FBC7D5B5C2B5EE211C58AEA54
X-Endpoint-Received: by B4 Relay for mkl@pengutronix.de/default with auth_id=52
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use the previously assigned variable netdev instead of using
dev->netdev.

Signed-off-by: Marc Kleine-Budde <mkl@pengutronix.de>
---
 drivers/net/can/usb/gs_usb.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/net/can/usb/gs_usb.c b/drivers/net/can/usb/gs_usb.c
index a60153f4cf1d..b66af9d0ce6a 100644
--- a/drivers/net/can/usb/gs_usb.c
+++ b/drivers/net/can/usb/gs_usb.c
@@ -562,7 +562,7 @@ static void gs_usb_receive_bulk_callback(struct urb *urb)
 
 	if (hf->echo_id == -1) { /* normal rx */
 		if (hf->flags & GS_CAN_FLAG_FD) {
-			skb = alloc_canfd_skb(dev->netdev, &cfd);
+			skb = alloc_canfd_skb(netdev, &cfd);
 			if (!skb)
 				return;
 
@@ -575,7 +575,7 @@ static void gs_usb_receive_bulk_callback(struct urb *urb)
 
 			memcpy(cfd->data, hf->canfd->data, cfd->len);
 		} else {
-			skb = alloc_can_skb(dev->netdev, &cf);
+			skb = alloc_can_skb(netdev, &cf);
 			if (!skb)
 				return;
 

-- 
2.40.1

