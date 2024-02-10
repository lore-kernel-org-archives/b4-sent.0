From: Janne Grunau <j@jannau.net>
Date: Sat, 10 Feb 2024 13:46:43 +0100
Subject: [PATCH v2 5/6] efi_selftest: Add box drawing character selftest
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240210-vidconsole-utf8-uefi-v2-5-88c03db60de2@jannau.net>
References: <20240210-vidconsole-utf8-uefi-v2-0-88c03db60de2@jannau.net>
In-Reply-To: <20240210-vidconsole-utf8-uefi-v2-0-88c03db60de2@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2500; i=j@jannau.net;
 h=from:subject:message-id; bh=GZoCC0DSNZV6PjfmSuk03NSxTlmJrrpiaf8kDJ9d6uM=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtTjBVbNeext+zyeW+u8fsXjxH0l6L7V9buTpsmJ/nrse
 2TWva09HaUsDGJcDLJiiixJ2i87GFbXKMbUPgiDmcPKBDKEgYtTACaiPJGRYd2vwON8AQc9vQ+V
 BAYEiPiVTg9e0KW2/cHD+XnzuXRaEhkZDrOyH/O+0lc0lbe2smnF+W18dhvC813LpcW1znzafuE
 rKwA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andre Przywara <andre.przywara@arm.com>

UEFI applications rely on Unicode output capability, and might use that
for drawing pseudo-graphical interfaces using Unicode defined box
drawing characters.

Add a simple test to display the most basic box characters, which would
need to be checked manually on the screen for correctness.
To facilitate this, add a three second delay after the output at this
point.

Signed-off-by: Andre Przywara <andre.przywara@arm.com>
Suggested-by: Heinrich Schuchardt <xypron.glpk@gmx.de>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 lib/efi_selftest/efi_selftest_textoutput.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/lib/efi_selftest/efi_selftest_textoutput.c b/lib/efi_selftest/efi_selftest_textoutput.c
index 2aa81b0a80..cc11a22eee 100644
--- a/lib/efi_selftest/efi_selftest_textoutput.c
+++ b/lib/efi_selftest/efi_selftest_textoutput.c
@@ -33,6 +33,19 @@ static int execute(void)
 	const u16 text[] =
 u"\u00d6sterreich Edelwei\u00df Sm\u00f8rrebr\u00f8d Sm\u00f6rg"
 u"\u00e5s Ni\u00f1o Ren\u00e9 >\u1f19\u03bb\u03bb\u03ac\u03c2<\n";
+	const u16 boxes[] =
+u"This should render as four boxes with text\n"
+u"\u250c\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
+u"\u2500\u2500\u2500\u252c\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
+u"\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2510\n\u2502"
+u" left top    \u2502 right top     \u2502\n\u251c\u2500"
+u"\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
+u"\u2500\u253c\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
+u"\u2500\u2500\u2500\u2500\u2500\u2500\u2524\n\u2502 "
+u"left bottom \u2502 right bottom  \u2502\n\u2514\u2500\u2500\u2500"
+u"\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2534"
+u"\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
+u"\u2500\u2500\u2500\u2500\u2518\n";
 
 	/* SetAttribute */
 	efi_st_printf("\nColor palette\n");
@@ -126,6 +139,13 @@ u"\u00e5s Ni\u00f1o Ren\u00e9 >\u1f19\u03bb\u03bb\u03ac\u03c2<\n";
 		efi_st_error("OutputString failed for international chars\n");
 		return EFI_ST_FAILURE;
 	}
+	ret = con_out->output_string(con_out, boxes);
+	if (ret != EFI_ST_SUCCESS) {
+		efi_st_error("OutputString failed for box drawing chars\n");
+		return EFI_ST_FAILURE;
+	}
+	con_out->output_string(con_out, u"waiting for admiration...\n");
+	EFI_CALL(systab.boottime->stall(3000000));
 	efi_st_printf("\n");
 
 	return EFI_ST_SUCCESS;

-- 
2.43.0

