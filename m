From: Jim Cromie <jim.cromie@gmail.com>
Date: Sat, 21 Nov 2026 14:22:56 -0700
Subject: [PATCH v3 3/6] fixup-makefile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-rd-mostly-v3-3-89e74b23b491@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795296180; l=715;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=UbYmJUbYozcybXjWWNTdliSZ+bJNJebHuGNQgVyBKs8=;
 b=W9b1h0CFK/+FvKXIc86Uv20na8l571YFEIY8hv/KYVeF/KJ6yWBD1+YHHC2aZHSmKfszziBsk
 H2r9xLeXHWsACnP7X4V6/Fp0asDBnR81nl5hPm2XvVOlbAQDWYlFoXu
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 drivers/gpu/drm/Makefile | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/Makefile b/drivers/gpu/drm/Makefile
index 4a93c09f08d9..2c0839b6d648 100644
--- a/drivers/gpu/drm/Makefile
+++ b/drivers/gpu/drm/Makefile
@@ -3,7 +3,7 @@
 # Makefile for the drm device driver.  This driver provides support for the
 # Direct Rendering Infrastructure (DRI) in XFree86 4.1.0 and higher.
 
-ccflags-$(CONFIG_DRM_USE_DYNAMIC_DEBUG)		+= -DDYNAMIC_DEBUG_MODULE
+# enable dyndbg for CONFIG_DYNAMIC_DEBUG_CORE (ie mechanism) w/o builtins
 subdir-ccflags-$(CONFIG_DRM_USE_DYNAMIC_DEBUG)	+= -DDYNAMIC_DEBUG_MODULE
 
 # Unconditionally enable W=1 warnings locally

-- 
2.56.1

