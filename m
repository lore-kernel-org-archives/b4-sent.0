From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH v4 0/3] drm/print,dyndbg: __drm_debug __read_mostly,
 restore it to uint, printer fix
Date: Tue, 24 Nov 2026 16:38:32 -0700
Message-Id: <20261124-rd-mostly-v4-0-26d60beb6666@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/13MTQqDMBBA4auEWZuSjBp/Vr1H6UKTUQNqSiJSE
 e9eFFpCtw++t0MgbylAzXbwtNpg3Qw1yxIGemjmnrg1UDNAgUpUmHNv+OTCMm5cNdhpoY3qjIK
 EwctTZ9/X6/FMGAw2LM5v13qVZ/1eVHRZJRccy7YwhczIoL73U2PHm3YTnJcVf1JKFLFELnhZi
 lyRIYFN+S/TWMpYpqesqMhaTNuskrE8juMDuxeYdBYBAAA=
X-Change-ID: 20260925-rd-mostly-6a2fc0cd6fd6
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795563513; l=2697;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=4UCbxxrKinpPTMCGiCL0XLcwvtLOOSiukBA+RJshUyc=;
 b=DxACAMOt+FgpZsUaHjYbUUKrmcIuwfXHdGJ8q/3WSUID/afBNTT5Gs5s45BY7C8VVCtGf9Z/B
 xLZXUirlnvbBXeu+MbnM3a6A/Ycqz7qZd8h76Fn4SVrzjJMtrq8Y598
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series improves __drm_debug placement/sizing and fixes a
drm_dbg_printer() bypass exposed when CONFIG_DRM_USE_DYNAMIC_DEBUG=y:

1. Mark __drm_debug as __read_mostly to move it out of the cacheline
   it currently shares with frequently written locks and structures. In
   a 12-vkcube test, its read rate is ~83 kHz.

2. Shrink __drm_debug and struct ddebug_class_param.bits from unsigned
   long back to (original) unsigned int, updating lib/dynamic_debug.c
   and lib/test_dynamic_debug.c callers accordingly.

3. Fix __drm_printfn_dbg() use of __drm_debug_enabled(), which always
   prints when CONFIG_DRM_USE_DYNAMIC_DEBUG=y, disregarding p->category.

NOTES:

drm and dyndbg are coupled on __drm_debug's size and type, so changing
the size requires coordination between DRM and dyndbg. The coupling
allows dyndbg to keep state in __drm_debug while letting drm use it in
cases where static-key drm_*dbg() macros do not fit.

Build-tested with BROKEN locally removed from DRM_USE_DYNAMIC_DEBUG to
cover both Y/N cases. That un-BROKEN patch is intentionally excluded
here as drm.debug still needs classmap fixes patchset.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Changes in v4:
- Replace unused-variable workaround with proper __drm_printfn_dbg()
  fix (per Sashiko review).
- Drop drivers/gpu/drm/Makefile and DONT_APPLY un-BROKEN patches from
  this series (deferred to classmap-inheritance series).
- Link to v3: https://lore.kernel.org/r/20261121-rd-mostly-v3-0-89e74b23b491@gmail.com

Changes in v3:
- dont need both ccflags-y and subdir-ccflags-y, latter covers former.
- Link to v2: https://lore.kernel.org/r/20261120-rd-mostly-v2-0-88056ede02a8@gmail.com

Changes in v2:
- Add subdir-ccflags- propagation in drivers/gpu/drm/Makefile (patch 2).
- Add unused `category` warning fix under CONFIG_DRM_USE_DYNAMIC_DEBUG=y
  (patch 3).
- Add __drm_debug and ddebug_class_param.bits shrink to unsigned int
  (patch 4).
- Link to v1: https://lore.kernel.org/r/20260926-rd-mostly-v1-0-28b7d714ed2c@gmail.com

---
Jim Cromie (3):
      drm/print: Mark __drm_debug as __read_mostly
      drm/print,dyndbg: restore __drm_debug to uint from ulong
      drm/print: fix drm_printer dynamic debug bit-test bypass

 drivers/gpu/drm/drm_print.c   | 7 +++----
 include/drm/drm_print.h       | 2 +-
 include/linux/dynamic_debug.h | 2 +-
 lib/dynamic_debug.c           | 8 +++++---
 lib/test_dynamic_debug.c      | 2 +-
 5 files changed, 11 insertions(+), 10 deletions(-)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20260925-rd-mostly-6a2fc0cd6fd6

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

