From: quanyeyang <quanyeyang@proton.me>
Date: Thu, 20 Aug 2026 19:11:29 +0800
Subject: [PATCH v2] bpf: Annotate bpf_obj_memcpy with data_race
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-bpf-kcsan-obj-memcpy-v2-1-672517a3145f@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22Nyw6CMBBFf4V07Zh2xPJY+R+GBS2DFEPbtEgkh
 H8X0KXLk9x7zsIiBUORlcnCAk0mGmc3wFPCdFfbB4FpNmbIUfJcFKB8C08dawtO9TDQoP0MMuM
 pKtFqyhq2XX2g1rwP7b36cnypnvS4u/ZFZ+Lownx0J7Hvfgnk/xOTAAGXDPW1SCWizG8+uNHZ8
 0CsWtf1A1Cm2GfKAAAA
X-Change-ID: 20260819-bpf-kcsan-obj-memcpy-67042b1fce7d
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Andrii Nakryiko <andrii@kernel.org>, Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+44044637ef892e79ca2b@syzkaller.appspotmail.com, 
 quanyeyang <quanyeyang@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787224289; l=4461;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=+I8QIIVUjRXzYFGg37nqcR5V75m/9N/tCkoDJ3IuiOI=;
 b=7KSiU4/cW7o48eVplDAvCeqtg14fkTFcr3P4LZAMxa+9fQRgxWWrtXisWwreoidErfXSvb8nM
 fXeJ6WPTzzwB2CEh5O7VMECIz41vR6I0QJKeWFre1OeOEquxSIExiz2
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

syzbot reported KCSAN write-write races when two tasks concurrently
update the same map value. Both accesses reach the ordinary memcpy()
paths in bpf_obj_memcpy() through copy_map_value().

Unlocked in-place updates of published map values are intentionally not
serialized and may produce torn values. Callers requiring consistency
must provide synchronization appropriate for the map type.
bpf_long_memcpy() already annotates the same behavior for long-aligned
copies.

Annotate the ordinary memcpy() sites in bpf_obj_memcpy() with
data_race(), matching bpf_long_memcpy(). This documents the existing
concurrency semantics and suppresses KCSAN reports for these intentional
races without changing synchronization or map update behavior.

Reported-by: syzbot+44044637ef892e79ca2b@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=44044637ef892e79ca2b
Signed-off-by: quanyeyang <quanyeyang@proton.me>
---
The annotations remain in the common bpf_obj_memcpy() helper, matching
bpf_long_memcpy(). This keeps the existing copy helper interfaces
unchanged. A narrower annotation would require propagating the
concurrency context through copy_map_value() or introducing separate
copy helpers.

The following checkpatch warnings are expected:

- DATA_RACE is reported for the three annotations because checkpatch
  only recognizes an immediately adjacent comment. Their shared
  rationale is documented above bpf_obj_memcpy().
- MISSING_FIXES_TAG is reported because the commit references syzkaller.
  No Fixes tag is included because this documents long-standing
  intentional lockless semantics rather than a regression introduced
  by a particular commit.
---
Changes in v2:
- Drop the BPF_F_LOCK recommendation because it is unavailable for
  per-CPU maps.
- Scope the concurrency description to unlocked in-place updates of
  published map values.
- Fold the redundant commit message paragraphs.
- Link to v1:
  https://patch.msgid.link/20260820-bpf-kcsan-obj-memcpy-v1-1-372c59462268@proton.me

To: Alexei Starovoitov <ast@kernel.org>
To: Daniel Borkmann <daniel@iogearbox.net>
To: Andrii Nakryiko <andrii@kernel.org>
To: Eduard Zingerman <eddyz87@gmail.com>
To: Kumar Kartikeya Dwivedi <memxor@gmail.com>
To: Martin KaFai Lau <martin.lau@linux.dev>
To: Song Liu <song@kernel.org>
To: Yonghong Song <yonghong.song@linux.dev>
To: Jiri Olsa <jolsa@kernel.org>
To: Emil Tsalapatis <emil@etsalapatis.com>
To: John Fastabend <john.fastabend@gmail.com>
Cc: bpf@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 include/linux/bpf.h | 15 +++++++++++----
 1 file changed, 11 insertions(+), 4 deletions(-)

diff --git a/include/linux/bpf.h b/include/linux/bpf.h
index 7719f6528445..10d1186ef3b4 100644
--- a/include/linux/bpf.h
+++ b/include/linux/bpf.h
@@ -560,7 +560,14 @@ static inline void bpf_long_memcpy(void *dst, const void *src, u32 size)
 		data_race(*ldst++ = *lsrc++);
 }
 
-/* copy everything but bpf_spin_lock, bpf_timer, and kptrs. There could be one of each. */
+/*
+ * Copy everything but bpf_spin_lock, bpf_timer, and kptrs. There could
+ * be one of each.
+ *
+ * When this helper performs an unlocked in-place update of a published
+ * map value, the ordinary byte copies may intentionally race with
+ * concurrent updates and the resulting value may be torn.
+ */
 static inline void bpf_obj_memcpy(struct btf_record *rec,
 				  void *dst, void *src, u32 size,
 				  bool long_memcpy)
@@ -572,7 +579,7 @@ static inline void bpf_obj_memcpy(struct btf_record *rec,
 		if (long_memcpy)
 			bpf_long_memcpy(dst, src, round_up(size, 8));
 		else
-			memcpy(dst, src, size);
+			data_race(memcpy(dst, src, size));
 		return;
 	}
 
@@ -580,10 +587,10 @@ static inline void bpf_obj_memcpy(struct btf_record *rec,
 		u32 next_off = rec->fields[i].offset;
 		u32 sz = next_off - curr_off;
 
-		memcpy(dst + curr_off, src + curr_off, sz);
+		data_race(memcpy(dst + curr_off, src + curr_off, sz));
 		curr_off += rec->fields[i].size + sz;
 	}
-	memcpy(dst + curr_off, src + curr_off, size - curr_off);
+	data_race(memcpy(dst + curr_off, src + curr_off, size - curr_off));
 }
 
 static inline void copy_map_value(struct bpf_map *map, void *dst, void *src)

---
base-commit: bd5f485f3f026225b86573e559af0b7254ef4184
change-id: 20260819-bpf-kcsan-obj-memcpy-67042b1fce7d

Best regards,
--  
quanyeyang <quanyeyang@proton.me>

