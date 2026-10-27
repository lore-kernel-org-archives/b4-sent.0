From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 27 Oct 2026 13:03:42 -0400
Subject: [PATCH bpf] bpf: Fix bpf_timer callback running on a freed map
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-bpf-timer-freed-map-v1-1-30402b0ee99b@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCMBBFr1Jm7YAJWIpXEReZ5kdHaA2TWoTSu
 zvq4i/eh/c2ajBFo3O3kWHVps/ZIRw6Gu9pvoE1O1M8xj74WGrhRScYFwMyT6lykiFLjv0gp0B
 uVkPR9696IRfo+j/bSx4Yl2+P9v0DHgf9vXwAAAA=
X-Change-ID: 20261026-bpf-timer-freed-map-ab8dbd268b51
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Mykyta Yatsenko <yatsenko@meta.com>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793120622; l=5226;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=wo8d1ZBRaCNTXAwLX98FIAW/3WUJoTeClaIWCGiqQ2c=;
 b=ztFexz4W1rs2a4NFbB057zVVJ9HMYN7CC2z2XAn6jD2hwbTbqCc+xrIdKK/suBfzQodRdZX2l
 hA0HzicDOzeBoUMjNbBZ5HGd00qfCwj75PYWldefBNJk4gP3wpMc18J
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A bpf_timer in an inner map can fire after the map has been freed, and
bpf_timer_cb() then reads the freed map:

  [   50.709520] BUG: KASAN: slab-use-after-free in bpf_timer_cb+0x249/0x290
  [   50.709540] Read of size 4 at addr ff11000003bc1030 by task bpftimer/72
  ...
  [   50.710783] Freed by task 12:
  ...
  [   50.710826]  bpf_map_free+0x1a2/0x380

When user space closes the map, its timers are cancelled and their
callbacks are cleared.  Since commit 1bfbc267ec91 ("bpf: Enable
bpf_timer and bpf_wq in any context"), bpf_timer_set_callback() and
bpf_timer_start() run without a lock, so a program that found the timer
just before the close can still use it afterwards:

  Task A                  Task B                  Task C
  ------                  ------                  ------
  bpf_timer_start()
    finds the timer
                          bpf_timer_set_callback()
                            finds the timer
                                                  close(map_fd)
                                                    clears the callback
                                                    cancels the timer
                            sets the callback
    arms the timer
                                                  deletes the map from
                                                  the outer map
                                                    map is freed
  the timer fires
    bpf_timer_cb() reads the freed map

The timer is cancelled once more when it is finally freed, but that
happens well after the inner map is freed, so a timer started this way
can still fire on the freed map.

Clear the timer's map pointer in bpf_async_cancel_and_free() before the
map can be freed, and make the bpf_timer and bpf_wq callbacks return
early when it is NULL.  The map is not freed until callbacks that are
already running have finished, so a callback either sees the map while
it is still valid or sees NULL.

The reproducer below calls the two helpers in a loop on two CPUs while a
third CPU keeps creating an inner map with a timer, closing it and
removing it from the outer map.  This bug was identified and confirmed
with the help of a deterministic hypervisor currently under development,
but the non-deterministic C reproducer can typically trigger it in the
1-50s time range.  With the fix, nothing is triggered after 600 seconds.

Fixes: 1bfbc267ec91 ("bpf: Enable bpf_timer and bpf_wq in any context")
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
This is a different use-after-free from the one fixed by "bpf:
Dissociate struct_ops progs before the grace period of the map" in
Qiliang Yuan's v6 struct_ops series [1].  There, a timer callback
returns into the freed trampoline of a struct_ops map.  Here, the
callback reads the freed map that holds the timer.

[1] https://lore.kernel.org/all/20261022-selftests-bpf-struct-ops-assoc-timer-v6-2-2c0f18e82582@gmail.com/

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/bpftimer.c
---
 kernel/bpf/helpers.c | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/kernel/bpf/helpers.c b/kernel/bpf/helpers.c
index 648abe1ba63a..58e357302850 100644
--- a/kernel/bpf/helpers.c
+++ b/kernel/bpf/helpers.c
@@ -1221,7 +1221,7 @@ static void bpf_async_refcount_put(struct bpf_async_cb *cb);
 static enum hrtimer_restart bpf_timer_cb(struct hrtimer *hrtimer)
 {
 	struct bpf_hrtimer *t = container_of(hrtimer, struct bpf_hrtimer, timer);
-	struct bpf_map *map = t->cb.map;
+	struct bpf_map *map = READ_ONCE(t->cb.map);
 	void *value = t->cb.value;
 	bpf_callback_t callback_fn;
 	void *key;
@@ -1229,7 +1229,7 @@ static enum hrtimer_restart bpf_timer_cb(struct hrtimer *hrtimer)
 
 	BTF_TYPE_EMIT(struct bpf_timer);
 	callback_fn = rcu_dereference_check(t->cb.callback_fn, rcu_read_lock_bh_held());
-	if (!callback_fn)
+	if (!callback_fn || !map)
 		goto out;
 
 	/* bpf_timer_cb() runs in hrtimer_run_softirq. It doesn't migrate and
@@ -1254,7 +1254,7 @@ static void bpf_wq_work(struct work_struct *work)
 {
 	struct bpf_work *w = container_of(work, struct bpf_work, work);
 	struct bpf_async_cb *cb = &w->cb;
-	struct bpf_map *map = cb->map;
+	struct bpf_map *map;
 	bpf_callback_t callback_fn;
 	void *value = cb->value;
 	void *key;
@@ -1265,8 +1265,9 @@ static void bpf_wq_work(struct work_struct *work)
 	/* keeps the program that callback_fn belongs to */
 	rcu_read_lock_trace();
 
+	map = READ_ONCE(cb->map);
 	callback_fn = READ_ONCE(cb->callback_fn);
-	if (!callback_fn)
+	if (!callback_fn || !map)
 		goto out;
 
 	key = map_key_from_value(map, value, &idx);
@@ -1733,6 +1734,8 @@ static void bpf_async_cancel_and_free(struct bpf_async_kern *async)
 	if (!cb)
 		return;
 
+	/* Callbacks that run after this see NULL and return. */
+	WRITE_ONCE(cb->map, NULL);
 	bpf_async_update_prog_callback(cb, NULL, NULL);
 	/*
 	 * No refcount_inc_not_zero(&cb->refcnt) here. Dropping the last

---
base-commit: 195a3519ff27bff5575e05b5086e38ee92715776
change-id: 20261026-bpf-timer-freed-map-ab8dbd268b51

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

