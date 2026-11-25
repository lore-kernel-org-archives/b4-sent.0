From: Ernest Borowski <ernest.borowski.git@proton.me>
Subject: [PATCH 0/4] fstests: ntfs support and three buffered write tests
Date: Wed, 25 Nov 2026 20:03:42 +0100
Message-Id: <20261125-ntfs-reproducers-v1-0-0cc67533d803@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBG4avIrBvIBBTaq4gLTX7tdBFlRosg3
 t20Lr/FewcZVGD0qg5SfMVkzgX8qCi++zzBSSqm4EPDHGqX19GcYtE5bRFqLnnw4PnpG+6pZIt
 ilP2/bLvbtg0fxPX3ofO8AJT3HC50AAAA
X-Change-ID: 20261125-ntfs-reproducers-d0e1b019061a
To: fstests@vger.kernel.org, Zorro Lang <zlang@kernel.org>
Cc: ntfs@lists.linux.dev, Namjae Jeon <linkinjeon@kernel.org>, 
 Hyunchul Lee <hyc.lee@gmail.com>, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2462;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=XBaQBfKYzKkAfsMoyeeX7k9F8LyBCcyRyZ9ahXpBzLg=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmx2Q75f0vVsKXEdK/d+MrKc/PqpwykPZudlG65fm+R76
 cyqJ+ZlHaUsDGJcDLJiiiwd/2+E+IR8+7QsTqsPZg4rE8gQBi5OAZhIpgEjw5OvIRu/XxN5v72A
 rUYucZa4p9a8BwlRn/kTQxZoqPbXmTAyPBSJvuPLs+//w+i4ggNVMjMcK0NnLjB5P/vM8od+cp7
 JnAA=
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series lets fstests run on the ntfs driver in fs/ntfs and adds three
generic tests for buffered write bugs found in it.

Patch 1 adds FSTYP=ntfs for the kernel driver. Volumes are made with
mkfs.ntfs and checked with fsck.ntfs from ntfsprogs-plus [1]. Mounts pass
-i, so that mount(8) always uses the kernel driver.

Patches 2-4 add the tests. Each names its fix with _fixed_by_fs_commit;
none of the fixes is merged yet:

- generic/816 checks the size after a buffered write runs out of space.
  Fixed by "ntfs: trim the sizes after a short write" from Zhan Xusheng,
  at v10 now [2].
- generic/817 runs fallocate, punch hole, collapse and insert range after
  a buffered write that faulted. Fixed by patches 7 and 8 of the ntfs
  delalloc series [3].
- generic/818 makes a short copy into a hole over freed blocks and checks
  that no old data shows. Fixed by patch 10 of the same series.

The tests need only xfs_io and one small helper, src/pwrite-short-copy.c.
I ran them on ntfs-next at cluster sizes 512, 4096 and 65536. All three
fail on ntfs-next as it is; with the delalloc series 817 and 818 pass; with
Zhan's patch on top all three pass.

[1] https://github.com/ntfsprogs-plus/ntfsprogs-plus
[2] https://lore.kernel.org/r/20261125051247.2880928-1-zhanxusheng1024@gmail.com
[3] https://lore.kernel.org/r/20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me

---
Ernest Borowski (4):
      common: add support for the ntfs driver
      generic: check the size after a buffered write runs out of space
      generic: test fallocate after a buffered write that faulted
      generic: test a short copy into a hole of reused blocks

 .gitignore              |   1 +
 common/config           |   9 +++++
 common/rc               |  37 +++++++++++++++++-
 src/Makefile            |   2 +-
 src/pwrite-short-copy.c | 101 ++++++++++++++++++++++++++++++++++++++++++++++++
 tests/generic/816       |  67 ++++++++++++++++++++++++++++++++
 tests/generic/816.out   |   2 +
 tests/generic/817       |  83 +++++++++++++++++++++++++++++++++++++++
 tests/generic/817.out   |   2 +
 tests/generic/818       |  58 +++++++++++++++++++++++++++
 tests/generic/818.out   |   2 +
 11 files changed, 362 insertions(+), 2 deletions(-)
---
base-commit: 71641219a506ac62bfa231592394265ca812670e
change-id: 20261125-ntfs-reproducers-d0e1b019061a

Best regards,
--  
Ernest Borowski <ernest.borowski.git@proton.me>

