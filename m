From: Nicholas Velten <nicholasfvelten@gmail.com>
Date: Mon, 19 Oct 2026 14:38:20 -0300
Subject: [PATCH bpf-next v2] bpf: Annotate data races on bpf_lru_node type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-fix-lru-node-type-kcsan-v2-1-c10a410b3565@gmail.com>
X-B4-Tracking: v=1; b=H4sIAItV1moC/4WOQQ6DIBREr2L+ur8R1Np01Xs0LgA/SqtgQI3Ge
 PeiPUCXk5k3MxsE8oYCPJINPM0mGGej4JcEVCtsQ2jqqIGn/MZSlqE2C3Z+QutqwnEdCD8qCIs
 5zwqV3gtZSgGRHjzF6Nn8AjlotLSMUP2cMMk3qfEoPrKtCaPz63liZifxd29myDCVZZ7pQmius
 2fTC9Ndleuh2vf9C54yZjLaAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792431499; l=4464;
 i=nicholasfvelten@gmail.com; s=20261014; h=from:subject:message-id;
 bh=vlUE37PtQTyOLq5PXbvONu4Xi4bntjAirjuFev9xeZY=;
 b=JZxRDHgecZKvX7el63L+yAF4pfGpixN4R034psx0LcMfaL23UJrM4JhFNTmIoIeIF5DZ/pcRr
 RfDrhWOWENtDM/LNh0/BhEjQCrZIogg3RW0HBM7bSLKxo4vOgBIIyF1
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

bpf_lru_list_push_free() reads node->type for a WARN_ON_ONCE() sanity
check before taking l->lock. __bpf_lru_node_move(), called right after
under l->lock, does the same check, so drop the unlocked one.

bpf_common_lru_push_free() re-checks node->type under loc_l->lock after
the lockless READ_ONCE() at function entry. By then the node has been
removed from the htab, so only flush and rotate can change its type,
through __bpf_lru_node_move_in() and __bpf_lru_node_move() under
l->lock. Mark that re-check with READ_ONCE() and those two writers with
WRITE_ONCE(), following commit 6df8fb83301d ("bpf_lru_list: Read
double-checked variable once without lock"). The remaining writers
operate on a node with a single owner that nobody else reads and are
left alone.

Tested on bpf-next with CONFIG_KCSAN=y in a 4-vCPU virtme-ng guest,
using a reproducer that runs 8 threads issuing BPF_MAP_UPDATE_BATCH
on a 64-entry BPF_MAP_TYPE_LRU_HASH with overlapping keys.

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
Changes in v2:
- Drop the Fixes: tag (Alexei)
- Remove the unlocked WARN_ON_ONCE() in bpf_lru_list_push_free() instead
  of annotating it; __bpf_lru_node_move() does the same check under
  l->lock (Alexei)
- Keep WRITE_ONCE() only in __bpf_lru_node_move_in() and
  __bpf_lru_node_move(), the only writers that can race with the
  re-check in bpf_common_lru_push_free() (Alexei)
- Link to v1: https://patch.msgid.link/20261013-fix-lru-node-type-kcsan-v1-1-0b743f5af2f3@gmail.com
---
 kernel/bpf/bpf_lru_list.c | 9 +++------
 1 file changed, 3 insertions(+), 6 deletions(-)

diff --git a/kernel/bpf/bpf_lru_list.c b/kernel/bpf/bpf_lru_list.c
index 5ed7cb4b9..3858886b0 100644
--- a/kernel/bpf/bpf_lru_list.c
+++ b/kernel/bpf/bpf_lru_list.c
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
 
@@ -298,9 +298,6 @@ static void bpf_lru_list_push_free(struct bpf_lru_list *l,
 {
 	unsigned long flags;
 
-	if (WARN_ON_ONCE(IS_LOCAL_LIST_TYPE(node->type)))
-		return;
-
 	if (raw_res_spin_lock_irqsave(&l->lock, flags)) {
 		WRITE_ONCE(node->pending_free, 1);
 		return;
@@ -542,7 +539,7 @@ static void bpf_common_lru_push_free(struct bpf_lru *lru,
 			return;
 		}
 
-		if (unlikely(node->type != BPF_LRU_LOCAL_LIST_T_PENDING)) {
+		if (unlikely(READ_ONCE(node->type) != BPF_LRU_LOCAL_LIST_T_PENDING)) {
 			raw_res_spin_unlock_irqrestore(&loc_l->lock,
 						       flags);
 			goto check_lru_list;

---
base-commit: 763187dbbf83764a57d5811168ef9de7b9a60e2d
change-id: 20261013-fix-lru-node-type-kcsan-4235c085b7ba

Best regards,
--  
Nicholas Velten <nicholasfvelten@gmail.com>

