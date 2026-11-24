From: Junho Cha <junho.cha@xcena.com>
Date: Tue, 24 Nov 2026 18:15:47 +0900
Subject: [PATCH] cxl/region: Reject freeing the HPA of a region with
 attached targets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-junhomax-fix-cxl-region-free-hpa-targets-v1-1-9229ae407595@xcena.com>
X-B4-Tracking: v=1; b=H4sIAMJVBWsC/yWNwQ6CMBBEf4Xs2Y1QiKK/Yjxsy9KWaCHbYpoQ/
 t2ixzeZebNBZPEc4V5tIPzx0c+hQHOqwDgKltEPhUHV6tI0qsNpDW5+U8bRZzT5hcK2bHAUZnQ
 LYSKxnCLWfdvTlTq+tQMU3SJcJr+rx/PPcdUTm3T4j4amyKiFgnFHVOTnwDnBvn8BCleAoKcAA
 AA=
X-Change-ID: 20261124-junhomax-fix-cxl-region-free-hpa-targets-0838a7a4e93d
To: linux-cxl@vger.kernel.org, Dave Jiang <dave.jiang@intel.com>
Cc: Li Ming <ming.li@zohomail.com>, Vishal Verma <vishal.l.verma@intel.com>, 
 Richard Cheng <icheng@nvidia.com>, Jonathan Cameron <jic23@kernel.org>, 
 Davidlohr Bueso <dave@stgolabs.net>, 
 Ben Cheatham <benjamin.cheatham@amd.com>, 
 Alison Schofield <alison.schofield@intel.com>, 
 Ira Weiny <iweiny@kernel.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795511746; l=2089;
 i=junho.cha@xcena.com; s=20261113; h=from:subject:message-id;
 bh=+shOErfbEre4hWHhIGr07nm3Q4E88vlfKVuH7VEIVN0=;
 b=Ge33xovHF4kL3qvaSeua03PXbWl189Ali97k6c0IKfwT5MsoMTw2ugPgYv7y4m36Rs2A0/Dbp
 GkWNGdbPA8NAccyrj3JxeFGeKlETm7M4BfZIDNdJhAzXOQ1CmEp9aVs
X-Developer-Key: i=junho.cha@xcena.com; a=ed25519;
 pk=OkFm4PnuJSze1AVqDdvnpHO7nnDQIheH2qYwg2a6Dyc=
X-Endpoint-Received: by B4 Relay for junho.cha@xcena.com/20261113 with auth_id=1507
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

free_hpa() only refuses once the region is CXL_CONFIG_ACTIVE. With
some targets attached, root can write 0 to size, which returns the
region to CXL_CONFIG_IDLE and lets interleave_ways,
interleave_granularity and size change while the attached endpoint
decoders keep their old settings.

The region can then be committed with endpoint decoders that do not
match it. If interleave_ways shrinks so that an attached target's
position is out of range, attaching targets until nr_targets reaches
the new interleave_ways can lead to a NULL dereference in
cxl_region_setup_targets(). Deleting the region and later unbinding
that target's memdev can lead to a use-after-free in
__cxl_decoder_detach(). All three were reproduced with cxl_test.

Refuse to free the HPA while any target is attached. libcxl never
writes 0 to size, so cxl-cli is not affected.

Fixes: 384e624bb211 ("cxl/region: Attach endpoint decoders")
Cc: stable@vger.kernel.org
Signed-off-by: Junho Cha <junho.cha@xcena.com>
---
Tested with cxl_test before and after the change on cxl/next, v6.12 and
v6.16. The patch applies unchanged to v6.1, v6.6, v6.12 and v6.18.
Writing 0 to size after detaching all targets still works. Before
commit b3a88225519c ("cxl/region: Consolidate cxl_decoder_kill_region()
and cxl_region_detach()"), the use-after-free case only triggers a
warning.
---
 drivers/cxl/core/region.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/cxl/core/region.c b/drivers/cxl/core/region.c
index 237172b33f55..53965f1e4719 100644
--- a/drivers/cxl/core/region.c
+++ b/drivers/cxl/core/region.c
@@ -772,6 +772,10 @@ static int free_hpa(struct cxl_region *cxlr)
 	if (!p->res)
 		return 0;
 
+	/* Attached targets hold the current geometry, detach them first */
+	if (p->nr_targets)
+		return -EBUSY;
+
 	if (p->state >= CXL_CONFIG_ACTIVE)
 		return -EBUSY;
 

---
base-commit: 32af7819352bae9c690ebe277a44eceb501d5c68
change-id: 20261124-junhomax-fix-cxl-region-free-hpa-targets-0838a7a4e93d

Best regards,
--  
Junho Cha <junho.cha@xcena.com>

