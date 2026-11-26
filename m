From: Ernest Borowski <ernest.borowski.git@proton.me>
Subject: [PATCH v2 0/4] fstests: ntfs support and three buffered write
 tests
Date: Thu, 26 Nov 2026 21:29:23 +0100
Message-Id: <20261126-ntfs-reproducers-v2-0-7d5fa5a688b9@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NzQ6CMBCEX4Xs2ZrdEvDn5HsYDtAuUhNbsi1EQ
 3h3C949fpmZbxaILI4jXIsFhGcXXfAZ9KEAM7T+wcrZzKBR10S6Uj71UQmPEuxkWKKyyNQhXbC
 mFvJsFO7de1femx/HqXuySZtnawwupiCf/XOmrfdHP5NChcbUp6os7RnLW85S8McXQ7Ou6xcH2
 TiEwgAAAA==
X-Change-ID: 20261125-ntfs-reproducers-d0e1b019061a
To: fstests@vger.kernel.org, Zorro Lang <zlang@kernel.org>
Cc: ntfs@lists.linux.dev, Namjae Jeon <linkinjeon@kernel.org>, 
 Hyunchul Lee <hyc.lee@gmail.com>, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 Ernest Borowski <ernest.borowski.git@proton.me>, 
 Baolin Liu <liubaolin@kylinos.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3814;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=SWS0raqeCoHoC84Ueny9Tod2CHfP/gGmqWmXz0vLsv8=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmyOaUtiVrgVVeYp1V/VUyjkX3n2XfPy50W/XZTbUj5t+
 nPTcGN/RykLgxgXg6yYIkvH/xshPiHfPi2L0+qDmcPKBDKEgYtTACaSH8DIsLBsUpVz+RTzBr9I
 56Zlxy643HASNXae9P+/Qc2Fq2sCmxj+6UmaLnn2e7Lh/2Zz78VX5c7PlXVX+BR4JPad40+hW43
 ZfAA=
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
  at v11 now [2].
- generic/817 runs fallocate, punch hole, collapse and insert range after
  a buffered write that faulted. Fixed by patches 7 and 8 of the ntfs
  delalloc series [3].
- generic/818 makes a short copy into a hole over freed blocks and checks
  that no old data shows. Fixed by patch 10 of the same series.

The tests need only xfs_io and one small helper, src/pwrite-short-copy.c.
I ran them on ntfs-next at cluster sizes 512, 4096 and 65536, and with
4096 byte sectors and clusters. All three fail on ntfs-next as it is; with
the delalloc series 817 and 818 pass; with Zhan's patch on top all three
pass. On XFS and ext4 (mounted with buffered_iomap), with 1k and 4k
blocks, all three pass.

[1] https://github.com/ntfsprogs-plus/ntfsprogs-plus
[2] https://lore.kernel.org/r/20261126015731.3254689-1-zhanxusheng1024@gmail.com
[3] https://lore.kernel.org/r/20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me

---
Changes in v2:
- common: pass -i in _mount(), so that it also reaches mounts with
  MOUNT_OPTIONS or TEST_FS_MOUNT_OPTS set (Baolin)
- common: count the size for _scratch_mkfs_sized in sectors of the -s
  size when MKFS_OPTIONS gives one (Baolin)
- generic/816: fail on write errors other than ENOSPC, and report "not
  run" after the checks when the write stored nothing (Baolin); start the
  write one unit before the end of the file, so that XFS and ext4 come up
  short instead of failing with nothing written
- generic/817: add Baolin's Reviewed-by
- generic/818: check the helper's exit status and that the write returns
  between one byte and the readable length; fill the filesystem with data
  first, so that the hole gets blocks that held data; skip with the
  discard mount option and with compression (Baolin)
- all: the added lines pass shellcheck; variables in arguments are
  quoted, and each line that keeps a warning on purpose (MKFS_OPTIONS
  split into words, _scratch_cycle_mount without its optional argument)
  has a disable comment with the reason
- Link to v1: https://patch.msgid.link/20261125-ntfs-reproducers-v1-0-0cc67533d803@proton.me

---
Ernest Borowski (4):
      common: add support for the ntfs driver
      generic: check the size after a buffered write runs out of space
      generic: test fallocate after a buffered write that faulted
      generic: test a short copy into a hole of reused blocks

 .gitignore              |   1 +
 common/config           |   9 +++++
 common/rc               |  52 +++++++++++++++++++++++--
 src/Makefile            |   2 +-
 src/pwrite-short-copy.c | 101 ++++++++++++++++++++++++++++++++++++++++++++++++
 tests/generic/816       |  91 +++++++++++++++++++++++++++++++++++++++++++
 tests/generic/816.out   |   2 +
 tests/generic/817       |  84 ++++++++++++++++++++++++++++++++++++++++
 tests/generic/817.out   |   2 +
 tests/generic/818       |  88 +++++++++++++++++++++++++++++++++++++++++
 tests/generic/818.out   |   2 +
 11 files changed, 430 insertions(+), 4 deletions(-)
---
base-commit: 71641219a506ac62bfa231592394265ca812670e
change-id: 20261125-ntfs-reproducers-d0e1b019061a

Best regards,
--  
Ernest Borowski <ernest.borowski.git@proton.me>

