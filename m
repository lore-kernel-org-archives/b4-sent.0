From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH v2 0/5] powerpc/spufs: assorted fixes
Date: Tue, 04 Aug 2026 16:50:37 +0800
Message-Id: <20260804-fixes-v2-0-5bfd827297f9@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN2ncWoC/12MQQ7CIBBFr9LMWgwMBBtX3sN0UXGwE7XTQG00D
 XcXu3T5/n95K2RKTBmOzQqJFs4sYwXcNRCGfryR4mtlQI1etxpV5DdlFa213gRzwZ6gulOi7aj
 quas8cJ4lfbbsYn7rf2ExSquD9a1D65yO7iSv+SFy3wd5QldK+QKRXSXYnAAAAA==
X-Change-ID: 20260802-fixes-f33361c1b2ae
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, Paul Mackerras <paulus@ozlabs.org>, 
 Al Viro <viro@zeniv.linux.org.uk>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2656;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=QCVnxSeHlT4Kk1BbHgcw8WESABILpZ1Gcclv0+B9Efw=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMLlry/5/e87ufmR/BnWtfHpHIHrQyawX+Nw/ekRF
 PCw42+Jt0tHKQuDGBeDrJgiy/GCS98sfLfobvHZkgwzh5UJZAgDF6cATEQoieF/lJoy52nuRazf
 itafO39H+rGWU6HqsR8PvjXzbolcde3db4Y/HOoCK16bHTHdpGSwISJGZsOK8hPsiUGXzzs/4ry
 wT/cYPwBdQU1U
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Five independent fixes for spufs. There is no dependency between them,
so they can be applied or dropped individually.

  1/5  spufs_coredump_extra_notes_write() never drops the reference taken
       by coredump_next_context(), so every SPE context written into a
       core dump leaks a spu_context. The matching ..._size() path gets
       this right.

  2/5  do_spu_run() copies out an uninitialized 'status' on the paths
       where spufs_run_spu() returns before assigning it, leaking four
       bytes of kernel stack to userspace.

  3/5  spufs_setattr() calls setattr_copy() without setattr_prepare().
       notify_change() leaves that check to the filesystem, so mode and
       ownership of a context's files can be changed without the usual
       authorization.

  4/5  spufs_create_gang() calls unuse_gang() with the parent directory's
       i_rwsem held for write, and the resulting simple_recursive_removal()
       takes it again as I_MUTEX_CHILD. The task deadlocks against itself
       and leaves the spufs directory write-locked.

  5/5  The mailbox read/write handlers hold ctx->state_mutex across
       put_user()/get_user(), so a userfaultfd region or FUSE-backed user
       buffer can stall the context lock for an arbitrary time.

Patches 1-4 are tagged for stable. 5/5 is deliberately not: it changes the
atomicity of multi-element mailbox transfers rather than just adding a
check, so it seems better to let it soak in mainline first.

Build-tested only. I have no Cell or PS3 hardware, so none of this has
been exercised at runtime.

---
Changes in v2:
- Add an Assisted-by: trailer to each patch identifying the tooling, as
  requested by Arnd.
- Drop 3/6 from v1 (bound NPC against local store size).
- Link to v1: https://lore.kernel.org/r/20260802-fixes-v1-0-7368423440f4@outlook.com

---
Junrui Luo (5):
      powerpc/spufs: fix spu_context leak in coredump
      powerpc/spufs: don't leak kernel stack via spu_run
      powerpc/spufs: check permissions in spufs_setattr()
      powerpc/spufs: fix deadlock on gang creation failure
      powerpc/spufs: don't hold state_mutex during user access

 arch/powerpc/platforms/cell/spufs/coredump.c |  6 +++-
 arch/powerpc/platforms/cell/spufs/file.c     | 52 ++++++++++++++++------------
 arch/powerpc/platforms/cell/spufs/inode.c    | 21 +++++++----
 arch/powerpc/platforms/cell/spufs/syscalls.c |  2 +-
 4 files changed, 50 insertions(+), 31 deletions(-)
---
base-commit: 02dc699f83d04069fdabc996fc22d47cda47a4a9
change-id: 20260802-fixes-f33361c1b2ae

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

