From: Jim Cromie <jim.cromie@gmail.com>
Date: Fri, 25 Sep 2026 15:16:37 -0600
Subject: [PATCH v5 2/3] kallsyms: Increase marker density to 16:1 to
 accelerate lookups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-ksyms-tune-v5-2-1f75ad0c321c@gmail.com>
References: <20260925-ksyms-tune-v5-0-1f75ad0c321c@gmail.com>
In-Reply-To: <20260925-ksyms-tune-v5-0-1f75ad0c321c@gmail.com>
To: Andrew Morton <akpm@linux-foundation.org>
Cc: Lorenzo Stoakes <ljs@kernel.org>, Kees Cook <kees@kernel.org>, 
 David Laight <david.laight.linux@gmail.com>, 
 Masahiro Yamada <masahiroy@kernel.org>, Jiri Olsa <olsajiri@gmail.com>, 
 linux-kernel@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 bpf@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790370996; l=5598;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=I5eAsIUxlAO2WTgi4bmGLPeCWEGaAl1zgyePZxGBQ0U=;
 b=ALxz2R5w89spC2a8/SE0eZBjI/rejwJkvJSAPFiQ4rxotstp18KpHBZTDfKA9Zy6c3Gku0tEv
 ARbSV5kqLr0AsTY7h9VZGxXOZ8OrHI+KyJU6YEpqvKpJde0l9EYux0O
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kallsyms_lookup_names() resolves symbol names to addresses using a
binary search over kallsyms_seqs_of_names[].  In baseline, each probe
invokes get_symbol_offset() to find the symbol in kallsyms_names[].
Because markers in kallsyms_markers[] are spaced every 256 symbols in
address order, each probe must sequentially scan and decode ULEB128
lengths across an average of 127.5 symbols from the nearest marker
(~2,176 hops across a 17-step binary search).

During bulk symbol resolution (e.g. BPF multi-kprobe and tracing-multi
attach across tens of thousands of functions), this linear scan penalty
compounds into substantial latency (~4.7 us to ~6.1 us per lookup).

Increase the static marker density from 256:1 down to 16:1 (1 marker
every 1 << 4 symbols):

0. Define KALLSYMS_MARKER_SHIFT as 4 in kernel/kallsyms_internal.h, with
   a matching KALLSYMS_MARKER_MASK of 0x0F.  Guard kernel types so host
   scripts/kallsyms.c can include this header directly as the single
   symbolic source of truth.

1. In scripts/kallsyms.c, emit markers every
   (1 << KALLSYMS_MARKER_SHIFT) symbols into kallsyms_markers[].  For a
   typical kernel with ~184,000 symbols, this increases marker count
   from 719 to 11,501 entries, adding only +42.2 KiB to write-protected
   .rodata (0.002% of vmlinux).

2. In kernel/kallsyms.c:get_symbol_offset(), compute marker offset via
   pos >> KALLSYMS_MARKER_SHIFT and step through
   pos & KALLSYMS_MARKER_MASK.  Because both are compile-time
   constants, GCC emits single bit-shift and AND instructions with zero
   division overhead.

This reduces the maximum sequential scan from 255 down to 15 symbols,
and cuts the average scan from 127.5 down to 7.5 hops (a 17x reduction
in sequential loop hops).  In-tree selftest measurements across all
184,008 symbols show lookup latency dropping from 6,102 ns down to
866 ns (a 7.0x speedup) with zero runtime memory allocation, zero RCU
synchronization, and zero new user-facing APIs or Kconfig options.

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Changes in v5:
- Replace dynamic 1:1 batch lookup index (kvmalloc, mutexes, RCU) with
  static 16:1 marker density (KALLSYMS_MARKER_SHIFT 4) in .rodata
  (addresses Kees Cook review).
- Eliminate all dynamic RAM allocations, setup/teardown costs, and
  external batch APIs.
---
 kernel/kallsyms.c          |  8 ++++----
 kernel/kallsyms_internal.h |  5 +++++
 scripts/kallsyms.c         | 14 +++++++++-----
 3 files changed, 18 insertions(+), 9 deletions(-)

diff --git a/kernel/kallsyms.c b/kernel/kallsyms.c
index d18d78e626db..91ced7aa797e 100644
--- a/kernel/kallsyms.c
+++ b/kernel/kallsyms.c
@@ -150,10 +150,10 @@ static unsigned int get_symbol_offset(unsigned long pos)
 	int i, len;
 
 	/*
-	 * Use the closest marker we have. We have markers every 256 positions,
-	 * so that should be close enough.
+	 * Use the closest marker we have. We have markers every
+	 * (1 << KALLSYMS_MARKER_SHIFT) positions, so that should be close enough.
 	 */
-	name = &kallsyms_names[kallsyms_markers[pos >> 8]];
+	name = &kallsyms_names[kallsyms_markers[pos >> KALLSYMS_MARKER_SHIFT]];
 
 	/*
 	 * Sequentially scan all the symbols up to the point we're searching
@@ -161,7 +161,7 @@ static unsigned int get_symbol_offset(unsigned long pos)
 	 * so we just need to add the len to the current pointer for every
 	 * symbol we wish to skip.
 	 */
-	for (i = 0; i < (pos & 0xFF); i++) {
+	for (i = 0; i < (pos & KALLSYMS_MARKER_MASK); i++) {
 		len = *name;
 
 		/*
diff --git a/kernel/kallsyms_internal.h b/kernel/kallsyms_internal.h
index 81a867dbe57d..3e6494b7dfc4 100644
--- a/kernel/kallsyms_internal.h
+++ b/kernel/kallsyms_internal.h
@@ -1,7 +1,11 @@
 /* SPDX-License-Identifier: GPL-2.0-only */
 #ifndef LINUX_KALLSYMS_INTERNAL_H_
 #define LINUX_KALLSYMS_INTERNAL_H_
+#define KALLSYMS_MARKER_SHIFT 4  /* 16:1 sweet spot: +42 KiB .rodata, 17x fewer hops */
+#define KALLSYMS_MARKER_SIZE  (1U << KALLSYMS_MARKER_SHIFT)
+#define KALLSYMS_MARKER_MASK  (KALLSYMS_MARKER_SIZE - 1U)
 
+#ifdef __KERNEL__
 #include <linux/types.h>
 
 extern const int kallsyms_offsets[];
@@ -14,5 +18,6 @@ extern const u16 kallsyms_token_index[];
 
 extern const unsigned int kallsyms_markers[];
 extern const u8 kallsyms_seqs_of_names[];
+#endif /* __KERNEL__ */
 
 #endif // LINUX_KALLSYMS_INTERNAL_H_
diff --git a/scripts/kallsyms.c b/scripts/kallsyms.c
index 494852ade6d8..be42a9111350 100644
--- a/scripts/kallsyms.c
+++ b/scripts/kallsyms.c
@@ -29,6 +29,8 @@
 
 #include <xalloc.h>
 
+#include "../kernel/kallsyms_internal.h"
+
 #define ARRAY_SIZE(arr) (sizeof(arr) / sizeof(arr[0]))
 
 #define KSYM_NAME_LEN		512
@@ -349,16 +351,18 @@ static void write_src(void)
 	printf("\t.long\t%u\n", table_cnt);
 	printf("\n");
 
-	/* table of offset markers, that give the offset in the compressed stream
-	 * every 256 symbols */
-	markers_cnt = (table_cnt + 255) / 256;
+	/*
+	 * Table of offset markers, giving the offset in the compressed stream
+	 * every (1 << KALLSYMS_MARKER_SHIFT) symbols.
+	 */
+	markers_cnt = (table_cnt + KALLSYMS_MARKER_MASK) >> KALLSYMS_MARKER_SHIFT;
 	markers = xmalloc(sizeof(*markers) * markers_cnt);
 
 	output_label("kallsyms_names");
 	off = 0;
 	for (i = 0; i < table_cnt; i++) {
-		if ((i & 0xFF) == 0)
-			markers[i >> 8] = off;
+		if ((i & KALLSYMS_MARKER_MASK) == 0)
+			markers[i >> KALLSYMS_MARKER_SHIFT] = off;
 		table[i]->seq = i;
 
 		/* There cannot be any symbol of length zero. */

-- 
2.55.0

