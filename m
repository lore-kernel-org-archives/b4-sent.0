From: Miao Wang <shankerwangmiao@gmail.com>
Date: Thu, 29 Aug 2024 00:11:49 +0800
Subject: [PATCH v5] linux: Add linux statx(fd, NULL, AT_EMPTY_PATH) support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240829-statx-null-path-v5-1-5356c9c35c7e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAERMz2YC/4XNQQqDMBCF4atI1k0xk9hoV71H6WI0iQasikmDR
 bx7o1CQuujyDXz/zMTp0WpHrslMRh2ss30XR3ZKSNVgV2tqVdwEUhBpDow6j36i3att6YC+oRl
 nVSplVpYoSFTDqI2dtuL9EXdjne/H9/YgwHr9tuDQCkAZNUYKrZRhCOxWP9G256p/krUV+N7nR
 8+jv5i00goLzBF/vfjjRfSc5xJ4UZQsM3u/LMsHKqkmMi4BAAA=
To: libc-alpha@sourceware.org
Cc: Adhemerval Zanella <adhemerval.zanella@linaro.org>, 
 Joseph Myers <josmyers@redhat.com>, Xi Ruoyao <xry111@xry111.site>, 
 =?utf-8?q?W=C3=81NG_Xu=C4=9Bru=C3=AC?= <kernel@xen0n.name>, 
 Adhemerval Zanella Netto <adhemerval.zanella@linaro.org>, 
 b4-sent@lore.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=6142;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=4LuRsod0489x9sMUlS1cFBTSUhYhIW/pzYkGuxn5Oek=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmz0xHdoYIrkhLJ0bu9w08Jc0S+s+IMRap2m1jD
 v89ZM0lW3WJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZs9MRwAKCRCwMePKe/7Z
 bjUnD/4oskMF4kFCD3dscLIyJ0TbdBJP61s6oHTKZ0uvvJd6kgFx5KrYkIdkU+XH+IZuHAkQn8f
 SL3Lsbq5Nc4ijfXSR7wlEeTRlpzbE1fKp0lU/N2QA2hF402EChmn55fkr45K2vYZxCKsAvT0bqM
 oQ/B+g3V/PCsF4UOz/it9LPihyS3PW+xN4QG77lT4wUn1Jswg7T/8yJsBg2TtVDZJtNuz+sFU29
 zRXk0OCFGJPt9Qu1BMKYlN3kc26M4Ic1C+UcDg+bPqemlQnhtWiBPX4wd66wub9iMHHZ4szTiRo
 gfV4HsYoewz9/LuANcRgSQcC0oWibzvvvNrl7AcmY2iFPDc/5TiDomBlv+RNfqB3qS0NDQHzrYH
 hsf5breLqnU2yEw5Ntgy7f/7ElNDnQosK+TTVV7DE6IXzTQ2AB7A/5t6iaUQo1J/1NnErtCzjzG
 8Q3FXm7Aw1s2s2hT7YyAmt06pcnQfB7b52fb5HqpiVH8N/GaMFIAl5mHWGrZe6lL3eAXX4H0aOf
 zpsp68Kqy+PjWctDitnNGUajLox7J5HZoIWXXCoyophrS/c9dfdbL3VMJOe12rhpefpc8XGOphd
 Ec2PH6+1H89sqyYq78uR6dV4T05tjoyJnumMbxP1c/j6+Smv1uGqiZpQ7+E0xu36hd/dALMApvR
 NHoqxPE2kAeMogQ==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Linux supports passing NULL instead of an empty string as the second
parameter when AT_EMPTY_PATH is set in the flags, starting from 6.11,
which brings a performance gain since it is much more efficient to
detect a NULL parameter than to detect an empty string in the kernel.
We utilize this feature if statx is used for fstat, when glibc is
compiled to target kernel versions afterwards, and dynamically probe
the kernel support of it, when targeting previous versions.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Kernel 6.11 adds support for passing NULL to statx(fd, NULL,
AT_EMPTY_PATH), which improves the performance. This series utilize this
feature when statx is used to implement fstat, on some 32-bit platforms
and on loongarch with targeting kernel version below 6.10.6.
---
Changes in v5:
- Use a hidden global varible to store if statx(... NULL ...) is
  supported.
- Link to v4: https://sourceware.org/pipermail/libc-alpha/2024-August/159479.html

Changes in v4:
- Give up tri-state flag implementation and adopt a binary flag.
- Link to v3: https://sourceware.org/pipermail/libc-alpha/2024-August/159468.html

Changes in v3:
- Fixed build error and failure to set errno in fxstat64.
- Utilize tri-state supported flag to eliminate possible data read
  barrier instructions after whether it is supported is determined.
- Link to v2: https://sourceware.org/pipermail/libc-alpha/2024-August/159336.html

Changes in v2:
- Separate this patch out from the series.
- Put the added __statx_empty_path() into internal-stat.h.
- Minor fixes according as suggested by Ruoyao.
- Link to v1: https://sourceware.org/pipermail/libc-alpha/2024-August/159333.html
---
 sysdeps/unix/sysv/linux/fstatat64.c       | 14 ++++++++++++--
 sysdeps/unix/sysv/linux/fxstat64.c        | 12 ++++++------
 sysdeps/unix/sysv/linux/internal-stat.h   | 28 ++++++++++++++++++++++++++++
 sysdeps/unix/sysv/linux/kernel-features.h |  5 +++++
 4 files changed, 51 insertions(+), 8 deletions(-)

diff --git a/sysdeps/unix/sysv/linux/fstatat64.c b/sysdeps/unix/sysv/linux/fstatat64.c
index da496177c9..59b461cbcf 100644
--- a/sysdeps/unix/sysv/linux/fstatat64.c
+++ b/sysdeps/unix/sysv/linux/fstatat64.c
@@ -38,6 +38,12 @@ _Static_assert (sizeof (__blkcnt_t) == sizeof (__blkcnt64_t),
                 "__blkcnt_t and __blkcnt64_t must match");
 #endif
 
+#if FSTATAT_USE_STATX || XSTAT_IS_XSTAT64
+# ifndef __ASSUME_STATX_NULL_PATH
+int __statx_null_path_supported attribute_hidden = 1;
+# endif
+#endif
+
 #if FSTATAT_USE_STATX
 
 static inline int
@@ -47,8 +53,12 @@ fstatat64_time64_statx (int fd, const char *file, struct __stat64_t64 *buf,
   /* 32-bit kABI with default 64-bit time_t, e.g. arc, riscv32.   Also
      64-bit time_t support is done through statx syscall.  */
   struct statx tmp;
-  int r = INTERNAL_SYSCALL_CALL (statx, fd, file, AT_NO_AUTOMOUNT | flag,
-				 STATX_BASIC_STATS, &tmp);
+  flag |= AT_NO_AUTOMOUNT;
+  int r;
+  if ((flag & AT_EMPTY_PATH) && (file == NULL || *file == '\0'))
+    r = __statx_empty_path (fd, flag, &tmp);
+  else
+    r = INTERNAL_SYSCALL_CALL (statx, fd, file, flag, STATX_BASIC_STATS, &tmp);
   if (r != 0)
     return r;
 
diff --git a/sysdeps/unix/sysv/linux/fxstat64.c b/sysdeps/unix/sysv/linux/fxstat64.c
index 230374cb22..bbe52de36d 100644
--- a/sysdeps/unix/sysv/linux/fxstat64.c
+++ b/sysdeps/unix/sysv/linux/fxstat64.c
@@ -20,7 +20,7 @@
 #include <sys/stat.h>
 #undef __fxstat
 #include <fcntl.h>
-#include <kernel_stat.h>
+#include <internal-stat.h>
 #include <sysdep.h>
 #include <xstatconv.h>
 #include <statx_cp.h>
@@ -53,11 +53,11 @@ ___fxstat64 (int vers, int fd, struct stat64 *buf)
 # else
   /* New 32-bit kABIs with only 64-bit time_t support, e.g. arc, riscv32.  */
   struct statx tmp;
-  int r = INLINE_SYSCALL_CALL (statx, fd, "", AT_EMPTY_PATH,
-			       STATX_BASIC_STATS, &tmp);
-  if (r == 0)
-    __cp_stat64_statx (buf, &tmp);
-  return r;
+  int r = __statx_empty_path (fd, 0, &tmp);
+  if (INTERNAL_SYSCALL_ERROR_P (r))
+    return INLINE_SYSCALL_ERROR_RETURN_VALUE (-r);
+  __cp_stat64_statx (buf, &tmp);
+  return 0;
 # endif
 #else
   /* All kABIs with non-LFS support, e.g. arm, csky, i386, hppa, m68k,
diff --git a/sysdeps/unix/sysv/linux/internal-stat.h b/sysdeps/unix/sysv/linux/internal-stat.h
index 9334059765..acaa11e21d 100644
--- a/sysdeps/unix/sysv/linux/internal-stat.h
+++ b/sysdeps/unix/sysv/linux/internal-stat.h
@@ -29,3 +29,31 @@
 #else
 # define FSTATAT_USE_STATX 0
 #endif
+
+#if FSTATAT_USE_STATX || XSTAT_IS_XSTAT64
+
+/* buf MUST be a valid buffer, or the feature detection may not work properly */
+
+static inline int
+__statx_empty_path (int fd, int flag, struct statx *buf)
+{
+  flag |= AT_EMPTY_PATH;
+#ifdef __ASSUME_STATX_NULL_PATH
+  return INTERNAL_SYSCALL_CALL (statx, fd, NULL, flag, STATX_BASIC_STATS, buf);
+#else
+  /* Defined in fstatat64.c.  */
+  extern int __statx_null_path_supported attribute_hidden;
+  int r;
+  int supported = atomic_load_relaxed (&__statx_null_path_supported);
+  if (__glibc_likely (supported))
+    {
+      r = INTERNAL_SYSCALL_CALL (statx, fd, NULL, flag, STATX_BASIC_STATS, buf);
+      if (r != -EFAULT)
+	return r;
+      atomic_store_relaxed (&__statx_null_path_supported, 0);
+    }
+  return INTERNAL_SYSCALL_CALL (statx, fd, "", flag, STATX_BASIC_STATS, buf);
+#endif
+}
+
+#endif
diff --git a/sysdeps/unix/sysv/linux/kernel-features.h b/sysdeps/unix/sysv/linux/kernel-features.h
index a25cf07e9f..78aaf43a82 100644
--- a/sysdeps/unix/sysv/linux/kernel-features.h
+++ b/sysdeps/unix/sysv/linux/kernel-features.h
@@ -257,4 +257,9 @@
 # define __ASSUME_FCHMODAT2 0
 #endif
 
+/* statx(fd, NULL, AT_EMPTY_PATH) was introduced in Linux 6.11. */
+#if __LINUX_KERNEL_VERSION >= 0x060b00
+# define __ASSUME_STATX_NULL_PATH 1
+#endif
+
 #endif /* kernel-features.h */

---
base-commit: 2eee835eca960c9d4119279804214b7a1ed5d156
change-id: 20240821-statx-null-path-531c0775bba4

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

