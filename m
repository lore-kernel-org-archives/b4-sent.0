From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH 0/2] mm: fix memcg_data reads during a THP split
Date: Wed, 04 Nov 2026 18:59:07 +0900
Message-Id: <20261104-kpagecgroup-split-v1-0-f70e947fec85@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOsB62oC/x3MQQqAIBRF0a3EHyeYRFlbiQZiL/sUJVoRSHtPG
 p7BvYkiAiNSXyQKuDnysWdUZUF2MbuD4CmblFRNJZUWqzcO1oXj8iL6jU+hTVt3tgFUC8qdD5j
 5+Z/D+L4feHUaV2MAAAA=
To: Andrew Morton <akpm@linux-foundation.org>
Cc: Tao Yi <escape@deepseek.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Michal Hocko <mhocko@kernel.org>, Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 David Hildenbrand <david@kernel.org>, Zi Yan <ziy@nvidia.com>, 
 Matthew Wilcox <willy@infradead.org>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Nico Pache <nico.pache@linux.dev>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Barry Song <baohua@kernel.org>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Brendan Jackman <brendan.jackman@linux.dev>, linux-mm@kvack.org, 
 cgroups@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793786347; l=1142;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=y+BIdTbHzrH+8Uu1YnmKDz/Hk8zUyXmI5VDnrLuv9PY=;
 b=0+otGc3rNezYaJu/zwXPPYuiIecNe6HZUqy7esh0CFuBqce5P1RDP0GxbRJvib69MJuiM1e+o
 VoK4dvibbOeC6yGIvA864Y0zKn7FrlYCtd9M/sFikqiNwtBE7itbRNL
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Tao Yi reported an oops in page_cgroup_ino() while reading
/proc/kpagecgroup and traced it to the THP split in an RFC [1]. The
RFC skips frozen folios in the reader. Patch 1 moves the memcg_data
copy in the split instead. Patch 2 orders the same loads in
page_owner and needs patch 1.

Charged large kmalloc pages are frozen, so the RFC would report them
as uncharged. My review of the RFC [2] got no reply. Tested on x86_64
with KASAN, see patch 1.

[1] https://lore.kernel.org/all/20260907124001.1544655-1-escape@deepseek.com/
[2] https://lore.kernel.org/all/20261028040418epcms2p7ac0f584cdfdc6a0ea9b7f20eadeada3d@epcms2p7/

---
Daejun Park (2):
      mm/huge_memory: set memcg_data before a split page leaves the folio
      mm/page_owner: also check PageTail before reading memcg_data

 mm/huge_memory.c | 17 +++++++++++++----
 mm/memcontrol.c  |  9 ++++++++-
 mm/page_owner.c  |  7 +++++++
 3 files changed, 28 insertions(+), 5 deletions(-)
---
base-commit: a13b500946e5dc467976838572b8ddd2fd777ca7
change-id: 20261028-kpagecgroup-split-8a749c6ee27e

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

