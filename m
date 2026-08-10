From: Zhenyu Yang <haruki@seu.edu.cn>
Date: Tue, 11 Aug 2026 03:32:37 +0800
Subject: [PATCH] drm/xe: Exclude wopcm region from stolen memory on TGL/DG1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-fix-xe-ttm-v1-1-8d58b08f02b3@seu.edu.cn>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBCF4VeRWZukRRSvIhZVg5G4pC2RiHdXL
 L+cnP8CR5bJQRVdYOlgx+sSIOMIzKiXgZC7YEhEkotCSuz5xJPQ+xkzXSqZdsoYXUI4bJbC+sX
 q5rfb24mMfwtw3w9iBrXybgAAAA==
X-Change-ID: 20260811-fix-xe-ttm-4a9713d7cca9
To: intel-xe@lists.freedesktop.org
Cc: dri-devel@lists.freedesktop.org, 
 Sanjay Yadav <sanjay.kumar.yadav@intel.com>, 
 Lucas De Marchi <demarchi@kernel.org>, Zhenyu Yang <haruki@seu.edu.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786390365; l=1557;
 i=haruki@seu.edu.cn; s=20260810; h=from:subject:message-id;
 bh=MR427Mkv+jciFjssrVFmackeIc2s7Un5r4gv3vpAeQo=;
 b=ZZ4mSkXpLj1hHTBkIU4V6FHUvr02o/TjpaiNSKWOGknZFsj0qu7+3SkTyaDlh1GF8mZ42zO1M
 h2qnkL26JQ7DNVv6AzduMMwbSe+dw5fzyM7SQZj85NJP8AV/hPVu+/2
X-Developer-Key: i=haruki@seu.edu.cn; a=ed25519;
 pk=Rh6scJJVrfKi0fDllLpvJXubmo9YB57MLrju0xpHeIk=
X-Endpoint-Received: by B4 Relay for haruki@seu.edu.cn/20260810 with auth_id=935
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Top of DSM contains the WOPCM which shouldn't be accessed. Carve it out
from the stolen memory on TGL/DG1 as well.  This fixes excessive ATS faults
on an RPL laptop since v7.2-rc1.

Fixes: 1c76fa517214 ("drm/xe: Convert stolen memory over to ttm_range_manager")
Signed-off-by: Zhenyu Yang <haruki@seu.edu.cn>
---
 drivers/gpu/drm/xe/xe_ttm_stolen_mgr.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/xe/xe_ttm_stolen_mgr.c b/drivers/gpu/drm/xe/xe_ttm_stolen_mgr.c
index 5e9070739e65..75f4d064d711 100644
--- a/drivers/gpu/drm/xe/xe_ttm_stolen_mgr.c
+++ b/drivers/gpu/drm/xe/xe_ttm_stolen_mgr.c
@@ -180,12 +180,22 @@ extern struct resource intel_graphics_stolen_res;
 static u64 detect_stolen(struct xe_device *xe, struct xe_ttm_stolen_mgr *mgr)
 {
 #ifdef CONFIG_X86
+	u64 stolen_size, wopcm_size;
+
 	/* Map into GGTT */
 	mgr->io_base = pci_resource_start(to_pci_dev(xe->drm.dev), 2);
 
 	/* Stolen memory is x86 only */
 	mgr->stolen_base = intel_graphics_stolen_res.start;
-	return resource_size(&intel_graphics_stolen_res);
+	stolen_size = resource_size(&intel_graphics_stolen_res);
+
+	/* Carve out the top of DSM as it contains the reserved WOPCM region */
+	wopcm_size = get_wopcm_size(xe);
+	if (drm_WARN_ON(&xe->drm, !wopcm_size))
+		return 0;
+
+	xe_assert(xe, stolen_size >= wopcm_size);
+	return stolen_size - wopcm_size;
 #else
 	return 0;
 #endif

---
base-commit: db2ddb87143519e20a95aa36c60b36107b736a58
change-id: 20260811-fix-xe-ttm-4a9713d7cca9

