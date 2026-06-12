From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 12 Jun 2026 02:53:31 -0500
Subject: [PATCH] udf: validate VAT header length against the VAT inode size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-b4-disp-9a2317ee-v1-1-fefef5736154@proton.me>
X-B4-Tracking: v=1; b=H4sIAPq6K2oC/x3MQQqAIBBA0avIrBvQyYy6SrSwnGo2JQoRSHdPW
 r7F/wUyJ+EMoyqQ+JYs11lhGgXr4c+dUUI1kCannSFcLAbJEQdPremZUWtLfjOddT1BzWLiTZ5
 /Oc3v+wGBXm8NYgAAAA==
To: Jan Kara <jack@suse.com>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781250810; l=2153;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=ZY17IT0BpaH4FEeyUQ1+9vxWALoFy1Q9t97ot9RCyJs=;
 b=+hWVDf6Al1o+d0WlLuXE3/T5kRNm3+rLfWn/Ysq5l85AMOnIiBzRi2ffmKiakyOM8zxBDbIU/
 M/0g3zukuj6Bl0eLeNL2qQ1X+NAI77/4pQfNbQl8MR0n5nBIsxeGF1l
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

udf_load_vat() takes the virtual partition's start offset straight from
the on-disk VAT 2.0 header without checking it against the VAT inode
size:

	map->s_type_specific.s_virtual.s_start_offset =
		le16_to_cpu(vat20->lengthHeader);
	map->s_type_specific.s_virtual.s_num_entries =
		(sbi->s_vat_inode->i_size -
			map->s_type_specific.s_virtual.s_start_offset) >> 2;

lengthHeader is a fully attacker-controlled 16-bit value.  If it exceeds
the VAT inode size, the s_num_entries subtraction underflows to a huge
count, which defeats the "block > s_num_entries" bound in
udf_get_pblock_virt15(); and on the ICB-inline path that function reads

	((__le32 *)(iinfo->i_data + s_start_offset))[block]

so a large s_start_offset indexes past the inode's in-ICB data.  Mounting
a crafted UDF image with a virtual (VAT) partition then triggers an
out-of-bounds read.

Reject a VAT whose header length does not leave room for at least one
entry within the VAT inode.

Fixes: fa5e08156335 ("udf: Handle VAT packed inside inode properly")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 fs/udf/super.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/fs/udf/super.c b/fs/udf/super.c
index cad2e15d633b..561eace476ab 100644
--- a/fs/udf/super.c
+++ b/fs/udf/super.c
@@ -1263,6 +1263,14 @@ static int udf_load_vat(struct super_block *sb, int p_index, int type1_index)
 
 		map->s_type_specific.s_virtual.s_start_offset =
 			le16_to_cpu(vat20->lengthHeader);
+		if (map->s_type_specific.s_virtual.s_start_offset +
+		    sizeof(__le32) > sbi->s_vat_inode->i_size) {
+			udf_err(sb, "Corrupted VAT header length %u (VAT inode size %lld)\n",
+				map->s_type_specific.s_virtual.s_start_offset,
+				sbi->s_vat_inode->i_size);
+			brelse(bh);
+			return -EFSCORRUPTED;
+		}
 		map->s_type_specific.s_virtual.s_num_entries =
 			(sbi->s_vat_inode->i_size -
 				map->s_type_specific.s_virtual.

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260612-b4-disp-9a2317ee-0042af154672

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

