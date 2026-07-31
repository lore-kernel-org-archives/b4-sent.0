From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 31 Jul 2026 17:54:55 -0500
Subject: [PATCH v2 2/2] dm array: reject an array block whose value size is
 not the caller's
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-b4-disp-4fd3bed9-v2-2-7b1835e4e7f6@proton.me>
References: <20260731-b4-disp-4fd3bed9-v2-0-7b1835e4e7f6@proton.me>
In-Reply-To: <20260731-b4-disp-4fd3bed9-v2-0-7b1835e4e7f6@proton.me>
To: Mike Snitzer <snitzer@kernel.org>, 
 Mikulas Patocka <mpatocka@redhat.com>
Cc: Ming-Hung Tsai <mtsai@redhat.com>, 
 Benjamin Marzinski <bmarzins@redhat.com>, dm-devel@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Alasdair Kergon <agk@redhat.com>, 
 Joe Thornber <ejt@redhat.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785538493; l=2167;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=Ul/YVEYx7ppMlrNbWtiuuf0bp6yCLk0T8hcMri+dvhc=;
 b=GMc3NdEdnxOY3TEwBmNrK1iW6ewemD37170O+LL6VpAiWbYeJ9RhKJKj58jcHkgVi5fx1k/Ng
 KlC8sRhAwB+BYUHmpw5iuKLdBFl5Tbuu3TXdtEdT2PPNSLVon8bGHxg
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

array_block_check() can only compare the header against itself, so a block
with value_size 4 and max_entries 1018 is internally consistent and passes.
dm-cache keeps two arrays -- mappings at 8 bytes and hints at 4 -- and the
roots for both live in the superblock. Point the mappings root at a hint
block and __load_mappings() walks it through an info whose value size is 8,
so element_at() strides 8 bytes over 4-byte entries and reaches offset 8160
of a 4096-byte block.

get_ablock() and __shadow_ablock() are the two places that hold the block
and the caller at once. Reject there when the two value sizes disagree.
Arrays only ever read their own blocks, so this fires on crafted metadata
only.

Fixes: 6513c29f44f2 ("dm persistent data: add transactional array")
Suggested-by: Ming-Hung Tsai <mtsai@redhat.com>
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/md/persistent-data/dm-array.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/md/persistent-data/dm-array.c b/drivers/md/persistent-data/dm-array.c
index 5949fb0e16c6..6de1c0467ec9 100644
--- a/drivers/md/persistent-data/dm-array.c
+++ b/drivers/md/persistent-data/dm-array.c
@@ -247,6 +247,14 @@ static int get_ablock(struct dm_array_info *info, dm_block_t b,
 		return r;
 
 	*ab = dm_block_data(*block);
+	if (le32_to_cpu((*ab)->value_size) != info->value_type.size) {
+		DMERR_LIMIT("%s failed: value_size %u != wanted %u", __func__,
+			    le32_to_cpu((*ab)->value_size),
+			    info->value_type.size);
+		dm_tm_unlock(info->btree_info.tm, *block);
+		return -EILSEQ;
+	}
+
 	return 0;
 }
 
@@ -309,6 +317,14 @@ static int __shadow_ablock(struct dm_array_info *info, dm_block_t b,
 		return r;
 
 	*ab = dm_block_data(*block);
+	if (le32_to_cpu((*ab)->value_size) != info->value_type.size) {
+		DMERR_LIMIT("%s failed: value_size %u != wanted %u", __func__,
+			    le32_to_cpu((*ab)->value_size),
+			    info->value_type.size);
+		dm_tm_unlock(info->btree_info.tm, *block);
+		return -EILSEQ;
+	}
+
 	if (inc)
 		inc_ablock_entries(info, *ab);
 

-- 
2.55.0

