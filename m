From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 15 Jul 2025 16:54:38 +0800
Subject: [PATCH] lib: Enable checks and compilation on LoongArch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250715-add-loongarch-v1-1-8c1867179cc4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAE0XdmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDc0NT3cSUFN2c/Py89MSi5AxdC2NjA7NUE6NUY4s0JaCegqLUtMwKsHn
 RsbW1AFkWbRZfAAAA
X-Change-ID: 20250715-add-loongarch-83306e42e38f
To: fwts-devel@lists.ubuntu.com
Cc: Ivan Hu <ivan.hu@canonical.com>, b4-sent@lore.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3636;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=lXQi4ZLZDtUoQn4UllC87kAunSyWtHhTrna6xJTtEhM=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBodhdObW2IKV6RA5ws0u68wQPhYdIO4Dbl0YEFf
 WX21ZTRogeJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCaHYXTgAKCRCwMePKe/7Z
 bgRaD/0RSNGHZm96NJDdx1GqRGxRwAA9JerDr61r2CLUIh2PUZ2i/J2o/Cdi4XcRv1cyhp2HL0y
 liQDYuk747pgukhZtdfK8lGVtMjTwdVMdrh9F7FZkjgnJkF+W923kJpTlq0EpgnldQCCHSM7hED
 U7snwqH/DZLFRkImV8nFkD4hxfeA/gHr/wYMmJ1UYj1kybvyHL3a3Gq7YEvuRomfoM3XrjosR1P
 p6oe46jRMgL8vV84AinkhkhLUJ+Coo/hxSYaNVVHbmFCRbJRAxLjIWRfWisja07/YJ2u/wIeIpg
 5Tkl3Ti8n+PhH5Jxp+ug9YrjI67Amyscnjr0eoaeDqr+uwqEJWQ5NBLqnoYMXWqj564+glZnx2y
 FAKwU4ydNrucM98KPv9iLw3pFDWTeHMvwOK7GR3J0jmHongSKzNne9YudJU/BOkQVzDut7lsHFn
 v7Z0WD+YXcct6f0lQxkNv03i7OHHf2cBReIwR2ToowJcBJJ54We7ywPlTJJuYgO7TaVm0IKp/xy
 NCkni24uH/yhTA6T2m4mTq0t9z2jPVD+4HX8bMSpOS5NINKhqA9NvYRjp9qpDvlOuR0BSOkX1Zt
 1eKIezgnc04hr+D+lBrZUf7WFqEwqX419jysRbeQiBNgiVSg75eK8vU7rYqNTC5A9eb7mV7g1b8
 6VI0RU8ikHvVIxQ==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

LoogArch64 has been included in UEFI spec. This patch enables checks for
LoongArch.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 debian/control         | 12 ++++++------
 src/lib/include/fwts.h |  7 +++++++
 2 files changed, 13 insertions(+), 6 deletions(-)

diff --git a/debian/control b/debian/control
index c3a2e607d8a2529fc10a313b9d4e3fdff713d2ac..4edfbd0c4ed11051aee8aa492a6f7b08fbd6cc47 100644
--- a/debian/control
+++ b/debian/control
@@ -19,7 +19,7 @@ Build-Depends: debhelper-compat (= 13),
                libbsd-dev
 
 Package: fwts
-Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el s390x riscv64
+Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el s390x riscv64 loong64
 Depends: libfwtsiasl1 (= ${binary:Version}),
          libfwtsacpica1 (= ${binary:Version}),
          libfwts1 (= ${binary:Version}),
@@ -37,7 +37,7 @@ Description: FirmWare Test Suite
  be a Linux-centric firmware troubleshooting tool.
 
 Package: libfwtsiasl1
-Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el s390x riscv64
+Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el s390x riscv64 loong64
 Depends: ${shlibs:Depends},
          ${misc:Depends}
 Description: FirmWare Test Suite ACPICA core built for iasl functionality
@@ -48,7 +48,7 @@ Description: FirmWare Test Suite ACPICA core built for iasl functionality
  interface with fwts.
 
 Package: libfwtsacpica1
-Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el s390x riscv64
+Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el s390x riscv64 loong64
 Depends: ${shlibs:Depends},
          ${misc:Depends}
 Description: FirmWare Test Suite ACPICA core built for acpiexec functionality
@@ -58,7 +58,7 @@ Description: FirmWare Test Suite ACPICA core built for acpiexec functionality
  contains this code with a thin fwts specific API to interface with fwts.
 
 Package: libfwts1
-Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el s390x riscv64
+Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el s390x riscv64 loong64
 Depends: ${shlibs:Depends},
          ${misc:Depends}
 Description: FirmWare Test Suite core support library
@@ -67,7 +67,7 @@ Description: FirmWare Test Suite core support library
  various fwts tests.
 
 Package: fwts-frontend
-Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el s390x riscv64
+Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el s390x riscv64 loong64
 Priority: optional
 Depends: ${misc:Depends},
          dialog,
@@ -78,7 +78,7 @@ Description: Firmware Test Suite frontend interface
  interface within Firmware Test Suite live images.
 
 Package: fwts-efi-runtime-dkms
-Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el
+Architecture: i386 amd64 armel armhf arm64 ppc64 ppc64el loong64
 Priority: optional
 Depends: ${misc:Depends},
          dkms
diff --git a/src/lib/include/fwts.h b/src/lib/include/fwts.h
index 70d185bd95b8048cfacb3f156910e998c46f1acd..0fd1c37ba082d71759ac63517d37c93be9dd92e8 100644
--- a/src/lib/include/fwts.h
+++ b/src/lib/include/fwts.h
@@ -127,6 +127,13 @@
 #define FWTS_USE_DEVMEM 1
 #endif
 
+#if defined(__loongarch__)
+#define FWTS_ARCH_LOONGARCH	1
+#define FWTS_HAS_ACPI	1
+#define FWTS_HAS_UEFI	1
+#define FWTS_USE_DEVMEM	1
+#endif
+
 /* version 3-tuple into integer */
 #define _VER_(major, minor, patchlevel)                 \
 	((major * 10000) + (minor * 100) + patchlevel)

---
base-commit: 72a8243073204858c79d809903f1a6926c736911
change-id: 20250715-add-loongarch-83306e42e38f

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

