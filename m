From: Junho Cha <junho.cha@xcena.com>
Date: Thu, 19 Nov 2026 10:44:36 +0900
Subject: [PATCH v2] cxl/region: Fix self-deadlock when
 cxl_memdev_attach_region() fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-junhomax-fix-cxl-attach-region-deadlock-v2-1-32ddef645e52@xcena.com>
X-B4-Tracking: v=1; b=H4sIAINU/moC/42Oyw4CIQxFf8WwtiqM4ySu/A8zi07pCD7AAE4wZ
 v5d0Lh3edre0/sSkYPlKPaLlwg82Wi9K6CWC0EG3YnB6sJCbdROStnA+eGMv2GG0WagfAVMCcl
 A4FOJgmbUV08XGGmDW9WOndq1otjugUvi8+nYfzk+hjNTqvp6MWBkGAI6MnVU3GvHOdWVsTH58
 Py0nGRV/Ap1fxeaJEgYm65B2bSstTpkYocr8jfRz/P8Bjz7J3wLAQAA
X-Change-ID: 20261113-junhomax-fix-cxl-attach-region-deadlock-fc0a425f7265
To: Dave Jiang <dave.jiang@intel.com>, linux-cxl@vger.kernel.org
Cc: Davidlohr Bueso <dave@stgolabs.net>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Alison Schofield <alison.schofield@intel.com>, 
 Vishal Verma <vishal.l.verma@intel.com>, Ira Weiny <iweiny@kernel.org>, 
 Li Ming <ming.li@zohomail.com>, Ben Cheatham <benjamin.cheatham@amd.com>, 
 Alejandro Lucero <alucerop@amd.com>, Richard Cheng <icheng@nvidia.com>, 
 linux-kernel@vger.kernel.org, Sashiko <sashiko-bot@kernel.org>, 
 Junho Cha <junho.cha@xcena.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795052675; l=4969;
 i=junho.cha@xcena.com; s=20261113; h=from:subject:message-id;
 bh=BzCoR+CtJdDu/2UmEZ5eieYhLBnjjCJCk7PJaGYt0VM=;
 b=R8gEPdS1ts+/teNCGYIS1PUdYfum3DZ3Pe8lqwiCWS65WPngOAm8oI373gSWHLTgwXKQ8InHI
 CBvdUtJR9CRBXAIFxghz2b4BwsjVWv7oDt7FjD1ue2yPYna772vEdsg
X-Developer-Key: i=junho.cha@xcena.com; a=ed25519;
 pk=OkFm4PnuJSze1AVqDdvnpHO7nnDQIheH2qYwg2a6Dyc=
X-Endpoint-Received: by B4 Relay for junho.cha@xcena.com/20261113 with auth_id=1507
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cxl_memdev_attach_region() holds cxl_rwsem.region for read while it
registers endpoint_unregister_region() with devm_add_action_or_reset().
If registering the action fails, devm_add_action_or_reset() runs the
action at once, which reaches cxl_decoder_detach() through
unregister_region() and detach_target():

  cxl_memdev_attach_region()
    down_read(&cxl_rwsem.region)
    devm_add_action_or_reset()          /* fails with -ENOMEM */
      endpoint_unregister_region()
        unregister_region()
          detach_target()
            cxl_decoder_detach()
              down_write_killable(&cxl_rwsem.region)

The task then waits for a write lock while holding the same rwsem for
read, and never makes progress.  Before it hangs, lockdep also reports
a circular dependency: endpoint_unregister_region() takes
cxlrd->regions_lock under cxl_rwsem.dpa, while cxl_add_to_region()
takes cxlrd->regions_lock before both rwsems.

Register the action with devm_add_action() instead, still under both
rwsems, and if that fails, run it only after the rwsems are dropped.
The endpoint device lock stays held throughout, as before.

Reproduced with cxl_test (type2_test=1) by failing the devres
allocation through failslab, with the stack filter limited to
cxl_memdev_attach_region().  Without this patch the probing task hangs
in cxl_decoder_detach().  With it, the cxl_mem probe fails with
-ENOMEM, the region is unregistered, and lockdep stays quiet.

Fixes: d8dcb0b74b04 ("cxl/region: Introduce devm_cxl_probe_mem()")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Link: https://lore.kernel.org/all/20260805080537.7489E1F000E9@smtp.kernel.org/
Assisted-by: LLM
Signed-off-by: Junho Cha <junho.cha@xcena.com>
---
Dave pointed at this reset path while reviewing the Type2 multipf
series [1]. This is a standalone fix for the existing code that keeps
the region teardown when registering the action fails.

[1] https://lore.kernel.org/linux-cxl/6bc33514-8bfb-44d6-8fde-28f45dff5eb9@intel.com/
---
Changes in v2:
- Register the action under both rwsems as before and only run the
  unwind after dropping them.  v1 left a window where the region could
  be detached before the action was registered (Ben).
- Add Reported-by/Link for Sashiko.
- Drop Alejandro's Reviewed-by, since the fix changed.
- Link to v1: https://patch.msgid.link/20261117-junhomax-fix-cxl-attach-region-deadlock-v1-1-f373a135edd2@xcena.com
---
 drivers/cxl/core/region.c | 32 ++++++++++++++++++++++++--------
 1 file changed, 24 insertions(+), 8 deletions(-)

diff --git a/drivers/cxl/core/region.c b/drivers/cxl/core/region.c
index 237172b33f55..f9538ac98a1f 100644
--- a/drivers/cxl/core/region.c
+++ b/drivers/cxl/core/region.c
@@ -4437,7 +4437,8 @@ static int first_mapped_decoder(struct device *dev, const void *data)
  * Runs in cxl_mem_probe context after successful endpoint probe, assumes the
  * simple case of single mapped decoder per memdev.
  */
-int cxl_memdev_attach_region(struct cxl_memdev *cxlmd)
+static int __cxl_memdev_attach_region(struct cxl_memdev *cxlmd,
+				      struct cxl_region **unwind)
 {
 	struct cxl_attach_region *attach =
 		container_of(cxlmd->attach, typeof(*attach), attach);
@@ -4446,10 +4447,6 @@ int cxl_memdev_attach_region(struct cxl_memdev *cxlmd)
 	struct cxl_region *cxlr;
 	int rc;
 
-	/* hold endpoint lock to setup autoremove of the region */
-	guard(device)(&endpoint->dev);
-	if (!endpoint->dev.driver)
-		return -ENXIO;
 	guard(rwsem_read)(&cxl_rwsem.region);
 	guard(rwsem_read)(&cxl_rwsem.dpa);
 
@@ -4484,10 +4481,11 @@ int cxl_memdev_attach_region(struct cxl_memdev *cxlmd)
 
 	/* Only teardown regions that pass validation, ignore the rest */
 	get_device(&cxlr->dev);
-	rc = devm_add_action_or_reset(&endpoint->dev,
-				      endpoint_unregister_region, cxlr);
-	if (rc)
+	rc = devm_add_action(&endpoint->dev, endpoint_unregister_region, cxlr);
+	if (rc) {
+		*unwind = cxlr;
 		return rc;
+	}
 
 	attach->hpa_range = (struct range) {
 		.start = cxlr->params.res->start,
@@ -4495,6 +4493,24 @@ int cxl_memdev_attach_region(struct cxl_memdev *cxlmd)
 	};
 	return 0;
 }
+
+int cxl_memdev_attach_region(struct cxl_memdev *cxlmd)
+{
+	struct cxl_port *endpoint = cxlmd->endpoint;
+	struct cxl_region *unwind = NULL;
+	int rc;
+
+	/* hold endpoint lock to setup autoremove of the region */
+	guard(device)(&endpoint->dev);
+	if (!endpoint->dev.driver)
+		return -ENXIO;
+
+	/* Detaching the region takes cxl_rwsem.region, so unwind without it */
+	rc = __cxl_memdev_attach_region(cxlmd, &unwind);
+	if (unwind)
+		endpoint_unregister_region(unwind);
+	return rc;
+}
 EXPORT_SYMBOL_FOR_MODULES(cxl_memdev_attach_region, "cxl_mem");
 
 /*

---
base-commit: 32af7819352bae9c690ebe277a44eceb501d5c68
change-id: 20261113-junhomax-fix-cxl-attach-region-deadlock-fc0a425f7265

Best regards,
--  
Junho Cha <junho.cha@xcena.com>

