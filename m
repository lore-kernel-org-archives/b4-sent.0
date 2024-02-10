From: Janne Grunau <j@jannau.net>
Date: Sat, 10 Feb 2024 13:46:44 +0100
Subject: [PATCH v2 6/6] efi_selftest: Add symbol character selftest
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240210-vidconsole-utf8-uefi-v2-6-88c03db60de2@jannau.net>
References: <20240210-vidconsole-utf8-uefi-v2-0-88c03db60de2@jannau.net>
In-Reply-To: <20240210-vidconsole-utf8-uefi-v2-0-88c03db60de2@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1604; i=j@jannau.net;
 h=from:subject:message-id; bh=R/KOzk/A0b3uoB67wZJBMV9GIH6TDpOY3EDG4XdGYNk=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtTjBdZBh7kanfTypnzf+tKPIU2E7/WeFW2rFOXZl7P9t
 eevel/bUcrCIMbFICumyJKk/bKDYXWNYkztgzCYOaxMIEMYuDgFYCLLzBgZNvU9UJtg5+Tp0vb7
 gf2/npio0n+zvp85fTJq5QLH2cWpbgz/k69H7X1lP8n+qdXdWaGy7w/2B3QvNSlTdL21dOdR+Y2
 MDAA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Draw symbols from code page 437 code points 0x01 - 01f used by UEFI
applications to draw user interfaces using
EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.

Add a simple test to displaying the Konami code using symbols used by
grub2. The output has to be checked manually on the screen for
correctness.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 lib/efi_selftest/efi_selftest_textoutput.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/lib/efi_selftest/efi_selftest_textoutput.c b/lib/efi_selftest/efi_selftest_textoutput.c
index cc11a22eee..9e5d944fa0 100644
--- a/lib/efi_selftest/efi_selftest_textoutput.c
+++ b/lib/efi_selftest/efi_selftest_textoutput.c
@@ -46,6 +46,8 @@ u"left bottom \u2502 right bottom  \u2502\n\u2514\u2500\u2500\u2500"
 u"\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2534"
 u"\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500"
 u"\u2500\u2500\u2500\u2500\u2518\n";
+	const u16 konami[] =
+u"Konami code: \u25b2 \u25b2 \u25bc \u25bc \u25c4 \u25ba \u25c4 \u25ba B A\n";
 
 	/* SetAttribute */
 	efi_st_printf("\nColor palette\n");
@@ -144,6 +146,11 @@ u"\u2500\u2500\u2500\u2500\u2518\n";
 		efi_st_error("OutputString failed for box drawing chars\n");
 		return EFI_ST_FAILURE;
 	}
+	ret = con_out->output_string(con_out, konami);
+	if (ret != EFI_ST_SUCCESS) {
+		efi_st_error("OutputString failed for symbol chars\n");
+		return EFI_ST_FAILURE;
+	}
 	con_out->output_string(con_out, u"waiting for admiration...\n");
 	EFI_CALL(systab.boottime->stall(3000000));
 	efi_st_printf("\n");

-- 
2.43.0

