From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 21 Jan 2023 21:08:00 +0100
Subject: [PATCH 22/86] drm/armada: Direct include headers from
 drm_atomic_helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230113-drm-include-v1-v1-22-c5cf72d8a5a2@ravnborg.org>
References: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
In-Reply-To: <20230113-drm-include-v1-v1-0-c5cf72d8a5a2@ravnborg.org>
To: dri-devel@lists.freedesktop.org
Cc: Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1674331666; l=1920;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=F/PFqK5fzfBIr84dBElMn3Pjk8hbGzis9NnpfDnPC3A=;
 b=NZn3W8X25L4U9EEpjAPA+w2jBmfsuq4fLYoeRGIQ2Wx8eHsHyekpj3OWiJ/NCenpL8+8RNW9xnYx
 7ta4cUfCBvPznlZFUnxBbq7Q7sAwKSJqD9qMJ0OMHpUhV9piognA
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Submission Endpoint for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Direct include the headers that otherwise comes indirect from
drm_atomic_helper, because drm_atomic_helper will be reduced to
include only the minimal set of headers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
---
 drivers/gpu/drm/armada/armada_crtc.c    | 2 ++
 drivers/gpu/drm/armada/armada_overlay.c | 2 ++
 drivers/gpu/drm/armada/armada_plane.c   | 2 ++
 3 files changed, 6 insertions(+)

diff --git a/drivers/gpu/drm/armada/armada_crtc.c b/drivers/gpu/drm/armada/armada_crtc.c
index 15dd667aa2e7..a2a6a94339de 100644
--- a/drivers/gpu/drm/armada/armada_crtc.c
+++ b/drivers/gpu/drm/armada/armada_crtc.c
@@ -12,6 +12,8 @@
 
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_probe_helper.h>
 #include <drm/drm_vblank.h>
 
diff --git a/drivers/gpu/drm/armada/armada_overlay.c b/drivers/gpu/drm/armada/armada_overlay.c
index f21eb8fb76d8..f273570eb92e 100644
--- a/drivers/gpu/drm/armada/armada_overlay.c
+++ b/drivers/gpu/drm/armada/armada_overlay.c
@@ -8,7 +8,9 @@
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
 #include <drm/drm_atomic_uapi.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_fourcc.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_plane_helper.h>
 
 #include "armada_crtc.h"
diff --git a/drivers/gpu/drm/armada/armada_plane.c b/drivers/gpu/drm/armada/armada_plane.c
index cc47c032dbc1..1f8810f969ec 100644
--- a/drivers/gpu/drm/armada/armada_plane.c
+++ b/drivers/gpu/drm/armada/armada_plane.c
@@ -6,7 +6,9 @@
 
 #include <drm/drm_atomic.h>
 #include <drm/drm_atomic_helper.h>
+#include <drm/drm_atomic_state_helper.h>
 #include <drm/drm_fourcc.h>
+#include <drm/drm_modeset_helper_vtables.h>
 #include <drm/drm_plane_helper.h>
 
 #include "armada_crtc.h"

-- 
2.34.1

