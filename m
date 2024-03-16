From: Janne Grunau <j@jannau.net>
Date: Sat, 16 Mar 2024 22:50:24 +0100
Subject: [PATCH v3 7/7] efi_selftest: Update StrToFat() unit test after
 CP473 map extension
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240316-vidconsole-utf8-uefi-v3-7-4e8a3d349447@jannau.net>
References: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
In-Reply-To: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1212; i=j@jannau.net;
 h=from:subject:message-id; bh=S73V6hU7BXR4dSCPxvtFJHg4c7CFAqBG6lzmd2874Rc=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtRvIgphX/pvhpSY3BJ89e7r1JpJkpyHD309FzydReTX3
 kyJvnXPO0pZGMS4GGTFFFmStF92MKyuUYypfRAGM4eVCWQIAxenAEzE/gUjw82ciw1zoue7fXjf
 o/9e5fudwpfczbmele9PqmdJ3E1d94GRYdGGqr9fLq9LWTND9tq52ieJ/ldvd/XGXK6fzqjI2d+
 ykRMA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test that Unicode code points which map to CP437 code points 1-31 are
converted to '_'. This ensures no FAT file names do not contain chars
which are control characters in other code pages (CP 1250 for example).

Signed-off-by: Janne Grunau <j@jannau.net>
---
 lib/efi_selftest/efi_selftest_unicode_collation.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/lib/efi_selftest/efi_selftest_unicode_collation.c b/lib/efi_selftest/efi_selftest_unicode_collation.c
index 32c99caf35..ad7dfa9fb9 100644
--- a/lib/efi_selftest/efi_selftest_unicode_collation.c
+++ b/lib/efi_selftest/efi_selftest_unicode_collation.c
@@ -220,6 +220,18 @@ static int test_str_to_fat(void)
 		return EFI_ST_FAILURE;
 	}
 
+	/*
+	 * Test unicode code points which map to CP 437 0x01 - 0x1f are
+	 * converted to '_'.
+	 */
+	boottime->set_mem(fat, 16, 0);
+	ret = unicode_collation_protocol->str_to_fat(unicode_collation_protocol,
+		u"\u263a\u2666\u2022\u25d8\u2642\u2194\u00b6\u203c", 8, fat);
+	if (!ret || efi_st_strcmp_16_8(u"________", fat)) {
+		efi_st_error("str_to_fat returned %u, \"%s\"\n", ret, fat);
+		return EFI_ST_FAILURE;
+	}
+
 	return EFI_ST_SUCCESS;
 }
 

-- 
2.44.0

