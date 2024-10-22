From: Manas <manas18244@iiitd.ac.in>
Date: Tue, 22 Oct 2024 20:55:32 +0530
Subject: [PATCH] bcachefs: Add missing btree_bitmap_shift check in
 bch2_dev_btree_bitmap_marked_sectors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241022-fix-missing-cond-bcachefs-v1-1-064a40e55610@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIAOvDF2cC/x2MQQqAMAzAviI9W3BFYfoV8VBnpz04ZQURxL87P
 AaSPGCSVQyG6oEsl5oeqYCrKwgbp1VQl8JADbWuIcKoN+5qpmnFcKQF58Bhk2jI3vexc+KZCUp
 /Ziny/x6n9/0A2B8oKWsAAAA=
X-Change-ID: 20241022-fix-missing-cond-bcachefs-a889f51e8aa2
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: Hongbo Li <lihongbo22@huawei.com>, linux-bcachefs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Anup Sharma <anupnewsmail@gmail.com>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 linux-kernel-mentees@lists.linuxfoundation.org, 
 syzbot+e8eff054face85d7ea41@syzkaller.appspotmail.com, 
 Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729610734; l=2170;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=NGrI/M2/WyNTfN55jNdw37iuKR8z9suYfRj2qkDzA8E=;
 b=BGWbWB7uVb+YRHyrS+si0zmvjxu3ypdpqlixw+iXJ1cuktYtCNYYpc/DgJ0bIV40PN3NL1hv/
 s7C5v41YqdZBIBgcpie7iEA49J2qevrmUO/LypEiD4F+7tvvLVkOGJE
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The syzkaller bug triggers BUG_ON assertions in
__bch2_dev_btree_bitmap_mark. btree_bitmap_shift is checked in
bch2_dev_btree_bitmap_marked_sectors prior to this. But only one out of
two assertions is checked. This patch adds the other as conditional.

Reported-by: syzbot+e8eff054face85d7ea41@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=e8eff054face85d7ea41
Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
The syzkaller bug[1] triggers BUG_ON assertions in
__bch2_dev_btree_bitmap_mark.

btree_bitmap_shift is checked in bch2_dev_btree_bitmap_marked_sectors
prior to this. But only one out of two assertions is checked. This patch
adds the other as conditional.

A previous discussion about adding conditional in
bch2_dev_btree_bitmap_marked_sectors is here[2].

[1] https://syzkaller.appspot.com/bug?extid=e8eff054face85d7ea41
[2] https://lore.kernel.org/all/9ec25394-3d89-41b3-b62e-2d522cdc7319@huawei.com/
---
 fs/bcachefs/sb-members.h | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/fs/bcachefs/sb-members.h b/fs/bcachefs/sb-members.h
index 762083b564ee5909071eb4235c3d5cd6e72ee519..3141791491928930a707a6a16579c6d2e11e3700 100644
--- a/fs/bcachefs/sb-members.h
+++ b/fs/bcachefs/sb-members.h
@@ -347,12 +347,16 @@ void bch2_dev_errors_reset(struct bch_dev *);
 static inline bool bch2_dev_btree_bitmap_marked_sectors(struct bch_dev *ca, u64 start, unsigned sectors)
 {
 	u64 end = start + sectors;
+	u8 bitmap_shift = ca->mi.btree_bitmap_shift;
 
-	if (end > 64ULL << ca->mi.btree_bitmap_shift)
+	if (bitmap_shift > 57)
+		return true;
+
+	if (end > 64ULL << bitmap_shift)
 		return false;
 
-	for (unsigned bit = start >> ca->mi.btree_bitmap_shift;
-	     (u64) bit << ca->mi.btree_bitmap_shift < end;
+	for (unsigned bit = start >> bitmap_shift;
+	     (u64) bit << bitmap_shift < end;
 	     bit++)
 		if (!(ca->mi.btree_allocated_bitmap & BIT_ULL(bit)))
 			return false;

---
base-commit: 42f7652d3eb527d03665b09edac47f85fb600924
change-id: 20241022-fix-missing-cond-bcachefs-a889f51e8aa2

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

