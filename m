From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 20 Aug 2024 22:12:38 +0800
Subject: [PATCH v2] Loongarch: adapt for the re-introduction of fstat and
 newfstatat in 6.11
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240820-loong-fstat-v2-1-5a254fef05ce@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFWkxGYC/23MQQrDIBRF0a2EP67FSIymo+6jZKCpmg+JFhVpC
 e69NuMO74N3Dkgmoklw6w6IpmDC4FuwSwfLqrwzBJ+tgVE2UMko2ULwjtiUVSaWCyu1GSQXHNr
 jFY3F96k95tYrphzi58RL/1v/O6UnPRHTpMeRCa2Zvbtd4XZdwg5zrfULAWOM6qYAAAA=
To: libc-alpha@sourceware.org
Cc: Adhemerval Zanella <adhemerval.zanella@linaro.org>, 
 Joseph Myers <josmyers@redhat.com>, Xi Ruoyao <xry111@xry111.site>, 
 b4-sent@lore.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=4171;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=kpBpskeB+zhbi3QKvMJEGkj6UsOKnNGyeEP+iG723W8=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmxKRaQUCGMGDVZO59hdBLEK2dXfNIW0sGndqrM
 WtEW3qtHSqJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZsSkWgAKCRCwMePKe/7Z
 bjjwD/0QuuaWd/ssVPJSRm1jndKe4xYOCPQq1JytoFRr4+F94XSprLPzVwCSSfeQlqma8/TIaRm
 5NsK+FG9aRlG6CcJ3i2hYfyPNEPq0IBYhKz/RLxHjF3VA8TLVBMUNj2n0huS1Jo2F7r9xUU3tLo
 +cYVxVdOEU60lbu+AWWdosj7yuBtVq2nGMQbasZKfkvfD3M2QvlQ1hShPO8viwdkh0u+O+D2O6Q
 hDvqgU5S1T6Q8I3RpmkDVHQl9sdDoME1YD9uHXpVwCSvP2otPkromJvi0FOtEIX1pnlSlFBLEv4
 Jo4jTctAqilWeC5qy+rxS0f41/EaIl9/NpZsqf3t3U5s2N5jn274A4u6btiFqOJrYUmVxbnlojN
 mP55vPzGqUvLXqJ403m0dYgjvXEKEMqKPWzQPc72v1KwZ9UIFi2XDFd4hjzqmqiQXILYx/9+Scl
 K4LmHpLMfhrGpgT+fcS0EhZS9d0Wl5mo0etdH4boXOC9XqHDaEHp4+8Rq+N6Yj9g6DLny1Keq3P
 rd9rcqNBuKj8QI0m81Hg65krwkK6U8/DGVHCxro8BGaLJ5cdampZZnFooEww7dWRj4f5NiiSEas
 AacmVhaDL26lEWD/kEs0U0zSCLt9o60rggVn6Z2NkJGiPSv9wIbleW/IzArs2QMYCftL0tODKDS
 ziu8FtAhFpz3h/g==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In Linux 6.11, fstat and newfstatat are added back. We need to include
this change in kernel-features.h to avoid producing libraries
incompatible with previous linux versions with new headers.

The definition of the two syscalls will be removed when the targeted
kernel version is below 6.11 in loongarch/sysdep.h.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Kernel 6.11 adds back fstat and newfstatat in commit 7697a0fe0154
("LoongArch: Define __ARCH_WANT_NEW_STAT in unistd.h"). With kernel
headers from 6.11, make update-syscall-lists will generate the following
diffs:

> diff --git a/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h b/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h
> index 8bb82448a7..7e732256fd 100644
> --- a/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h
> +++ b/sysdeps/unix/sysv/linux/loongarch/arch-syscall.h
> @@ -59,6 +59,7 @@
>  #define __NR_fsmount 432
>  #define __NR_fsopen 430
>  #define __NR_fspick 433
> +#define __NR_fstat 80
>  #define __NR_fstatfs 44
>  #define __NR_fsync 82
>  #define __NR_ftruncate 46
> @@ -166,6 +167,7 @@
>  #define __NR_munmap 215
>  #define __NR_name_to_handle_at 264
>  #define __NR_nanosleep 101
> +#define __NR_newfstatat 79
>  #define __NR_nfsservctl 42
>  #define __NR_open_by_handle_at 265
>  #define __NR_open_tree 428

With that changed, the compiled libraries will unexpectedly include
calls to these two syscalls, and be incompatible with previous kernel
versions.

This patch addresses this issue by removing the two definitions if the
targeted kernel version is below 6.11. I have tested this patch along
with the change to arch-syscall.h with or without the configuration
option --enable-kernel=6.11.
---
Changes in v2:
- Improve commit message for better patch handling
- Link to v1: https://sourceware.org/pipermail/libc-alpha/2024-August/159295.html
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

