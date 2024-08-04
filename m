From: Koakuma <koachan@protonmail.com>
Date: Sun, 04 Aug 2024 10:39:49 +0700
Subject: [PATCH] sparc/vdso: Add helper function for 64-bit right shift on
 32-bit target
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240804-sparc-shr64-v1-1-25050968339a@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAT4rmYC/x3MMQqAMAxA0atIZgtpKUa8ijgUjZpFSwIilN7d4
 viG/wsYq7DB1BVQfsTkvhp838F6putgJ1szBAwRyZOznHR1duoQXdgRE41jJEJoRVbe5f1v81L
 rB4OsFpBdAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722742843; l=3316;
 i=koachan@protonmail.com; s=20240620; h=from:subject:message-id;
 bh=5vLiK7ELLqD1RRIEMvqkT4bYtvygqFoGLfpouZxp/Ns=;
 b=VGHa0DUmTa67NoKaZwaMHf2po7TjbodTym97uTjAmdtk/iY/OmPZTEI5cVbFiZWWBQBEJKWku
 Jhid1FM83fRAZ8JbZbH+jGYt7MRV1DsT9z8K7DrQRITNzWjcW7eIzDb
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
 arch/sparc/vdso/vclock_gettime.c |  8 ++++----
 include/vdso/math64.h            | 28 ++++++++++++++++++++++++++++
 2 files changed, 32 insertions(+), 4 deletions(-)

diff --git a/arch/sparc/vdso/vclock_gettime.c b/arch/sparc/vdso/vclock_gettime.c
index e794edde6755..c0251a632bdb 100644
--- a/arch/sparc/vdso/vclock_gettime.c
+++ b/arch/sparc/vdso/vclock_gettime.c
@@ -154,7 +154,7 @@ notrace static __always_inline int do_realtime(struct vvar_data *vvar,
 		ts->tv_sec = vvar->wall_time_sec;
 		ns = vvar->wall_time_snsec;
 		ns += vgetsns(vvar);
-		ns >>= vvar->clock.shift;
+		ns = __shr64(ns, vvar->clock.shift);
 	} while (unlikely(vvar_read_retry(vvar, seq)));
 
 	ts->tv_sec += __iter_div_u64_rem(ns, NSEC_PER_SEC, &ns);
@@ -174,7 +174,7 @@ notrace static __always_inline int do_realtime_stick(struct vvar_data *vvar,
 		ts->tv_sec = vvar->wall_time_sec;
 		ns = vvar->wall_time_snsec;
 		ns += vgetsns_stick(vvar);
-		ns >>= vvar->clock.shift;
+		ns = __shr64(ns, vvar->clock.shift);
 	} while (unlikely(vvar_read_retry(vvar, seq)));
 
 	ts->tv_sec += __iter_div_u64_rem(ns, NSEC_PER_SEC, &ns);
@@ -194,7 +194,7 @@ notrace static __always_inline int do_monotonic(struct vvar_data *vvar,
 		ts->tv_sec = vvar->monotonic_time_sec;
 		ns = vvar->monotonic_time_snsec;
 		ns += vgetsns(vvar);
-		ns >>= vvar->clock.shift;
+		ns = __shr64(ns, vvar->clock.shift);
 	} while (unlikely(vvar_read_retry(vvar, seq)));
 
 	ts->tv_sec += __iter_div_u64_rem(ns, NSEC_PER_SEC, &ns);
@@ -214,7 +214,7 @@ notrace static __always_inline int do_monotonic_stick(struct vvar_data *vvar,
 		ts->tv_sec = vvar->monotonic_time_sec;
 		ns = vvar->monotonic_time_snsec;
 		ns += vgetsns_stick(vvar);
-		ns >>= vvar->clock.shift;
+		ns = __shr64(ns, vvar->clock.shift);
 	} while (unlikely(vvar_read_retry(vvar, seq)));
 
 	ts->tv_sec += __iter_div_u64_rem(ns, NSEC_PER_SEC, &ns);
diff --git a/include/vdso/math64.h b/include/vdso/math64.h
index 22ae212f8b28..771d84faa8d7 100644
--- a/include/vdso/math64.h
+++ b/include/vdso/math64.h
@@ -21,6 +21,34 @@ __iter_div_u64_rem(u64 dividend, u32 divisor, u64 *remainder)
 	return ret;
 }
 
+#if BITS_PER_LONG == 32
+/* This is to prevent the compiler from emitting a call to __lshrdi3. */
+static __always_inline u64
+__shr64(u64 val, int amt)
+{
+	u32 mask = (1U << amt) - 1;
+	u32 lo = val;
+	u32 hi = val >> 32;
+	u32 mi;
+
+	if (amt >= 32)
+		return hi >> (amt - 32);
+
+
+	mi = (hi & mask) << (32 - amt);
+	hi >>= amt;
+	lo = (lo >> amt) | mi;
+
+	return ((u64) hi) << 32 | lo;
+}
+#else
+static __always_inline u64
+__shr64(u64 val, int amt)
+{
+	return val >> amt;
+}
+#endif /* BITS_PER_LONG == 32 */
+
 #if defined(CONFIG_ARCH_SUPPORTS_INT128) && defined(__SIZEOF_INT128__)
 
 #ifndef mul_u64_u32_add_u64_shr

---
base-commit: defaf1a2113a22b00dfa1abc0fd2014820eaf065
change-id: 20240717-sparc-shr64-2f00a7884770

Best regards,
-- 
Koakuma <koachan@protonmail.com>

