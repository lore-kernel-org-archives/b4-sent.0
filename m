From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:40 -0500
Subject: [PATCH 49/60] mm/vmscan: reclaim private nodes for memcg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-49-74f5f9a115c2@gourry.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198153; l=4186;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=gf0+A4YMX7aNzEjLzoppxY9C0nz/hDCzkhh7ctvqKwQ=;
 b=PXI/X13XAoa7r+jmzPre0N2z+VrJATpuAV7CpwhBQAVTEngszA2E6bmutkAMGbnv2eUsyGVrn
 +kF2GDAg++lDYHrIPmvec6YTNf5pZ5MjEHc8/slSYzQiq7FbbeI35Jq
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Memcg reclaim does not serve one allocation, so it should cover every
node that permits reclaim. It walks the current node's fallback
zonelist, which holds no private node, so a private node that permits
reclaim is never scanned for a cgroup over its limit.

After the zonelist, visit the nodes that permit reclaim and that the
zonelist did not cover, and give them the same refault snapshot and
congestion reset. The zonelist keeps setting the order, which matters
because memcg reclaim stops once it has freed enough.

Direct reclaim for an allocation still walks only that allocation's
zonelist. A private allocation's zonelist covers its own node, and
reclaiming private memory cannot satisfy a common allocation.

Without private nodes the zonelist covers every node that permits
reclaim, so behavior is unchanged.

Another way to do this would be to implement a reclaim zonelist that
only reclaim uses, but this implementation does not carry the static
per-node size overhead that adding another zonelist does.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 mm/vmscan.c | 43 ++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 42 insertions(+), 1 deletion(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index 03d0919d11be..49ec85ed00e0 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -6636,6 +6636,21 @@ static void consider_reclaim_throttle(pg_data_t *pgdat, struct scan_control *sc)
 		reclaim_throttle(pgdat, VMSCAN_THROTTLE_NOPROGRESS);
 }
 
+/* Whether shrink_zones() reaches @nid through @zonelist. */
+static bool zonelist_reaches_node(struct zonelist *zonelist, int nid,
+				  struct scan_control *sc)
+{
+	struct zoneref *z;
+	struct zone *zone;
+
+	for_each_zone_zonelist_nodemask(zone, z, zonelist, sc->reclaim_idx,
+					sc->nodemask) {
+		if (zone_to_nid(zone) == nid)
+			return true;
+	}
+	return false;
+}
+
 /*
  * This is the direct reclaim path, for page-allocating processes.  We only
  * try to reclaim pages from zones which will satisfy the caller's allocation
@@ -6651,6 +6666,7 @@ static void shrink_zones(struct zonelist *zonelist, struct scan_control *sc)
 	gfp_t orig_mask;
 	pg_data_t *last_pgdat = NULL;
 	pg_data_t *first_pgdat = NULL;
+	int nid;
 
 	/*
 	 * If the number of buffer_heads in the machine exceeds the maximum
@@ -6706,6 +6722,14 @@ static void shrink_zones(struct zonelist *zonelist, struct scan_control *sc)
 		shrink_node(zone->zone_pgdat, sc);
 	}
 
+	/* A cgroup's memory may be on nodes that are not on the zonelist. */
+	if (cgroup_reclaim(sc)) {
+		for_each_node_state(nid, N_MEMORY_RECLAIM) {
+			if (!zonelist_reaches_node(zonelist, nid, sc))
+				shrink_node(NODE_DATA(nid), sc);
+		}
+	}
+
 	if (first_pgdat)
 		consider_reclaim_throttle(first_pgdat, sc);
 
@@ -6754,6 +6778,7 @@ static unsigned long do_try_to_free_pages(struct zonelist *zonelist,
 	pg_data_t *last_pgdat;
 	struct zoneref *z;
 	struct zone *zone;
+	int nid;
 retry:
 	delayacct_freepages_start();
 
@@ -6792,6 +6817,21 @@ static unsigned long do_try_to_free_pages(struct zonelist *zonelist,
 		}
 	}
 
+	/*
+	 * Also cover the nodes shrink_zones() reclaimed beyond the zonelist.
+	 * Finishing a zonelist node again is harmless.
+	 */
+	if (cgroup_reclaim(sc)) {
+		for_each_node_state(nid, N_MEMORY_RECLAIM) {
+			struct lruvec *lruvec;
+
+			snapshot_refaults(sc->target_mem_cgroup, NODE_DATA(nid));
+			lruvec = mem_cgroup_lruvec(sc->target_mem_cgroup,
+						   NODE_DATA(nid));
+			clear_bit(LRUVEC_CGROUP_CONGESTED, &lruvec->flags);
+		}
+	}
+
 	delayacct_freepages_end();
 
 	if (sc->nr_reclaimed)
@@ -7038,7 +7078,8 @@ unsigned long try_to_free_mem_cgroup_pages(struct mem_cgroup *memcg,
 	/*
 	 * Traverse the ZONELIST_FALLBACK zonelist of the current node to put
 	 * equal pressure on all the nodes. This is based on the assumption that
-	 * the reclaim does not bail out early.
+	 * the reclaim does not bail out early. shrink_zones() also visits the
+	 * nodes that permit reclaim and are not on the zonelist.
 	 */
 	struct zonelist *zonelist = node_zonelist(numa_node_id(), sc.gfp_mask);
 

-- 
2.56.1

