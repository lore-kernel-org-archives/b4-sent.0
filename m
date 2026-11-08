From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Sun, 08 Nov 2026 18:07:13 +0000
Subject: [PATCH] ntfs3: reject on-disk c_unit values that cause shift
 overflow
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-ntfs3-cunit-fix-v1-1-fb8d02b3f8a2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFC68GoC/x2MQQqAIBAAvxJ7bsFVyugr0aFsrb1YaEUg/T3pO
 AMzGRJH4QR9lSHyLUn2UIDqCtw2hZVRlsKglW6JVIfh9Mmgu4Kc6OVBT460VWRm20CpjshF/8d
 hfN8PcvXE2mEAAAA=
To: Konstantin Komarov <almaz.alexandrovich@paragon-software.com>, 
 joasantonio108@gmail.com
Cc: linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794161232; l=1984;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=+VpBC7rJJPtIcs1JV3jkHoT7tsNpQiBY1oYu00e37pw=;
 b=PVQJisUuA6eNNZUFtQw8suvtGByi8YYwcknEc984ulPxb9QyosF23DXcoVImT09ALmkDNyS1w
 XG0orKvnbuvCpJWxdbqEDblXdIEHE/1zcEnkEcbSSSY1LKsLhCQmuq9
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The c_unit field of non-resident NTFS attributes controls frame size
via shift expressions like 1u << c_unit throughout attrib.c. This
field is read directly from the on-disk MFT record without bounds
validation for extended (compressed/sparse) attributes.

When c_unit >= 32, the expression 1u << c_unit is undefined behavior
for 32-bit integers. On x86, the shift count is masked to 5 bits,
producing wrong frame alignment (e.g., c_unit=32 yields 1u << 0 = 1
instead of 2^32). On strict-alignment architectures this may trap.

The affected expressions in attrib.c include:
  - 1u << attr_b->nres.c_unit (lines 1168, 1732)
  - align <<= attr_b->nres.c_unit (line 501)
  - sbi->cluster_size << attr_b->nres.c_unit (lines 2089, 2401, 2617)

Add a bounds check in mi_enum_attr() to reject attributes with
c_unit > 31, which covers all downstream users. The existing
validation in frecord.c (checking c_unit == NTFS_LZNT_CUNIT) only
covers explicit compression read/write paths, not the attrib.c
block mapping, truncate, fallocate, and punch_hole paths.

A crafted NTFS image with c_unit=32 triggers the UB on mount when
any compressed file is accessed.

Found by LLM-assisted manual code review.

Fixes: be71b5cba2e6 ("fs/ntfs3: Add attrib operations")
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 fs/ntfs3/record.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/fs/ntfs3/record.c b/fs/ntfs3/record.c
index d7785f9e8..5344958ef 100644
--- a/fs/ntfs3/record.c
+++ b/fs/ntfs3/record.c
@@ -366,6 +366,9 @@ struct ATTRIB *mi_enum_attr(struct ntfs_inode *ni, struct mft_inode *mi,
 
 		if (tot_size > alloc_size)
 			goto out;
+
+		if (attr->nres.c_unit > 31)
+			goto out;
 	} else {
 		if (attr->nres.c_unit)
 			goto out;

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261108-ntfs3-cunit-fix-f1c127013b75

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

