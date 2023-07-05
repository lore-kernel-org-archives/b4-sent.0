From: Marc Kleine-Budde <mkl@pengutronix.de>
Date: Wed, 05 Jul 2023 11:39:54 +0200
Subject: [PATCH 3/6] can: gs_usb: gs_usb_receive_bulk_callback(): count RX
 overflow errors also in case of OOM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230705-gs_usb-rx-offload-v1-3-8e7e46e40137@pengutronix.de>
References: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
In-Reply-To: <20230705-gs_usb-rx-offload-v1-0-8e7e46e40137@pengutronix.de>
To: linux-can@vger.kernel.org
Cc: kernel@pengutronix.de, Marc Kleine-Budde <mkl@pengutronix.de>
X-Mailer: b4 0.13-dev-099c9
X-Developer-Signature: v=1; a=openpgp-sha256; l=1185; i=mkl@pengutronix.de;
 h=from:subject:message-id; bh=GKQzem9MCaDKD+CYo1F0A0x3ZO3+aBNF5BxFuvgp1OY=;
 b=owEBbQGS/pANAwAKAb5QHEoqigToAcsmYgBkpTp3cRLRpgNiG9gLwrJE1zS/P2EDYgoac7SWK
 rl877uNZ8CJATMEAAEKAB0WIQQOzYG9qPI0qV/1MlC+UBxKKooE6AUCZKU6dwAKCRC+UBxKKooE
 6MjIB/9Z08jmbD52uWLUn/3UXHeHa5K2hubho2WWgmuQvUQt5bqeAGmAZ0lnU7ZHFwIEpiAjZ0v
 tqiLsbtnwwv33ujIeTLKnjDOlGlagxeeyqhr9iJa2j5LdUKZmraDhXFe/H9mdO+EyETBBG0nHKY
 kFXpGV8uzjQQFbwWvFEfTxs7cMkd6bcLUz0bB9Y3lQOD/xMN5dnbXDHBJUxdn0JK8MKmNONXZ22
 kpOHG19/NMm4J4LHMoNqlwvZSvwhJ6ZB+ZUhEF0Z2lgmIzNt5kMJ8h6cjqzy1524cNJMKG5GF4/
 N0Ezo/F0zY+FDcbbRczNprn71oNRGDfQO8G+Yo1HYVKaVYtf
X-Developer-Key: i=mkl@pengutronix.de; a=openpgp;
 fpr=C1400BA0B3989E6FBC7D5B5C2B5EE211C58AEA54
X-Endpoint-Received: by B4 Relay for mkl@pengutronix.de/default with auth_id=52
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In case of an RX overflow error from the CAN controller and an OOM
where no skb can be allocated, the error counters are not incremented.

Fix this by first incrementing the error counters and then allocate
the skb.

Fixes: d08e973a77d1 ("can: gs_usb: Added support for the GS_USB CAN devices")
Signed-off-by: Marc Kleine-Budde <mkl@pengutronix.de>
---
 drivers/net/can/usb/gs_usb.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/net/can/usb/gs_usb.c b/drivers/net/can/usb/gs_usb.c
index d476c2884008..a60153f4cf1d 100644
--- a/drivers/net/can/usb/gs_usb.c
+++ b/drivers/net/can/usb/gs_usb.c
@@ -628,6 +628,9 @@ static void gs_usb_receive_bulk_callback(struct urb *urb)
 	}
 
 	if (hf->flags & GS_CAN_FLAG_OVERFLOW) {
+		stats->rx_over_errors++;
+		stats->rx_errors++;
+
 		skb = alloc_can_err_skb(netdev, &cf);
 		if (!skb)
 			goto resubmit_urb;
@@ -635,8 +638,6 @@ static void gs_usb_receive_bulk_callback(struct urb *urb)
 		cf->can_id |= CAN_ERR_CRTL;
 		cf->len = CAN_ERR_DLC;
 		cf->data[1] = CAN_ERR_CRTL_RX_OVERFLOW;
-		stats->rx_over_errors++;
-		stats->rx_errors++;
 		netif_rx(skb);
 	}
 

-- 
2.40.1

