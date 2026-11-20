From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:14 -0500
Subject: [PATCH 23/60] mm/damon: restrict DAMON-native folio operations to
 common memory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-23-74f5f9a115c2@gourry.net>
References: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
In-Reply-To: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
To: Yury Norov <yury.norov@gmail.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 David Hildenbrand <david@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Michal Hocko <mhocko@suse.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Oscar Salvador <osalvador@suse.de>, Johannes Weiner <hannes@cmpxchg.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Brendan Jackman <brendan.jackman@linux.dev>, Zi Yan <ziy@nvidia.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Rakie Kim <rakie.kim@sk.com>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Matthew Brost <matthew.brost@intel.com>, Byungchul Park <byungchul@sk.com>, 
 Alistair Popple <apopple@nvidia.com>, SJ Park <sj@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, Kees Cook <kees@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Michal Hocko <mhocko@kernel.org>, David Rientjes <rientjes@google.com>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Xu Xin <xu.xin@linux.dev>, Chengming Zhou <chengming.zhou@linux.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, Pedro Falcato <pfalcato@suse.de>, 
 Jann Horn <jannh@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, Jan Kara <jack@suse.cz>, 
 Waiman Long <longman@redhat.com>, Ridong Chen <ridong.chen@linux.dev>, 
 Tejun Heo <tj@kernel.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Dan Williams <djbw@kernel.org>, Vishal Verma <vishal.l.verma@intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, 
 Alison Schofield <alison.schofield@intel.com>, 
 Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 linux-cxl@vger.kernel.org, linux-doc@vger.kernel.org, 
 driver-core@lists.linux.dev, damon@lists.linux.dev, 
 linux-pm@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 cgroups@vger.kernel.org, nvdimm@lists.linux.dev, 
 linux-kselftest@vger.kernel.org, "Gregory Price (Meta)" <gourry@gourry.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198152; l=1668;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=V04Qzs1fFpNTUapr14E0HnNb9Xxz8DrH55t1p7KWMZU=;
 b=RMc1L4r0dlZpqP5Q+uot3dU1rWD7OMYOabzEbwk3/bzUXH/pZdb+6OmzM/UnOgzxpD/hhyFTZ
 4DV6BPxrgdECffvg689x8JzsMYq+qTUvinCDA2UxDQTgWjuAldpeOdl
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DAMON acquires folios to age them, check their accesses, and apply LRU
operations and migration. Treat these as general-purpose MM services
and restrict them to N_MEMORY_COMMON.

Memory outside N_MEMORY_COMMON can still hold ordinary LRU folios, so
it would pass the checks that keep ZONE_DEVICE memory out of these
operations.

Treat these folios like ZONE_DEVICE memory.

DAMON cannot acquire such a folio, so it never ages one and virtual
address monitoring reports it as accessed, and DAMOS cannot isolate
one for migration.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 mm/damon/ops-common.c | 5 +++--
 mm/damon/vaddr.c      | 2 +-
 2 files changed, 4 insertions(+), 3 deletions(-)

diff --git a/mm/damon/ops-common.c b/mm/damon/ops-common.c
index 15cabc79613b..57201a0c5e3a 100644
--- a/mm/damon/ops-common.c
+++ b/mm/damon/ops-common.c
@@ -17,8 +17,9 @@
 
 static bool damon_folio_acceptable(struct folio *folio, bool monitor)
 {
-	return folio_test_lru(folio) ||
-		(monitor && folio_test_hugetlb(folio));
+	return folio_is_common_memory(folio) &&
+		(folio_test_lru(folio) ||
+		 (monitor && folio_test_hugetlb(folio)));
 }
 
 /*
diff --git a/mm/damon/vaddr.c b/mm/damon/vaddr.c
index 1e65e7651cd9..338876559140 100644
--- a/mm/damon/vaddr.c
+++ b/mm/damon/vaddr.c
@@ -830,7 +830,7 @@ static void damos_va_migrate_dests_add(struct folio *folio,
 	if (folio_nid(folio) == nid)
 		return;
 
-	if (!folio_isolate_lru(folio))
+	if (!folio_is_common_memory(folio) || !folio_isolate_lru(folio))
 		return;
 	node_stat_add_folio(folio, NR_ISOLATED_ANON +
 			folio_is_file_lru(folio));

-- 
2.56.1

