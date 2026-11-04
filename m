From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Date: Wed, 04 Nov 2026 18:37:57 +0700
Subject: [PATCH bpf-next 1/2] bpf: Limit local storage value size to max
 kmalloc_nolock() allocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-local-storage-max-v1-1-c836731bd184@gmail.com>
References: <20261104-local-storage-max-v1-0-c836731bd184@gmail.com>
In-Reply-To: <20261104-local-storage-max-v1-0-c836731bd184@gmail.com>
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 John Fastabend <john.fastabend@gmail.com>, Amery Hung <ameryhung@gmail.com>, 
 Shuah Khan <shuah@kernel.org>, Christian Brauner <brauner@kernel.org>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Amery Hung <ameryhung@gmail.com>, 
 Slava Imameev <slava.imameev@crowdstrike.com>, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793792278; l=4249;
 i=thamrinjonathan@gmail.com; s=20261102; h=from:subject:message-id;
 bh=Degv3fbAgO6TESwqgj+YkYxSZ9RU1+DcLlSWyENFy7g=;
 b=cen+qO4ur3YTB/SmL21hKq4U36/Q64zQ63ccC0saOivh2BAnXSGqNMS715rPRfGM1KA84y7Kg
 PxNvP7QGjRlDeLleHApEb3SA97iuvrJBD1IK21KPEjZpC63CldPomvl
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=mr0q5PZVaUIrv8WvTxIfK7QVcAiRSYI8hOByBQL1ZRo=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261102 with auth_id=1383
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit f484f4a3e058 ("bpf: Replace bpf memory allocator
with kmalloc_nolock() in local storage") for task and cgroup
local storage and commit 5063e7758899 ("bpf: Use kmalloc_nolock()
universally in local storage") for the rest, elements are
allocated using kmalloc_nolock() which has a maximum
allocation size of KMALLOC_MAX_CACHE_SIZE. Map creation still
doesn't match this and accepts values up to ~64KB. This causes
map updates to fail with ENOMEM due to the map not being able
to store anything.

BPF_LOCAL_STORAGE_MAX_VALUE_SIZE is now based on
KMALLOC_MAX_CACHE_SIZE and maps with larger values fail on
creation with E2BIG. Cgroup storage (BPF_MAP_TYPE_CGROUP_STORAGE)
still uses the previous limit as its own constant since it
allocates with kmalloc().

Fixes: f484f4a3e058 ("bpf: Replace bpf memory allocator with kmalloc_nolock() in local storage")
Fixes: 5063e7758899 ("bpf: Use kmalloc_nolock() universally in local storage")
Reported-by: Slava Imameev <slava.imameev@crowdstrike.com>
Closes: https://lore.kernel.org/bpf/20260410014341.47043-1-slava.imameev@crowdstrike.com/
Suggested-by: Alexei Starovoitov <ast@kernel.org>
Link: https://lore.kernel.org/bpf/CAADnVQKeFF--bgnZZSU12UY0muuwYA=7EdzLyOi837oZs+bXTA@mail.gmail.com/
Signed-off-by: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
---
 include/linux/bpf_local_storage.h | 10 +++++-----
 kernel/bpf/local_storage.c        | 13 +++++++++++--
 2 files changed, 16 insertions(+), 7 deletions(-)

diff --git a/include/linux/bpf_local_storage.h b/include/linux/bpf_local_storage.h
index 6c643ac51079..e1ce75b0fb0a 100644
--- a/include/linux/bpf_local_storage.h
+++ b/include/linux/bpf_local_storage.h
@@ -117,13 +117,13 @@ bpf_local_storage_unpin_owner(struct bpf_local_storage *local_storage)
 	last = refcount_dec_and_test(&local_storage->owner_refcnt);
 }
 
-/* U16_MAX is much more than enough for sk local storage
- * considering a tcp_sock is ~2k.
+/* Elements come from kmalloc_nolock() where the max size
+ * is KMALLOC_MAX_CACHE_SIZE.
  */
-#define BPF_LOCAL_STORAGE_MAX_VALUE_SIZE				       \
+#define BPF_LOCAL_STORAGE_MAX_VALUE_SIZE                                       \
 	min_t(u32,                                                             \
-	      (KMALLOC_MAX_SIZE - MAX_BPF_STACK -                              \
-	       sizeof(struct bpf_local_storage_elem)),                         \
+	      (KMALLOC_MAX_CACHE_SIZE -                                        \
+	       offsetof(struct bpf_local_storage_elem, sdata.data)),           \
 	      (U16_MAX - sizeof(struct bpf_local_storage_elem)))
 
 #define SELEM(_SDATA)                                                          \
diff --git a/kernel/bpf/local_storage.c b/kernel/bpf/local_storage.c
index 83cd527a2542..22a9841d4fd5 100644
--- a/kernel/bpf/local_storage.c
+++ b/kernel/bpf/local_storage.c
@@ -18,6 +18,15 @@
 #define LOCAL_STORAGE_CREATE_FLAG_MASK					\
 	(BPF_F_NUMA_NODE | BPF_F_ACCESS_MASK)
 
+/* Cgroup storage allocates with kmalloc() where the max size is
+ * larger than kmalloc_nolock() used by other local storages.
+ */
+#define BPF_CGROUP_STORAGE_MAX_VALUE_SIZE                                      \
+	min_t(u32,                                                             \
+	      (KMALLOC_MAX_SIZE - MAX_BPF_STACK -                              \
+	       sizeof(struct bpf_local_storage_elem)),                         \
+	      (U16_MAX - sizeof(struct bpf_local_storage_elem)))
+
 struct bpf_cgroup_storage_map {
 	struct bpf_map map;
 
@@ -296,12 +305,12 @@ static int cgroup_storage_get_next_key(struct bpf_map *_map, void *key,
 
 static struct bpf_map *cgroup_storage_map_alloc(union bpf_attr *attr)
 {
-	__u32 max_value_size = BPF_LOCAL_STORAGE_MAX_VALUE_SIZE;
+	__u32 max_value_size = BPF_CGROUP_STORAGE_MAX_VALUE_SIZE;
 	int numa_node = bpf_map_attr_numa_node(attr);
 	struct bpf_cgroup_storage_map *map;
 
 	/* percpu is bound by PCPU_MIN_UNIT_SIZE, non-percu
-	 * is the same as other local storages.
+	 * uses the cgroup storage limit above
 	 */
 	if (attr->map_type == BPF_MAP_TYPE_PERCPU_CGROUP_STORAGE)
 		max_value_size = min_t(__u32, max_value_size,

-- 
2.56.0

