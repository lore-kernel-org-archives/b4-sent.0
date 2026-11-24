From: Jim Cromie <jim.cromie@gmail.com>
Date: Tue, 24 Nov 2026 16:38:35 -0700
Subject: [PATCH v4 3/3] drm/print: fix drm_printer dynamic debug bit-test
 bypass
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-rd-mostly-v4-3-26d60beb6666@gmail.com>
References: <20261124-rd-mostly-v4-0-26d60beb6666@gmail.com>
In-Reply-To: <20261124-rd-mostly-v4-0-26d60beb6666@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jason Baron <jbaron@akamai.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Luca Coelho <luciano.coelho@intel.com>, Jani Nikula <jani.nikula@intel.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795563513; l=2848;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=y0RWdr4HR8Hk2DeVmjJ5zNw17ifUMWtuwVaP7R47qsw=;
 b=o/UPdYHp3ZSlSA352RCmGdx4bwNiWNRBEtVQZfdCAr+VEeNWDZNiiVVuPpXN/Sg8lqYCYmBXN
 l5Da1oeomWwAxTBPIr2u7bCiiC1yqxmfDqlQtWfq+pOzSgalBs1DPUK
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

drm_debug_enabled() [$1] is the canonical bit-test for drm.debug.
Commit 6ce6fae84536 ("drm_print: optimize drm_debug_enabled for
jump-label") elaborated it into 4 names, controlled by
CONFIG_DRM_USE_DYNAMIC_DEBUG:

A- $1_raw() - rename of the original bit-test.
B- $1_instrumented() - like raw, but adds a pr_debug(), allowing us to
   count callsite frequency and consider optimizing them later.
C- __$1() - evaluates to 'true' when CONFIG_DRM_USE_DYNAMIC_DEBUG=y
   (avoiding the bit-test where callsites are already guarded by a
   dyndbg static-key), and forwards to A when =n.
D- $1() - forwards to B when CONFIG_DRM_USE_DYNAMIC_DEBUG=y, and to A
   when =n, for cases where an explicit bit-mask check is required.

Later, commit 9fd6f61a297e ("drm/print: add drm_dbg_printer() for drm
device specific printer") added a general-use __drm_printfn_dbg()
function, but used __$1() instead of $1(). When
CONFIG_DRM_USE_DYNAMIC_DEBUG=y, __$1() evaluates to 'true' and always
prints.  This went unnoticed because CONFIG_DRM_USE_DYNAMIC_DEBUG was
marked BROKEN.

With =y, this results in a flood of messages, and in CI-tests on slow
serial consoles, creates bottlenecks, as seen in DRM-CI on i915 CML
devices.  When IGT causes a mismatch in intel_pipe_config_compare(),
the resulting UART storm causes a hard timeout after 20 minutes.

NOTES:

Drop the single-use `category` local variable and pass p->category
directly (which previously also triggered an unused-variable warning
under the old __$1() bypass).

Because __drm_printfn_dbg() is a shared helper invoked via p->printfn
with a runtime p->category, the callsite cannot be guarded by a
static-key; we'd need a macro version and callsites where category is
a compile-time constant.

Replacing __$1() with $1() or $1_raw() would also work, but
$1_instrumented() adds the pr_debug() in both =y and =n configs; when
enabled it can provide call-freq data to inform further callsite
optimization choices.

Fixes: 9fd6f61a297e ("drm/print: add drm_dbg_printer() for drm device specific printer")
Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
 drivers/gpu/drm/drm_print.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/drm_print.c b/drivers/gpu/drm/drm_print.c
index 2e7685849f44..3d26483975f2 100644
--- a/drivers/gpu/drm/drm_print.c
+++ b/drivers/gpu/drm/drm_print.c
@@ -218,9 +218,8 @@ void __drm_printfn_dbg(struct drm_printer *p, struct va_format *vaf)
 {
 	const struct drm_device *drm = p->arg;
 	const struct device *dev = drm ? drm->dev : NULL;
-	enum drm_debug_category category = p->category;
 
-	if (!__drm_debug_enabled(category))
+	if (!drm_debug_enabled_instrumented(p->category))
 		return;
 
 	__drm_dev_vprintk(dev, KERN_DEBUG, p->origin, p->prefix, vaf);

-- 
2.56.1

