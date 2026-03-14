From: Levi Zim <rsworktech@outlook.com>
Date: Sun, 15 Mar 2026 00:02:48 +0800
Subject: [PATCH bpf v3] bpf: do not use kmalloc_nolock when
 !HAVE_CMPXCHG_DOUBLE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260315-bpf-kmalloc-nolock-v3-1-91c72bf91902@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XNyQ6CMBAG4Fchc7amCxT15HsYDwWm0rAMabHRE
 N7dpjcvepnkn+WbDQJ6hwEuxQYeowuO5hTUoYC2N/MDmetSBsml5kqUrFksGyYzjtSymVIdmOa
 dOXHUQnUI6XDxaN0rozdI+3BPzd6Flfw7P4oij36ZUTDBZGkaq2xdmbO90nMdiYZjS1MGo/yPy
 IRUtUalsLRG19/Ivu8fv2qK1AABAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5177;
 i=rsworktech@outlook.com; s=ryzen; h=from:subject:message-id;
 bh=F3NzhvAzd0zCVDcRlr7RmrSHpJygKeFMqZIONIS/DVY=;
 b=owEBbQKS/ZANAwAKAW87mNQvxsnYAcsmYgBptYataz9Rjqgmj6vGqmsIM8a6ZekZLkTCdBL8E
 xjDsqOUPQWJAjMEAAEKAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCabWGrQAKCRBvO5jUL8bJ
 2F2AD/9oKgja014FkRBZt0+EeVAdwGQx2xV8nIGzJFegeQEj1nn2IEPSyYITgmeLJ+wp0LhaJ7M
 KZ2ZG7quAiDTUYPLSTk1+qNAR+JaDp15cA1/GHDrdFoLCEO0A4TYRP4eMrqQIOIZra2hF+7EX0C
 v6ndojsunyGRPgeDln9cs6pYfa1XUa8dHgD9bSivT1DluvOajJU1gXjbhTKEOeasYdzMt1IQfNw
 kQX7wq/P3JoUFMTJCL4I66odN1QlGfe2sS7xNg5GOu08NtxDrXY8QkbSLNGAqYA/t5lKwOjdjNg
 MfdFm4zzKcTm4Qe9STv6V9cQjVoG3kRqCbP35meqrOq690na+7HUW4RrAjozujCSLeQ8Zv2s32q
 o9m6p3nzUyP6wB2/sJkwk8eD7S3o4X9ODWpdSAr76mi+9o5AHTvTA2BdaHE4yDhjfSByRrZxjin
 riSi1Foj46ovVjKDCFwdEN0ocJFHCfUW1GjnXA2qjM2Sale7GV7fS/UNNnftktWBTyYA2Jw8hyK
 V30UKE2bZsSHx5wsDVKV/YphBApMDRFi+2OUkKhFIJovNl7pxU2DxjHiKa0T5r1u6xAVlpvEfA7
 5lHcoM60D8Hn0Xn4JcC9YioctxKS6UI/2FPAVvrham+ytnO0SIbDZbXaiqjWhkr/F7qR0LE3eGI
 k2lMPSDkv1fCCIA==
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
Changes in v3:
- Use macro instead of const static variable to avoid triggering
  warnings.
- Wrap lines at 80 columns
- Link to v2: https://lore.kernel.org/r/20260314-bpf-kmalloc-nolock-v2-1-576e33e4fa67@outlook.com

Changes in v2:
- Drop the modification to the PREEMPT_RT case as it requires
  kmalloc_nolock for correctness.
- Add a comment to the PREEMPT_RT case about the limitation when
  not HAVE_CMPXCHG_DOUBLE but enables PREEMPT_RT.
- Link to v1: https://lore.kernel.org/r/20260314-bpf-kmalloc-nolock-v1-1-24abf3f75a9f@outlook.com
---
 include/linux/bpf_local_storage.h | 1 +
 kernel/bpf/bpf_cgrp_storage.c     | 3 ++-
 kernel/bpf/bpf_local_storage.c    | 4 ++++
 kernel/bpf/bpf_task_storage.c     | 3 ++-
 4 files changed, 9 insertions(+), 2 deletions(-)

diff --git a/include/linux/bpf_local_storage.h b/include/linux/bpf_local_storage.h
index 8157e8da61d40..d8f2c5d63a80e 100644
--- a/include/linux/bpf_local_storage.h
+++ b/include/linux/bpf_local_storage.h
@@ -18,6 +18,7 @@
 #include <asm/rqspinlock.h>
 
 #define BPF_LOCAL_STORAGE_CACHE_SIZE	16
+#define KMALLOC_NOLOCK_SUPPORTED IS_ENABLED(CONFIG_HAVE_CMPXCHG_DOUBLE)
 
 struct bpf_local_storage_map_bucket {
 	struct hlist_head list;
diff --git a/kernel/bpf/bpf_cgrp_storage.c b/kernel/bpf/bpf_cgrp_storage.c
index c2a2ead1f466d..cd18193c44058 100644
--- a/kernel/bpf/bpf_cgrp_storage.c
+++ b/kernel/bpf/bpf_cgrp_storage.c
@@ -114,7 +114,8 @@ static int notsupp_get_next_key(struct bpf_map *map, void *key, void *next_key)
 
 static struct bpf_map *cgroup_storage_map_alloc(union bpf_attr *attr)
 {
-	return bpf_local_storage_map_alloc(attr, &cgroup_cache, true);
+	return bpf_local_storage_map_alloc(attr, &cgroup_cache,
+					   KMALLOC_NOLOCK_SUPPORTED);
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
index 605506792b5b4..6e8597edea314 100644
--- a/kernel/bpf/bpf_task_storage.c
+++ b/kernel/bpf/bpf_task_storage.c
@@ -212,7 +212,8 @@ static int notsupp_get_next_key(struct bpf_map *map, void *key, void *next_key)
 
 static struct bpf_map *task_storage_map_alloc(union bpf_attr *attr)
 {
-	return bpf_local_storage_map_alloc(attr, &task_cache, true);
+	return bpf_local_storage_map_alloc(attr, &task_cache,
+					   KMALLOC_NOLOCK_SUPPORTED);
 }
 
 static void task_storage_map_free(struct bpf_map *map)

---
base-commit: e06e6b8001233241eb5b2e2791162f0585f50f4b
change-id: 20260314-bpf-kmalloc-nolock-60da80e613de

Best regards,
-- 
Levi Zim <rsworktech@outlook.com>

