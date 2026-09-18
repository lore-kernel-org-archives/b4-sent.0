From: Jingxiang Zeng <linuszeng@tencent.com>
Date: Fri, 18 Sep 2026 16:53:46 +0800
Subject: [PATCH 6/6] mm: memcontrol: clamp mem_cgroup_get_max() to the
 combined limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-descriptive-name-v1-6-dfcfdd91b456@tencent.com>
References: <20260918-descriptive-name-v1-0-dfcfdd91b456@tencent.com>
In-Reply-To: <20260918-descriptive-name-v1-0-dfcfdd91b456@tencent.com>
To: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Maarten Lankhorst <dev@lankhorst.se>, Maxime Ripard <mripard@kernel.org>, 
 Natalie Vock <nat@pixelcluster.dev>, Tejun Heo <tj@kernel.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Oscar Salvador <osalvador@suse.de>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: Jingxiang Zeng <jingxiangzeng.cas@gmail.com>, cgroups@vger.kernel.org, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-doc@vger.kernel.org, 
 Jingxiang Zeng <linuszeng@tencent.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721651; l=1734;
 i=linuszeng@tencent.com; s=20260909; h=from:subject:message-id;
 bh=zhtOFhKxtUFb8xp+y1sRK9RNl80hp/9T+5xQLqfkz8g=;
 b=EL4RDYrjbrEVE0Vr7y+4cIOSQgOIfXScAu7h3KFs+GeoFED9JQADdqJOi0z5dI/RGqwmZiadl
 oD5iJCJEyvMDmM2LC4+vXp+Pk0BjC/J109Snq3XrqY5aSU7jeIHLraO
X-Developer-Key: i=linuszeng@tencent.com; a=ed25519;
 pk=6K54xRzYIRWqatrAPy86M4E0MsI92BVJBhXwz5NdC74=
X-Endpoint-Received: by B4 Relay for linuszeng@tencent.com/20260909 with auth_id=1017
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mem_cgroup_get_max() reports the memory ceiling of a cgroup.  Its
default-hierarchy branch derives that ceiling from memory.max plus
memory.swap.max, which overstates the reachable total once a combined
memory+swap limit is configured: with memory.max at 32M,
memory.memsw.max at 48M and 2G of swap online it reports about 2080M.

For memcg OOM, constrained_alloc() stores that value in oc->totalpages,
and oom_badness() scales the task's oom_score_adj by
totalpages / OOM_SCORE_ADJ_MAX, so an overstated ceiling weighs
oom_score_adj far more than intended inside such a cgroup: in the
example above about forty times, enough that a task with a negative
adjustment stops being selectable at all while a positive one is picked
long before its rss would justify it.

Clamp the result to memory.memsw.max, which is what the v1 branch
already derives its ceiling from.  The limit defaults to "max", so this
changes nothing until a combined limit is configured.

Signed-off-by: Jingxiang Zeng <linuszeng@tencent.com>
---
 mm/memcontrol.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 9e8a176e7afb..e229de0d35e0 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -1919,6 +1919,12 @@ unsigned long mem_cgroup_get_max(struct mem_cgroup *memcg)
 		if (mem_cgroup_swappiness(memcg))
 			max += min(READ_ONCE(memcg->swap.max),
 				   (unsigned long)total_swap_pages);
+		/*
+		 * A combined memory+swap limit caps the sum of the two, so it
+		 * is the real ceiling once it is configured.  It defaults to
+		 * "max", which leaves the value above unchanged.
+		 */
+		max = min(max, READ_ONCE(memcg->memsw.max));
 	}
 	return max;
 }

-- 
2.43.7

