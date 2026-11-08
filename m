From: Cunhao Lu <1579567540@qq.com>
Date: Sun, 08 Nov 2026 19:33:30 +0800
Subject: [PATCH net v8 03/10] can: rockchip_canfd: retry the outstanding TX
 buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-rockchip-canfd-restart-close-v8-3-3e7a23fd9eae@qq.com>
References: <20261108-rockchip-canfd-restart-close-v8-0-3e7a23fd9eae@qq.com>
In-Reply-To: <20261108-rockchip-canfd-restart-close-v8-0-3e7a23fd9eae@qq.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, kernel@pengutronix.de, 
 Vincent Mailhol <mailhol@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Oliver Hartkopp <socketcan@hartkopp.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Wolfgang Grandegger <wg@grandegger.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-can@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794137678; l=1735;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=mAdiDJWuUPvQyM82hTpk52wGLUSpbq2jpnpY6emM93U=;
 b=5PD3i2rXvndHL9umpnZZAsui/1VjENqN/gRejX7O7unl+AadS6RIjqskIrEeKTbuOi2Z5U+n+
 V5DughzQwSGAMzCZBZhEjnvCjwIxOfZtZl3wXwGzioCjFv+ItgjAm8I
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rkcanfd_xmit_retry() uses tx_head to select the buffer for the erratum 6
retransmission. With a TX FIFO depth of one, the masked head and tail
indices both select buffer 0. With two buffers and one outstanding frame,
tx_head selects the next free buffer instead of the pending one.

Use tx_tail to retry the outstanding buffer. Otherwise, the pending echo
entry can remain incomplete and leave the TX queue stopped.

Backports must include the preceding TX serialization fix or equivalent
synchronization. It prevents completion and retry from observing a newly
published head before its initial TX command and serializes the
MODE/CMD/MODE sequences used by submission and retry.

Fixes: a5605d61c7dd ("can: rockchip_canfd: enable full TX-FIFO depth of 2")
Cc: stable@vger.kernel.org
Signed-off-by: Cunhao Lu <1579567540@qq.com>

---
Changes in v8:
- Apply the retry-slot correction after TX serialization.
---
 drivers/net/can/rockchip/rockchip_canfd-tx.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/net/can/rockchip/rockchip_canfd-tx.c b/drivers/net/can/rockchip/rockchip_canfd-tx.c
index caa71cf8e39a..8998b7855d15 100644
--- a/drivers/net/can/rockchip/rockchip_canfd-tx.c
+++ b/drivers/net/can/rockchip/rockchip_canfd-tx.c
@@ -63,8 +63,8 @@ static void rkcanfd_start_xmit_write_cmd(const struct rkcanfd_priv *priv,
 
 void rkcanfd_xmit_retry(struct rkcanfd_priv *priv)
 {
-	const unsigned int tx_head = rkcanfd_get_tx_head(priv);
-	const u32 reg_cmd = RKCANFD_REG_CMD_TX_REQ(tx_head);
+	const unsigned int tx_tail = rkcanfd_get_tx_tail(priv);
+	const u32 reg_cmd = RKCANFD_REG_CMD_TX_REQ(tx_tail);
 
 	lockdep_assert_held(&priv->tx_lock);
 

-- 
2.34.1

