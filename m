From: Jim Cromie <jim.cromie@gmail.com>
Date: Fri, 09 Oct 2026 11:44:24 -0600
Subject: [PATCH v2 1/3] nouveau: Fix NULL pointer dereferences in GETPARAM
 ioctl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-my-fixups-v2-1-839e2bbe514d@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791567877; l=2685;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=Hif+OXQYKGWad7cgItXjfW/GXatKjgqK4mxSXyvdrUE=;
 b=9cdX7+DUx135DFDJCetWzH9k6vfQQujrkuxa/oz4qwmA06OyhC7CiX9BCv1kVkG8JLTwPwxNC
 YIYLlsJo9aPDJRTkKENISrnqqpG3lA8kUAlCWBZWX1oBgm/i+89bEvM
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When hardware or firmware initialization fails, the graphics engine
(gr) or device functions may remain NULL. Attempting to access these
during the GETPARAM ioctl (e.g., NOUVEAU_GETPARAM_GRAPH_UNITS) results
in a kernel NULL pointer dereference, causing a crash when userspace
(GNOME/Mesa) attempts to probe the device.

Add safety checks for 'gr', 'gr->func', and 'nvkm_device->func' in the
ioctl handler. Return -ENODEV to signal the missing hardware state to
userspace, and use NV_ERROR_ONCE to provide diagnostic proof in the
kernel log without risking a console flood.

NOTE:

I encountered these crashes while booting unrelated code (in
dynamic-debug) on real HW.  There was also some fwupd updates around
this time, so it could all be transient/unreproducible.  But it did
happen, and could happen again in unforseen circumstances.

@Capitain_Jack tested the error path in v1 by deleting the FW

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
Tested-by: Daniel Campos Ramos <Capitain_Jack@yahoo.com>
---
 drivers/gpu/drm/nouveau/nouveau_abi16.c | 22 ++++++++++++++++++++--
 1 file changed, 20 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/nouveau_abi16.c b/drivers/gpu/drm/nouveau/nouveau_abi16.c
index 4542d5f4ded8..3f130cd4fbcd 100644
--- a/drivers/gpu/drm/nouveau/nouveau_abi16.c
+++ b/drivers/gpu/drm/nouveau/nouveau_abi16.c
@@ -306,6 +306,11 @@ nouveau_abi16_ioctl_getparam(ABI16_IOCTL_ARGS)
 		getparam->value = 1;
 		break;
 	case NOUVEAU_GETPARAM_GRAPH_UNITS:
+		if (!gr || !gr->func) {
+			NV_ERROR_ONCE(drm, "GETPARAM_GRAPH_UNITS: no gr engine or func\n");
+			return -ENODEV;
+		}
+
 		getparam->value = nvkm_gr_units(gr);
 		break;
 	case NOUVEAU_GETPARAM_EXEC_PUSH_MAX: {
@@ -315,10 +320,23 @@ nouveau_abi16_ioctl_getparam(ABI16_IOCTL_ARGS)
 		break;
 	}
 	case NOUVEAU_GETPARAM_VRAM_BAR_SIZE:
-		getparam->value = nvkm_device->func->resource_size(nvkm_device, NVKM_BAR1_FB);
+		if (!nvkm_device || !nvkm_device->func || !nvkm_device->func->resource_size) {
+			NV_ERROR_ONCE(drm, "GETPARAM_VRAM_BAR_SIZE: no device func\n");
+			return -ENODEV;
+		}
+
+		getparam->value =
+			nvkm_device->func->resource_size(nvkm_device, NVKM_BAR1_FB);
 		break;
 	case NOUVEAU_GETPARAM_VRAM_USED: {
-		struct ttm_resource_manager *vram_mgr = ttm_manager_type(&drm->ttm.bdev, TTM_PL_VRAM);
+		struct ttm_resource_manager *vram_mgr =
+			ttm_manager_type(&drm->ttm.bdev, TTM_PL_VRAM);
+
+		if (!vram_mgr) {
+			NV_ERROR_ONCE(drm, "GETPARAM_VRAM_USED: no vram mgr\n");
+			return -ENODEV;
+		}
+
 		getparam->value = (u64)ttm_resource_manager_usage(vram_mgr);
 		break;
 	}

-- 
2.56.0

