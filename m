From: Jim Cromie <jim.cromie@gmail.com>
Date: Fri, 09 Oct 2026 11:44:26 -0600
Subject: [PATCH v2 3/3] nouveau: Fix NULL dereference in
 nvkm_gsp_gcx_ready()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-my-fixups-v2-3-839e2bbe514d@gmail.com>
References: <20261009-my-fixups-v2-0-839e2bbe514d@gmail.com>
In-Reply-To: <20261009-my-fixups-v2-0-839e2bbe514d@gmail.com>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Daniel Campos Ramos <Capitain_Jack@yahoo.com>, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791567877; l=3425;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=YyKLmo0bEj/hJpRUlDlZOCssFCXNnz2YynMbMOOeOi4=;
 b=UOPAMqmtzEXw0svG2xoRhLf7pa0/9gTca19f8JoK3eLaMt8FPyB6oNGnlVSyxtXKPSpi3IYhZ
 IiR/juE41x5CH1MMejtk/VLRyAgubmV7cjNA/+0qHI5/NXBvF8OzuRL
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit cb4c7603678c ("drm/nouveau/gsp/r570: Add support for
INTERNAL_GCX_ENTRY_PREREQUISITE") hooked nvif_device_gcx_ready() into
nouveau_pmops_runtime_suspend() to consult GSP before runtime suspend.

On GPUs running without GSP-RM (e.g. Volta GV100, NvGspRm=0, or missing
GSP firmware blobs), device->gsp is instantiated but gsp->rm remains
NULL. nvkm_udevice_gcx_ready() checked "!gsp" instead of verifying
nvkm_gsp_rm(gsp), allowing non-RM instances to invoke
nvkm_gsp_gcx_ready(). nvkm_gsp_gcx_ready() then unconditionally
dereferenced gsp->rm->api, causing a kernel oops:

  RIP: 0010:nvkm_gsp_gcx_ready+0x10/0x30 [nouveau]
  Code: ... 48 8b 87 70 0e 00 00 <48> 8b 40 18 ...
  RAX: 0000000000000000 RDI: ffff8c9555fca000
  Call Trace:
   nvkm_udevice_mthd+0xa5/0x150 [nouveau]
   nvkm_ioctl+0xcc/0x1d0 [nouveau]
   nvif_object_mthd+0x110/0x1e0 [nouveau]
   nvif_device_gcx_ready+0x36/0x60 [nouveau]
   nouveau_pmops_runtime_suspend+0x39/0x140 [nouveau]

Instruction decode shows `mov rax, [rdi+0xe70]` loads gsp->rm (0x0),
and `<48> 8b 40 18` (`mov rax, [rax+0x18]`) faults accessing rm->api.

Fix by:
0. Checking !nvkm_gsp_rm(gsp) in nvkm_udevice_gcx_ready() so non-RM
   devices report GC6/GcOff ready and bypass the GSP call entirely.
1. Guarding gsp and gsp->rm in nvkm_gsp_gcx_ready() before inspecting
   gsp->rm->api->gsp->gcx_ready.

Fixes: cb4c7603678c ("drm/nouveau/gsp/r570: Add support for INTERNAL_GCX_ENTRY_PREREQUISITE")
Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 drivers/gpu/drm/nouveau/include/nvkm/subdev/gsp.h | 2 +-
 drivers/gpu/drm/nouveau/nvkm/engine/device/user.c | 2 +-
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/base.c    | 2 +-
 3 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/include/nvkm/subdev/gsp.h b/drivers/gpu/drm/nouveau/include/nvkm/subdev/gsp.h
index ed5c6e0e68d3..933f13ed2a50 100644
--- a/drivers/gpu/drm/nouveau/include/nvkm/subdev/gsp.h
+++ b/drivers/gpu/drm/nouveau/include/nvkm/subdev/gsp.h
@@ -274,7 +274,7 @@ struct nvkm_gsp {
 static inline bool
 nvkm_gsp_rm(struct nvkm_gsp *gsp)
 {
-	return gsp && (gsp->fws.rm || gsp->fw.img);
+	return gsp && gsp->rm && (gsp->fws.rm || gsp->fw.img);
 }
 
 #include <rm/rm.h>
diff --git a/drivers/gpu/drm/nouveau/nvkm/engine/device/user.c b/drivers/gpu/drm/nouveau/nvkm/engine/device/user.c
index f78e6b9b4292..d469437eb991 100644
--- a/drivers/gpu/drm/nouveau/nvkm/engine/device/user.c
+++ b/drivers/gpu/drm/nouveau/nvkm/engine/device/user.c
@@ -201,7 +201,7 @@ nvkm_udevice_gcx_ready(struct nvkm_udevice *udev, void *data, u32 size)
 	} *args = data;
 	int ret = -ENOSYS;
 
-	if (!gsp) {
+	if (!nvkm_gsp_rm(gsp)) {
 		args->v0.ready = NV_DEVICE_GC6_READY | NV_DEVICE_GCOFF_READY;
 		return 0;
 	}
diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/base.c b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/base.c
index e475d0e8fa7b..ea895f04293a 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/base.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/base.c
@@ -51,7 +51,7 @@ nvkm_gsp_intr_stall(struct nvkm_gsp *gsp, enum nvkm_subdev_type type, int inst)
 int
 nvkm_gsp_gcx_ready(struct nvkm_gsp *gsp)
 {
-	if (!gsp->rm->api->gsp->gcx_ready)
+	if (!nvkm_gsp_rm(gsp) || !gsp->rm->api->gsp->gcx_ready)
 		return NV_DEVICE_GC6_READY | NV_DEVICE_GCOFF_READY;
 
 	return gsp->rm->api->gsp->gcx_ready(gsp);

-- 
2.56.0

