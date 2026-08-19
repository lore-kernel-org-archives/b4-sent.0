From: quanyeyang <quanyeyang@proton.me>
Date: Thu, 20 Aug 2026 00:10:06 +0800
Subject: [PATCH] bpf: Annotate bpf_obj_memcpy with data_race
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-bpf-kcsan-obj-memcpy-v1-1-372c59462268@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWTtJ2xhQrkJctMNUB0NpOmg0h
 LtbdfkW/2+gXIQV+maDwk9RWVKFPTRAN5+ujDJWgzOuNSd7xpAj3kl9wiVMOPNM+Y1tZ44u2Ej
 cjVDTXDjK67cdLn/rI0xM6/cF+/4BluprtHgAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787155807; l=4081;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=tfpKJW3phN1GEBcGG9Kq8oDiAg1lgr7Q83T4T+ixdto=;
 b=rlcxDG6+IEslaqJKQTJzaUYLrSrpDSUvq8CUp8S0yYJ3UdneWGKzlUiPJfkqLEPWrYXd5kpbE
 iG7CCA8orA/CyecI6e23BwrdxcdAv1aAMIQhDROhIhr9SGUp7foOXRB
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

syzbot reported KCSAN write-write races when two tasks concurrently
update the same map value. Both accesses reach the ordinary memcpy()
paths in bpf_obj_memcpy() through copy_map_value().

Unlocked map value updates are intentionally not serialized. Therefore,
a concurrent update may result in a torn value. Callers requiring
consistency must provide external synchronization or use BPF_F_LOCK
where supported. bpf_long_memcpy() already documents and annotates the
same behavior for long-aligned copies.

Annotate the ordinary memcpy() operations in bpf_obj_memcpy() with
data_race() as well. This documents the existing concurrency semantics
and prevents KCSAN from reporting these intentional races. It does not
add synchronization or change map update behavior.

Place the annotations at the memcpy() sites in the common helper, matching
bpf_long_memcpy(), without changing the existing copy helper interfaces.

Reported-by: syzbot+44044637ef892e79ca2b@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=44044637ef892e79ca2b
Signed-off-by: quanyeyang <quanyeyang@proton.me>
---
For this V1, the annotations are placed in the common
bpf_obj_memcpy() helper. This also covers callers that may already
provide synchronization. Restricting the annotations to known unlocked
callers would require propagating the concurrency context through the
copy_map_value() call chain or introducing separate copy helpers. I kept
the existing interfaces unchanged for V1 and would appreciate feedback
on whether a narrower annotation is preferred.

There are two classes of expected checkpatch warnings:

  - DATA_RACE is reported for the three annotations because checkpatch
    only recognizes an immediately adjacent comment. Their common
    rationale is documented once above bpf_obj_memcpy().
  - MISSING_FIXES_TAG is reported because the commit references
    syzkaller. No Fixes tag is included because this documents
    long-standing intentional lockless semantics rather than a
    regression introduced by a particular commit.
---
 include/linux/bpf.h | 17 +++++++++++++----
 1 file changed, 13 insertions(+), 4 deletions(-)

diff --git a/include/linux/bpf.h b/include/linux/bpf.h
index 7719f6528445..b37573b9d01d 100644
--- a/include/linux/bpf.h
+++ b/include/linux/bpf.h
@@ -560,7 +560,16 @@ static inline void bpf_long_memcpy(void *dst, const void *src, u32 size)
 		data_race(*ldst++ = *lsrc++);
 }
 
-/* copy everything but bpf_spin_lock, bpf_timer, and kptrs. There could be one of each. */
+/*
+ * Copy everything but bpf_spin_lock, bpf_timer, and kptrs. There could
+ * be one of each.
+ *
+ * Map value copies can race with unlocked updates from BPF programs or
+ * syscalls. Such copies are best effort and may be torn, so annotate the
+ * ordinary byte copies as intentional data races. Callers that require a
+ * consistent value must provide synchronization or use BPF_F_LOCK where
+ * supported.
+ */
 static inline void bpf_obj_memcpy(struct btf_record *rec,
 				  void *dst, void *src, u32 size,
 				  bool long_memcpy)
@@ -572,7 +581,7 @@ static inline void bpf_obj_memcpy(struct btf_record *rec,
 		if (long_memcpy)
 			bpf_long_memcpy(dst, src, round_up(size, 8));
 		else
-			memcpy(dst, src, size);
+			data_race(memcpy(dst, src, size));
 		return;
 	}
 
@@ -580,10 +589,10 @@ static inline void bpf_obj_memcpy(struct btf_record *rec,
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

