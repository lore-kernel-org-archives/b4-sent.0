From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 25 Sep 2024 00:37:50 +0800
Subject: [PATCH] io: statx, fstatat64: allow using NULL as path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240925-statx-null-path-user-v1-1-73e21e14c79e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAN3q8mYC/2XMSw6DIBSF4a0YxiXhIqi4lcYBj2sl8VVBY2Lce
 6kOOujwP8n5DhJw8RhInR1kwc0HP40p4JER2+nxhdS71IQzLpjikoao407Hte/prGNH1wRQy6x
 AY1zLwZJ0nRds/X6xz+buBd9r0uM9/vA6u+iKwx8tc7CsLKUxWtSb/MJGB6R2GgYf0xERq1yi1
 apgVjkBoHipKiY4CFNqQCcdyII05/kBf8OtBukAAAA=
To: libc-alpha@sourceware.org
Cc: Florian Weimer <fweimer@redhat.com>, 
 Adhemerval Zanella <adhemerval.zanella@linaro.org>, 
 Joseph Myers <josmyers@redhat.com>, Xi Ruoyao <xry111@xry111.site>, 
 =?utf-8?q?W=C3=81NG_Xu=C4=9Bru=C3=AC?= <kernel@xen0n.name>, 
 Adhemerval Zanella Netto <adhemerval.zanella@linaro.org>, 
 b4-sent@lore.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=7191;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=h3S3eC5ZEzW/pE5HYrcOSy9IPK3IpKQv+BHq6FhjlSs=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm8uribh0OwEoUAK5k7RmtGFcn17rMpvrrSV+31
 Ksex23VlzyJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZvLq4gAKCRCwMePKe/7Z
 budcEAC21aZE0f1IsCmNQ00m4nCiGbvdy3htJJBYnJbp2YDjtE7qCeLBqvADkZ7auvP3GuXSoQn
 xTWkXi50eB/Si928VcMY88d3hcHimz9AVNWWpYgJ0IuSuSVNmnlEO5WbHUx6bTNAozGwYpqgDmK
 608weJom0wfdBtxPykSUNJ3vEcgxdvZdsM2uz/1wgh+Nhazw924nFUTAv4dubD5zDm4jVWGIe+Q
 PftImkVlVEG9a2/8chUzDO/pBYuNtMbrqtTGV89c0Vtt+DnRq+ZmPs+IW8Eto1J+M9V2aJGJypM
 WPGYrs2A+R7xPlUdotMNOlYC1sVg75ECXNMPTLf0YpNU5GOZ7KoDblfWfCKLG9Kzyyhg0WKKaz1
 CA5T0GphEpuz0uT9WGRaRSflAphraaZBg7cmJ4odQgKDpW0W/bJ7dG63sSILIgIbqqvd31JRSra
 aJxEwp7JPZV8uNWrt1+AD8wdTYM6AjIvAPKOBQf5zWbeU7nZoTa4yymzVUJYx9CBRxSFgBO+NwL
 uQxDuAIztLw2VWJ3U13fidfK+7EoTcVI07GZVfGVyY7EZhl820nmNWC+mTxC3V942R3KX54Bnmx
 q2NfapyuirS+ndSwH0HtCC+sT9iRzPtyLX8xGscnf6AkHMPslW+vgUAE/BqOWMYpxEC5wQljWi6
 dL+R15T39YvhgTA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since linux 6.11, fstatat and statx syscalls allow using NULL as path
when AT_EMPTY_PATH is given. We also expose this to glibc users, and
change path to an empty string when this is not supported by the kernel.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Since kernel 6.11, statx/fstatat(..., NULL, AT_EMPTH_PATH...) are
supported for better performance by avoiding copying buffer data from
userland. Since currently the declaration of statx and fstatat flags
the path argument as nonull, it prevents users from utilizing this
kernel feature. I can come up with the following possible solutions:

1. Directly remove the nonull annotation on the path argument, and
   pass the parameter given by the user as-is to the kernel, exposing
   the kernel behavior. This would be confusing since on older kernels,
   the user would receive EFAULT and need to handle this.

2. Based on 1, but if the user provides NULL, the handling of EFAULT is
   integrated in glibc, who implicitly change the parameter to an empty
   string if EFAULT received.

In either case, I think there is no need to introduce a new ABI version
of statx() and fstatat(), since we are loosening the restriction on the
given parameters, and executables linked with previous versions of statx
and fstatat can still work after this change.

This RFC patch contains changes for the solution 2 above.
---
 io/bits/statx-generic.h             |  2 +-
 io/sys/stat.h                       | 10 +++++-----
 io/tst-statx.c                      |  6 ++++++
 sysdeps/mach/hurd/fstatat64.c       |  2 ++
 sysdeps/unix/sysv/linux/fstatat64.c | 12 ++++++++++++
 sysdeps/unix/sysv/linux/statx.c     |  7 ++++++-
 6 files changed, 32 insertions(+), 7 deletions(-)

diff --git a/io/bits/statx-generic.h b/io/bits/statx-generic.h
index 19c3565edc..c0e00c9d8b 100644
--- a/io/bits/statx-generic.h
+++ b/io/bits/statx-generic.h
@@ -62,6 +62,6 @@ __BEGIN_DECLS
 /* Fill *BUF with information about PATH in DIRFD.  */
 int statx (int __dirfd, const char *__restrict __path, int __flags,
            unsigned int __mask, struct statx *__restrict __buf)
-  __THROW __nonnull ((2, 5));
+  __THROW __nonnull ((5));
 
 __END_DECLS
diff --git a/io/sys/stat.h b/io/sys/stat.h
index 3b4ba80132..7ea39b8755 100644
--- a/io/sys/stat.h
+++ b/io/sys/stat.h
@@ -263,14 +263,14 @@ extern int __REDIRECT_NTH (fstat64, (int __fd, struct stat64 *__buf),
 # ifndef __USE_FILE_OFFSET64
 extern int fstatat (int __fd, const char *__restrict __file,
 		    struct stat *__restrict __buf, int __flag)
-     __THROW __nonnull ((2, 3));
+     __THROW __nonnull ((3));
 # else
 #  ifdef __USE_TIME64_REDIRECTS
 #   ifdef __REDIRECT_NTH
 extern int __REDIRECT_NTH (fstatat, (int __fd, const char *__restrict __file,
 				     struct stat *__restrict __buf,
 				     int __flag),
-			   __fstatat64_time64) __nonnull ((2, 3));
+			   __fstatat64_time64) __nonnull ((3));
 #   else
 #    define fstatat __fstatat64_time64
 #   endif
@@ -279,7 +279,7 @@ extern int __REDIRECT_NTH (fstatat, (int __fd, const char *__restrict __file,
 extern int __REDIRECT_NTH (fstatat, (int __fd, const char *__restrict __file,
 				     struct stat *__restrict __buf,
 				     int __flag),
-			   fstatat64) __nonnull ((2, 3));
+			   fstatat64) __nonnull ((3));
 #   else
 #    define fstatat fstatat64
 #   endif
@@ -290,7 +290,7 @@ extern int __REDIRECT_NTH (fstatat, (int __fd, const char *__restrict __file,
 #  ifndef __USE_TIME64_REDIRECTS
 extern int fstatat64 (int __fd, const char *__restrict __file,
 		      struct stat64 *__restrict __buf, int __flag)
-     __THROW __nonnull ((2, 3));
+     __THROW __nonnull ((3));
 #  else
 #   ifdef __REDIRECT_NTH
 extern int __REDIRECT_NTH (fstatat64, (int __fd,
@@ -298,7 +298,7 @@ extern int __REDIRECT_NTH (fstatat64, (int __fd,
 				       struct stat64 *__restrict __buf,
 				       int __flag),
 			   __fstatat64_time64)
-     __nonnull ((2, 3));
+     __nonnull ((3));
 #   else
 #    define fstatat64 __fstatat64_time64
 #   endif
diff --git a/io/tst-statx.c b/io/tst-statx.c
index 685924ae76..4b70999e96 100644
--- a/io/tst-statx.c
+++ b/io/tst-statx.c
@@ -74,6 +74,12 @@ both_implementations_tests (statx_function impl, const char *path, int fd)
     TEST_COMPARE (buf.stx_size, 3);
     TEST_COMPARE (buf.stx_ino, ino);
   }
+  {
+    struct statx buf = { 0, };
+    TEST_COMPARE (statx (fd, NULL, AT_EMPTY_PATH, STATX_BASIC_STATS, &buf), 0);
+    TEST_COMPARE (buf.stx_size, 3);
+    TEST_COMPARE (buf.stx_ino, ino);
+  }
   {
     struct statx stx = { 0, };
     TEST_COMPARE (statx (fd, "", AT_EMPTY_PATH, STATX_BASIC_STATS, &stx), 0);
diff --git a/sysdeps/mach/hurd/fstatat64.c b/sysdeps/mach/hurd/fstatat64.c
index 61b6593f3a..18dc9d2f08 100644
--- a/sysdeps/mach/hurd/fstatat64.c
+++ b/sysdeps/mach/hurd/fstatat64.c
@@ -45,6 +45,8 @@ __fstatat64_common (int fd, const char *filename, struct stat64 *buf, int at_fla
 int
 __fstatat64 (int fd, const char *filename, struct stat64 *buf, int at_flags)
 {
+  if ((at_flags & AT_EMPTY_PATH) && filename == NULL)
+    filename = "";
   return __fstatat64_common (fd, filename, buf, at_flags, 0);
 }
 libc_hidden_def (__fstatat64)
diff --git a/sysdeps/unix/sysv/linux/fstatat64.c b/sysdeps/unix/sysv/linux/fstatat64.c
index 59b461cbcf..a9e3b85179 100644
--- a/sysdeps/unix/sysv/linux/fstatat64.c
+++ b/sysdeps/unix/sysv/linux/fstatat64.c
@@ -156,6 +156,10 @@ __fstatat64_time64 (int fd, const char *file, struct __stat64_t64 *buf,
 {
   int r;
 
+#ifndef __ASSUME_STATX_NULL_PATH
+retry:
+#endif
+
 #if FSTATAT_USE_STATX
   r = fstatat64_time64_statx (fd, file, buf, flag);
 # ifndef __ASSUME_STATX
@@ -166,6 +170,14 @@ __fstatat64_time64 (int fd, const char *file, struct __stat64_t64 *buf,
   r = fstatat64_time64_stat (fd, file, buf, flag);
 #endif
 
+#ifndef __ASSUME_STATX_NULL_PATH
+  if (file == NULL && (flag & AT_EMPTY_PATH) && r == -EFAULT)
+    {
+      file = "";
+      goto retry;
+    }
+#endif
+
   return INTERNAL_SYSCALL_ERROR_P (r)
 	 ? INLINE_SYSCALL_ERROR_RETURN_VALUE (-r)
 	 : 0;
diff --git a/sysdeps/unix/sysv/linux/statx.c b/sysdeps/unix/sysv/linux/statx.c
index a6295a155d..9549614a6b 100644
--- a/sysdeps/unix/sysv/linux/statx.c
+++ b/sysdeps/unix/sysv/linux/statx.c
@@ -25,7 +25,12 @@ int
 statx (int fd, const char *path, int flags,
        unsigned int mask, struct statx *buf)
 {
-  int ret = INLINE_SYSCALL_CALL (statx, fd, path, flags, mask, buf);
+  int ret;
+  ret = INLINE_SYSCALL_CALL (statx, fd, path, flags, mask, buf);
+#ifndef __ASSUME_STATX_NULL_PATH
+  if (path == NULL && (flags & AT_EMPTY_PATH) && errno == EFAULT)
+    ret = INLINE_SYSCALL_CALL (statx, fd, "", flags, mask, buf);
+#endif
 #ifdef __ASSUME_STATX
   return ret;
 #else

---
base-commit: 2eee835eca960c9d4119279804214b7a1ed5d156
change-id: 20240925-statx-null-path-user-c0c4ebbdf21c
prerequisite-change-id: 20240821-statx-null-path-531c0775bba4:v5
prerequisite-patch-id: cf313d4d0660fa972ce419167e3847722c3481d3

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

