From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Mon, 27 Apr 2026 17:18:07 -0700
Subject: [PATCH 2/3] i2c: xiic: defer RX_FULL until all trailing bytes are
 in FIFO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260427-i2c-xiic-v1-2-e6207f9aa5ad@nexthop.ai>
References: <20260427-i2c-xiic-v1-0-e6207f9aa5ad@nexthop.ai>
In-Reply-To: <20260427-i2c-xiic-v1-0-e6207f9aa5ad@nexthop.ai>
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1720;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=/BR++2xUka9oKwbdfFmIjG9WrhZsf5+FmlIpH4Pjs/c=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZL7/c5Dl1rVsxY3/f5udq7z6ZWXx1n2lu9jToncwV
 nQ8kNa6vuJvRykLgxgXg6yYIsucR/5v2jraIjbEHLKHmcPKBDKEgYtTACbCacjIcIOLUWjar5tb
 n+Tu97xhFckYv8L3SMvfx/KTDnMU3Em03cHIsOGUcENQ5t4lVzP5PCTOxCUzhAVOOVD/xHJyg4d
 ObZ81KwAG1lBj
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For the normal path of xiic_smbus_block_read_setup() (rxmsg_len less
than IIC_RX_FIFO_DEPTH), RFD was programmed to rxmsg_len - 2, which
fires the RX_FULL interrupt while the last payload byte is still in
flight. xiic_read_rx()'s bytes_rem == 1 branch then sets NACK on that
byte still on the wire, truncating the read in the PEC-enabled case.

Raise the threshold so RX_FULL fires only once every remaining byte
(payload plus optional PEC) is already buffered in the FIFO. That
routes the drain through xiic_read_rx()'s bytes_rem == 0 path, which
reads everything out and emits the stop cleanly. For the non-PEC path
the full payload is still read out through the same bytes_rem == 0
branch; the only user-visible change is that the controller waits one
extra byte-time before servicing the interrupt.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/i2c/busses/i2c-xiic.c | 7 ++-----
 1 file changed, 2 insertions(+), 5 deletions(-)

diff --git a/drivers/i2c/busses/i2c-xiic.c b/drivers/i2c/busses/i2c-xiic.c
index 959a47b645a5..946e3ed2d760 100644
--- a/drivers/i2c/busses/i2c-xiic.c
+++ b/drivers/i2c/busses/i2c-xiic.c
@@ -559,11 +559,8 @@ static void xiic_smbus_block_read_setup(struct xiic_i2c *i2c)
 			rfd_set = 0;
 			i2c->rx_msg->len = SMBUS_BLOCK_READ_MIN_LEN;
 		} else {
-			/*
-			 * When Rx msg len less than Rx fifo capacity
-			 * Receive fifo depth should set to Rx msg len minus 2
-			 */
-			rfd_set = rxmsg_len - 2;
+			/* Defer RX_FULL until all trailing bytes are in FIFO. */
+			rfd_set = rxmsg_len + pec_len - 1;
 			i2c->rx_msg->len = rxmsg_len + 1 + pec_len;
 		}
 		xiic_setreg8(i2c, XIIC_RFD_REG_OFFSET, rfd_set);

-- 
2.53.0

