From: Janne Grunau <j@jannau.net>
Date: Sat, 16 Mar 2024 22:50:22 +0100
Subject: [PATCH v3 5/7] efi_selftest: Add box drawing character selftest
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240316-vidconsole-utf8-uefi-v3-5-4e8a3d349447@jannau.net>
References: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
In-Reply-To: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2307; i=j@jannau.net;
 h=from:subject:message-id; bh=wEwJ0xrzxZBgOxXNRFVt8QAxWgkeF7bJcOttXZyj7lI=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtRvIgrKe6RdngaF9wdx6uXNfD3Jjn+HW+ppP2kpq4TfX
 xYuPMHQUcrCIMbFICumyJKk/bKDYXWNYkztgzCYOaxMIEMYuDgFYCJJiQy/WZg3+snz3Q44t+v3
 xFKGtnfG29I+Vc3aHbRnO0vjY45Ndxj+2dpZL1zPZ1Fmpdc/Y+blGY7rFrbNFPd7p7Fjqsil7O1
 6jAA=
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

Signed-off-by: Andre Przywara <andre.przywara@arm.com>
Suggested-by: Heinrich Schuchardt <xypron.glpk@gmx.de>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 lib/efi_selftest/efi_selftest_textoutput.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/lib/efi_selftest/efi_selftest_textoutput.c b/lib/efi_selftest/efi_selftest_textoutput.c
index 917903473d..b56fd2ab76 100644
--- a/lib/efi_selftest/efi_selftest_textoutput.c
+++ b/lib/efi_selftest/efi_selftest_textoutput.c
@@ -46,6 +46,20 @@ u"U+03BB \u03BB - Greek small letter lambda\n"
 u"U+03C2 \u03C2 - Greek small letter final sigma\n"
 u"U+1F19 \u1F19 - Greek capital letter epsilon with dasia\n";
 
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
+
 	/* SetAttribute */
 	efi_st_printf("\nColor palette\n");
 	for (foreground = 0; foreground < 0x10; ++foreground) {
@@ -140,6 +154,12 @@ u"U+1F19 \u1F19 - Greek capital letter epsilon with dasia\n";
 		return EFI_ST_FAILURE;
 	}
 	efi_st_printf("\n");
+	ret = con_out->output_string(con_out, boxes);
+	if (ret != EFI_ST_SUCCESS) {
+		efi_st_error("OutputString failed for box drawing chars\n");
+		return EFI_ST_FAILURE;
+	}
+	efi_st_printf("\n");
 
 	return EFI_ST_SUCCESS;
 }

-- 
2.44.0

