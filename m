From: Suyuan Wang <shyckless@gmail.com>
Date: Fri, 20 Nov 2026 04:26:54 +0000
Subject: [PATCH v2] fscrypt: Don't set a policy on immutable or append-only
 directories
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-fscrypt-v2-1-fb752135ea32@gmail.com>
X-B4-Tracking: v=1; b=H4sIAA3M/2oC/yXMQQ5AMBCF4avIrDVpu0BcRSwYU8aipIMQ6d0Vy
 y/537tBKDAJ1NkNgQ4WXnyCzTPAqfMjKR6SwWpbGGO1coLhWjdVlRrRuKGiUkOq10COz++paX/
 L3s+E2zuHGB9Z/Mw3awAAAA==
X-Change-ID: 20261120-fscrypt-870cc1fd8e70
To: ebiggers@kernel.org
Cc: tytso@mit.edu, jaegeuk@kernel.org, linux-kernel@vger.kernel.org, 
 linux-fscrypt@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795148814; l=3139;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=HdhE/JCVYL2ShTcy8TLudc8o8wzmup9lBguCVgI9jFA=;
 b=u5JY19oJwFRT9thLPhYwuqQwILk8t5gZKg9f70tbYfLu8UCqK/d5b2jUitWeBGrpXS21ya+vb
 YmGkAV+dFAnDI3X1EzpcXLIrqA0SZocPubH7LDtmBMk3iHLgs5OSyis
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
already set still return 0, since they don't change the inode. Update
the documented EPERM cases to match.

Found with a static analysis tool and checked by hand.

Fixes: 9bd8212f981e ("ext4 crypto: add encryption policy and password salt support")
Fixes: f424f664f0e8 ("f2fs crypto: add encryption policy and password salt support")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Changes in v2:
- Point the Fixes tags at the ext4 and f2fs commits that added the
  ioctls, and ask for a stable backport (Eric).
- Document the new EPERM case in fscrypt.rst (Eric).

Tested in QEMU (x86_64, ext4 with -O encrypt, v1 policy). Before the
patch the ioctl succeeds on both immutable and append-only empty
directories; with it both get -EPERM, and an ordinary empty directory
still gets its policy.

v1: https://lore.kernel.org/all/20261119-fscrypt-v1-1-c07e1dd93644@gmail.com/
---
 Documentation/filesystems/fscrypt.rst | 2 +-
 fs/crypto/policy.c                    | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/filesystems/fscrypt.rst b/Documentation/filesystems/fscrypt.rst
index 6e2e511a70bb..188295f09b21 100644
--- a/Documentation/filesystems/fscrypt.rst
+++ b/Documentation/filesystems/fscrypt.rst
@@ -736,7 +736,7 @@ FS_IOC_SET_ENCRYPTION_POLICY can fail with the following errors:
   feature flag enabled using ``tune2fs -O encrypt`` or ``mkfs.ext4 -O
   encrypt``.)
 - ``EPERM``: this directory may not be encrypted, e.g. because it is
-  the root directory of an ext4 filesystem
+  the root directory of an ext4 filesystem or is immutable or append-only
 - ``EROFS``: the filesystem is readonly
 
 Getting an encryption policy
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



