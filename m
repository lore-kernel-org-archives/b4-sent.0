From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH v10 00/38] dyndbg: Fix classmaps API for subsystems, query
 extensions, selftests
Date: Wed, 16 Sep 2026 09:32:52 -0600
Message-Id: <20260916-dd-cmap-part2-clean-v10-0-af4cf4767707@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23NzQqDMBAE4FeRnLsliWlqeup7lB6WZKMB/4gSW
 sR3bxQKHjzOwHyzsIlioIk9ioVFSmEKQ5+D4JeC2Qb7miC4XDDJpeaGC3AObIcjjBhnCbYl7KH
 UhqwwihR6lpdjJB8+O/t659yEaR7id39J1db+vduplyrggMparu/Ka++edYehvdqhY5uXzNGoz
 g2TjRJLr6XwCgU/Guu6/gC0Idm8+wAAAA==
X-Change-ID: 20260901-dd-cmap-part2-clean-369ec194e4af
To: Jason Baron <jbaron@akamai.com>, Shuah Khan <shuah@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Arnd Bergmann <arnd@arndb.de>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Jonathan Corbet <corbet@net.net>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Len Brown <lenb@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, linux-pm@vger.kernel.org, 
 Jim Cromie <jim.cromie@gmail.com>, 
 Louis Chauvet <louis.chauvet@bootlin.com>, Philipp Hahn <phahn-oss@avm.de>, 
 kernel test robot <lkp@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789572777; l=15402;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=Ef9Ou5FFxyRBGmnrX7vBr+/DzEG7B/a7eQZ3i9ojBoM=;
 b=KdVzu21dVZZNsPZuLOUfdU9QlcAucSpkHMLykb66C9OT/Ek4ao2Z/HmH8Z4R5V/2jJMwfhdS3
 nXlcNqTtijwBM/sgdqvgd3BW6OvAt/m7hi1s7gy3TxFOb0UwE8dDWlV
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The drm subsystem has *lots* of debug statements, in 11 categories:

 $> ack '\w*_dbg' drivers/gpu/drm/ | wc
    5532   29318  553806
 $> ack 'DRM_DEBUG\w*' drivers/gpu/drm/ | wc
    2208   12856  212035

All of these are bit-tests on __drm_debug, exposed to users as
/sys/module/drm/parameters/debug. Many of these are done often;
vblank is done ~100/sec for some displays. Over the uptime of many
boxes, this is a lot of cpu cycles on bits that are almost always off.

Dynamic-debug excels at replacing such tests with NOOPs (via static
keys). Classmaps was devised to bring that 0-off-cost to drm's
categories.

Classmaps-v1 went into the kernel in Sept 2022, in 2 chunks:
  b7b4eebdba7b..6ea3bf466ac6    # core dyndbg changes
  0406faf25fb1..ee7d633f2dfb    # drm adoption

Sadly DRM-CI found a regression during init with drm.debug=<initval>;
the static-keys underneath the drm-dbgs in drm.ko got enabled, but
those in drivers & helpers did not.

So in Feb 2023, it got pulled:
commit bb2ff6c27bc9 ("drm: Disable dynamic debug as broken")

Root Problem:

DECLARE_DYNDBG_CLASSMAP defined the classmap, but its repeated use in
both core and drivers violated a K&R rule "define once, refer
afterwards". This flaw resulted in a regression; with drm.debug=0xFF
boot arg, drm-core got enabled, but drivers/helpers did not.

This patchset replaces DECLARE_DYNDBG_CLASSMAP with:
- DYNAMIC_DEBUG_CLASSMAP_DEFINE (invoked once in the exporting module)
- DYNAMIC_DEBUG_CLASSMAP_USE (invoked repeatedly in drivers & helpers)

_DEFINE exports the classmap it creates (in drm.ko), and other modules
_USE the classmap. The _USE adds a record referencing the _DEFINEd (&
exported) classmap in a 2nd __dyndbg_class_users section.

At modprobe, dyndbg scans the new section after __dyndbg_class_maps,
follows the linkage to the _DEFINEr module, finds the (optional)
kernel-param controlling the classmap, examines its drm.debug=<initval>,
and applies it to the module being initialized.

To recapitulate the multi-module problem wo DRM involvement, we add:

- tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh:
  Alters pr_debugs in builtins and test modules,
  checks results against checksums of expected results

- lib/test_dynamic_debug.c & test_dynamic_debug_submod.c:
  Builds parent & _submod modules with _DEFINE and _USE inside #if/#else
  blocks, reproducing the 2-module scenario under selftests.

Series Breakdown (38 Patches):

0. Subsystem separation: Drop DRM opt-in patches to route separately via
   dri-devel / drm-misc, keeping core dyndbg infrastructure focused for
   -mm.

1. Selftest up front: Introduce dyndbg_selftest.sh early (commit 2) to
   verify syntax and query baseline; subsequent testpoints are phased in
   alongside the exact features they test. Strict mode (K=0) validates
   exact golden output, while "I know" mode (K=1) tracks drift.

2. Linker script 32-bit fixes & cleanup: Refactor BOUNDED_SECTION* into
   include/asm-generic/bounded_sections.lds.h. Add dyndbg sections to
   scripts/module.lds.S to prevent lost sections in loadable modules.
   Fix 8-byte alignment omission causing i386 NULL pointer derefs.

3. Built-in module naming hook: Introduce DDEBUG_MODNAME in
   include/linux/dynamic_debug.h, defaulting cleanly to KBUILD_MODNAME.
   Bind callsites and classmaps through this hook without altering
   dynamic_debug/control output or userspace ABI.

4. Validation hardening & API: Add compile-time validation for classmap
   parameters and offset bounds (__DYNAMIC_DEBUG_CLASSMAP_CHECK). Harden
   modprobe error detection for unknown classes and class ID reservation
   conflicts. Promote DYNAMIC_DEBUG_CLASSMAP_PARAM to API. Reduce class
   parameter storage to u32.

5. Parser & grammar extensions: Treat comma as a token separator. Add
   multi-query splitting via '@'. Bump max tokens per command from 9 to
   15. Drop class "protection" special-casing per maintainer feedback.

What's Unchanged:
0. /proc/dynamic_debug/control format and output: Module names remain
   strictly identical to KBUILD_MODNAME; no userspace breakage.
1. struct _ddebug footprint: Callsites maintain zero pointer overhead;
   no per-callsite module pointers or classmap references are added.
2. Query grammar backwards compatibility: Existing queries using
   module, file, format, line, and flags continue to operate unchanged.

Testing:
- Tested locally using virtme-ng on x86_64 across ~10 configs.
- dyndbg_selftest.sh passes all checksum tests through the series.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Changes in v10:
- Builtin module naming across revisions:
  Recognized that v8, v9 were misadventures: both altered modname in
  dynamic_debug/control to avoid a hypothetical collision that was not
  going to happen (and could be addressed if it ever did). While
  improved built-in module names (non-fragmented names amongst them)
  might have merit someday, that is not for now; existing ambiguity is
  better than new novel bugs.
  . v8 used KBUILD_MODFILE to disambiguate built-ins sharing
    KBUILD_MODNAME="main" (init/main.c, drivers/.../main.c).
  . sashiko review noted the hyphen/underscore mismatch problem across
    module names.
  . v9 tried further changes to "main" via KBUILD_DD_MODNAME in
    scripts/Makefile.lib to synthesize subsystem prefixes (e.g. [init],
    [power]), mutating column 2 in dynamic_debug/control.
  . Dropped KBUILD_DD_MODNAME from scripts/Makefile.lib and dropped
    hyphen-underscore matching (match_wildcard_hyphen).
  . Introduced DDEBUG_MODNAME defaulting cleanly to KBUILD_MODNAME as
    a lightweight hook preserving dynamic_debug/control invariants.
- Reorganize dyndbg_selftest.sh so tests are phased in alongside the
  features they verify rather than defined in advance.
- Address review findings from sashiko-9 across core dyndbg:
  . Elevate NULL dp->format check to top of ddebug_match_desc() to guard
    format-less queries.
  . Add const qualifier to struct ddebug_class_user.mod_name.
  . Pass init_bits computed from _DPRINTK_CLASSBITS_INIT in
    ddebug_sync_classbits() to properly disable -DDEBUG callsites.
  . Define _DPRINTK_CLASSBITS_INIT, initialize static bitvectors, and
    add module_param_named fallback for DYNAMIC_DEBUG_CLASSMAP_PARAM*
    under !CONFIG_DYNAMIC_DEBUG.
  . Add "V8" and Vu8 to classmaps and do_levels().
  . Replace strpbrk() with quote-aware ddebug_find_delimiter() to ignore
    '@' inside quotes.
  . Drop dead #if 0 ddebug_apply_class_maps() block.
  . Fix pr_warn_ratelimited() line wrap in ddebug_match_desc().
  . Pass raw fmt to DEFINE_DYNAMIC_DEBUG_METADATA in
    pr_debug_ratelimited() to avoid mangled control file strings.
  . Fix ddebug_proc_start() epilogue token boundary check (n <= 1).
  . Handle "reset_stats" inside ddebug_exec_queries() to preserve
    batched multi-queries.
  . Add __DYNAMIC_DEBUG_BRANCH() checking _ENABLED while
    DYNAMIC_DEBUG_BRANCH() checks _ACTIVE; add early return guards in
    __dynamic_*_dbg() helpers.
- Link to v9: https://lore.kernel.org/r/20260908-dd-cmap-part2-clean-v9-0-3a3f621f4a10@gmail.com

Changes in v9:
- Decouple DRM core setup and driver opt-in commits to route separately
  through dri-devel / drm-misc, keeping this foundation series 100%
  focused on core dynamic_debug infrastructure for -mm.
- Incorporate review findings and automated test fixes prompted by
  sashiko:
  . Rework Kbuild naming heuristic in scripts/Makefile.lib to assign
    clean subsystem-scoped names to built-ins and shared helpers
    (e.g. [init], [power], [coco/sev], [mmc/host]), eliminating
    multi-token whitespace in column 2 of dynamic_debug/control.
  . Fix missing DYNAMIC_DEBUG_CLASSMAP_USE_() stub under
    !CONFIG_DYNAMIC_DEBUG.
  . Make ddebug_add_module() non-fatal on failure during
    dynamic_debug_init().
  . Fix off-by-one assertions in __DYNAMIC_DEBUG_CLASSMAP_CHECK and
    ddebug_add_module().
  . Prevent loop wrapping lockup in test_dynamic_debug:do_bulk() on
    UINT_MAX and add cond_resched() to bulk print loops.
  . Fix 4-argument signature on DYNAMIC_DEBUG_CLASSMAP_PARAM_REF
    fallback macro stub.
  . Assign map->controlling_param to enforce classmap protection on
    parameterized classes.
  . Update ddebug_proc_start() seeking to return EPILOGUE_TOKEN
    when n == 0.
  . Free temporary buffer in reset_stats handler and iterate across
    possible CPUs for dynamic debug call counter.
  . Selftests: sanitize "$K", drop duplicate declarations, fix
    unquoted error output, align LACK_DD_BUILTIN filters to labels,
    add K=2 silent mode, and prime params with +p in
    FT_comma_terminators.
- Link to v8: https://lore.kernel.org/r/20260905-dd-cmap-part2-clean-v8-0-a4cc0674f6fd@gmail.com

Changes in v8:
- Unified 44-patch series (incorporating follow-on compile-time checks,
  comma-token delimiters, '@' multi-query separator, and inheritance
  tests).
- Rebased onto upstream v7.3-rc1.
- Passing on dyndbg_selftest.sh under KASAN + KMEMLEAK.
- Link to v7: https://lore.kernel.org/r/20260721-dd-maint-2-v7-0-010fbe73b311@gmail.com

Changes in v6..v7:
- Add compile-time validation for classmap parameters and offset
bounds (__DYNAMIC_DEBUG_CLASSMAP_CHECK).
- Harden modprobe-time error detection for unknown class names and
  class ID reservation conflicts.
- Promote DYNAMIC_DEBUG_CLASSMAP_PARAM to public API.
- Shrink class parameter storage to u32.
- Hoist classmap filtering up to ddebug_add_module().

Changes in v4..v5:
- Tighten function signatures (ddebug_apply_class_bitmap,
  param_set_dyndbg_classes).
- Replace classmap linked-list with vector / array-slice.
- Add for_subvec() loop helper and restructure _ddebug_info substructs.
- Move mod_name down from struct ddebug_table to _ddebug_info.

Changes in v2..v3:
- Refactor BOUNDED_SECTION* macros from
  include/asm-generic/vmlinux.lds.h into
  include/asm-generic/bounded_sections.lds.h.
- Add dyndbg output sections to scripts/module.lds.S to fix lost
  sections in loadable modules.
- Fix 8-byte section alignment omission causing i386 NULL pointer deref.
- Move dyndbg_selftest.sh to the front of the series for bisectability.

Changes in v12 (DRM combined series):
- Refactor vmlinux.lds.h and add bounded_sections.lds.h and
  dyndbg.lds.h.
- Refine DYNAMIC_DEBUG_CLASSMAP_USE*() with extern'd classmap linkages
  and compile-time offset checks.
- Include patch from Philipp Hahn <phahn-oss@avm.de> (Ignore additional
  arguments from pr_fmt).
- Link to v12: https://lore.kernel.org/lkml/20260326175533.1402867-1-jim.cromie@gmail.com/

Changes in v11 (DRM combined series):
- Rebase on drm-misc-next for DRM-CI testing.
- Fix 32-bit truncation error in drm_buddy.
- Fix drm_printer_debug_fn message spew causing test timeouts.
- Verify on DRM-CI Pipeline #1622778 (621 KUnit tests, 370 i915-CML
  tests passed, 0 failures).
- Link to v11: https://lore.kernel.org/lkml/20260313132103.2529746-1-jim.cromie@gmail.com/

Changes in v10 (DRM combined series):
- Initial replacement of DECLARE_DYNDBG_CLASSMAP with
  DYNAMIC_DEBUG_CLASSMAP_DEFINE and DYNAMIC_DEBUG_CLASSMAP_USE.
- Add tools/testing/selftests/dynamic_debug/ and
  test_dynamic_debug_submod.ko.
- Drop class "protection" special-casing per Jason Baron's feedback.
- Link to v10: https://lore.kernel.org/lkml/20250125064619.8305-1-jim.cromie@gmail.com/

---
Jim Cromie (37):
      selftests/dyndbg: Add kselftest script to verify dynamic-debug
      vmlinux.lds.h: refactor BOUNDED_SECTION_* macros into bounded_sections.lds.h
      vmlinux.lds.h: drop unused HEADERED_SECTION* macros
      vmlinux.lds.h: Fix ALIGN(8) omission causing NULL ptr on i386
      vmlinux.lds.h: remove redundant ALIGN(8) directives
      dyndbg.lds.S: fix lost dyndbg sections in modules
      dyndbg: factor ddebug_match_desc out from ddebug_change
      dyndbg: add stub macro for DECLARE_DYNDBG_CLASSMAP
      dyndbg: reword "class unknown," to "class:_UNKNOWN_"
      dyndbg-API: remove DD_CLASS_TYPE_(DISJOINT|LEVEL)_NAMES and code
      dyndbg: drop NUM_TYPE_ARGS
      dyndbg: bump num-tokens in a query-cmd from 9 to 15
      dyndbg: reduce verbose/debug clutter
      dyndbg: Bind callsites and classmaps to DDEBUG_MODNAME
      dyndbg: refactor param_set_dyndbg_classes and below
      dyndbg: tighten fn-sig of ddebug_apply_class_bitmap
      dyndbg: replace classmap list with an array-slice
      dyndbg: macrofy a 2-index for-loop pattern
      dyndbg: reduce class param storage to u32
      dyndbg,module: make proper substructs in _ddebug_info
      dyndbg: move mod_name down from struct ddebug_table to _ddebug_info
      dyndbg: hoist classmap-filter-by-modname up to ddebug_add_module
      dyndbg-API: replace DECLARE_DYNDBG_CLASSMAP
      selftests/dyndbg: Enable FT_classmap_inheritance
      dyndbg: detect class_id reservation conflicts
      dyndbg: check DYNAMIC_DEBUG_CLASSMAP_{DEFINE,USE_} args at compile-time
      dyndbg-test: add do_bulk testpoint, rename do_prints to do_classes
      dyndbg-API: promote DYNAMIC_DEBUG_CLASSMAP_PARAM to API
      dyndbg: control-parser: treat comma as a token separator
      selftests: enable comma-terminator tests
      dyndbg: split multi-query strings with @
      dyndbg: resolve "protection" of class'd pr_debug
      dyndbg: harden classmap and descriptor validation
      docs/dyndbg: add classmap info to howto
      dyndbg: add epilogue to dynamic_debug/control file
      dyndbg: add +c flag to count advantage of classmaps for DRM
      dyndbg: add DEBUG-biased fallback stubs for _dynamic_func_call_cls

Philipp Hahn (1):
      dyndbg: Ignore additional arguments from pr_fmt

 Documentation/admin-guide/dynamic-debug-howto.rst  | 157 +++-
 MAINTAINERS                                        |   2 +
 drivers/gpu/drm/drm_print.c                        |   4 +-
 include/asm-generic/bounded_sections.lds.h         |  32 +
 include/asm-generic/dyndbg.lds.h                   |  22 +
 include/asm-generic/vmlinux.lds.h                  |  68 +-
 include/drm/drm_print.h                            |   2 +-
 include/linux/dynamic_debug.h                      | 397 +++++++--
 include/linux/printk.h                             |   2 +-
 kernel/module/main.c                               |  15 +-
 lib/Kconfig.debug                                  |  24 +-
 lib/Makefile                                       |   3 +
 lib/dynamic_debug.c                                | 971 +++++++++++++++------
 lib/test_dynamic_debug.c                           | 277 ++++--
 lib/test_dynamic_debug_submod.c                    |  21 +
 scripts/module.lds.S                               |   2 +
 tools/testing/selftests/dynamic_debug/Makefile     |  10 +
 tools/testing/selftests/dynamic_debug/config       |   8 +
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 735 ++++++++++++++++
 .../dynamic_debug/syslog_hash_validation.sh        | 393 +++++++++
 20 files changed, 2620 insertions(+), 525 deletions(-)
---
base-commit: 136ebbeb1c6040f2739ac4a9e0f704395faaf64f
change-id: 20260901-dd-cmap-part2-clean-369ec194e4af

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

