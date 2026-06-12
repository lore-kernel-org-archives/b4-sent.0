From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 12 Jun 2026 01:40:01 -0500
Subject: [PATCH] udf: validate sparing table length as an entry count, not
 a byte count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-b4-disp-91780c4e-v1-1-f15112ff6882@proton.me>
X-B4-Tracking: v=1; b=H4sIAMCpK2oC/x3MQQqAIBBA0avErBtQMa2uEi00x5qNhUIE0t2Tl
 m/xf4VCmanA3FXIdHPhMzXIvoPtcGkn5NAMSigjjFToNQYuF07SjmLThNEPylltwhQitOzKFPn
 5l8v6vh+CZBI9YgAAAA==
To: Jan Kara <jack@suse.com>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781246400; l=1995;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=zBe8mptXEujMyjU6qf+RIqq+0ZlZo1cMKaiqend5j20=;
 b=WeqmhVEN3wupw9o9mRFUUMvTq3vhpzEk39WiJnCSMVuHt7PGWYysDe+ok4w5S2ZGiQHdevz6s
 Jlj5N0Ea7tYBvy/QaKuPdBwTgdtD4u7TLZcYIYQXvZBAEs+PoZt2Jwc
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

udf_load_sparable_map() accepts a sparing table when

	sizeof(*st) + le16_to_cpu(st->reallocationTableLen) > sb->s_blocksize

is false, i.e. it treats reallocationTableLen as a number of BYTES that
must fit in the block.  But the table is walked as an array of 8-byte
sparingEntry elements:

	for (i = 0; i < le16_to_cpu(st->reallocationTableLen); i++) {
		struct sparingEntry *entry = &st->mapEntry[i];
		... entry->origLocation ...
	}

in udf_get_pblock_spar15() and udf_relocate_blocks().  A
reallocationTableLen of N therefore passes the check whenever
sizeof(*st) + N <= blocksize, yet the consumers index
sizeof(*st) + N * sizeof(struct sparingEntry) bytes -- up to ~8x the
block.  On a crafted UDF image this is an out-of-bounds read in
udf_get_pblock_spar15(); udf_relocate_blocks() additionally feeds the
same length to udf_update_tag(), whose crc_itu_t() reads far past the
block, and its memmove() through st->mapEntry[] is an out-of-bounds
write.

Validate reallocationTableLen as the entry count it is, with
struct_size().

Fixes: 1df2ae31c724 ("udf: Fortify loading of sparing table")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 fs/udf/super.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/fs/udf/super.c b/fs/udf/super.c
index cad2e15d633b..d75bfc733975 100644
--- a/fs/udf/super.c
+++ b/fs/udf/super.c
@@ -1418,7 +1418,8 @@ static int udf_load_sparable_map(struct super_block *sb,
 		if (ident != 0 ||
 		    strncmp(st->sparingIdent.ident, UDF_ID_SPARING,
 			    strlen(UDF_ID_SPARING)) ||
-		    sizeof(*st) + le16_to_cpu(st->reallocationTableLen) >
+		    struct_size(st, mapEntry,
+				le16_to_cpu(st->reallocationTableLen)) >
 							sb->s_blocksize) {
 			brelse(bh);
 			continue;

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260612-b4-disp-91780c4e-fb52a746d9df

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

