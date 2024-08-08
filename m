From: Koakuma <koachan@protonmail.com>
Date: Thu, 08 Aug 2024 09:05:00 +0700
Subject: [PATCH v2] sparc/vdso: Add helper function for 64-bit right shift
 on 32-bit target
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240808-sparc-shr64-v2-1-fd18f1b2cea9@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAMsntGYC/1XMQQ6CMBCF4auQWVszLYUWV97DsGhqkUmEkikhG
 tK7W3Hl8n/J+3ZIgSkkuFQ7cNgoUZxLqFMFfnTzIwi6lwaFSqORRqTFsRdp5FYLNSA6Y602BqE
 8Fg4DvQ7t1pceKa2R3we+ye/6cyzqP2eTQgrVYINda+u6c9eF4xrnydHz7OMEfc75A6nfi5OrA
 AAA
To: "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, Andy Lutomirski <luto@kernel.org>, 
 Thomas Gleixner <tglx@linutronix.de>, 
 Vincenzo Frascino <vincenzo.frascino@arm.com>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>
Cc: sparclinux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 llvm@lists.linux.dev, Koakuma <koachan@protonmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723082700; l=3512;
 i=koachan@protonmail.com; s=20240620; h=from:subject:message-id;
 bh=Si3c44/d6jXgPlqHAyYiaOjLlLDe1/nmaPBaKpcPsPo=;
 b=kN78zuvs/mL6hPLposgcU9M29S3E9kBq3BS+8FzltzlrdxSTJDNeaDNDLou81Sqo6m93sqG47
 MEVfcgCRTcJAQlIIHmzdXbKSV8zMnEkOycj+RuqbwOfStGRK4FjLCgw
X-Developer-Key: i=koachan@protonmail.com; a=ed25519;
 pk=UA59FS3yiAA1cnAAUZ1rehTmr6skh95PgkNRBLcoKCg=
X-Endpoint-Received: by B4 Relay for koachan@protonmail.com/20240620 with auth_id=174
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add helper function for 64-bit right shift on 32-bit target so that
clang does not emit a runtime library call.

Signed-off-by: Koakuma <koachan@protonmail.com>
---
Hi~

This adds a small function to do 64-bit right shifts for use in vDSO
code, needed so that clang does not emit a call to runtime library.
---
Changes in v2:
- Move __shr64 to sparc code since there are no other users of it.
- Now that __shr64 is not in portable code, redo it in inline asm for simpler implementation & better performance.
- Link to v1: https://lore.kernel.org/r/20240804-sparc-shr64-v1-1-25050968339a@protonmail.com
---
 arch/sparc/vdso/vclock_gettime.c | 28 ++++++++++++++++++++++++----
 1 file changed, 24 insertions(+), 4 deletions(-)

diff --git a/arch/sparc/vdso/vclock_gettime.c b/arch/sparc/vdso/vclock_gettime.c
index e794edde6755..79607804ea1b 100644
--- a/arch/sparc/vdso/vclock_gettime.c
+++ b/arch/sparc/vdso/vclock_gettime.c
@@ -86,6 +86,11 @@ notrace static long vdso_fallback_gettimeofday(struct __kernel_old_timeval *tv,
 }
 
 #ifdef	CONFIG_SPARC64
+notrace static __always_inline u64 __shr64(u64 val, int amt)
+{
+	return val >> amt;
+}
+
 notrace static __always_inline u64 vread_tick(void)
 {
 	u64	ret;
@@ -102,6 +107,21 @@ notrace static __always_inline u64 vread_tick_stick(void)
 	return ret;
 }
 #else
+notrace static __always_inline u64 __shr64(u64 val, int amt)
+{
+	u64 ret;
+
+	__asm__ __volatile__("sllx %H1, 32, %%g1\n\t"
+			     "srl %L1, 0, %L1\n\t"
+			     "or %%g1, %L1, %%g1\n\t"
+			     "srlx %%g1, %2, %L0\n\t"
+			     "srlx %L0, 32, %H0"
+			     : "=r" (ret)
+			     : "r" (val), "r" (amt)
+			     : "g1");
+	return ret;
+}
+
 notrace static __always_inline u64 vread_tick(void)
 {
 	register unsigned long long ret asm("o4");
@@ -154,7 +174,7 @@ notrace static __always_inline int do_realtime(struct vvar_data *vvar,
 		ts->tv_sec = vvar->wall_time_sec;
 		ns = vvar->wall_time_snsec;
 		ns += vgetsns(vvar);
-		ns >>= vvar->clock.shift;
+		ns = __shr64(ns, vvar->clock.shift);
 	} while (unlikely(vvar_read_retry(vvar, seq)));
 
 	ts->tv_sec += __iter_div_u64_rem(ns, NSEC_PER_SEC, &ns);
@@ -174,7 +194,7 @@ notrace static __always_inline int do_realtime_stick(struct vvar_data *vvar,
 		ts->tv_sec = vvar->wall_time_sec;
 		ns = vvar->wall_time_snsec;
 		ns += vgetsns_stick(vvar);
-		ns >>= vvar->clock.shift;
+		ns = __shr64(ns, vvar->clock.shift);
 	} while (unlikely(vvar_read_retry(vvar, seq)));
 
 	ts->tv_sec += __iter_div_u64_rem(ns, NSEC_PER_SEC, &ns);
@@ -194,7 +214,7 @@ notrace static __always_inline int do_monotonic(struct vvar_data *vvar,
 		ts->tv_sec = vvar->monotonic_time_sec;
 		ns = vvar->monotonic_time_snsec;
 		ns += vgetsns(vvar);
-		ns >>= vvar->clock.shift;
+		ns = __shr64(ns, vvar->clock.shift);
 	} while (unlikely(vvar_read_retry(vvar, seq)));
 
 	ts->tv_sec += __iter_div_u64_rem(ns, NSEC_PER_SEC, &ns);
@@ -214,7 +234,7 @@ notrace static __always_inline int do_monotonic_stick(struct vvar_data *vvar,
 		ts->tv_sec = vvar->monotonic_time_sec;
 		ns = vvar->monotonic_time_snsec;
 		ns += vgetsns_stick(vvar);
-		ns >>= vvar->clock.shift;
+		ns = __shr64(ns, vvar->clock.shift);
 	} while (unlikely(vvar_read_retry(vvar, seq)));
 
 	ts->tv_sec += __iter_div_u64_rem(ns, NSEC_PER_SEC, &ns);

---
base-commit: defaf1a2113a22b00dfa1abc0fd2014820eaf065
change-id: 20240717-sparc-shr64-2f00a7884770

Best regards,
-- 
Koakuma <koachan@protonmail.com>

