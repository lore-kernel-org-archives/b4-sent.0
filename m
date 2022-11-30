From: Noralf Trønnes <noralf@tronnes.org>
Date: Wed, 30 Nov 2022 20:26:54 +0100
Subject: [PATCH v2 6/6] drm/gud: Enable synchronous flushing by default
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20221122-gud-shadow-plane-v2-6-435037990a83@tronnes.org>
References: <20221122-gud-shadow-plane-v2-0-435037990a83@tronnes.org>
In-Reply-To: <20221122-gud-shadow-plane-v2-0-435037990a83@tronnes.org>
To: Thomas Zimmermann <tzimmermann@suse.de>, Javier Martinez Canillas <javierm@redhat.com>,
 dri-devel@lists.freedesktop.org, Maxime Ripard <mripard@kernel.org>, stable@vger.kernel.org,
 Noralf Trønnes <noralf@tronnes.org>
X-Mailer: b4 0.11.0-dev-cc6f6
X-Developer-Signature: v=1; a=ed25519-sha256; t=1669836415; l=2023;
 i=noralf@tronnes.org; s=20221122; h=from:subject:message-id;
 bh=h2o+XqMBQHUWEJfpLcc+HZU/hC6MAxxmg8TWrtkZl5c=;
 b=PVR2ctkGVWUaqtpGxbUgZ6431+rt3RQPRUMnZWnZ7iu59dZF437cyLiFf+lDYBYV9Ety0wLM71xE
 NwFjFV4RAr/uKnDq6ZbyeWe5J2FCEiZAER7z/jH+5e/qUwVYAyjZ
X-Developer-Key: i=noralf@tronnes.org; a=ed25519;
 pk=0o9is4iddvvlrY3yON5SVtAbgPnVs0LfQsjfqR2Hvz8=
X-Endpoint-Received: by B4 Submission Endpoint for noralf@tronnes.org/20221122 with auth_id=8
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

gud has a module parameter that controls whether framebuffer flushing
happens synchronously during the commit or asynchronously in a worker.

GNOME before version 3.38 handled all displays in the same rendering loop.
This lead to gud slowing down the refresh rate for a faster monitor. This
has now been fixed so lets change the default.

The plan is to remove async flushing in the future. The code is now
structured in a way that makes it easy to do this.

Link: https://blogs.gnome.org/shell-dev/2020/07/02/splitting-up-the-frame-clock/
Suggested-by: Thomas Zimmermann <tzimmermann@suse.de>
Signed-off-by: Noralf Trønnes <noralf@tronnes.org>
---
 drivers/gpu/drm/gud/gud_pipe.c | 12 ++++--------
 1 file changed, 4 insertions(+), 8 deletions(-)

diff --git a/drivers/gpu/drm/gud/gud_pipe.c b/drivers/gpu/drm/gud/gud_pipe.c
index 92189474a7ed..62c43d3632d4 100644
--- a/drivers/gpu/drm/gud/gud_pipe.c
+++ b/drivers/gpu/drm/gud/gud_pipe.c
@@ -25,17 +25,13 @@
 #include "gud_internal.h"
 
 /*
- * Some userspace rendering loops runs all displays in the same loop.
+ * Some userspace rendering loops run all displays in the same loop.
  * This means that a fast display will have to wait for a slow one.
- * For this reason gud does flushing asynchronous by default.
- * The down side is that in e.g. a single display setup userspace thinks
- * the display is insanely fast since the driver reports back immediately
- * that the flush/pageflip is done. This wastes CPU and power.
- * Such users might want to set this module parameter to false.
+ * Such users might want to enable this module parameter.
  */
-static bool gud_async_flush = true;
+static bool gud_async_flush;
 module_param_named(async_flush, gud_async_flush, bool, 0644);
-MODULE_PARM_DESC(async_flush, "Enable asynchronous flushing [default=true]");
+MODULE_PARM_DESC(async_flush, "Enable asynchronous flushing [default=0]");
 
 /*
  * FIXME: The driver is probably broken on Big Endian machines.

-- 
2.34.1
