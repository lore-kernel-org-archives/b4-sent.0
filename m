From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 21 Aug 2024 21:03:53 +0800
Subject: [PATCH v3 1/2] Loongarch: adapt for the re-introduction of fstat
 and newfstatat in 6.11
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240821-loong-fstat-v3-1-0df9bd4f7ca6@gmail.com>
References: <20240821-loong-fstat-v3-0-0df9bd4f7ca6@gmail.com>
In-Reply-To: <20240821-loong-fstat-v3-0-0df9bd4f7ca6@gmail.com>
To: libc-alpha@sourceware.org
Cc: Adhemerval Zanella <adhemerval.zanella@linaro.org>, 
 Joseph Myers <josmyers@redhat.com>, Xi Ruoyao <xry111@xry111.site>, 
 b4-sent@lore.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2575;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=w0nF466oMcnJ5XJ+d/1ta4U1NbS6zy8ZLg8X1f0LRsY=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmxeW6qDhTKiMAyC3+fEHtRdCmrFVGSjgliEpbw
 +Lx9RuYo2GJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZsXlugAKCRCwMePKe/7Z
 bmQ7EAC43sjqJpH9HQwlidDUEQ5mc02EYxXBkK8v1bv2iGgZdhTu2ZHWrx/xj24df4PGLpsRDrh
 0GvrKOgkvy3bPf51gIUMimtr3iRXjUZxzC1nuPm7EUhT5ujukxmC3sjt64LYrVe5VTh9mQ17C2I
 tRkLs60HwNNuxbed9YHeV9gysZNbePMM1sYIKZfQnsPuXclZAGqe9CpD+ta4kqq7QfDkhSrnFXK
 3UbcF9zfdHmR17HoEMTxt38GYrfu7AZ6xlBs8QFEtsOLljYzOeiIvf0kwXhvD9WmdjoJXYUX6cQ
 tFSmYc6CUscb7qjJQRFdJJMciPuhUny/838cdeE73eAZ9+u9yz44/rr3bYyeYbQgbld/C+s7vpS
 pQQyIB4xAvdXjOwzuXVedfofk7WXErOQuSnRv1EJZOY6iWJmyQrjZ8HjEAPQk9UTct3+TtkZUFB
 DwAq5BnVpX7faGqDgrPrGZ0qXM9fyrqYpI9ril6Jx7/oa7jGqB0hZuQCTAhqq6r5pCu6i2ovvWz
 1hmQsGsYHsm827EDeA2xA4TQEmPy0McjXkudEwNOGp04BRrvdCGjmN3TelxgLV9waYeKJj1zNR7
 uldeSRNVA9wRHPcWczsU/z8j4R4OnEKT1K8CfT+EPQ0e/UW8gj6Xc/aREs+PX8MoV6IF5BD1j2c
 88ZoxhLkjSE7oMg==
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

-- 
2.43.0

