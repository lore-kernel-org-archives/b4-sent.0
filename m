From: Janne Grunau <j@jannau.net>
Date: Sat, 16 Mar 2024 22:50:20 +0100
Subject: [PATCH v3 3/7] lib/charset: Map Unicode code points to CP437 code
 points 1-31
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240316-vidconsole-utf8-uefi-v3-3-4e8a3d349447@jannau.net>
References: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
In-Reply-To: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4021; i=j@jannau.net;
 h=from:subject:message-id; bh=ABn1fOrT1x/a43I0epJTDvkk5WI5gl9Pemj634Mj+Yg=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtRvIgr1jTNNnj/v7DgwcWlPe+SksqN1T/9bHGnR2p70b
 l0z7wf/jlIWBjEuBlkxRZYk7ZcdDKtrFGNqH4TBzGFlAhnCwMUpABN5zsvI0JiyOUXb6kuP6C3F
 5jX9DYcunGZ8ue/duf/C2qXemy35rzH89+s+vX/Ss5g/pyODXmovq1Q+/n7Dzs1sn1N293e2il3
 fzwQA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Code page 437 uses code points 1-31 for glyphs instead of control
characters. Map the appropriate Unicode code points to this code points.
Fixes rendering of grub2's menu as EFI application using the
EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL on a console with bitmap fonts.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 include/charset.h                      |  2 +-
 include/cp1250.h                       | 12 ++++++++++--
 include/cp437.h                        | 12 ++++++++++--
 lib/charset.c                          |  9 ++++++---
 lib/efi_loader/efi_unicode_collation.c |  2 +-
 5 files changed, 28 insertions(+), 9 deletions(-)

diff --git a/include/charset.h b/include/charset.h
index f1050c903d..348bad5883 100644
--- a/include/charset.h
+++ b/include/charset.h
@@ -16,7 +16,7 @@
 /*
  * codepage_437 - Unicode to codepage 437 translation table
  */
-extern const u16 codepage_437[128];
+extern const u16 codepage_437[160];
 
 /**
  * console_read_unicode() - read Unicode code point from console
diff --git a/include/cp1250.h b/include/cp1250.h
index adacf8a958..b762c78d9f 100644
--- a/include/cp1250.h
+++ b/include/cp1250.h
@@ -1,10 +1,18 @@
 /* SPDX-License-Identifier: GPL-2.0+ */
 
 /*
- * Constant CP1250 contains the Unicode code points for characters 0x80 - 0xff
- * of the code page 1250.
+ * Constant CP1250 contains the Unicode code points for characters 0x00 - 0x1f
+ * and 0x80 - 0xff of the code page 1250.
  */
 #define CP1250 { \
+	0x0000, 0x0000, 0x0000, 0x0000, \
+	0x0000, 0x0000, 0x0000, 0x0000, \
+	0x0000, 0x0000, 0x0000, 0x0000, \
+	0x0000, 0x0000, 0x0000, 0x0000, \
+	0x0000, 0x0000, 0x0000, 0x0000, \
+	0x0000, 0x0000, 0x0000, 0x0000, \
+	0x0000, 0x0000, 0x0000, 0x0000, \
+	0x0000, 0x0000, 0x0000, 0x0000, \
 	0x20ac, 0x0000, 0x201a, 0x0000, \
 	0x201e, 0x2026, 0x2020, 0x2021, \
 	0x0000, 0x2030, 0x0160, 0x2039, \
diff --git a/include/cp437.h b/include/cp437.h
index 0b2b97132e..5093130f5e 100644
--- a/include/cp437.h
+++ b/include/cp437.h
@@ -1,10 +1,18 @@
 /* SPDX-License-Identifier: GPL-2.0+ */
 
 /*
- * Constant CP437 contains the Unicode code points for characters 0x80 - 0xff
- * of the code page 437.
+ * Constant CP437 contains the Unicode code points for characters 0x00 - 0x1f
+ * and 0x80 - 0xff of the code page 437.
  */
 #define CP437 { \
+	0x0000, 0x263a, 0x263b, 0x2665, \
+	0x2666, 0x2663, 0x2660, 0x2022, \
+	0x25d8, 0x25cb, 0x25d9, 0x2642, \
+	0x2640, 0x266a, 0x266b, 0x263c, \
+	0x25ba, 0x25c4, 0x2195, 0x203c, \
+	0x00b6, 0x00a7, 0x25ac, 0x21a8, \
+	0x2191, 0x2193, 0x2192, 0x2190, \
+	0x221f, 0x2194, 0x25b2, 0x25bc, \
 	0x00c7, 0x00fc, 0x00e9, 0x00e2, \
 	0x00e4, 0x00e0, 0x00e5, 0x00e7, \
 	0x00ea, 0x00eb, 0x00e8, 0x00ef, \
diff --git a/lib/charset.c b/lib/charset.c
index 5e4c4f948a..1f8480150a 100644
--- a/lib/charset.c
+++ b/lib/charset.c
@@ -16,7 +16,7 @@
 /**
  * codepage_437 - Unicode to codepage 437 translation table
  */
-const u16 codepage_437[128] = CP437;
+const u16 codepage_437[160] = CP437;
 
 static struct capitalization_table capitalization_table[] =
 #ifdef CONFIG_EFI_UNICODE_CAPITALIZATION
@@ -517,9 +517,12 @@ int utf_to_cp(s32 *c, const u16 *codepage)
 		int j;
 
 		/* Look up codepage translation */
-		for (j = 0; j < 0x80; ++j) {
+		for (j = 0; j < 0xA0; ++j) {
 			if (*c == codepage[j]) {
-				*c = j + 0x80;
+				if (j < 0x20)
+					*c = j;
+				else
+					*c = j + 0x60;
 				return 0;
 			}
 		}
diff --git a/lib/efi_loader/efi_unicode_collation.c b/lib/efi_loader/efi_unicode_collation.c
index c4c7572063..4b2c52918a 100644
--- a/lib/efi_loader/efi_unicode_collation.c
+++ b/lib/efi_loader/efi_unicode_collation.c
@@ -257,7 +257,7 @@ static void EFIAPI efi_fat_to_str(struct efi_unicode_collation_protocol *this,
 	for (i = 0; i < fat_size; ++i) {
 		c = (unsigned char)fat[i];
 		if (c > 0x80)
-			c = codepage[c - 0x80];
+			c = codepage[c - 0x60];
 		string[i] = c;
 		if (!c)
 			break;

-- 
2.44.0

