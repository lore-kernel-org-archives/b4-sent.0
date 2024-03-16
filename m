From: Janne Grunau <j@jannau.net>
Date: Sat, 16 Mar 2024 22:50:23 +0100
Subject: [PATCH v3 6/7] efi_selftest: Add geometric shapes character
 selftest
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240316-vidconsole-utf8-uefi-v3-6-4e8a3d349447@jannau.net>
References: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
In-Reply-To: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1625; i=j@jannau.net;
 h=from:subject:message-id; bh=hYWsFfe9/MO1IcHBjYtWqpX5zvOcIH05xUAd27c+G1g=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtRvIgozRXfmnJYoFZe4uE1RaO2ko94cYnJqb6euvG83n
 c1eQVa4o5SFQYyLQVZMkSVJ+2UHw+oaxZjaB2Ewc1iZQIYwcHEKwEQuJTD8swuX9eRYWvkmob05
 q9j4Gk/qz/VxoVrzZL79Ond6RRvnLkaGbQ1f2izMu+NC2eZ0mT/uDlmlGRHx66WlQtqB+zo/bKd
 zAAA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Draw symbols from Unicode's "Geometric shapes" page which translate to
code page 437 code points 1-31. These are used by UEFI applications to
draw user interfaces using EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.
The output has to be checked manually on the screen for correctness.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 lib/efi_selftest/efi_selftest_textoutput.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/lib/efi_selftest/efi_selftest_textoutput.c b/lib/efi_selftest/efi_selftest_textoutput.c
index b56fd2ab76..2208a9877a 100644
--- a/lib/efi_selftest/efi_selftest_textoutput.c
+++ b/lib/efi_selftest/efi_selftest_textoutput.c
@@ -60,6 +60,13 @@ u"\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2534"
 u"\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
 u"\u2500\u2500\u2500\u2500\u2518\n";
 
+	const u16 shapes[] =
+u"Geometric shapes as described\n"
+u"U+25B2 \u25B2 - Black up-pointing triangle\n"
+u"U+25BA \u25BA - Black right-pointing pointer\n"
+u"U+25BC \u25BC - Black down-pointing triangle\n"
+u"U+25C4 \u25C4 - Black left-pointing pointer\n";
+
 	/* SetAttribute */
 	efi_st_printf("\nColor palette\n");
 	for (foreground = 0; foreground < 0x10; ++foreground) {
@@ -160,6 +167,12 @@ u"\u2500\u2500\u2500\u2500\u2518\n";
 		return EFI_ST_FAILURE;
 	}
 	efi_st_printf("\n");
+	ret = con_out->output_string(con_out, shapes);
+	if (ret != EFI_ST_SUCCESS) {
+		efi_st_error("OutputString failed for geometric shapes\n");
+		return EFI_ST_FAILURE;
+	}
+	efi_st_printf("\n");
 
 	return EFI_ST_SUCCESS;
 }

-- 
2.44.0

