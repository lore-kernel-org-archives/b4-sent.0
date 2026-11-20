From: Jim Cromie <jim.cromie@gmail.com>
Date: Fri, 20 Nov 2026 10:18:30 -0700
Subject: [PATCH v2 3/5] drm: fix config dependent unused variable warning.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-rd-mostly-v2-3-88056ede02a8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795195125; l=1090;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=FWl5eybJevr+52Kq5KRfTj77HDYm3mQVIttIFHf1YBM=;
 b=NOIutQD7kqK1VDi5lWhr/3MbHVkNy3BWiKygm/5FUyz8vqm+NhKzWvQHtDpOo/JTpswB2rCf6
 ArCsKbgc6SBB7oIAgpHM1xZDuD/c6LoxyRdqST7f4JZguv4n1e4CRNW
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__drm_printfn_dbg() does:
      enum drm_debug_category category = p->category;
then:
      if (!__drm_debug_enabled(category))

When CONFIG_DRM_USE_DYNAMIC_DEBUG=y, __drm_debug_enabled(category)
expands to `true` without referencing `category`, causing an
unused-variable warning/error. Silence it by passing p->category
directly.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 drivers/gpu/drm/drm_print.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/drm_print.c b/drivers/gpu/drm/drm_print.c
index 50cdeb1b15e2..12b95901eb70 100644
--- a/drivers/gpu/drm/drm_print.c
+++ b/drivers/gpu/drm/drm_print.c
@@ -218,9 +218,8 @@ void __drm_printfn_dbg(struct drm_printer *p, struct va_format *vaf)
 {
 	const struct drm_device *drm = p->arg;
 	const struct device *dev = drm ? drm->dev : NULL;
-	enum drm_debug_category category = p->category;
 
-	if (!__drm_debug_enabled(category))
+	if (!__drm_debug_enabled(p->category))
 		return;
 
 	__drm_dev_vprintk(dev, KERN_DEBUG, p->origin, p->prefix, vaf);

-- 
2.56.1

