From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 20 Aug 2024 20:27:51 +0800
Subject: [PATCH] Loongarch: adapt for the re-introduction of fstat and
 newfstatat in 6.11
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240820-loong-fstat-v1-1-799b6627bb2f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMaLxGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDCyMD3Zz8/Lx03bTiksQS3TRT8zSLpFQTC1NzUyWgjoKi1LTMCrBp0bG
 1tQDKZlzCXQAAAA==
To: libc-alpha@sourceware.org
Cc: Adhemerval Zanella <adhemerval.zanella@linaro.org>, 
 Joseph Myers <joseph_myers@mentor.com>, b4-sent@lore.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=3975;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=Zh2HgNAub7JJgXNZvEVyMiCH7kcM0TCZA32I/YLUcVU=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmxIvQrF0sCtQZ6786vtlAdMgZC8Q1dxvMF48Yf
 Con4K+RBK2JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZsSL0AAKCRCwMePKe/7Z
 bpg9D/4++D5ORomXcx3yamGI7sDNtP8s+ccXHi4KZR6IGj5HsCYyc/lks4ARHKEmmh1pjyZ9lDc
 fW/NJOzMfLqzdnsPTFYENQePjXPRJuOpthqvHGlHvvgEHvcK9Ig/j2z0CP0scnwKERS3/utWU1Q
 FF4I3uoW282nwTiqfUaeb7hthm0mw3K2mxQr42C91KViFA4iR5T3boYpxwbUVqfG7r+GINIsjtH
 FA323pj2YdwUWSXH7fVlT7BAzA2IBQn67l+Ebk9zyu+h3bNcqNj1b3mGqbboghDqGy+hLgW4EoB
 p09m9AtEq1aywxzTWSTsI6vL565t7JWGKy10qyulrg3IUHd59GincCcVSDRC+GdcZZ4GYZ6+3CH
 f0sw1i1OOtzcOVugY90W/eAsvo3Z3BEldPsEHzRUR6BOvNabHKlgpjMtIafdqD+V7GcQJ1gczN3
 aV1TRrllUakmi+Nbz1GeeKcOTW7Q5IjFfbvrH/0FHV/lrK75+EeUkL3Xm7hXrwjS1fyN6GPp3aI
 64ONOYwA6/AOGKwIY2v5X+o0zPeEIFfPq8Sqlls1MC3jhnzPKEHR5CWSHkaIaC7cqgenqnWJwzn
 dML+F/eK1QfCnYvjEEETEcvqEbVeMcOYnUbV4/w8C62K57icBU4Q9Sv2U3kj9FIX5GvMGN/JlLE
 QOCJo1m/hgdkRGA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In Linux 6.11, fstat and newfstatat are added back. We need to include
this change in kernel-features.h to avoid producing libraries
incompatible with previous linux versions with new headers.

The defination of the two syscalls will be removed when the targeted
kernel version is below 6.11 in loongarch/sysdep.h.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Kernel 6.11 adds back fstat and newfstatat in commit 7697a0fe0154
("LoongArch: Define __ARCH_WANT_NEW_STAT in unistd.h"). With kernel
headers from 6.11, make update-syscall-lists will generate the following
diffs:

diff --git a/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h b/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h
index 8bb82448a7..7e732256fd 100644
--- a/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h
+++ b/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h
@@ -59,6 +59,7 @@
 #define __NR_fsmount 432
 #define __NR_fsopen 430
 #define __NR_fspick 433
+#define __NR_fstat 80
 #define __NR_fstatfs 44
 #define __NR_fsync 82
 #define __NR_ftruncate 46
@@ -166,6 +167,7 @@
 #define __NR_munmap 215
 #define __NR_name_to_handle_at 264
 #define __NR_nanosleep 101
+#define __NR_newfstatat 79
 #define __NR_nfsservctl 42
 #define __NR_open_by_handle_at 265
 #define __NR_open_tree 428

With that changed, the compiled libraries will unexpectedly include
calls to these two syscalls, and be incompatible with previous kernel
versions.

This patch addresses this issue by removing the two definations if the
targeted kernel version is below 6.11. I have tested this patch along
with the change to arch-syscall.h with or without the configuration
option --enable-kernel=6.11.
---
 .../unix/sysv/linux/loongarch/kernel-features.h    | 27 ++++++++++++++++++++++
 sysdeps/unix/sysv/linux/loongarch/sysdep.h         |  5 ++++
 2 files changed, 32 insertions(+)

diff --git a/sysdeps/unix/sysv/linux/loongarch/kernel-features.h b/sysdeps/unix/sysv/linux/loongarch/kernel-features.h
new file mode 100644
index 0000000000..c0e7ccb5de
--- /dev/null
+++ b/sysdeps/unix/sysv/linux/loongarch/kernel-features.h
@@ -0,0 +1,27 @@
+/* Set flags signalling availability of kernel features based on given
+   kernel version number.  Loongarch version.
+   Copyright (C) 2024-2024 Free Software Foundation, Inc.
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
+#include_next <kernel-features.h>
+
+#define __ASSUME_LOONGARCH_NEWSTAT 1
+
+/* No support for fstat or newfstatat before 6.11.  */
+#if __LINUX_KERNEL_VERSION < 0x060b00
+# undef __ASSUME_LOONGARCH_NEWSTAT
+#endif
diff --git a/sysdeps/unix/sysv/linux/loongarch/sysdep.h b/sysdeps/unix/sysv/linux/loongarch/sysdep.h
index eb0ba790da..1fdf18197f 100644
--- a/sysdeps/unix/sysv/linux/loongarch/sysdep.h
+++ b/sysdeps/unix/sysv/linux/loongarch/sysdep.h
@@ -109,6 +109,11 @@
 #undef SYS_ify
 #define SYS_ify(syscall_name) __NR_##syscall_name
 
+#ifndef __ASSUME_LOONGARCH_NEWSTAT
+#undef __NR_fstat
+#undef __NR_newfstatat
+#endif
+
 #ifndef __ASSEMBLER__
 
 #define VDSO_NAME "LINUX_5.10"

---
base-commit: 2eee835eca960c9d4119279804214b7a1ed5d156
change-id: 20240820-loong-fstat-f57f8be48575

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

