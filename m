From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 21 Nov 2026 14:22:55 -0700
Subject: [PATCH v3 2/6] drm: Fix incorrect CFLAGS-y spelling inside
 Makefile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-rd-mostly-v3-2-89e74b23b491@gmail.com>
References: <20261121-rd-mostly-v3-0-89e74b23b491@gmail.com>
In-Reply-To: <20261121-rd-mostly-v3-0-89e74b23b491@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jason Baron <jbaron@akamai.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795296180; l=1669;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=PNDrfsA84PuTN7eG4zqahY8+OYZihSCYKHCt1mJS2go=;
 b=Q6kceBssgoFt7rOTiEK1VGH0yxbBzkdT5eBxc86olKaz7paVZQWDuXjWaVpVLbEseC9xpc0Tk
 VqMMcCF4r5SBfRvBGFgkAqhtu9XVs9FyZ1VYoWMpKye1Q8lr7TOxUMQ
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DRM Makefile spelled CFLAGS-$(CONFIG_DRM_USE_DYNAMIC_DEBUG)
incorrectly, which kbuild ignores.  So -D<flag> was omitted, breaking
DRM dynamic debug callsites when CONFIG_DYNAMIC_DEBUG_CORE=y without
CONFIG_DYNAMIC_DEBUG.

Replace "CFLAGS-" with "subdir-ccflags-", so that -D<flag> is added to
drm-core and to drivers and helpers in the subdirectories.  "ccflags-y"
only applies to the current directory.

NOTE: When CONFIG_DYNAMIC_DEBUG=y, -DDYNAMIC_DEBUG_MODULE is redundant
because defined(CONFIG_DYNAMIC_DEBUG) already enables callsites.
Passing it unconditionally under CONFIG_DRM_USE_DYNAMIC_DEBUG avoids
extra Makefile conditionals and keeps the preprocessor environment
consistent across DYNAMIC_DEBUG=y and DYNAMIC_DEBUG_CORE=y builds.

Fixes: 84ec67288c10 ("drm_print: wrap drm_*_dbg in dyndbg descriptor factory macro")
Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 drivers/gpu/drm/Makefile | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/Makefile b/drivers/gpu/drm/Makefile
index 2c6bc093a923..4a93c09f08d9 100644
--- a/drivers/gpu/drm/Makefile
+++ b/drivers/gpu/drm/Makefile
@@ -3,7 +3,8 @@
 # Makefile for the drm device driver.  This driver provides support for the
 # Direct Rendering Infrastructure (DRI) in XFree86 4.1.0 and higher.
 
-CFLAGS-$(CONFIG_DRM_USE_DYNAMIC_DEBUG)	+= -DDYNAMIC_DEBUG_MODULE
+ccflags-$(CONFIG_DRM_USE_DYNAMIC_DEBUG)		+= -DDYNAMIC_DEBUG_MODULE
+subdir-ccflags-$(CONFIG_DRM_USE_DYNAMIC_DEBUG)	+= -DDYNAMIC_DEBUG_MODULE
 
 # Unconditionally enable W=1 warnings locally
 # --- begin copy-paste W=1 warnings from scripts/Makefile.warn

-- 
2.56.1

