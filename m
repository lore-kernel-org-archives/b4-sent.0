From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH 0/6] powerpc/spufs: assorted fixes
Date: Sun, 02 Aug 2026 23:51:38 +0800
Message-Id: <20260802-fixes-v1-0-7368423440f4@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIpnb2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCwMj3bTMitRi3TRjY2Mzw2TDJKPEVCWg2oKiVLAEUGl0bG0tABNQmaV
 XAAAA
X-Change-ID: 20260802-fixes-f33361c1b2ae
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Paul Mackerras <paulus@ozlabs.org>, Arnd Bergmann <arnd@arndb.de>, 
 Al Viro <viro@zeniv.linux.org.uk>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2818;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=D3ZdLkxeKQ+GTih21pSwwkDXOkOvUZicqpK0qWxiBCY=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrPz0aWk8f0qquGarOzbMrX/o+01iK+91zkc2ndpez
 HErJv65tLCjlIVBjItBVkyR5XjBpW8Wvlt0t/hsSYaZw8oEMoSBi1MAJiLEyfA/TGeRYOUegUNz
 fpgLbjgR/WxWfG6LgGWTS62dxFRPBbsMhv+5q+ydUxz/LE8/Znav8sDslIxt274FHZo19YvO6qX
 XhabyAADeT0oh
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Six independent fixes for spufs. There is no dependency between them,
so they can be applied or dropped individually.

  1/6  spufs_coredump_extra_notes_write() never drops the reference taken
       by coredump_next_context(), so every SPE context written into a
       core dump leaks a spu_context. The matching ..._size() path gets
       this right.

  2/6  do_spu_run() copies out an uninitialized 'status' on the paths
       where spufs_run_spu() returns before assigning it, leaking four
       bytes of kernel stack to userspace.

  3/6  spu_process_callback() only aligns the NPC value, never bounds it,
       before using it as an offset into the local store. The register is
       userspace-controlled, so the following in_be32() can be driven far
       past the 256K mapping.

  4/6  spufs_setattr() calls setattr_copy() without setattr_prepare().
       notify_change() leaves that check to the filesystem, so mode and
       ownership of a context's files can be changed without the usual
       authorization.

  5/6  spufs_create_gang() calls unuse_gang() with the parent directory's
       i_rwsem held for write, and the resulting simple_recursive_removal()
       takes it again as I_MUTEX_CHILD. The task deadlocks against itself
       and leaves the spufs directory write-locked.

  6/6  The mailbox read/write handlers hold ctx->state_mutex across
       put_user()/get_user(), so a userfaultfd region or FUSE-backed user
       buffer can stall the context lock for an arbitrary time.

Patches 1-5 are tagged for stable. 6/6 is deliberately not: it changes the
atomicity of multi-element mailbox transfers rather than just adding a
check, so it seems better to let it soak in mainline first.

Build-tested only. I have no Cell or PS3 hardware, so none of this has
been exercised at runtime.

Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Junrui Luo (6):
      powerpc/spufs: fix spu_context leak in coredump
      powerpc/spufs: don't leak kernel stack via spu_run
      powerpc/spufs: bound NPC against local store size
      powerpc/spufs: check permissions in spufs_setattr()
      powerpc/spufs: fix deadlock on gang creation failure
      powerpc/spufs: don't hold state_mutex during user access

 arch/powerpc/platforms/cell/spufs/coredump.c |  6 +++-
 arch/powerpc/platforms/cell/spufs/file.c     | 52 ++++++++++++++++------------
 arch/powerpc/platforms/cell/spufs/inode.c    | 21 +++++++----
 arch/powerpc/platforms/cell/spufs/run.c      |  2 ++
 arch/powerpc/platforms/cell/spufs/syscalls.c |  2 +-
 5 files changed, 52 insertions(+), 31 deletions(-)
---
base-commit: 02dc699f83d04069fdabc996fc22d47cda47a4a9
change-id: 20260802-fixes-f33361c1b2ae

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

