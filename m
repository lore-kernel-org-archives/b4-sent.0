From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 28 Aug 2024 04:18:08 +0800
Subject: [PATCH v5] Loongarch: adapt for the re-introduction of fstat and
 newfstatat in 6.10.6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-loong-fstat-v5-1-56a567574bba@gmail.com>
X-B4-Tracking: v=1; b=H4sIAH80zmYC/33NTQ6CMBCG4auQrq1ph5aCK+9hXPRvoIlSQwnRE
 O5uYYXGuPwmed6ZSfJD8ImcipkMfgopxD4PeSiI7XTfehpc3gQYCFYDo7cY+5ZiGvVIUSqsjRe
 1VJJk8Rg8hudWu1zz7kIa4/Da4hNfr787E6ecqqYxVQXKGMBze9fhdrTxTtbOBH8sZCs1SIEem
 bT+25Z7yz9tSRllDhvjBCqrq28r9hY+rch/ua2sxNqBKNXeLsvyBg5tbqVaAQAA
To: libc-alpha@sourceware.org
Cc: Adhemerval Zanella <adhemerval.zanella@linaro.org>, 
 Joseph Myers <josmyers@redhat.com>, Xi Ruoyao <xry111@xry111.site>, 
 =?utf-8?q?W=C3=81NG_Xu=C4=9Bru=C3=AC?= <kernel@xen0n.name>, 
 Adhemerval Zanella Netto <adhemerval.zanella@linaro.org>, 
 b4-sent@lore.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=4948;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=OLPDRolKq4twOPm2m5HBJhIpwvFq8JZF/94KxCa2qdY=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmzjSH36GW8SSNE3UahSyZZRC6sZp4Kn4dTpy/c
 fu02VFweKeJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZs40hwAKCRCwMePKe/7Z
 bqUHD/96BvSciEvgjEae0yobbp1IzcmCVZvmSbFoaWlJXBhH6iCxSDjjoaFJ9b+9p64l6ghc4HM
 L/+zaUMApFwUzo1EMKy6SJ7LAo9BMclSTsAExF2OS8mD96tqbSQYHGzUsTudAx4FF5H0YQbNsL0
 wiahj9/zyPLEj4AN1lSj1LVqZUwb+fb71O5k9Pwyo03WHVszsqwzwp8WJMDiTKS/CuztZP1LoiL
 8syJyEYf8HCk3PissGhIYPFaZwKOs1Q3wFoqP0nNOUc8qw6QMY9HP52veFMCk6iFf419XA1xO4Y
 LfH0peryvSqksisTqFwA+9FFCbxEPoHKI1gxh3vliocxjO8YlxnhAS0lnUzx4Z/nBydLiW1H/Ow
 RePfHJ2cRaebPi9F4zjHEMUc4I7lPOnHnr4XiwxrFQQv5MZQjkOc+T6BZvDszZPmxPqaHyVmV3S
 0R85jHSo48ZMSJ8/VN6MZ+AhHPC+0RC+MBRzu8Rb+/weYXFsH7moia/MecwWDKP+BKqV2asp/HB
 bn6qcG5yf+t8BLIyKJvcKThodXiaoudK/9OXTiphMrti6imoBgJB87ADbNtpQg3eePGC7ElOTFX
 Im1d8FaY5aRnM1Dar1bYpXPHthdUace8N9taQAlN2CeXRjhURfH6TODnuT7wmMrq5YW2CEqtEks
 rWw3YaECxjWjQlw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In Linux 6.11, fstat and newfstatat are added back. We need to include
this change in kernel-features.h to avoid producing libraries
incompatible with previous linux versions with new headers.

The definition of the two syscalls will be removed when the targeted
kernel version is below 6.10.6 in loongarch/sysdep.h, since the feature
has already been backported to 6.10.6 in the stable tree.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Kernel 6.11 adds back fstat and newfstatat in commit 7697a0fe0154
("LoongArch: Define __ARCH_WANT_NEW_STAT in unistd.h") for loongarch.
With kernel headers from 6.11, make update-syscall-lists will generate
the following diffs:

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

With the changes, the compiled libraries will unexpectedly include
calls to these two syscalls, and be incompatible withi the previous
kernel versions.

This patch addresses this issue by removing the two definitions if the
targeted kernel version is below 6.10.6. I have tested this patch
along with the change to arch-syscall.h with or without the
configuration option --enable-kernel=6.10.6.
---
Changes in v5:
- Reword the patch title to address the kernel version in the stable
  tree where the syscalls are added back.
- Link to v4: https://sourceware.org/pipermail/libc-alpha/2024-August/159337.html

Changes in v4:
- Separate the support of statx(fd, NULL, AT_EMPTY_PATH) away from this
  series.
- Link to v3: https://sourceware.org/pipermail/libc-alpha/2024-August/159331.html

Changes in v3:
- Changed the starting version where fstat/newfstatat are supported to
  6.10.6.
- Add a new patch to this series, addressing the support of statx(fd,
  NULL, AT_EMPTY_PATH).
- Link to v2: https://sourceware.org/pipermail/libc-alpha/2024-August/159300.html

Changes in v2:
- Improve commit message for better patch handling
- Link to v1: https://sourceware.org/pipermail/libc-alpha/2024-August/159295.html
---
 .../unix/sysv/linux/loongarch/kernel-features.h    | 27 ++++++++++++++++++++++
 sysdeps/unix/sysv/linux/loongarch/sysdep.h         |  5 ++++
 2 files changed, 32 insertions(+)

diff --git a/sysdeps/unix/sysv/linux/loongarch/kernel-features.h b/sysdeps/unix/sysv/linux/loongarch/kernel-features.h
new file mode 100644
index 0000000000..8e2927c501
--- /dev/null
+++ b/sysdeps/unix/sysv/linux/loongarch/kernel-features.h
@@ -0,0 +1,27 @@
+/* Set flags signalling availability of kernel features based on given
+   kernel version number.  Loongarch version.
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
+#include_next <kernel-features.h>
+
+#define __ASSUME_LOONGARCH_NEWSTAT 1
+
+/* No support for fstat or newfstatat before 6.10.6.  */
+#if __LINUX_KERNEL_VERSION < 0x060a06
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

