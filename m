From: Janne Grunau <j@jannau.net>
Date: Wed, 17 Jan 2024 23:24:30 +0100
Subject: [PATCH RFC 4/6] efi_selftest: Add international characters test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240117-vidconsole-utf8-uefi-v1-4-539f7ce74fb9@jannau.net>
References: <20240117-vidconsole-utf8-uefi-v1-0-539f7ce74fb9@jannau.net>
In-Reply-To: <20240117-vidconsole-utf8-uefi-v1-0-539f7ce74fb9@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1491; i=j@jannau.net;
 h=from:subject:message-id; bh=xhSCbsHJtQ6v72d/HK7UQUIy+oFjZujSPTkEnV2wRR8=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtQVwQseKgff/39tVeY3/XO295eneVs8nDOZc2NDh7W3Q
 tCmMAapjlIWBjEuBlkxRZYk7ZcdDKtrFGNqH4TBzGFlAhnCwMUpABPxcmb4n62dOPNw3/mXjRf8
 1r9jd7L6xD0laLbS6pJMv4rMg00sVxgZjjK+1NoWuu/6Yf8beqfCvlS3vMn6G2bJWs2zY2tJ1LJ
 EHgA=
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

