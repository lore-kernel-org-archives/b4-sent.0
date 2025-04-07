From: David Dgien <dgienda125@gmail.com>
Date: Sun, 06 Apr 2025 22:24:40 -0400
Subject: [PATCH v2] tlsf: Add tracking of added tlsf memory pools
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250406-tlsf-addpool-v2-1-880c64d19d59@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGc382cC/1XMyw6DIBCF4Vcxsy4Nl2JsV75H4wK56CQoBgxpY
 3j3Urvq8p/J+Q5INqJN8GgOiDZjwrDW4JcG9KzWyRI0tYFTLikTjOw+OaKM2ULwRLpbfdxH2XE
 NdbJF6/B1cs+h9oxpD/F96pl9rz9I8O4fyowwwqUzdKQtFbLtp0Whv+qwwFBK+QCJEsvmqAAAA
 A==
X-Change-ID: 20250131-tlsf-addpool-5f42029b582c
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: David Dgien <dgienda125@gmail.com>, Tyler Reece <mtreece@acm.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743992692; l=3891;
 i=dgienda125@gmail.com; s=20250126; h=from:subject:message-id;
 bh=9Sv5Zm8CxnEOIhpDZkPAusucZer8DxpiuaUFQn/VIf4=;
 b=qPQQJ1Gil3d1QP1FDZQnYgOioNJM9FBSPBIBkZKuLPMSluwvHKKfixsnVcFa8IP7qJOOnqLmc
 BpnbMJTYuRdCT7ttWT9+u0UeI8VVVL0UBO8r6jjXOlyIDq5ePceLrvm
X-Developer-Key: i=dgienda125@gmail.com; a=ed25519;
 pk=zPhfl/eH2iShpaIksvU8MCg11Il6Dx2oW7WYAzpKbo0=
X-Endpoint-Received: by B4 Relay for dgienda125@gmail.com/20250126 with auth_id=332
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When configured to use the TLSF allocator, the malloc_stats function
only walks the initial memory pool, as that is the only pool it is aware
of, and TLSF doesn't link pools together in a way that the walker can
follow.

Add a wrapper function around tlsf_add_pool to add additional tracking
of added pools, so that they can be walked by the malloc_stats function
and meminfo can report accurate heap utilization.

Signed-off-by: David Dgien <dgienda125@gmail.com>
Reviewed-by: Tyler Reece <mtreece@acm.org>
---
Changes in v2:
 - Removed malloc_remove_pool (Sasha)
 - Reworked tlsf initialization into malloc_add_pool
---
 common/memory.c      |  7 +------
 common/tlsf_malloc.c | 46 ++++++++++++++++++++++++++++++++++++++++++++--
 include/malloc.h     |  4 ++++
 3 files changed, 49 insertions(+), 8 deletions(-)

diff --git a/common/memory.c b/common/memory.c
index 36aa4bcb8800943a2742dd13a34165f6238af728..f25fe143984a538f5b1f7c5af7a76596b4aeaa33 100644
--- a/common/memory.c
+++ b/common/memory.c
@@ -34,11 +34,6 @@ unsigned long mem_malloc_end(void)
 	return malloc_end;
 }
 
-#ifdef CONFIG_MALLOC_TLSF
-#include <tlsf.h>
-tlsf_t tlsf_mem_pool;
-#endif
-
 int mem_malloc_initialized;
 
 int mem_malloc_is_initialized(void)
@@ -52,7 +47,7 @@ void mem_malloc_init(void *start, void *end)
 	malloc_end = (unsigned long)end;
 	malloc_brk = malloc_start;
 #ifdef CONFIG_MALLOC_TLSF
-	tlsf_mem_pool = tlsf_create_with_pool(start, end - start + 1);
+	malloc_add_pool(start, end - start + 1);
 #endif
 	mem_malloc_initialized = 1;
 }
diff --git a/common/tlsf_malloc.c b/common/tlsf_malloc.c
index 6a90ee47199fa9e8223f843cc95f52eebfec2aee..4acf1c1c507153e1fef98f9f73f42605c580bc6c 100644
--- a/common/tlsf_malloc.c
+++ b/common/tlsf_malloc.c
@@ -12,7 +12,17 @@
 #include <module.h>
 #include <tlsf.h>
 
-extern tlsf_t tlsf_mem_pool;
+#include <linux/kasan.h>
+#include <linux/list.h>
+
+tlsf_t tlsf_mem_pool;
+
+struct pool_entry {
+	pool_t pool;
+	struct list_head list;
+};
+
+static LIST_HEAD(mem_pool_list);
 
 void *malloc(size_t bytes)
 {
@@ -75,12 +85,44 @@ static void malloc_walker(void* ptr, size_t size, int used, void *user)
 
 void malloc_stats(void)
 {
+	struct pool_entry *cur_pool;
 	struct malloc_stats s;
 
 	s.used = 0;
 	s.free = 0;
 
-	tlsf_walk_pool(tlsf_get_pool(tlsf_mem_pool), malloc_walker, &s);
+	list_for_each_entry(cur_pool, &mem_pool_list, list)
+		tlsf_walk_pool(cur_pool->pool, malloc_walker, &s);
 
 	printf("used: %zu\nfree: %zu\n", s.used, s.free);
 }
+
+void *malloc_add_pool(void *mem, size_t bytes)
+{
+	pool_t new_pool;
+	struct pool_entry *new_pool_entry;
+
+	if (!mem)
+		return NULL;
+
+	if (!tlsf_mem_pool) {
+		tlsf_mem_pool = tlsf_create(mem);
+		mem = (char *)mem + tlsf_size();
+		bytes = bytes - tlsf_size();
+	}
+
+	new_pool = tlsf_add_pool(tlsf_mem_pool, mem, bytes);
+	if (!new_pool)
+		return NULL;
+
+	new_pool_entry = malloc(sizeof(*new_pool_entry));
+	if (!new_pool_entry)
+		return NULL;
+
+	kasan_poison_shadow(mem, bytes, KASAN_TAG_INVALID);
+
+	new_pool_entry->pool = new_pool;
+	list_add(&new_pool_entry->list, &mem_pool_list);
+
+	return (void *)new_pool;
+}
diff --git a/include/malloc.h b/include/malloc.h
index 0b74746360c08a95e593c9afe485382d02cd5c12..35551250324ee1d3c8ddc06f49a06ce07d2855bd 100644
--- a/include/malloc.h
+++ b/include/malloc.h
@@ -21,6 +21,10 @@
 #define ZERO_OR_NULL_PTR(x) ((unsigned long)(x) <= \
 				(unsigned long)ZERO_SIZE_PTR)
 
+#ifdef CONFIG_MALLOC_TLSF
+void *malloc_add_pool(void *mem, size_t bytes);
+#endif
+
 #if IN_PROPER
 void *malloc(size_t) __alloc_size(1);
 size_t malloc_usable_size(void *);

---
base-commit: b4c0c4615ace1795aa75ced21caa1e78b665cde0
change-id: 20250131-tlsf-addpool-5f42029b582c

Best regards,
-- 
David Dgien <dgienda125@gmail.com>

