From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 28 Aug 2024 12:41:56 +0800
Subject: [PATCH v4] linux: Add linux statx(fd, NULL, AT_EMPTY_PATH) support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-statx-null-path-v4-1-33872399b15f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJOqzmYC/2WNywqDMBQFf0Wy7i1JjNV21f8oXVzz0IAvkjRYx
 H9vFAqCyzkwcxbitbPak0e2EKej9XYcEohLRmSLQ6PBqsSEUy5oxRn4gGGG4dN1MGFoociZpGV
 Z1DUKkqzJaWPnvfh6J26tD6P77geRb+u/xU+tyIGBMaXQShmGnD2bHm13lWNPtlbMj3519vPk3
 wyVWuEdK8Sjv67rD3OluffuAAAA
To: libc-alpha@sourceware.org
Cc: Adhemerval Zanella <adhemerval.zanella@linaro.org>, 
 Joseph Myers <josmyers@redhat.com>, Xi Ruoyao <xry111@xry111.site>, 
 =?utf-8?q?W=C3=81NG_Xu=C4=9Bru=C3=AC?= <kernel@xen0n.name>, 
 Adhemerval Zanella Netto <adhemerval.zanella@linaro.org>, 
 b4-sent@lore.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=5540;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=SBCCwRaFod3c+EjxBGhGs2MVsg8sC25sdmvpJVoZLHw=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmzqqUno1aP7FYMEiukf2viH1alSwEAUYRZ71cU
 I4MeNwNFDSJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZs6qlAAKCRCwMePKe/7Z
 bo9QD/9Lg6rpyRuj2VtB8F1t9liIw/GccXJJzz06MIzUrpDEF9NIxBI7ebftQEhVEEA3lpWfzAC
 /gK+kuvwAgbHEWZ2XqVxP8+4p33v4Q3yRuS9dHtBLAdygV7PJavVy9yRG2PIHfieqbIMKijLKXm
 gaUwoc10ja/4z5lcafGlPPmF6a3yEwWBfmZS+uQ3/MsbQZxehclhRCQ69K7wegIeoX694vjRX1R
 hGgKqSKyS/p1EAvB4CFdlCI/bvfVGjV2VsGMsTsD6W25HKeMvJaUWGjQBB2gv3uhQi0FRH2o2E4
 WGc4jNI7m+mo4pn+9TIU9e6FqNfQm6lZkcRsatMx1g1ODLltGNYMr6PcizwLkr6CpWKQgk3MtwP
 1ZjhQtZMI93BmHXLXe9rpMj3bylAT0BmTPzfRgQ0ALLVB8u3EOMlA2NvtOFhtt09015GsPkv2xc
 oJmno/X7aHiBafmomOnnzqv+YG7Wo5xuLfvvoyODn7zz0lfpz72H6Mb8XBEjbX2EylDls0N6VOS
 YJaeg9c5AefOHaqWzmL0TeiF1kafV63dm4XBpiAAxzh8Ve7n8NE+xYF2ipmkLCmmUxCX03WfHyV
 JyTIgjLwIvkkXc3eqz/z/B5vFlIBZHexwDmkYCi9CIG18jZmj2DFq+i0+/7PpU9QhVFqQnxxE8w
 tA92a9dmEqgVIyg==
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
 sysdeps/unix/sysv/linux/fstatat64.c       |  8 ++++++--
 sysdeps/unix/sysv/linux/fxstat64.c        | 12 ++++++------
 sysdeps/unix/sysv/linux/internal-stat.h   | 27 +++++++++++++++++++++++++++
 sysdeps/unix/sysv/linux/kernel-features.h |  5 +++++
 4 files changed, 44 insertions(+), 8 deletions(-)

diff --git a/sysdeps/unix/sysv/linux/fstatat64.c b/sysdeps/unix/sysv/linux/fstatat64.c
index da496177c9..b67a5f4469 100644
--- a/sysdeps/unix/sysv/linux/fstatat64.c
+++ b/sysdeps/unix/sysv/linux/fstatat64.c
@@ -47,8 +47,12 @@ fstatat64_time64_statx (int fd, const char *file, struct __stat64_t64 *buf,
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
index 9334059765..263e29637f 100644
--- a/sysdeps/unix/sysv/linux/internal-stat.h
+++ b/sysdeps/unix/sysv/linux/internal-stat.h
@@ -29,3 +29,30 @@
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
+  static int statx_null_path_supported = 1;
+  int r;
+  int supported = atomic_load_relaxed (&statx_null_path_supported);
+  if (__glibc_likely (supported))
+    {
+      r = INTERNAL_SYSCALL_CALL (statx, fd, NULL, flag, STATX_BASIC_STATS, buf);
+      if (r != -EFAULT)
+	return r;
+      atomic_store_relaxed (&statx_null_path_supported, 0);
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

