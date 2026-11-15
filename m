From: Alireza Asgari <alireza@asgari.net>
Date: Sun, 15 Nov 2026 22:34:41 +0000
Subject: [PATCH RFC nf-next 1/9] memcg: saturate deferred memory.high page
 debt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-b4-nfqueue-memory-accounting-v1-1-b9cc30819997@asgari.net>
References: <20261115-b4-nfqueue-memory-accounting-v1-0-b9cc30819997@asgari.net>
In-Reply-To: <20261115-b4-nfqueue-memory-accounting-v1-0-b9cc30819997@asgari.net>
To: netfilter-devel@vger.kernel.org, linux-mm@kvack.org
Cc: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, Florian Westphal <fw@strlen.de>, 
 Phil Sutter <phil@nwl.cc>, Shuah Khan <shuah@kernel.org>, 
 Tejun Heo <tj@kernel.org>, Vladimir Davydov <vdavydov.dev@gmail.com>, 
 Chris Down <chris@chrisdown.name>, 
 Zhang Jiao <zhangjiao2@cmss.chinamobile.com>, Song Hu <husong@kylinos.cn>, 
 cgroups@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Alireza Asgari <alireza@asgari.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794782082; l=2138;
 i=alireza@asgari.net; s=alireza-kernel; h=from:subject:message-id;
 bh=MFLqtuTtN7u8/DPQa2KEvRoRy7eP6Qdkj4IqlD51WpM=;
 b=m98I55EK5DDGlH5OD7HSN8CrjP52A8a7eITltlcAQqwelzQ/Ji/0VnlVZwsHX3oQHyR75mAWM
 RPrXccDRgy0DuW481S+kjEPQp4IqBc8At79t2aeJgNQhfDBRfENeSrn
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=wuQ0/M69FqoVnrCMUJ13EQCwrCwVjCrtz75k15vW8tw=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/alireza-kernel with auth_id=1055
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Repeated nonblocking charges can accumulate deferred memory.high work
before the charging task returns to userspace. The unsigned-int page
counter can wrap, including to zero, and erase that pending work. Large
virtual capacity reservations can reach this range without allocating
corresponding physical memory, including on 64-bit kernels.

Saturate the addition at UINT_MAX. Ordinary additions retain their value;
very large debt retains the pressure signal instead of wrapping. This does
not change memory.max checks or promise exact debt beyond the saturation
point.

Found during AI-assisted source review of virtual capacity accounting.
The accompanying KUnit patch calls the real GFP_NOWAIT charging path with
an isolated counter fixture and a 65-page charge. It seeds debt near
UINT_MAX to cover exact-boundary, crossing, and already-saturated cases;
it does not allocate the corresponding large amount of physical memory.

The debt case passed on both 64-bit and 32-bit x86 KUnit kernels built
from this series. The test exercises the production charging and debt
update path; it does not reproduce end-to-end throttling.

Fixes: b23afb93d317 ("memcg: punt high overage reclaim to return-to-userland path")
Signed-off-by: Alireza Asgari <alireza@asgari.net>
---
 mm/memcontrol.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/mm/memcontrol.c b/mm/memcontrol.c
index 84f4a8fd4d16..1980fb7431a8 100644
--- a/mm/memcontrol.c
+++ b/mm/memcontrol.c
@@ -2894,8 +2894,12 @@ static int try_charge_memcg(struct mem_cgroup *memcg, gfp_t gfp_mask,
 			 * Target some best-effort fairness between the tasks,
 			 * and distribute reclaim work and delay penalties
 			 * based on how much each task is actually allocating.
+			 * Saturate so repeated nonblocking charges cannot erase
+			 * pending work by wrapping the counter back to zero.
 			 */
-			current->memcg_nr_pages_over_high += batch;
+			current->memcg_nr_pages_over_high += min(
+				batch,
+				UINT_MAX - current->memcg_nr_pages_over_high);
 			set_notify_resume(current);
 			break;
 		}

-- 
2.34.1

