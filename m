From: Nicholas Velten <nicholasfvelten@gmail.com>
Date: Tue, 13 Oct 2026 23:00:08 -0300
Subject: [PATCH bpf-next] bpf: Annotate data races on bpf_lru_node type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-fix-lru-node-type-kcsan-v1-1-0b743f5af2f3@gmail.com>
X-B4-Tracking: v=1; b=H4sIACfizmoC/yWMQQ7CMAwEv1L5jKUkpYD4CuohSV0wIDeKU1RU9
 e8EOI52Z1ZQykwK52aFTC9WnqSC3TUQb16uhDxUBmfcwRrb4sgLPvOMMg2E5Z0IH1G94N61XTS
 nLhyDh2qnTPX6K18gpBGFlgL9f9E53CmWbxi27QO54VVRhQAAAA==
X-Change-ID: 20261013-fix-lru-node-type-kcsan-4235c085b7ba
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+1ea4f564bf6f1f3d1dc4@syzkaller.appspotmail.com, 
 Nicholas Velten <nicholasfvelten@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791943208; l=5845;
 i=nicholasfvelten@gmail.com; s=20261014; h=from:subject:message-id;
 bh=WM3jG1qGFgTy5qrm7atN2qIeOxz8lgQ0gTs8dQ4l6AA=;
 b=bgMTrFCubT71XavVs+ksvwRRK7NsZFVbtOic7XxImNEoFWp1uJYCmUOnOIW/1StCjeileGEvT
 wn3Z65qP5X9ASeyGonyR/LHliHmufb2EDmu3MRqTtyPqM5B4EDUSHHG
X-Developer-Key: i=nicholasfvelten@gmail.com; a=ed25519;
 pk=WVTZgm6yXQ+XrhULAObg4lwcHPhhxAXrAY+YY6svXzg=
X-Endpoint-Received: by B4 Relay for nicholasfvelten@gmail.com/20261014 with auth_id=1173
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KCSAN reports a data race on bpf_lru_node::type between the LRU list
rotation and the free path of the common LRU:

  BUG: KCSAN: data-race in __bpf_lru_list_rotate / bpf_lru_push_free

  write to 0xffff88811b758022 of 1 bytes by task 4756 on cpu 1:
   __bpf_lru_node_move
   __bpf_lru_list_rotate_active
   __bpf_lru_list_rotate
   bpf_lru_list_pop_free_to_local
   bpf_common_lru_pop_free
   bpf_lru_pop_free
   htab_lru_map_update_elem

  read to 0xffff88811b758022 of 1 bytes by task 4752 on cpu 0:
   bpf_lru_list_push_free
   bpf_common_lru_push_free
   bpf_lru_push_free
   htab_lru_push_free
   htab_lru_map_update_elem

  value changed: 0x00 -> 0x01

node->type is written under the global l->lock when a node moves between
the active, inactive and free lists, and under the per-CPU loc_l->lock
when it moves to or from a local list. It is read in two places that do
not hold the lock the writer holds:

 - bpf_lru_list_push_free() reads it for a WARN_ON_ONCE() sanity check
   before taking l->lock.
 - bpf_common_lru_push_free() re-checks it under loc_l->lock after the
   lockless READ_ONCE() at function entry, while a concurrent rotation
   may be changing it under l->lock.

Both races are benign: the type is a single byte, the sanity check only
feeds a warning, and the re-check exists precisely because the value can
change concurrently (any change sends the node down the check_lru_list
path, which revalidates under l->lock). Mark the two reads with
READ_ONCE() and the runtime writers with WRITE_ONCE(), following
commit 6df8fb83301d ("bpf_lru_list: Read double-checked variable once
without lock") and commit ee9fd0ac3017 ("bpf: Address KCSAN report on
bpf_lru_list"), which did the same for the entry read of node->type and
for node->ref. The writers in the *_populate() functions run before the
map is visible and are left alone.

Tested on bpf-next with CONFIG_KCSAN=y in a 4-vCPU virtme-ng guest,
using a reproducer that runs 8 threads issuing BPF_MAP_UPDATE_BATCH
on a 64-entry BPF_MAP_TYPE_LRU_HASH with overlapping keys: 110 KCSAN
reports for this race per run before the change, 0 in two runs after.
test_lru_map passes before and after.

Fixes: 3a08c2fd7634 ("bpf: LRU List")
Reported-by: syzbot+1ea4f564bf6f1f3d1dc4@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=1ea4f564bf6f1f3d1dc4
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Nicholas Velten <nicholasfvelten@gmail.com>
---
The reproducer used for testing is a small userspace program (8 threads
issuing BPF_MAP_UPDATE_BATCH on a 64-entry BPF_MAP_TYPE_LRU_HASH with
overlapping keys). I can post it, or turn it into a selftest, if that
would be useful.

Not tested: architectures other than x86_64, sparse, and the full
test_maps / test_progs suites (only test_lru_map was run).
---
 kernel/bpf/bpf_lru_list.c | 16 ++++++++--------
 1 file changed, 8 insertions(+), 8 deletions(-)

diff --git a/kernel/bpf/bpf_lru_list.c b/kernel/bpf/bpf_lru_list.c
index 5ed7cb4b9..db8051193 100644
--- a/kernel/bpf/bpf_lru_list.c
+++ b/kernel/bpf/bpf_lru_list.c
@@ -56,7 +56,7 @@ static void __bpf_lru_node_move_to_free(struct bpf_lru_list *l,
 
 	bpf_lru_list_count_dec(l, node->type);
 
-	node->type = tgt_free_type;
+	WRITE_ONCE(node->type, tgt_free_type);
 	WRITE_ONCE(node->pending_free, 0);
 	list_move(&node->list, free_list);
 }
@@ -71,7 +71,7 @@ static void __bpf_lru_node_move_in(struct bpf_lru_list *l,
 		return;
 
 	bpf_lru_list_count_inc(l, tgt_type);
-	node->type = tgt_type;
+	WRITE_ONCE(node->type, tgt_type);
 	bpf_lru_node_clear_ref(node);
 	/* Reset pending_free only when moving to the free list */
 	if (tgt_type == BPF_LRU_LIST_T_FREE)
@@ -94,7 +94,7 @@ static void __bpf_lru_node_move(struct bpf_lru_list *l,
 	if (node->type != tgt_type) {
 		bpf_lru_list_count_dec(l, node->type);
 		bpf_lru_list_count_inc(l, tgt_type);
-		node->type = tgt_type;
+		WRITE_ONCE(node->type, tgt_type);
 	}
 	bpf_lru_node_clear_ref(node);
 
@@ -298,7 +298,7 @@ static void bpf_lru_list_push_free(struct bpf_lru_list *l,
 {
 	unsigned long flags;
 
-	if (WARN_ON_ONCE(IS_LOCAL_LIST_TYPE(node->type)))
+	if (WARN_ON_ONCE(IS_LOCAL_LIST_TYPE(READ_ONCE(node->type))))
 		return;
 
 	if (raw_res_spin_lock_irqsave(&l->lock, flags)) {
@@ -357,7 +357,7 @@ static void __local_list_add_pending(struct bpf_lru *lru,
 {
 	*(u32 *)((void *)node + lru->hash_offset) = hash;
 	node->cpu = cpu;
-	node->type = BPF_LRU_LOCAL_LIST_T_PENDING;
+	WRITE_ONCE(node->type, BPF_LRU_LOCAL_LIST_T_PENDING);
 	WRITE_ONCE(node->pending_free, 0);
 	bpf_lru_node_clear_ref(node);
 	list_add(&node->list, &loc_l->pending_list);
@@ -502,7 +502,7 @@ static struct bpf_lru_node *bpf_common_lru_pop_free(struct bpf_lru *lru,
 		 * free_llist instead of orphaning it; the next pop_free on
 		 * this CPU will pick it up.
 		 */
-		node->type = BPF_LRU_LOCAL_LIST_T_FREE;
+		WRITE_ONCE(node->type, BPF_LRU_LOCAL_LIST_T_FREE);
 		bpf_lru_node_clear_ref(node);
 		WRITE_ONCE(node->pending_free, 0);
 		llist_add(&node->llist, &loc_l->free_llist);
@@ -542,13 +542,13 @@ static void bpf_common_lru_push_free(struct bpf_lru *lru,
 			return;
 		}
 
-		if (unlikely(node->type != BPF_LRU_LOCAL_LIST_T_PENDING)) {
+		if (unlikely(READ_ONCE(node->type) != BPF_LRU_LOCAL_LIST_T_PENDING)) {
 			raw_res_spin_unlock_irqrestore(&loc_l->lock,
 						       flags);
 			goto check_lru_list;
 		}
 
-		node->type = BPF_LRU_LOCAL_LIST_T_FREE;
+		WRITE_ONCE(node->type, BPF_LRU_LOCAL_LIST_T_FREE);
 		bpf_lru_node_clear_ref(node);
 		list_del(&node->list);
 

---
base-commit: 763187dbbf83764a57d5811168ef9de7b9a60e2d
change-id: 20261013-fix-lru-node-type-kcsan-4235c085b7ba

Best regards,
--  
Nicholas Velten <nicholasfvelten@gmail.com>

