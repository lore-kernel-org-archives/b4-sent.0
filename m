From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH v8 00/43] dyndbg: fix classmaps API for DRM, query
 extensions, and selftests
Date: Sat, 05 Sep 2026 12:13:14 -0600
Message-Id: <20260905-dd-cmap-part2-clean-v8-0-a4cc0674f6fd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBswi8iuEi0GnWqgTDQiCO+et
 HyL/19IHIUTjNULkW9JcvqCoa7AbuRXRnHFoJXulVENOof2oICB4qXR7kwe296wbUzHHS1QyhB
 5kee/TnPOHwtEmR1lAAAA
X-Change-ID: 20260901-dd-cmap-part2-clean-369ec194e4af
To: Jason Baron <jbaron@akamai.com>, Shuah Khan <shuah@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Arnd Bergmann <arnd@arndb.de>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kbuild@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>, 
 Louis Chauvet <louis.chauvet@bootlin.com>, Philipp Hahn <phahn-oss@avm.de>, 
 kernel test robot <lkp@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788632017; l=7904;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=M4k2IpIBGuD4cW1OZSGixEalubL/dRnvHok/5OiqB7w=;
 b=zRYb95PXWXrcudOWEH+azUEqBIwHci3cXEUskesWlaNEkySWcW9F7+T8oSp4wSg/MCKDiav2X
 xDhMhkiQs01CRgLB2hGhCb4AokPshap72DlnPVZZUYX9Bsb/Z50iFo1
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes problems which broke CONFIG_DRM_USE_DYNAMIC_DEBUG=Y,
then fixes a classmap section mis-alignment on 32-bit, adds ",@"
token/cmd terminators to the query parser, and adds regression
selftests.

The core bug was an initialization order mismatch: handling of
`drm.debug` settings occurs when `drm.ko` initializes, long before DRM
driver and helper modules are loaded. Consequently, drivers missed the
initial parameter settings.  Test scripts modprobing with explicit
options obscured the problem.

The fix splits DECLARE_DYNDBG_CLASSMAP into a client-server model:
- DRM core calls DYNAMIC_DEBUG_CLASSMAP_DEFINE()
- Drivers call DYNAMIC_DEBUG_CLASSMAP_USE()

When a driver is modprobed, dyndbg finds its _USE record, references
the _DEFINE record in drm core, finds the `drm.debug` param wired to
that classmap, and applies the current bitmap to the newly loaded
driver.

Series Breakdown (44 Patches):

0. Selftest First:
   - add tools/testing/selftests/dynamic_debug/dyndbg_selftest.sh
   - at series start, to validate and bisect every following commit
   - recap 2-module bug scenario, prove its fixed.
   - fingerprint-the-response based.

1. 32-bit Linker Fixes:
   - Fix ALIGN(8) omission causing crashes on i386.
   - Refactor BOUNDED_SECTION_* macros from vmlinux.lds.h.

2. DRM Setup
   - ccflags fix
   - Remove BROKEN on CONFIG_DRM_USE_DYNAMIC_DEBUG (maximize testing)
   - probly defer these to drm-folk.
   - drm drivers need 1-liner opt-ins, not included here.

3. lots of cleanup patches

4. Disambiguate Builtin Module Names:
   - Use KBUILD_MODFILE to name builtin modules by path
     (e.g., `[init/main]` vs `[kernel/power/main]`).
   - Prevents classmap collision between distinct builtins named "main".
   - Preserves legacy queries: `module main` still selects `[*/main]`.

5. Classmap Core & Public API:
   - Replace DECLARE_DYNDBG_CLASSMAP with explicit DEFINE/USE macros.
   - Promote DYNAMIC_DEBUG_CLASSMAP_PARAM to public API.
   - Shrink class parameter storage to u32.
   - Add compile-time argument validation and detect class ID conflicts.

6. Query Parser Extensions:
   - Treat comma as a token separator.
   - parse multi-query command submissions with '@' delimiter too.
   - Bump max tokens per command from 9 to 15.
   - Add hyphen-agnostic matching for module names. (kvm-intel == kvm_intel)

7. User-Visible Changes:
   - Error string on bad classmap changed to `class:_UNKNOWN_ id:1`.
   - Reverted `__drm_debug` from `long int` back to `u32`.
   - exposes chosen classnames in dynamic_debug/control

Testing:

Tested locally using virtme-ng and increasingly bare x86_64
hardware. Selftests pass on ~8 builds/configs, including KASAN with
zero KMEMLEAK warnings.

Gitlab DRM-CI test runs show no regressions vs v7.2, but I need to
look again to see if DRM_USE_DYNAMIC_DEUBUG=y was in effect.
The kernel-under-test has the follow-on patchset for drm drivers, helpers.
https://gitlab.freedesktop.org/jim.cromie/kernel-drm-next-dd/-/pipelines

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Changes in v8:
- Unified full 44-patch series (incorporating follow-on compile-time checks,
  comma-token delimiters, '@' multi-query separator, and inheritance tests).
- Rebased onto upstream v7.3-rc1 
- passing on dyndbg_selftest.sh under KASAN + KMEMLEAK.
- Link to v7: https://lore.kernel.org/r/20260721-dd-maint-2-v7-0-010fbe73b311@gmail.com

---
Jim Cromie (42):
      selftests/dyndbg: Add kselftest script to verify dynamic-debug
      drm: Fix incorrect ccflags-y spelling inside Makefile
      drm: fix config dependent unused variable warning.
      drm: Mark CONFIG_DRM_USE_DYNAMIC_DEBUG as unBROKEN
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
      lib/parser: add match_wildcard_hyphen() for agnostic matching
      kbuild, dyndbg: clean up builtin module-name ambiguities
      dyndbg: refactor param_set_dyndbg_classes and below
      dyndbg: tighten fn-sig of ddebug_apply_class_bitmap
      dyndbg: replace classmap list with an array-slice
      dyndbg: macrofy a 2-index for-loop pattern
      dyndbg: reduce class param storage to u32
      dyndbg,module: make proper substructs in _ddebug_info
      dyndbg: move mod_name down from struct ddebug_table to _ddebug_info
      dyndbg: hoist classmap-filter-by-modname up to ddebug_add_module
      dyndbg-API: replace DECLARE_DYNDBG_CLASSMAP
      selftests/dyndbg: enable FT_classmap_inheritance
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
      selftests/dynamic_debug: Prime params module with +p in FT_comma_terminators

Philipp Hahn (1):
      dyndbg: Ignore additional arguments from pr_fmt

 Documentation/admin-guide/dynamic-debug-howto.rst  | 194 ++++-
 MAINTAINERS                                        |   2 +
 drivers/gpu/drm/Kconfig.debug                      |   3 +-
 drivers/gpu/drm/Makefile                           |   3 +-
 drivers/gpu/drm/drm_print.c                        |   7 +-
 include/asm-generic/bounded_sections.lds.h         |  32 +
 include/asm-generic/dyndbg.lds.h                   |  22 +
 include/asm-generic/vmlinux.lds.h                  |  68 +-
 include/drm/drm_print.h                            |   2 +-
 include/linux/dynamic_debug.h                      | 361 ++++++--
 include/linux/parser.h                             |   1 +
 kernel/module/main.c                               |  15 +-
 lib/Kconfig.debug                                  |  24 +-
 lib/Makefile                                       |   3 +
 lib/dynamic_debug.c                                | 924 +++++++++++++++------
 lib/parser.c                                       |  58 +-
 lib/test_dynamic_debug.c                           | 274 ++++--
 lib/test_dynamic_debug_submod.c                    |  21 +
 scripts/Makefile.lib                               |   9 +
 scripts/module.lds.S                               |   2 +
 tools/testing/selftests/dynamic_debug/Makefile     |  10 +
 tools/testing/selftests/dynamic_debug/config       |   8 +
 .../selftests/dynamic_debug/dyndbg_selftest.sh     | 831 ++++++++++++++++++
 .../dynamic_debug/syslog_hash_validation.sh        | 393 +++++++++
 24 files changed, 2734 insertions(+), 533 deletions(-)
---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260901-dd-cmap-part2-clean-369ec194e4af

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

