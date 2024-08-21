From: Miao Wang <shankerwangmiao@gmail.com>
Date: Thu, 22 Aug 2024 00:14:39 +0800
Subject: [PATCH v2] linux: Add linux statx(fd, NULL, AT_EMPTY_PATH) support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240822-statx-null-path-v2-1-ff74eddf1a21@gmail.com>
X-B4-Tracking: v=1; b=H4sIAG4SxmYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIxMDCyND3eKSxJIK3bzSnBzdgsSSDF1TY8NkA3Nz06SkRBMloK6CotS0zAq
 widGxtbUAy/04iWEAAAA=
To: libc-alpha@sourceware.org
Cc: Adhemerval Zanella <adhemerval.zanella@linaro.org>, 
 Joseph Myers <josmyers@redhat.com>, Xi Ruoyao <xry111@xry111.site>, 
 =?utf-8?q?W=C3=81NG_Xu=C4=9Bru=C3=AC?= <kernel@xen0n.name>, 
 b4-sent@lore.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=4680;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=ctnRlx3S3xQwUe8WF84yoJaLt7Txice/vv8m5L/Cvk4=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmxhJxkuDUe4Mn0P1QaDTuHxR7P4Hg/SfXlKvS0
 9403yRgxyiJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZsYScQAKCRCwMePKe/7Z
 bsM5D/9EgibgPVWnF5KcdutqaCpCgcjVR5G0PAcWV9372o4Ey6lRlkgV+zbskImdbn+VXdAfFT+
 O2xHjtwCTGaD927brSUewO9bmLKpeZqxpwbIr+qx+AMwNo8BgoYrCIO8X98lS0hwtfZCavt90GH
 mV/LBb7DIXlUS//KOLEavIIbFw9ov4I9osmltjcnW0RD0BXBdQGRdgDtYyNHTmXxKEet8V3HcXo
 6VSOOMjm1wTUMumD2zcizG2SS5Jru8XmSFmHS8GqOMw/tO5wqQXHX/peUabNcbJOc1ItnLUhnsg
 q40P0XyO530Fcz5ZQcP0PuFsP9M/ca3sczfzkxdzbq16a//u/k4nH6KBIdC7FbWAn4xODm+a/96
 Ll//ORUnIswH4Ig/O2sOdq7ALBRbzB+oHporugVxusX5ubyIv2m3rlGrsTbX+o6SwOJdkOomqVN
 0ihemaclHwrZmGaaZLh5pw/Ep+G2vhk0SPMDT0Gt+ZH+yF+vJGeS3YmxEIQzS204UNAuTQWSXyu
 qzKgEXCtakC9+34wQTXLjptnWrki9OssumAaONYWFqGRmLo3Xp422m9pS+01cH+8RqaQxBBL2hS
 Q/FbNcyeby0QmupvqmWWiF2yqYqgcINhN5yTugLdMfgVvhG0GYL1ZP8/oWFcLfT8EFNokDsz1BY
 4iU/IoB3AmDCK5A==
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
Changes in v2:
- Separate this patch out from the series.
- Put the added __statx_empty_path() into internal-stat.h.
- Minor fixes according as suggested by Ruoyao.
- Link to v1: https://sourceware.org/pipermail/libc-alpha/2024-August/159333.html
---
 sysdeps/unix/sysv/linux/fstatat64.c       |  8 ++++++--
 sysdeps/unix/sysv/linux/fxstat64.c        |  3 +--
 sysdeps/unix/sysv/linux/internal-stat.h   | 31 +++++++++++++++++++++++++++++++
 sysdeps/unix/sysv/linux/kernel-features.h |  5 +++++
 4 files changed, 43 insertions(+), 4 deletions(-)

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
index 230374cb22..2ece683992 100644
--- a/sysdeps/unix/sysv/linux/fxstat64.c
+++ b/sysdeps/unix/sysv/linux/fxstat64.c
@@ -53,8 +53,7 @@ ___fxstat64 (int vers, int fd, struct stat64 *buf)
 # else
   /* New 32-bit kABIs with only 64-bit time_t support, e.g. arc, riscv32.  */
   struct statx tmp;
-  int r = INLINE_SYSCALL_CALL (statx, fd, "", AT_EMPTY_PATH,
-			       STATX_BASIC_STATS, &tmp);
+  int r = __statx_empty_path (fd, 0, &tmp);
   if (r == 0)
     __cp_stat64_statx (buf, &tmp);
   return r;
diff --git a/sysdeps/unix/sysv/linux/internal-stat.h b/sysdeps/unix/sysv/linux/internal-stat.h
index 9334059765..ee30cb1bd6 100644
--- a/sysdeps/unix/sysv/linux/internal-stat.h
+++ b/sysdeps/unix/sysv/linux/internal-stat.h
@@ -29,3 +29,34 @@
 #else
 # define FSTATAT_USE_STATX 0
 #endif
+
+#if FSTATAT_USE_STATX || XSTAT_IS_XSTAT64
+
+static inline int
+__statx_empty_path (int fd, int flag, struct statx *buf)
+{
+  flag |= AT_EMPTY_PATH;
+#ifdef __ASSUME_STATX_NULL_PATH
+  return INTERNAL_SYSCALL_CALL (statx, fd, NULL, flag, STATX_BASIC_STATS, buf);
+#else
+  static int statx_null_path_supported = -1;
+  int r;
+  int supported = atomic_load_relaxed (&statx_null_path_supported);
+  if (supported != 0)
+    {
+      r = INTERNAL_SYSCALL_CALL (statx, fd, NULL, flag, STATX_BASIC_STATS, buf);
+      if (__glibc_likely (supported == 1))
+	return r;
+      if (r != -EFAULT)
+	{
+	  if (r == 0)
+	    atomic_store_relaxed (&statx_null_path_supported, 1);
+	  return r;
+	}
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

