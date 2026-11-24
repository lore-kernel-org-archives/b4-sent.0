From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH v2 0/6] dyndbg,vmlinux.lds.h: fix i386 section alignment in
 BOUNDED_SECTION macros
Date: Mon, 23 Nov 2026 18:30:32 -0700
Message-Id: <20261123-vmlinux-lds-v2-0-6f608abfa042@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/23MMQ6DIBQA0KuQP0vDp2DQqfdoHCyC/gS0gZbYG
 O7e1LnrG94B2SVyGXp2QHKFMm0r9Ew2DOwyrrPjNEHPQArZIkrkJQZa3zsPU+YP3SkUqFpjNDQ
 Mnsl52s/tPjQMFsqvLX3OvOBP/z8FueCqM2j81WtrxW2OI4WL3SIMtdYvSLXNi6YAAAA=
X-Change-ID: 20261121-vmlinux-lds-b59410146885
To: Arnd Bergmann <arnd@arndb.de>, Jason Baron <jbaron@akamai.com>, 
 Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Daniel Gomez <da.gomez@kernel.org>, Sami Tolvanen <samitolvanen@google.com>, 
 Aaron Tomlin <atomlin@atomlin.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>, 
 Louis Chauvet <louis.chauvet@bootlin.com>, Joe Perches <joe@perches.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795483834; l=2874;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=6NBOkHJt3QdBU+ak+6FV5tsQ+HpSrEWmsWMcv2DR53w=;
 b=VeETTy30banfAaTjZ+p7CKuBzeaXn9flaRLzykZHo+EyHI91bEXZoJUlqytWg4UaA4wEWhgPB
 CXwBzEoA+4PCh854cLIxqBiDOzmjes7+m0peoSe8xiDrWROTrh5D7Mh
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes a latent i386 section-alignment bug by adding
explicit alignments to the BOUNDED_SECTION_* linker script macros.
On i386, struct _ddebug_classmap is 28 bytes, so without an explicit
ALIGN(8) in the macro, a following __dyndbg section inherits 4-byte
alignment instead of 8-byte alignment, causing a NULL pointer
dereference in dynamic_debug_init().

1. Drop the unused HEADERED_SECTION* macros from vmlinux.lds.h.

2. Refactor BOUNDED_SECTION_* macros from vmlinux.lds.h into
   include/asm-generic/bounded_sections.lds.h for reuse.

3. Add explicit ALIGN(8) defaults to BOUNDED_SECTION_* (with _ALIGNED
   variants for non-8-byte tables like ORC_UNWIND_TABLE,
   EXCEPTION_TABLE, TRACEDATA, INIT_SETUP, and NOTES), fixing the i386
   NULL deref in dynamic_debug_init().

4. Remove now-redundant outer `. = ALIGN(8);` directives preceding
   BOUNDED_SECTION* uses in vmlinux.lds.h.

5. Add include/asm-generic/dyndbg.lds.h with DYNDBG_SECTIONS() for
   vmlinux.lds.h and MOD_DYNDBG_SECTIONS() (`0 : ALIGN(8)` + `KEEP`) for
   scripts/module.lds.S, fixing lost __dyndbg* sections in DRM modules
   under CONFIG_DRM_USE_DYNAMIC_DEBUG=y.

6. Generalize checkpatch linker script macro exceptions to match any
   *.lds.h via a single `$is_linker_file` regex across all 4 checks.

NB: most of this patchset was split out of a larger series fixing
dyndbg-classmaps.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Changes in v2:
- Drop unused HEADERED_SECTION* macros from vmlinux.lds.h before
  moving BOUNDED_SECTION_* to bounded_sections.lds.h.
- Fix broken `/\.lds\.h$` regexes in checkpatch.pl (remove leading `/`).
- Introduce single `$is_linker_file = '\.lds\.h$'` in checkpatch.pl
  for all 4 `.lds.h` checks (Joe Perches).
- Link to v1: https://lore.kernel.org/r/20261121-vmlinux-lds-v1-0-49818f3f5cc0@gmail.com

---
Jim Cromie (6):
      vmlinux.lds.h: drop unused HEADERED_SECTION* macros
      vmlinux.lds.h: refactor BOUNDED_SECTION_* macros into bounded_sections.lds.h
      vmlinux.lds.h: fix ALIGN(8) omission causing NULL ptr on i386
      vmlinux.lds.h: remove redundant ALIGN(8) directives
      dyndbg.lds.h: fix lost dyndbg sections in modules
      checkpatch: generalize linker script macro exceptions

 MAINTAINERS                                |  1 +
 include/asm-generic/bounded_sections.lds.h | 32 ++++++++++++++
 include/asm-generic/dyndbg.lds.h           | 18 ++++++++
 include/asm-generic/vmlinux.lds.h          | 68 ++++++------------------------
 scripts/checkpatch.pl                      | 11 ++---
 scripts/module.lds.S                       |  2 +
 6 files changed, 72 insertions(+), 60 deletions(-)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261121-vmlinux-lds-b59410146885

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

