From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 21 Aug 2024 21:03:54 +0800
Subject: [PATCH v3 2/2] linux: Add linux statx(fd, NULL, AT_EMPTY_PATH)
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240821-loong-fstat-v3-2-0df9bd4f7ca6@gmail.com>
References: <20240821-loong-fstat-v3-0-0df9bd4f7ca6@gmail.com>
In-Reply-To: <20240821-loong-fstat-v3-0-0df9bd4f7ca6@gmail.com>
To: libc-alpha@sourceware.org
Cc: Adhemerval Zanella <adhemerval.zanella@linaro.org>, 
 Joseph Myers <josmyers@redhat.com>, Xi Ruoyao <xry111@xry111.site>, 
 b4-sent@lore.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=5366;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=bxAtOdV2CcsHsYYlt1CZeGdi2yu2ZKIGWtpRN5Dm2bE=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmxeW6ARcX1QihOA2us2my54AG1BRxD8jmLebnt
 CvB2phVkU6JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZsXlugAKCRCwMePKe/7Z
 bgQgD/4+84CjQofUuuGH0G19E7CTEQ8sbjn6WHjDVhZh18gkAyyJbIh1zsRkbBM2pznYVf93vkO
 W+T0kVWR6hEhJDAFHDYYRpZzk1QkpR1GXpMf7rbIDln3tTBpGNV9fynF0W7P6OuW1qI69Iy0azl
 1C7W7yRwvv1cYJChLenzdMeHlLefk29gffsP/ZG0HozTTRUz3PQyxARX9A4huumk4FaISzhBfCY
 BNmEVUYpI3IJvTdYItaA8dBobynomNxGr4CKIXqFTOASN63stB5VyuXutFSOtZy43r40CmwhOeL
 WXXL5Zc9Lk/ms9F0nx85VYyJPyhlBnkHIuRlV/87W8YngMmSloxDSQOkZMmRBKaXnOHun2SJfbu
 xY6d9o++IY5Ehggf/l91If1cq4SHcLRZo/guj/jYNAVuA6+A5svB0XT4qOW3mEyfIzY9FcntWxA
 u0bT7vcorL3PtP1nWpZ62ip1OL4OQglBTHXPaRq/bzEHWt2KzgKfNkGHOGCM9aSyjPWqx/umBjr
 9Z81T+/145vEr/tm4X8TZmfQW5WZ3Ny86uIrw/Ef0la8hDyOGKvMRD3fRt+NiHRHyEr693Y94Se
 mpd1SXxmDrUYv03KYHhABtIr9xWR4lkCp/SQrjPxXlxV3f96h6Lx+p4b/okmRmaohDDPz6hq3tZ
 0c2mOgRZptzZidw==
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
 sysdeps/unix/sysv/linux/fstatat64.c        |  9 +++--
 sysdeps/unix/sysv/linux/fxstat64.c         |  4 +--
 sysdeps/unix/sysv/linux/kernel-features.h  |  5 +++
 sysdeps/unix/sysv/linux/statx_empty_path.h | 53 ++++++++++++++++++++++++++++++
 4 files changed, 67 insertions(+), 4 deletions(-)

diff --git a/sysdeps/unix/sysv/linux/fstatat64.c b/sysdeps/unix/sysv/linux/fstatat64.c
index da496177c9..5b5ce7d9b5 100644
--- a/sysdeps/unix/sysv/linux/fstatat64.c
+++ b/sysdeps/unix/sysv/linux/fstatat64.c
@@ -39,6 +39,7 @@ _Static_assert (sizeof (__blkcnt_t) == sizeof (__blkcnt64_t),
 #endif
 
 #if FSTATAT_USE_STATX
+#include <statx_empty_path.h>
 
 static inline int
 fstatat64_time64_statx (int fd, const char *file, struct __stat64_t64 *buf,
@@ -47,8 +48,12 @@ fstatat64_time64_statx (int fd, const char *file, struct __stat64_t64 *buf,
   /* 32-bit kABI with default 64-bit time_t, e.g. arc, riscv32.   Also
      64-bit time_t support is done through statx syscall.  */
   struct statx tmp;
-  int r = INTERNAL_SYSCALL_CALL (statx, fd, file, AT_NO_AUTOMOUNT | flag,
-				 STATX_BASIC_STATS, &tmp);
+  int r;
+  if ((flag & AT_EMPTY_PATH) && (file == NULL || *file == '\0'))
+    r = __statx_empty_path (fd, AT_NO_AUTOMOUNT | flag, &tmp);
+  else
+    r = INTERNAL_SYSCALL_CALL (statx, fd, file, AT_NO_AUTOMOUNT | flag,
+			      STATX_BASIC_STATS, &tmp);
   if (r != 0)
     return r;
 
diff --git a/sysdeps/unix/sysv/linux/fxstat64.c b/sysdeps/unix/sysv/linux/fxstat64.c
index 230374cb22..9ed4530ca8 100644
--- a/sysdeps/unix/sysv/linux/fxstat64.c
+++ b/sysdeps/unix/sysv/linux/fxstat64.c
@@ -25,6 +25,7 @@
 #include <xstatconv.h>
 #include <statx_cp.h>
 #include <shlib-compat.h>
+#include <statx_empty_path.h>
 
 #if LIB_COMPAT(libc, GLIBC_2_0, GLIBC_2_33)
 
@@ -53,8 +54,7 @@ ___fxstat64 (int vers, int fd, struct stat64 *buf)
 # else
   /* New 32-bit kABIs with only 64-bit time_t support, e.g. arc, riscv32.  */
   struct statx tmp;
-  int r = INLINE_SYSCALL_CALL (statx, fd, "", AT_EMPTY_PATH,
-			       STATX_BASIC_STATS, &tmp);
+  int r = __statx_empty_path (fd, AT_EMPTY_PATH, &tmp);
   if (r == 0)
     __cp_stat64_statx (buf, &tmp);
   return r;
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
diff --git a/sysdeps/unix/sysv/linux/statx_empty_path.h b/sysdeps/unix/sysv/linux/statx_empty_path.h
new file mode 100644
index 0000000000..7c82311ffc
--- /dev/null
+++ b/sysdeps/unix/sysv/linux/statx_empty_path.h
@@ -0,0 +1,53 @@
+/* Linux statx(fd, NULL, AT_EMPTY_PATH) support
+   Copyright (C) 2024 Free Software Foundation, Inc.
+   This file is part of the GNU C Library.
+
+   The GNU C Library is free software; you can redistribute it and/or
+   modify it under the terms of the GNU Lesser General Public
+   License as published by the Free Software Foundation; either
+   version 2.1 of the License, or (at your option) any later version.
+
+   The GNU C Library is distributed in the hope that it will be useful,
+   but WITHOUT ANY WARRANTY; without even the implied warranty of
+   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
+   Lesser General Public License for more details.
+
+   You should have received a copy of the GNU Lesser General Public
+   License along with the GNU C Library; if not, see
+   <https://www.gnu.org/licenses/>.  */
+
+#include <sys/stat.h>
+#include <internal-stat.h>
+#include <kernel_stat.h>
+#include <sysdep.h>
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
+      if (__glibc_likely(supported == 1))
+	return r;
+      if (r != -EFAULT)
+	{
+	  if (r == 0)
+            atomic_store_relaxed (&statx_null_path_supported, 1);
+	  return r;
+	}
+      atomic_store_relaxed (&statx_null_path_supported, 0);
+    }
+  return INTERNAL_SYSCALL_CALL (statx, fd, "", flag, STATX_BASIC_STATS, buf);
+#endif
+}
+
+#endif

-- 
2.43.0

