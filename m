From: Janne Grunau <j@jannau.net>
Date: Sat, 10 Feb 2024 13:46:42 +0100
Subject: [PATCH v2 4/6] efi_selftest: Add international characters test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240210-vidconsole-utf8-uefi-v2-4-88c03db60de2@jannau.net>
References: <20240210-vidconsole-utf8-uefi-v2-0-88c03db60de2@jannau.net>
In-Reply-To: <20240210-vidconsole-utf8-uefi-v2-0-88c03db60de2@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1491; i=j@jannau.net;
 h=from:subject:message-id; bh=xhSCbsHJtQ6v72d/HK7UQUIy+oFjZujSPTkEnV2wRR8=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtTjBVYmPXq7Od1aslLTlh/fqfywwPZByBKDQ5+aN1j/N
 j4+x2NmRykLgxgXg6yYIkuS9ssOhtU1ijG1D8Jg5rAygQxh4OIUgImcD2VkePPWPzhc4v+S91/f
 VncEhMXxrS3WmnaM6/W2ZYbHNhx9V8Hwi+nymfj9Gx8sfTPV6vyWoEjhhEmfI644XxUNn7T1MJ/
 DDVYA
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
 lib/efi_selftest/efi_selftest_textoutput.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/lib/efi_selftest/efi_selftest_textoutput.c b/lib/efi_selftest/efi_selftest_textoutput.c
index cc44b38bc2..2aa81b0a80 100644
--- a/lib/efi_selftest/efi_selftest_textoutput.c
+++ b/lib/efi_selftest/efi_selftest_textoutput.c
@@ -30,6 +30,9 @@ static int execute(void)
 		0xD804, 0xDC05,
 		0xD804, 0xDC22,
 		0};
+	const u16 text[] =
+u"\u00d6sterreich Edelwei\u00df Sm\u00f8rrebr\u00f8d Sm\u00f6rg"
+u"\u00e5s Ni\u00f1o Ren\u00e9 >\u1f19\u03bb\u03bb\u03ac\u03c2<\n";
 
 	/* SetAttribute */
 	efi_st_printf("\nColor palette\n");
@@ -118,6 +121,11 @@ static int execute(void)
 		efi_st_printf("Unicode not handled properly\n");
 		return EFI_ST_FAILURE;
 	}
+	ret = con_out->output_string(con_out, text);
+	if (ret != EFI_ST_SUCCESS) {
+		efi_st_error("OutputString failed for international chars\n");
+		return EFI_ST_FAILURE;
+	}
 	efi_st_printf("\n");
 
 	return EFI_ST_SUCCESS;

-- 
2.43.0

