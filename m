From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 09:12:21 +0000
Subject: [PATCH 6.6.y] mm: list_lru: fix UAF for memory cgroup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-listlru-66b-v1-1-38119b440740@certik.com>
X-B4-Tracking: v=1; b=H4sIAPSaCmsC/02NwQ7CIBBEf6XZs1uFCDH+ivEAdLEYAoalRtP03
 wW9eJyXmTcrMJVADOdhhULPwCGnFsRuADebdCMMU8sgD1ILIU8YA9dYFtTa4tEraaVSznmCtng
 U8uH1tV1Aj3p8w/WHebF3crWbetEaJrTFJDd3xJSmmnPEzvd/D7BtH2+euYmiAAAA
X-Change-ID: 20261128-listlru-66b-4f52b255ccfe
To: stable@vger.kernel.org
Cc: Muchun Song <muchun.song@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Vlastimil Babka <vbabka@suse.cz>, 
 Andrew Morton <akpm@linux-foundation.org>, linux-mm@kvack.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795857140; l=3786;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=POu2beyDobF+0phd+hiYwzwZCt9DRStto5gd3AQtySg=;
 b=mlGUL6TzOy4lzlVmeugaep9HuL/M5Krv56k/4wQTf+FCHY77yp8viURAqToN7Ofyk8c7+RRov
 gtF7vaL5er6CAsoxmGSYZAbH2VtVd/aWo8uOSXe6A5g6EJkzWLWiy4D
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Muchun Song <songmuchun@bytedance.com>

commit 5161b48712dcd08ec427c450399d4d1483e21dea upstream.

The mem_cgroup_from_slab_obj() is supposed to be called under rcu lock or
cgroup_mutex or others which could prevent returned memcg from being
freed.  Fix it by adding missing rcu read lock.

Found by code inspection.

[songmuchun@bytedance.com: only grab rcu lock when necessary, per Vlastimil]
  Link: https://lkml.kernel.org/r/20240801024603.1865-1-songmuchun@bytedance.com
Link: https://lkml.kernel.org/r/20240718083607.42068-1-songmuchun@bytedance.com
Fixes: 0a97c01cd20b ("list_lru: allow explicit memcg and NUMA node selection")
Signed-off-by: Muchun Song <songmuchun@bytedance.com>
Acked-by: Shakeel Butt <shakeel.butt@linux.dev>
Acked-by: Vlastimil Babka <vbabka@suse.cz>
Cc: Johannes Weiner <hannes@cmpxchg.org>
Cc: Nhat Pham <nphamcs@gmail.com>
Cc: <stable@vger.kernel.org>
Signed-off-by: Andrew Morton <akpm@linux-foundation.org>
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.6.y picked up the code this fixes later than the other branches:
0a97c01cd20b came to 6.6.y as 32d7120a499d in 6.6.160, but this
follow-up didn't come with it, so 6.6 has the unprotected
mem_cgroup_from_slab_obj() calls in list_lru_add_obj() and
list_lru_del_obj(). It applies cleanly.

Tested on 6.6.163: allmodconfig W=1 build of mm/list_lru.o, base vs
patched, no new warnings. Both kernels booted under QEMU from an ext4
root and passed all six cgroup test_kmem selftests, including the
memcg deletion case. I didn't hit the race itself.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 mm/list_lru.c | 28 ++++++++++++++++++++++------
 1 file changed, 22 insertions(+), 6 deletions(-)

diff --git a/mm/list_lru.c b/mm/list_lru.c
index fcca67ac26ec..e362a956bf8f 100644
--- a/mm/list_lru.c
+++ b/mm/list_lru.c
@@ -116,6 +116,7 @@ list_lru_from_kmem(struct list_lru *lru, int nid, void *ptr,
 }
 #endif /* CONFIG_MEMCG_KMEM */
 
+/* The caller must ensure the memcg lifetime. */
 bool list_lru_add(struct list_lru *lru, struct list_head *item, int nid,
 		    struct mem_cgroup *memcg)
 {
@@ -140,14 +141,22 @@ EXPORT_SYMBOL_GPL(list_lru_add);
 
 bool list_lru_add_obj(struct list_lru *lru, struct list_head *item)
 {
+	bool ret;
 	int nid = page_to_nid(virt_to_page(item));
-	struct mem_cgroup *memcg = list_lru_memcg_aware(lru) ?
-		mem_cgroup_from_slab_obj(item) : NULL;
 
-	return list_lru_add(lru, item, nid, memcg);
+	if (list_lru_memcg_aware(lru)) {
+		rcu_read_lock();
+		ret = list_lru_add(lru, item, nid, mem_cgroup_from_slab_obj(item));
+		rcu_read_unlock();
+	} else {
+		ret = list_lru_add(lru, item, nid, NULL);
+	}
+
+	return ret;
 }
 EXPORT_SYMBOL_GPL(list_lru_add_obj);
 
+/* The caller must ensure the memcg lifetime. */
 bool list_lru_del(struct list_lru *lru, struct list_head *item, int nid,
 		    struct mem_cgroup *memcg)
 {
@@ -170,11 +179,18 @@ EXPORT_SYMBOL_GPL(list_lru_del);
 
 bool list_lru_del_obj(struct list_lru *lru, struct list_head *item)
 {
+	bool ret;
 	int nid = page_to_nid(virt_to_page(item));
-	struct mem_cgroup *memcg = list_lru_memcg_aware(lru) ?
-		mem_cgroup_from_slab_obj(item) : NULL;
 
-	return list_lru_del(lru, item, nid, memcg);
+	if (list_lru_memcg_aware(lru)) {
+		rcu_read_lock();
+		ret = list_lru_del(lru, item, nid, mem_cgroup_from_slab_obj(item));
+		rcu_read_unlock();
+	} else {
+		ret = list_lru_del(lru, item, nid, NULL);
+	}
+
+	return ret;
 }
 EXPORT_SYMBOL_GPL(list_lru_del_obj);
 

---
base-commit: e2bb30811e063ce0db964484357973b855b06572
change-id: 20261128-listlru-66b-4f52b255ccfe

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

