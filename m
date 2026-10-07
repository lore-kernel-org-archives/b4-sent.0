From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 07 Oct 2026 09:41:20 +0900
Subject: [PATCH 1/2] ext4: don't cache unzeroed blocks as written after a
 failed zeroout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261007-ext4-fc-zeroout-v1-1-b86de6439431@samsung.com>
References: <20261007-ext4-fc-zeroout-v1-0-b86de6439431@samsung.com>
In-Reply-To: <20261007-ext4-fc-zeroout-v1-0-b86de6439431@samsung.com>
To: Theodore Ts'o <tytso@mit.edu>, linux-ext4@vger.kernel.org
Cc: Jan Kara <jack@suse.cz>, Andreas Dilger <adilger.kernel@dilger.ca>, 
 Baokun Li <libaokun@linux.alibaba.com>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, 
 "Ritesh Harjani (IBM)" <ritesh.list@gmail.com>, 
 Zhang Yi <yi.zhang@huawei.com>, Zhang Yi <yi.zhang@huaweicloud.com>, 
 Harshad Shirwadkar <harshadshirwadkar@gmail.com>, Li Chen <me@linux.beauty>, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791333679; l=2338;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=RixNJloKlUfTTc2VvX+N9XCtFJeSTCK2879z3k01VHs=;
 b=kq4ONXbnPOq9j/EmanCLfZs3xxBZibjN/oBtHU366YrMSq/c7ud5bKpOiarUOrhtEFuHIv7vg
 4BEYhdjtzOqBu27feR83Tk3wCq6HtjTjBY/uVLkAQWkRKqxxrFwWcZj
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ext4_ext_convert_to_initialized() may zero out the blocks before and
after the range being written and convert them to written together with
it, instead of splitting them off the unwritten extent. If
ext4_ext_zeroout() fails for one side, it falls back to splitting the
extent, so the blocks on that side stay unwritten in the extent tree.
But zero_ex1 or zero_ex2 keeps its length, and ext4_zeroout_es() still
inserts those blocks into the extent status tree as written.

Until that entry goes away, a read of those blocks returns whatever was
on the disk before the extent was allocated. A write to them is mapped
from the cache and goes in place without converting the extent, so its
data would read back as zeroes once the entry is dropped. To reproduce
on 4 KiB blocks with -o nodelalloc: fallocate 32 KiB, map the last seven
blocks of that extent to dm-error, write the first block, restore the
mapping and read the second block. It returns the old disk contents
instead of zeroes.

Clear the length of an extent that could not be zeroed out, so that
ext4_zeroout_es() skips it, as the comment at the out label intends.

Fixes: 308c57ccf431 ("ext4: if zeroout fails fall back to splitting the extent node")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/ext4/extents.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/fs/ext4/extents.c b/fs/ext4/extents.c
index 836396ea79..d65e30f3c1 100644
--- a/fs/ext4/extents.c
+++ b/fs/ext4/extents.c
@@ -3755,8 +3755,10 @@ ext4_ext_convert_to_initialized(handle_t *handle, struct inode *inode,
 				ext4_ext_pblock(ex) + split_map.m_lblk +
 				split_map.m_len - ee_block);
 			err = ext4_ext_zeroout(inode, &zero_ex1);
-			if (err)
+			if (err) {
+				zero_ex1.ee_len = 0;
 				goto fallback;
+			}
 			split_map.m_len = *allocated;
 		}
 		if (split_map.m_lblk - ee_block + split_map.m_len <
@@ -3769,8 +3771,10 @@ ext4_ext_convert_to_initialized(handle_t *handle, struct inode *inode,
 				ext4_ext_store_pblock(&zero_ex2,
 						      ext4_ext_pblock(ex));
 				err = ext4_ext_zeroout(inode, &zero_ex2);
-				if (err)
+				if (err) {
+					zero_ex2.ee_len = 0;
 					goto fallback;
+				}
 			}
 
 			split_map.m_len += split_map.m_lblk - ee_block;

-- 
2.43.0

