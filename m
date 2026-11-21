From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH 0/6] dyndbg,vmlinux.lds.h: fix i386 section alignment in
 BOUNDED_SECTION macros
Date: Sat, 21 Nov 2026 15:49:18 -0700
Message-Id: <20261121-vmlinux-lds-v1-0-49818f3f5cc0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3M3QpAQBAG0FeZvmtbZkPsq8iFn8EUS7vZlLy7c
 h7gPIgSVCIcPQiSNOrh4Ygzwrj2fhGjExzB5rZitmzSvqm/brNN0QxlU3DORVXXJTLCGWTW+9/
 a7n0/HYCNLV0AAAA=
X-Change-ID: 20261121-vmlinux-lds-b59410146885
To: Arnd Bergmann <arnd@arndb.de>, Jason Baron <jbaron@akamai.com>, 
 Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Daniel Gomez <da.gomez@kernel.org>, Sami Tolvanen <samitolvanen@google.com>, 
 Aaron Tomlin <atomlin@atomlin.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-arch@vger.kernel.org, 
 linux-modules@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>, 
 Louis Chauvet <louis.chauvet@bootlin.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795301375; l=2466;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=InmaDXtqg+/ahjVrbCn9lEk8jOf8zxExCbI82ydIsZw=;
 b=Sf2U1Fv6tD3GNRvKetfdqrqq6Lle3eJzJPocyk3wSnGWKzNm3t5q6lF4H62eVd+rRfUiiwlLR
 LlWgl5loBYOCdW0Eb97rHq1Fo2nHdILm6Wsn3J80brn9VpViuJ1gDzm
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes a latent i386 section-alignment bug, by adding
explicit alignments into the BOUNDED_SECTION_* linker script macros.
The misalignment appears once __dyndbg_classes is split in 2, and the
1st section has just 1 entry; the 2nd section implicitly gets ALIGN(4).

1. Refactor BOUNDED_SECTION_* (and HEADERED_SECTION_*) macros from
   vmlinux.lds.h into include/asm-generic/bounded_sections.lds.h for
   reuse.

2. Drop the unused HEADERED_SECTION* macros from bounded_sections.lds.h.

3. Add explicit ALIGN(8) defaults to BOUNDED_SECTION_* (with _ALIGNED
   variants for non-8-byte tables like ORC_UNWIND_TABLE,
   EXCEPTION_TABLE, TRACEDATA, INIT_SETUP, and NOTES), fixing an i386
   NULL deref in dynamic_debug_init() caused by 28-byte
   __dyndbg_classes misaligning the following __dyndbg section.

4. Remove now-redundant outer `. = ALIGN(8);` directives preceding 
   BOUNDED_SECTION* uses in vmlinux.lds.h.

5. Add include/asm-generic/dyndbg.lds.h with DYNDBG_SECTIONS() for 
   vmlinux.lds.h and MOD_DYNDBG_SECTIONS() (`0 : ALIGN(8)` + `KEEP`) for
   scripts/module.lds.S, fixing lost __dyndbg* sections in DRM modules 
   under CONFIG_DRM_USE_DYNAMIC_DEBUG=y.

6. fix checkpatch to skip macro-rules checks on any *.lds.h, in 3
   places where only vmlinux.lds.h is currently skipped.

NB: most of this patchset was split out of larger series fixing
dyndbg-classmaps.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Jim Cromie (6):
      vmlinux.lds.h: refactor BOUNDED_SECTION_* macros into bounded_sections.lds.h
      vmlinux.lds.h: drop unused HEADERED_SECTION* macros
      vmlinux.lds.h: Fix ALIGN(8) omission causing NULL ptr on i386
      vmlinux.lds.h: remove redundant ALIGN(8) directives
      dyndbg.lds.S: fix lost dyndbg sections in modules
      checkpatch.pl: generalize linker script macro exceptions

 MAINTAINERS                                |  1 +
 include/asm-generic/bounded_sections.lds.h | 32 ++++++++++++++
 include/asm-generic/dyndbg.lds.h           | 18 ++++++++
 include/asm-generic/vmlinux.lds.h          | 68 ++++++------------------------
 scripts/checkpatch.pl                      |  6 +--
 scripts/module.lds.S                       |  2 +
 6 files changed, 69 insertions(+), 58 deletions(-)
---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261121-vmlinux-lds-b59410146885

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

