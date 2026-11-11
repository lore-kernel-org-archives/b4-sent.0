From: Mani Tofigh <mt4022@columbia.edu>
Subject: [PATCH 0/3] ext4: fix counts left by fast commit replay of a mkdir
Date: Wed, 11 Nov 2026 18:02:44 -0500
Message-Id: <20261111-ext4-fc-replay-mkdir-v1-0-4b20be29aed8@columbia.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw6DMAxF0a0gj7FEKEXQraAOQuKA+RU5tAIh9
 t4Ab3YG7+7gSZg8vKIdhH7s+TMFqDgC0+qpIWQbDGmS5ioMaV0ydAaF5kFvOPaWBR8m0dYV2VO
 rEsJ1FnK8Xtnqfdt/647McrbgOP45FbLPeAAAAA==
X-Change-ID: 20261111-ext4-fc-replay-mkdir-3c0adf845a19
To: Theodore Ts'o <tytso@mit.edu>
Cc: Andreas Dilger <adilger.kernel@dilger.ca>, 
 Baokun Li <libaokun@linux.alibaba.com>, Jan Kara <jack@suse.cz>, 
 Ojaswin Mujoo <ojaswin@linux.ibm.com>, 
 "Ritesh Harjani (IBM)" <ritesh.list@gmail.com>, 
 Zhang Yi <yi.zhang@huawei.com>, 
 Harshad Shirwadkar <harshadshirwadkar@gmail.com>, 
 linux-ext4@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794438165; l=1985;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=s9EkpYwpSolR0KtDZVkWqHGcJwk8MoygE6T++8LQ7sM=;
 b=VpVkrzKAvefNpNbgr52Wh3U42SQ1jXdqRJVWgknqB+j4rUFcniNknG2d4PR+K9EcFf4bmjAp+
 JUeAJX8X0RrAjkLkqVT/I9tj7H8ePv9G1bBNCu4oJ3rwYZnU47qSNRO
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On ext4 with fast_commit, a crash after an fsync of a file in a new
directory leaves counts that e2fsck has to fix.  The mount works, but
e2fsck -fn reports:

  Inode 14, i_blocks is 0, should be 8.  Fix? no
  Inode 2 ref count is 3, should be 4.  Fix? no
  Inode 14 ref count is 1, should be 2.  Fix? no
  Directories count wrong for group #0 (2, counted=3).

All it takes is

  mkdir a
  fd = creat a/f0
  fsync(fd)
  <crash>

Fast commits don't track directories, so the replay of a CREAT tag has
to redo what ext4_mkdir() does and misses each of these counts.  The
replay of an rmdir has the opposite problem with the link counts.
There's one patch per count.  Patch 1 has to go before patch 3, since
with patch 3 the replay of an rmdir frees the directory and lowers the
directory count.

Baokun has the same fix as patch 1 in his LBS RFC [1], plus a flex_bg
update that never runs during replay since s_log_groups_per_flex is
still 0 then.  Baokun, happy to drop patch 1 if you'd rather send yours.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it every time.

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/ext4fcmkdir.c

[1] https://lore.kernel.org/linux-ext4/20260508121539.4174601-12-libaokun@linux.alibaba.com/

---
Mani Tofigh (3):
      ext4: fix directory count after fast commit replay
      ext4: fix directory i_blocks after fast commit replay
      ext4: fix directory link counts after fast commit replay

 fs/ext4/ext4.h        |  4 +++-
 fs/ext4/fast_commit.c | 34 ++++++++++++++++++++++++++--------
 fs/ext4/ialloc.c      |  4 +++-
 fs/ext4/namei.c       |  4 ++--
 4 files changed, 34 insertions(+), 12 deletions(-)
---
base-commit: 067c5c24cef23d913b67eaaf71ae67e7169a6620
change-id: 20261111-ext4-fc-replay-mkdir-3c0adf845a19

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

