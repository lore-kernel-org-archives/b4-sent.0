From: Levi Zim <rsworktech@outlook.com>
Date: Sat, 14 Mar 2026 23:31:28 +0800
Subject: [PATCH bpf v2] bpf: do not use kmalloc_nolock when
 !HAVE_CMPXCHG_DOUBLE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260314-bpf-kmalloc-nolock-v2-1-576e33e4fa67@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/31NSw6CMBC9Cpm1Y/pBVFbew7AodCoN0CEtEg3h7
 jYcwM1L3n+DRNFTgrrYINLqk+eQiToV0PUmvAi9zRyUUJXQssR2djhMZhy5w8AZB6yENTdBldS
 WIBfnSM5/jtEn5Dw0Wex9Wjh+j6NVHta/zVWiRFWa1ml3vZi7e/B7GZmHc8cTNPu+/wC4ZOdtu
 wAAAA==
X-Change-ID: 20260314-bpf-kmalloc-nolock-60da80e613de
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, 
 John Fastabend <john.fastabend@gmail.com>, KP Singh <kpsingh@kernel.org>, 
 Stanislav Fomichev <sdf@fomichev.me>, Hao Luo <haoluo@google.com>, 
 Jiri Olsa <jolsa@kernel.org>, 
 Sebastian Andrzej Siewior <bigeasy@linutronix.de>, 
 Clark Williams <clrkwllms@kernel.org>, Steven Rostedt <rostedt@goodmis.org>, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: Amery Hung <ameryhung@gmail.com>, linux-riscv@lists.infradead.org, 
 stable@vger.kernel.org, bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-rt-devel@lists.linux.dev, Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4940;
 i=rsworktech@outlook.com; s=ryzen; h=from:subject:message-id;
 bh=OgmsL+IoFTwpgQ53xi0uCbqj+KUlvmYc6EsmLeVQARY=;
 b=owEBbQKS/ZANAwAKAW87mNQvxsnYAcsmYgBptX9aBEUQoXxUoQbiBYRV3LwvC1cyq5/288bP7
 35R5HsR91qJAjMEAAEKAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCabV/WgAKCRBvO5jUL8bJ
 2BRsD/96Swu0tWcACwdoVeOTVhC7njCgpPYwK7wSVhEobsYCLke6OMJCvhzTH9oy3RdMe9w0TWL
 TjRmb7Lmy5uMgLM6EFp+buP+147gkZKf8pjUDTjDpqXeHIBwqD5b4c8lXSCwmPXJDT1T8yTkW7k
 f2Dq3kAz4bD5VPbWOEu2cAYK+VkQVfHUD7qKvhMnkn/lh/2HNNYbcS6HhcWHbWNavYWkYT+4/zK
 ymDxTC0qpCa8qNCyIgz7rkH2CDddoOXRi5QScgb9BR+EZMy7rQyoeGyQ1xnEsF1qeihAzIwdHGb
 PnoRdg0iNIK8Zgv0lqflDDOo46IxQRVHv4oB2zeAxGV/XuOIMp9WDBC0kGQv5sydzb/ATIWbNey
 QE9KicHd8ZgiLOlO7/FMQRrupfMZq4aJzpxx3PS8+MpN8owd+4XYbd5k4p2s+tCfUDB+9QtgmH+
 KSO+DSXbUeuVSJqx4mGPaBS960sshd0Os1fvag8eqF0z3RnvHxBFVj8rfA58wW7t2C4usIS/6rc
 7/txBQVAV8I+ukor2HacVOsvhEfpfxnmJ7KOIIwnnRLdaN/l3sp2sEFmJzqmca5D6i1ye70N3yY
 UftIwAZFk8nldDqLTu8DkBjR2eLg615FVkL57XrZqrh9M8fFjb/13T37CAU6xV8LIQr9KXcq8OA
 FC9BoF/h2QyyAOQ==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/ryzen with auth_id=536
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kmalloc_nolock always fails for architectures that lack cmpxchg16b.
For example, this causes bpf_task_storage_get with flag
BPF_LOCAL_STORAGE_GET_F_CREATE to fails on riscv64 6.19 kernel.

Fix it by enabling use_kmalloc_nolock only when HAVE_CMPXCHG_DOUBLE.
But leave the PREEMPT_RT case as is because it requires kmalloc_nolock
for correctness. Add a comment about this limitation that architecture's
lack of CMPXCHG_DOUBLE combined with PREEMPT_RT could make
bpf_local_storage_alloc always fail.

Fixes: f484f4a3e058 ("bpf: Replace bpf memory allocator with kmalloc_nolock() in local storage")
Cc: stable@vger.kernel.org
Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
I find that bpf_task_storage_get with flag BPF_LOCAL_STORAGE_GET_F_CREATE
always fails for me on 6.19 kernel on riscv64 and bisected it.

In f484f4a3e058 ("bpf: Replace bpf memory allocator with kmalloc_nolock()
in local storage"), bpf memory allocator is replaced with kmalloc_nolock.
This approach is problematic for architectures that lack CMPXCHG_DOUBLE
because kmalloc_nolock always fails in this case:

In function kmalloc_nolock (kmalloc_nolock_noprof): 

	if (!(s->flags & __CMPXCHG_DOUBLE) && !kmem_cache_debug(s))
		/*
		 * kmalloc_nolock() is not supported on architectures that
		 * don't implement cmpxchg16b, but debug caches don't use
		 * per-cpu slab and per-cpu partial slabs. They rely on
		 * kmem_cache_node->list_lock, so kmalloc_nolock() can
		 * attempt to allocate from debug caches by
		 * spin_trylock_irqsave(&n->list_lock, ...)
		 */
		return NULL;

Fix it by enabling use_kmalloc_nolock only when HAVE_CMPXCHG_DOUBLE.
(But not for a PREEMPT_RT case as explained in the comment and commitmsg)

Note for stable: this only needs to be picked into v6.19 if the patch
makes it into 7.0.
---
Changes in v2:
- Drop the modification to the PREEMPT_RT case as it requires
  kmalloc_nolock for correctness.
- Add a comment to the PREEMPT_RT case about the limitation when
  not HAVE_CMPXCHG_DOUBLE but enables PREEMPT_RT.
- Link to v1: https://lore.kernel.org/r/20260314-bpf-kmalloc-nolock-v1-1-24abf3f75a9f@outlook.com
---
 include/linux/bpf_local_storage.h | 2 ++
 kernel/bpf/bpf_cgrp_storage.c     | 2 +-
 kernel/bpf/bpf_local_storage.c    | 4 ++++
 kernel/bpf/bpf_task_storage.c     | 2 +-
 4 files changed, 8 insertions(+), 2 deletions(-)

diff --git a/include/linux/bpf_local_storage.h b/include/linux/bpf_local_storage.h
index 8157e8da61d40..a7ae5dde15bcb 100644
--- a/include/linux/bpf_local_storage.h
+++ b/include/linux/bpf_local_storage.h
@@ -19,6 +19,8 @@
 
 #define BPF_LOCAL_STORAGE_CACHE_SIZE	16
 
+static const bool KMALLOC_NOLOCK_SUPPORTED = IS_ENABLED(CONFIG_HAVE_CMPXCHG_DOUBLE);
+
 struct bpf_local_storage_map_bucket {
 	struct hlist_head list;
 	rqspinlock_t lock;
diff --git a/kernel/bpf/bpf_cgrp_storage.c b/kernel/bpf/bpf_cgrp_storage.c
index c2a2ead1f466d..09c557e426968 100644
--- a/kernel/bpf/bpf_cgrp_storage.c
+++ b/kernel/bpf/bpf_cgrp_storage.c
@@ -114,7 +114,7 @@ static int notsupp_get_next_key(struct bpf_map *map, void *key, void *next_key)
 
 static struct bpf_map *cgroup_storage_map_alloc(union bpf_attr *attr)
 {
-	return bpf_local_storage_map_alloc(attr, &cgroup_cache, true);
+	return bpf_local_storage_map_alloc(attr, &cgroup_cache, KMALLOC_NOLOCK_SUPPORTED);
 }
 
 static void cgroup_storage_map_free(struct bpf_map *map)
diff --git a/kernel/bpf/bpf_local_storage.c b/kernel/bpf/bpf_local_storage.c
index 9c96a4477f81a..a6c240da87668 100644
--- a/kernel/bpf/bpf_local_storage.c
+++ b/kernel/bpf/bpf_local_storage.c
@@ -893,6 +893,10 @@ bpf_local_storage_map_alloc(union bpf_attr *attr,
 	/* In PREEMPT_RT, kmalloc(GFP_ATOMIC) is still not safe in non
 	 * preemptible context. Thus, enforce all storages to use
 	 * kmalloc_nolock() when CONFIG_PREEMPT_RT is enabled.
+	 *
+	 * However, kmalloc_nolock would fail on architectures that do not
+	 * have CMPXCHG_DOUBLE. On such architectures with PREEMPT_RT,
+	 * bpf_local_storage_alloc would always fail.
 	 */
 	smap->use_kmalloc_nolock = IS_ENABLED(CONFIG_PREEMPT_RT) ? true : use_kmalloc_nolock;
 
diff --git a/kernel/bpf/bpf_task_storage.c b/kernel/bpf/bpf_task_storage.c
index 605506792b5b4..9f74fd1ef7f46 100644
--- a/kernel/bpf/bpf_task_storage.c
+++ b/kernel/bpf/bpf_task_storage.c
@@ -212,7 +212,7 @@ static int notsupp_get_next_key(struct bpf_map *map, void *key, void *next_key)
 
 static struct bpf_map *task_storage_map_alloc(union bpf_attr *attr)
 {
-	return bpf_local_storage_map_alloc(attr, &task_cache, true);
+	return bpf_local_storage_map_alloc(attr, &task_cache, KMALLOC_NOLOCK_SUPPORTED);
 }
 
 static void task_storage_map_free(struct bpf_map *map)

---
base-commit: e06e6b8001233241eb5b2e2791162f0585f50f4b
change-id: 20260314-bpf-kmalloc-nolock-60da80e613de

Best regards,
-- 
Levi Zim <rsworktech@outlook.com>

