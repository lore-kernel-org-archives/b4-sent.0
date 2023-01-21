From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:07:56 +0100
Subject: [PATCH 18/86] drm/amd: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-18-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=3544;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=b1ouRY5I3fdWx+hNJSbwrqgLHcgX7tBe99hA9VR0ek0=;
 b=EKq5wu+y4rZZHCPbHJyGIAxg8GMLZ9jxAa9jMEmHNkOfGJXDVE4/VSJ5cVQcEhHMAA3lvLBO45VE
 knEwvy9wBPne5Oh4gWchcXcXLAhfb+KnTggbrN+e6TRnWDI6nYyk
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/amd/amdgpu/amdgpu_vkms.c                    | 3 +++
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c           | 2 ++
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c      | 2 ++
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c | 2 ++
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c     | 2 ++
 5 files changed, 11 insertions(+)

diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_vkms.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_vkms.c
index 53ff91fc6cf6..f617b8ddee9e 100644
--- a/drivers/gpu/drm/amd/amdgpu/amdgpu_vkms.c
+++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_vkms.c
@@ -1,6 +1,9 @@
 // SPDX-License-Identifier: GPL-2.0+
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
+#include <drm/drm_modeset_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_simple_kms_helper.h>
 #include <drm/drm_vblank.h>
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
index 2db449fed300..d95ec18ee71d 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c
@@ -82,9 +82,11 @@
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_uapi.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_blend.h>
 #include <drm/drm_fourcc.h>
 #include <drm/drm_edid.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_vblank.h>
 #include <drm/drm_audio_component.h>
 #include <drm/drm_gem_atomic_helper.h>
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
index 22125daf9dcf..c53652f594e1 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c
@@ -25,6 +25,8 @@
  */
 #include <drm/drm_vblank.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 
 #include "dc.h"
 #include "amdgpu.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
index 41f35d75d0a8..540b0fa923e3 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_mst_types.c
@@ -27,6 +27,8 @@
 #include <drm/display/drm_dp_mst_helper.h>
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include "dm_services.h"
 #include "amdgpu.h"
 #include "amdgpu_dm.h"
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c
index 3c50b3ff7954..8638f95af243 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c
@@ -25,8 +25,10 @@
  */
 
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_blend.h>
 #include <drm/drm_gem_atomic_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_plane_helper.h>
 #include <drm/drm_fourcc.h>
 

-- 
2.34.1

