From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 12:57:20 +0000
Subject: [PATCH] fscrypt: Don't set a policy on immutable or append-only
 directories
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-fscrypt-v1-1-c07e1dd93644@gmail.com>
X-B4-Tracking: v=1; b=H4sIAC/y/moC/yXMQQ5AMBCF4avIrDVpu2jKVcSixmAskA5CxN0Vy
 y/537tAKDIJlNkFkXYWnqcEk2eAQ5h6Utwmg9XWGWMK1QnGc1mVDz44ry0G1JDqJVLHx/dU1b9
 la0bC9Z3DfT9gVfx9awAAAA==
X-Change-ID: 20261119-fscrypt-8a8a6802cac0
To: ebiggers@kernel.org
Cc: jaegeuk@kernel.org, tytso@mit.edu, linux-kernel@vger.kernel.org, 
 linux-fscrypt@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795093039; l=2183;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=bkUMq9TQAUp7j8HTWB6oD7Om1tlULjPX8N2Xbu4lXn4=;
 b=BOF/mJPnAVkejDkaX0f8vEY4LP69odAYy37bE0kKTGiRbRAsRU4uGR+z41xKWLqJipS22RxD8
 ws7iITmByAYAheXTfuJcvUqTuQ1dC3MqNc7+Zr96JYKbV7UrH6H9PBd
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

FS_IOC_SET_ENCRYPTION_POLICY stores an encryption context in the
directory (an xattr on ext4 and f2fs) and marks the inode as encrypted.
fscrypt_ioctl_set_policy() checks inode_owner_or_capable(), but not the
immutable or append-only inode flags, so the ioctl also succeeds on a
directory with one of those flags set. Setting any other xattr on the
same directory fails with -EPERM in may_write_xattr(), and
FS_IOC_ENABLE_VERITY refuses such files as well.

For example, on ext4 with the encrypt feature:

	mkdir d && chattr +i d
	setfattr -n user.x -v 1 d           -> Operation not permitted
	FS_IOC_SET_ENCRYPTION_POLICY on d   -> succeeds, d now has a policy

Return -EPERM for an immutable or append-only directory before setting
the policy, as may_write_xattr() does. Calls that find the same policy
already set still return 0, since they don't change the inode.

Found with a static analysis tool and checked by hand.

Fixes: 0b81d0779072 ("fs crypto: move per-file encryption from f2fs tree to fs/crypto")
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Tested in QEMU (x86_64, ext4 with -O encrypt, v1 policy). Before the
patch the ioctl succeeds on both immutable and append-only empty
directories; with it both get -EPERM, and an ordinary empty directory
still gets its policy.

The Fixes: tag points to the commit that created fs/crypto/policy.c; the
ext4 and f2fs encryption policy code before it lacked these checks too.
I left out Cc: stable, as I'm not sure you'd want this backported.
---
 fs/crypto/policy.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/fs/crypto/policy.c b/fs/crypto/policy.c
index 6dd510f93e6d..86a8254bc3a8 100644
--- a/fs/crypto/policy.c
+++ b/fs/crypto/policy.c
@@ -553,6 +553,8 @@ int fscrypt_ioctl_set_policy(struct file *filp, const void __user *arg)
 			ret = -ENOTDIR;
 		else if (IS_DEADDIR(inode))
 			ret = -ENOENT;
+		else if (IS_IMMUTABLE(inode) || IS_APPEND(inode))
+			ret = -EPERM;
 		else if (!inode->i_sb->s_cop->empty_dir(inode))
 			ret = -ENOTEMPTY;
 		else



