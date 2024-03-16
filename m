From: Janne Grunau <j@jannau.net>
Date: Sat, 16 Mar 2024 22:50:21 +0100
Subject: [PATCH v3 4/7] efi_selftest: Add international characters test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240316-vidconsole-utf8-uefi-v3-4-4e8a3d349447@jannau.net>
References: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
In-Reply-To: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2141; i=j@jannau.net;
 h=from:subject:message-id; bh=vvgCL+bpYJ3yFHjvmsah3TdozXuBIy3nC4D7AIESVaI=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtRvIgqxylPdZIsfLsxkqRQ7H3xO/sbyCR9SK9iyzEoD1
 bJvlRzsKGVhEONikBVTZEnSftnBsLpGMab2QRjMHFYmkCEMXJwCMJHaWIa/Ao5aa7kOCBu9PDBx
 w8ywLPfYpK7k2KW+Yt77+Ju05J8vZmS4wSk/T37ffSfL9qUhqlZSv8V3y52KnbBNi3uLNuOKyMP
 8AA==
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andre Przywara <andre.przywara@arm.com>

UEFI relies entirely on unicode output, which actual fonts displayed on
the screen might not be ready for.

Add a test displaying some international characters, to reveal missing
glyphs, especially in our builtin fonts.
This would be needed to be manually checked on the screen for
correctness.

Signed-off-by: Andre Przywara <andre.przywara@arm.com>
Suggested-by: Heinrich Schuchardt <xypron.glpk@gmx.de>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 lib/efi_selftest/efi_selftest_textoutput.c | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/lib/efi_selftest/efi_selftest_textoutput.c b/lib/efi_selftest/efi_selftest_textoutput.c
index cc44b38bc2..917903473d 100644
--- a/lib/efi_selftest/efi_selftest_textoutput.c
+++ b/lib/efi_selftest/efi_selftest_textoutput.c
@@ -31,6 +31,21 @@ static int execute(void)
 		0xD804, 0xDC22,
 		0};
 
+	const u16 text[] =
+u"This should render international characters as described\n"
+u"U+00D6 \u00D6 - Latin capital letter O with diaresis\n"
+u"U+00DF \u00DF - Latin small letter sharp s\n"
+u"U+00E5 \u00E5 - Latin small letter a with ring above\n"
+u"U+00E9 \u00E9 - Latin small letter e with acute\n"
+u"U+00F1 \u00F1 - Latin small letter n with tilde\n"
+u"U+00F6 \u00F6 - Latin small letter o with diaresis\n"
+u"The following characters will render as '?' with bitmap fonts\n"
+u"U+00F8 \u00F8 - Latin small letter o with stroke\n"
+u"U+03AC \u03AC - Greek small letter alpha with tonus\n"
+u"U+03BB \u03BB - Greek small letter lambda\n"
+u"U+03C2 \u03C2 - Greek small letter final sigma\n"
+u"U+1F19 \u1F19 - Greek capital letter epsilon with dasia\n";
+
 	/* SetAttribute */
 	efi_st_printf("\nColor palette\n");
 	for (foreground = 0; foreground < 0x10; ++foreground) {
@@ -119,6 +134,12 @@ static int execute(void)
 		return EFI_ST_FAILURE;
 	}
 	efi_st_printf("\n");
+	ret = con_out->output_string(con_out, text);
+	if (ret != EFI_ST_SUCCESS) {
+		efi_st_error("OutputString failed for international chars\n");
+		return EFI_ST_FAILURE;
+	}
+	efi_st_printf("\n");
 
 	return EFI_ST_SUCCESS;
 }

-- 
2.44.0

