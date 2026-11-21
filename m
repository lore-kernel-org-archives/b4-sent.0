From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH v3 0/6] drm/print,dyndbg: __drm_debug __read_mostly, uint
 shrink, build fixes
Date: Sat, 21 Nov 2026 14:22:53 -0700
Message-Id: <20261121-rd-mostly-v3-0-89e74b23b491@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/03MQQqDMBBA0auEWTslmdZoXfUepYs0GTWgTUkkV
 MS7F4UWtx/+WyBx9JygEQtEzj758IJGnAsBtjevjtE7aASQJC2vVGJ0OIY0DTNqQ62V1unWaSg
 EvCO3/rNb90choPdpCnHe6ay2+lP0QckKJVL9rFylLuzI3rrR+OFkwwibkul/KkXyeBJKrGtZa
 nYsydTHc13XLwnwPercAAAA
X-Change-ID: 20260925-rd-mostly-6a2fc0cd6fd6
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jason Baron <jbaron@akamai.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795296180; l=3008;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=Zau8dBhEANl7tYMwKgNve822IH1DfMTFcsXZxbLchlw=;
 b=+5W/OGApBUn9TFxMzwW4M3u5InVhsVQ/obNCS6z+Qr1EgJELGNrrlfdhyhiRCjYpbMyWnod0y
 l/s988xi8iMBQjKmnJzA4ROSuqromCFp4nPJpw3woRYXjvSIhxb6Nlh
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series improves __drm_debug placement/sizing and fixes two build
issues exposed when CONFIG_DRM_USE_DYNAMIC_DEBUG=y is enabled:        

1. Mark __drm_debug as __read_mostly to move it out of the cacheline
it currently shares with frequently written locks and structures.  In
a 12-vkcube test, its read rate is ~83 kHz.
    
2. Fix spelling error in drivers/gpu/drm/Makefile, ie change "CFLAGS-"
to "subdir-ccflags-".

This adds -DDYNAMIC_DEBUG_MODULE to compilations in both drm and its
subdirs, as needed with CONFIG_DYNAMIC_DEBUG_CORE=y but without
CONFIG_DYNAMIC_DEBUG=y.

3. Drop the unused `category` local in __drm_printfn_dbg() when
CONFIG_DRM_USE_DYNAMIC_DEBUG=y expands __drm_debug_enabled() to true.

4. Shrink __drm_debug and struct ddebug_class_param.bits from unsigned
long back to (original) unsigned int, updating lib/dynamic_debug.c and        
lib/test_dynamic_debug.c callers accordingly.               

NOTES:

drm and dyndbg are coupled on __drm_debug's size and type, so changing
the size requires coordination between DRM and dyndbg.  The coupling
allows dyndbg to still use the var to keep 'state', and allows drm to
continue using it in the few cases where drm_*dbg doesnt quite fit.

Because DRM_USE_DYNAMIC_DEBUG still depends on BROKEN, patches 2-4
were build-tested with that dependency locally removed. That un-BROKEN
patch is intentionally excluded here, as modular DRM probe-time
drm.debug support (and external users like drivers/accel/) still
need the separate/pending classmap fixup series.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
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
Jim Cromie (6):
      drm/print: Mark __drm_debug as __read_mostly
      drm: Fix incorrect CFLAGS-y spelling inside Makefile
      fixup-makefile
      drm: fix config dependent unused variable warning.
      drm/print,dyndbg: restore __drm_debug to uint from ulong
      drm-dyndbg: drop BROKEN on DRM_USE_DYNAMIC_DEBUG for testing (DONT_APPLY)

 drivers/gpu/drm/Kconfig.debug | 1 -
 drivers/gpu/drm/Makefile      | 3 ++-
 drivers/gpu/drm/drm_print.c   | 7 +++----
 include/drm/drm_print.h       | 2 +-
 include/linux/dynamic_debug.h | 2 +-
 lib/dynamic_debug.c           | 8 +++++---
 lib/test_dynamic_debug.c      | 2 +-
 7 files changed, 13 insertions(+), 12 deletions(-)
---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20260925-rd-mostly-6a2fc0cd6fd6

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

