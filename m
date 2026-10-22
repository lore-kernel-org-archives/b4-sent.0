From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Thu, 22 Oct 2026 16:27:46 +0200
Subject: [PATCH v6 01/13] can: peak_usb: fix missing CAN_ERR_FLAG when
 reporting error counters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261022-canfd_check_channel_idx-v6-1-197704231551@peak-system.fr>
References: <20261022-canfd_check_channel_idx-v6-0-197704231551@peak-system.fr>
In-Reply-To: <20261022-canfd_check_channel_idx-v6-0-197704231551@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Stefan_G=C3=BCnther?= <stefangun@pm.me>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792679273; l=1235;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=yJYGMmDCA5H1YtV9p82vQMvFYiAXoP2GMFxyPs3vVf0=;
 b=giTbEhTDNz1JKGA3Nk9D3GSrBLoWSPvbnnTIHpcUF8ZsSexcQ7ZlE05peeDe8Iqr8U6Fv6Gol
 RpuAxRy2t86CfYYlij4CxeLs+N5zlrQ6ZAloDrY4zhZuo0pnNvNY7Yw
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Stefan Günther <stefangun@pm.me>

When the device reports error counters, the driver incorrectly uses an
assignment (=) instead of a bitwise OR (|=) for CAN_ERR_CNT. This wipes
out the CAN_ERR_FLAG and CAN_ERR_CRTL flags, causing the error frame to
be sent to userspace as a regular CAN frame with ID 0x200.

Fix this by using a bitwise OR to preserve the flags.

Signed-off-by: Stefan Günther <stefangun@pm.me>
Cc: stable@vger.kernel.org
Fixes: 3e5c291c7942 ("can: add CAN_ERR_CNT flag to notify availability of error counter")
Signed-off-by: Marc Kleine-Budde <mkl@pengutronix.de>
---
 drivers/net/can/usb/peak_usb/pcan_usb.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb.c b/drivers/net/can/usb/peak_usb/pcan_usb.c
index 8fd058c32856..785224e00c4e 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb.c
@@ -526,7 +526,7 @@ static int pcan_usb_decode_error(struct pcan_usb_msg_context *mc, u8 n,
 			/* Supply TX/RX error counters in case of
 			 * controller error.
 			 */
-			cf->can_id = CAN_ERR_CNT;
+			cf->can_id |= CAN_ERR_CNT;
 			cf->data[6] = mc->pdev->bec.txerr;
 			cf->data[7] = mc->pdev->bec.rxerr;
 		}

-- 
2.53.0

