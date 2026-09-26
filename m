From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 26 Sep 2026 16:33:33 -0600
Subject: [PATCH 2/2] drm: Fix incorrect ccflags-y spelling inside Makefile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-rd-mostly-v1-2-28b7d714ed2c@gmail.com>
References: <20260926-rd-mostly-v1-0-28b7d714ed2c@gmail.com>
In-Reply-To: <20260926-rd-mostly-v1-0-28b7d714ed2c@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790462033; l=1146;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=k/p3/mF4PjoGAd1p0WbIzbzTATt0GlWd9hAVgx/C8sg=;
 b=bsI2eblwopjRAJO9Q6o7zYYZ/Kl0joBNGfqKkrxAZc//Sxa+h9iENDsnV5jfIDaqARyTd1QOv
 U97OkhBUfhbA0PXGax8ZzT7KTdN6cBxedw9fm2RbrswYs2s/1ZVNYAa
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a longstanding spelling error in the DRM Makefile by changing
'CFLAGS-y' to 'ccflags-y'. This fixes CONFIG_DRM_USE_DYNAMIC_DEBUG=y
dependent addition of -DDYNAMIC_DEBUG_MODULE, which is needed to
enable dyndbg-under-drm-debug when only CONFIG_DYNAMIC_DEBUG_CORE is
enabled (and not CONFIG_DYNAMIC_DEBUG itself).

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 drivers/gpu/drm/Makefile | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/Makefile b/drivers/gpu/drm/Makefile
index e635fcffd379..c42884d84ad1 100644
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
2.55.0

