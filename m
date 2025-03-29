From: David Dgien <dgienda125@gmail.com>
Date: Fri, 28 Mar 2025 23:13:40 -0400
Subject: [PATCH] tlsf: Add tracking of added tlsf memory pools
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250328-tlsf-addpool-v1-1-25fd0b060356@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGNl52cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDQ2ND3ZKc4jTdxJSUgvz8HF3TNBOghGWSqYVRshJQS0FRalpmBdi46Nj
 aWgA0FFaQXgAAAA==
X-Change-ID: 20250131-tlsf-addpool-5f42029b582c
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: David Dgien <dgienda125@gmail.com>, Tyler Reece <mtreece@acm.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743218026; l=3859;
 i=dgienda125@gmail.com; s=20250126; h=from:subject:message-id;
 bh=O4sf++it3RgO9HV57t9FvIY9tpxEZ5SIabtWRErNi08=;
 b=E/0i4ekUZR4j8HwfhyNduxcRtGahVzOPzLMApGJF++z5PzKfDO6ohqjaxtRotznVInuC2/uyr
 MmpV0ySkxzzB6WnI25toBsWiI0+JueoHMgYItXOoBgbH8+QzgxqWstv
X-Developer-Key: i=dgienda125@gmail.com; a=ed25519;
 pk=zPhfl/eH2iShpaIksvU8MCg11Il6Dx2oW7WYAzpKbo0=
X-Endpoint-Received: by B4 Relay for dgienda125@gmail.com/20250126 with auth_id=332
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When configured to use the TLSF allocator, the malloc_stats function
only walks the initial memory pool, as that is the only pool it is aware
of, and TLSF doesn't link pools together in a way that the walker can
follow.

Add wrapper functions around tlsf_add_pool and tlsf_remove_pool to add
additional tracking of added pools, so that they can be walked by the
malloc_stats function and meminfo can report accurate heap utilization.

Signed-off-by: David Dgien <dgienda125@gmail.com>
Reviewed-by: Tyler Reece <mtreece@acm.org>
---
For this change I put the wrapper function prototypes in malloc.h, gated
by CONFIG_MALLOC_TLSF. I was split between there and memory.h, but I'm
not entirely convinced malloc.h was the right decision. I also didn't
provide stubs for when CONFIG_MALLOC_TLSF isn't enabled, as I did not
see any upstream code that utilizes tlsf_add_pool. If the project has
different preferences I can make those changes.
---
 common/tlsf_malloc.c | 64 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 include/malloc.h     |  5 ++++
 2 files changed, 69 insertions(+)

diff --git a/common/tlsf_malloc.c b/common/tlsf_malloc.c
index 6a90ee47199fa9e8223f843cc95f52eebfec2aee..0e756a13d5a2665eccf8931b19dfa4e56cad15eb 100644
--- a/common/tlsf_malloc.c
+++ b/common/tlsf_malloc.c
@@ -12,8 +12,18 @@
 #include <module.h>
 #include <tlsf.h>
 
+#include <linux/kasan.h>
+#include <linux/list.h>
+
 extern tlsf_t tlsf_mem_pool;
 
+struct pool_entry {
+	pool_t pool;
+	struct list_head list;
+};
+
+static LIST_HEAD(mem_pool_list);
+
 void *malloc(size_t bytes)
 {
 	void *mem;
@@ -75,6 +85,7 @@ static void malloc_walker(void* ptr, size_t size, int used, void *user)
 
 void malloc_stats(void)
 {
+	struct pool_entry *cur_pool;
 	struct malloc_stats s;
 
 	s.used = 0;
@@ -82,5 +93,58 @@ void malloc_stats(void)
 
 	tlsf_walk_pool(tlsf_get_pool(tlsf_mem_pool), malloc_walker, &s);
 
+	list_for_each_entry(cur_pool, &mem_pool_list, list)
+		tlsf_walk_pool(cur_pool->pool, malloc_walker, &s);
+
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
+	new_pool_entry = malloc(sizeof(struct pool_entry));
+	if (!new_pool_entry)
+		return NULL;
+
+	new_pool = tlsf_add_pool(tlsf_mem_pool, mem, bytes);
+	if (!new_pool) {
+		free(new_pool_entry);
+		return NULL;
+	}
+
+	kasan_poison_shadow(mem, bytes, KASAN_TAG_INVALID);
+
+	new_pool_entry->pool = new_pool;
+	list_add(&new_pool_entry->list, &mem_pool_list);
+
+	return (void *)new_pool;
+}
+
+int malloc_remove_pool(void *pool)
+{
+	struct pool_entry *cur_pool;
+	struct malloc_stats s;
+
+	s.used = 0;
+	s.free = 0;
+
+	list_for_each_entry(cur_pool, &mem_pool_list, list) {
+		if (cur_pool->pool == (pool_t)pool) {
+			tlsf_walk_pool(cur_pool->pool, malloc_walker, &s);
+			if (s.used)
+				return -EBUSY;
+
+			list_del(&(cur_pool->list));
+			free(cur_pool);
+			tlsf_remove_pool(tlsf_mem_pool, pool);
+			return 0;
+		}
+	}
+
+	return -EINVAL;
+}
diff --git a/include/malloc.h b/include/malloc.h
index 0b74746360c08a95e593c9afe485382d02cd5c12..a3684105981eb4a27594c7cb9a71191ca9dceff3 100644
--- a/include/malloc.h
+++ b/include/malloc.h
@@ -21,6 +21,11 @@
 #define ZERO_OR_NULL_PTR(x) ((unsigned long)(x) <= \
 				(unsigned long)ZERO_SIZE_PTR)
 
+#ifdef CONFIG_MALLOC_TLSF
+void *malloc_add_pool(void *mem, size_t bytes);
+int malloc_remove_pool(void *pool);
+#endif
+
 #if IN_PROPER
 void *malloc(size_t) __alloc_size(1);
 size_t malloc_usable_size(void *);

---
base-commit: d4b5f3d3d1919189c2a8ebbc6ecc531c5459acf8
change-id: 20250131-tlsf-addpool-5f42029b582c

Best regards,
-- 
David Dgien <dgienda125@gmail.com>

