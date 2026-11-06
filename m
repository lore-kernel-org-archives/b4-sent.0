From: Alireza Asgari <alireza@asgari.net>
Date: Fri, 06 Nov 2026 00:37:04 +0000
Subject: [PATCH RFC net 1/3] netfilter: nfnetlink_queue: reject duplicate
 pending packet IDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-nfqueue-review-v1-1-b6c933f44943@asgari.net>
References: <20261106-nfqueue-review-v1-0-b6c933f44943@asgari.net>
In-Reply-To: <20261106-nfqueue-review-v1-0-b6c933f44943@asgari.net>
To: Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>
Cc: Phil Sutter <phil@nwl.cc>, netfilter-devel@vger.kernel.org, 
 netdev@vger.kernel.org, kunit-dev@googlegroups.com, 
 Alireza Asgari <alireza@asgari.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793925516; l=1761;
 i=alireza@asgari.net; s=nfqueue-20261106-d5b860a0; h=from:subject:message-id;
 bh=H8ooWtA1mr2Wq7BiH1vRavQSsCcbnCRuf8kq87M4yUU=;
 b=84zUIRG+XE722zKxiEYoCLVl6WGYPK4vnkbl5+ISktq8p6Dji8ar1sNsaWAEdMESLei6jWSKk
 G0u+QkVt0z3CrggCgC8bJsnmpfMn31HqytmWM91Lae2aDyyoHlMleSb
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=zQFqyM4zwBHzads8dtEOnNQiQQ1pktgndpKPB3TI+AE=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/nfqueue-20261106-d5b860a0 with auth_id=1424
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A queued packet can outlive a complete 32-bit ID cycle while newer
packets receive verdicts. rhashtable_insert_fast() permits equal keys,
so the reused ID can identify two pending packets and verdict lookup
can select the wrong entry.

Use rhashtable_lookup_insert_fast() under the queue lock to reject an
incoming collision before list insertion or userspace notification.
Preserve the pending packet and use the existing enqueue-failure path:
drop the incoming packet by default, or accept it with FAIL_OPEN.
The attempted ID is consumed and the next enqueue advances normally.

This enforces uniqueness among pending entries. The unchanged 32-bit
interface cannot distinguish stale verdicts after an ID is released
and reused.

Codex assisted with development, review and validation of this change.

Fixes: 7af4cc3fa158 ("[NETFILTER]: Add "nfnetlink_queue" netfilter queue handler over nfnetlink")
Signed-off-by: Alireza Asgari <alireza@asgari.net>
---
 net/netfilter/nfnetlink_queue.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/net/netfilter/nfnetlink_queue.c b/net/netfilter/nfnetlink_queue.c
index 90d887546f7db..c71f4fe890eee 100644
--- a/net/netfilter/nfnetlink_queue.c
+++ b/net/netfilter/nfnetlink_queue.c
@@ -227,8 +227,10 @@ __enqueue_entry(struct nfqnl_instance *queue, struct nf_queue_entry *entry)
 {
 	int err;
 
-	err = rhashtable_insert_fast(&queue->nfqnl_packet_map, &entry->hash_node,
-				     nfqnl_rhashtable_params);
+	/* A wrapped ID must not alias a packet that is still queued. */
+	err = rhashtable_lookup_insert_fast(&queue->nfqnl_packet_map,
+					    &entry->hash_node,
+					    nfqnl_rhashtable_params);
 	if (unlikely(err))
 		return err;
 

-- 
2.43.0

