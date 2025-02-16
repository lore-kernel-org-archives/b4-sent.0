From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 16 Feb 2025 22:18:13 +0100
Subject: [PATCH 2/2] net: tsec: Re-arm packet buffer in error case
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250216-tsec-v1-2-9a704bedd048@posteo.net>
References: <20250216-tsec-v1-0-9a704bedd048@posteo.net>
In-Reply-To: <20250216-tsec-v1-0-9a704bedd048@posteo.net>
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739740693; l=1107;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=SSh2KQviGiBSxqVXj7rXpjNJd656QnKX46ebAatVirI=;
 b=BTQtZNA+y90oDnV/DDQpEbCvxpkarUNWzOQZC6W7ZcU+y7TKnKYXUY1l54gqPPEksTFit9zjx
 eywjN5eM+hBDCa7Y5FcXPpTNkGgiQk8OBgb87mNqXuxZvfkk1EwPIia
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When an error is detected in the TSEC receive path, the driver currently
prints an error message, but leaves the corresponding packet descriptor
in its old state (i.e. owned by the CPU side). As a result, the packet
queue can be starved of available buffers if enough errors happen.

To recover from errors, re-arm the packet buffer descriptor after an
error has been detected.

Errors can be provoked by changing a PHY with phy-mode = "rgmii-id" to
phy-mode = "rgmii".

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/net/tsec.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/net/tsec.c b/drivers/net/tsec.c
index b27fc322db55b7b845f8d629348cb34d79de3cc2..bd4ebdd745a6cee5828ef1584518589c7667e667 100644
--- a/drivers/net/tsec.c
+++ b/drivers/net/tsec.c
@@ -314,6 +314,9 @@ static int tsec_recv(struct udevice *dev, int flags, uchar **packetp)
 			ret = length - 4;
 		} else {
 			printf("Got error %x\n", (status & RXBD_STATS));
+
+			/* Rearm the packet buffer */
+			tsec_free_pkt(dev, NULL, 0);
 		}
 	}
 

-- 
2.48.0.rc1.219.gb6b6757d772

