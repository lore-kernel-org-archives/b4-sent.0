From: Jim Cromie <jim.cromie@gmail.com>
Date: Fri, 20 Nov 2026 10:18:32 -0700
Subject: [PATCH v2 5/5] drm-dyndbg: drop BROKEN on DRM_USE_DYNAMIC_DEBUG
 for testing (DONT_APPLY)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-rd-mostly-v2-5-88056ede02a8@gmail.com>
References: <20261120-rd-mostly-v2-0-88056ede02a8@gmail.com>
In-Reply-To: <20261120-rd-mostly-v2-0-88056ede02a8@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jason Baron <jbaron@akamai.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795195125; l=818;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=FywBSQVzh/O/x8StOKw+M4F1py0iU1srNXGib4Mzet0=;
 b=4Q8U85N1C78yeLyMj63YwqF5+U6ufImwakmci5dnOIkTR0vcUY/p5hPB0NgOgmTxtzEL7NacS
 D8I+sK++SG0DdBHGG2yIIQ9pyIAuGL+NHhbni9gLByaSDk7SS5SJuyI
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

remove BROKEN from DRM_USE_DYNAMIC_DEBUG, to facilitate testing with
it enabled.

DO_NOT_APPLY - full functionality requires the (forthcoming) classmaps
patchset, and drivers/accel/ uses drm_*dbg, and needs the ccflags
additions like for drm/Makefile

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 drivers/gpu/drm/Kconfig.debug | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/gpu/drm/Kconfig.debug b/drivers/gpu/drm/Kconfig.debug
index b909cd0a619f..b0aa56281413 100644
--- a/drivers/gpu/drm/Kconfig.debug
+++ b/drivers/gpu/drm/Kconfig.debug
@@ -1,7 +1,6 @@
 config DRM_USE_DYNAMIC_DEBUG
 	bool "use dynamic debug to implement drm.debug"
 	default n
-	depends on BROKEN
 	depends on DRM
 	depends on DYNAMIC_DEBUG || DYNAMIC_DEBUG_CORE
 	depends on JUMP_LABEL

-- 
2.56.1

