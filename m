From: Ofri Zangi <ofriz@xsightlabs.com>
Date: Sun, 08 Nov 2026 21:12:57 +0200
Subject: [PATCH net] tls: fix async encryption race on weakly ordered
 architectures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-tls-async-tx-ordering-v1-1-f9a1844ca88e@xsightlabs.com>
X-B4-Tracking: v=1; b=H4sIALjJ8GoC/x3MQQqDQAxA0atI1g1MBlukVxEXOok2ILFMhqKId
 3fo8i/eP8Elqzi8mxOy/NR1sxr0aCB9RlsElWtDDPFFFJ5YVsfRD0tYdtwyV24LdhIDTUycWoZ
 qv1lm3f/fHkwKDNd1A46LG0lsAAAA
X-Change-ID: 20261105-tls-async-tx-ordering-8e201bd1dc4d
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Vakul Garg <vakul.garg@nxp.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Guy Tzalik <guyt@xsightlabs.com>, Ofri Zangi <ofriz@xsightlabs.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794165214; l=2872;
 i=ofriz@xsightlabs.com; s=20261105; h=from:subject:message-id;
 bh=hcXcF7sxE609mzlFBuSNX0rkVPXJlsc5tyQKGD8S0wc=;
 b=ayXzZfMgnuQMW3NnzjfQ5jTuEsBo7LYME27Rl3fx9x5JicPgVp/2/Lcb6BPAx2gMQvgS9GPAl
 2if/wONP5OODANNDt9nhRj3LWCaLg6RD9RMYDR2v2aGnFdPV8kZLLtu
X-Developer-Key: i=ofriz@xsightlabs.com; a=ed25519;
 pk=pD06etcYUBGIxIDkICg6n7JJNuijXIPti5DrRX4CxuQ=
X-Endpoint-Received: by B4 Relay for ofriz@xsightlabs.com/20261105 with auth_id=1416
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With async encryption, a record can be transmitted without its TLS
header on weakly ordered architectures such as arm64, because the
consumer may observe rec->tx_ready set while still seeing the old
scatterlist entry.

tls_encrypt_done() restores the TLS header in the scatterlist entry
(sge->offset -= prot->prepend_size, sge->length += prot->prepend_size)
and then publishes the record with smp_store_mb(rec->tx_ready, true).
On another CPU, tls_tx_records() checks rec->tx_ready with READ_ONCE()
and then reads the entry in tls_push_sg().

Nothing orders these accesses. The barrier in smp_store_mb() comes
after the tx_ready store, so it does not order the earlier scatterlist
update before it. On the reader side, READ_ONCE() does not order the
later loads of sge->offset and sge->length. The reader can therefore
see tx_ready set together with the old offset and length, and pushes
the record without its header.

Publish tx_ready with smp_store_release() in tls_encrypt_done() and read
it with smp_load_acquire() in tls_tx_records(), so that observing
tx_ready guarantees the restored scatterlist entry is visible. Keep the
full barrier that smp_store_mb() provided as an explicit smp_mb(), as
it is still needed to order the tx_ready store before the tx_list head
check.

Fixes: a42055e8d2c3 ("net/tls: Add support for async encryption of records for performance")
Signed-off-by: Ofri Zangi <ofriz@xsightlabs.com>
---
 net/tls/tls_sw.c | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)

diff --git a/net/tls/tls_sw.c b/net/tls/tls_sw.c
index 771e02bff519..c9d3b9eb22be 100644
--- a/net/tls/tls_sw.c
+++ b/net/tls/tls_sw.c
@@ -436,7 +436,8 @@ int tls_tx_records(struct sock *sk, int flags)
 
 	/* Tx all ready records */
 	list_for_each_entry_safe(rec, tmp, &ctx->tx_list, list) {
-		if (READ_ONCE(rec->tx_ready)) {
+		/* Pairs with smp_store_release() in tls_encrypt_done() */
+		if (smp_load_acquire(&rec->tx_ready)) {
 			if (flags == -1)
 				tx_flags = rec->tx_flags;
 			else
@@ -504,8 +505,14 @@ static void tls_encrypt_done(void *data, int err)
 	if (rec) {
 		struct tls_rec *first_rec;
 
-		/* Mark the record as ready for transmission */
-		smp_store_mb(rec->tx_ready, true);
+		/* Mark the record as ready for transmission. Pairs with
+		 * smp_load_acquire() in tls_tx_records(): the sge
+		 * offset/length update above must be visible before tx_ready.
+		 */
+		smp_store_release(&rec->tx_ready, true);
+
+		/* Order the tx_ready store before the tx_list head check */
+		smp_mb();
 
 		/* If received record is at head of tx_list, schedule tx */
 		first_rec = list_first_entry(&ctx->tx_list,

---
base-commit: 30c71476d842b094651bd7712f6c8ee8716147d0
change-id: 20261105-tls-async-tx-ordering-8e201bd1dc4d

Best regards,
-- 
Ofri Zangi <ofriz@xsightlabs.com>

