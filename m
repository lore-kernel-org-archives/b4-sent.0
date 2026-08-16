From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH 0/3] NFSv4/pnfs: LAYOUTSTATS overflow, DS cache aliasing,
 lseg leak
Date: Sun, 16 Aug 2026 16:01:26 +0800
Message-Id: <20260816-nfs4-fixes-v1-0-a810f21729ab@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFdugWoC/x2LQQqAIBAAvyJ7TlApsb4SHazW2ouFCxGIf2/pO
 MxMBcZCyDCpCgUfYrqygO0UbGfMB2rahcEZ502wXufEvU70ImtM0YTVej+MFmS4C/5C+nlp7QO
 UOy8KXAAAAA==
X-Change-ID: 20260816-nfs4-fixes-efa08b166591
To: Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 Peng Tao <tao.peng@primarydata.com>, 
 Jeff Layton <jeff.layton@primarydata.com>, 
 Tao Peng <bergwolf@primarydata.com>, 
 Weston Andros Adamson <dros@primarydata.com>, 
 Tom Haynes <loghyr@primarydata.com>
Cc: Trond Myklebust <trond.myklebust@primarydata.com>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Trond Myklebust <trond.myklebust@hammerspace.com>, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2261;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=ugIdjCPx7Q44lWqGntaI4myy9Ts7PbfRvgOhT5lVeFU=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMa8KBV1LqFvtlsyOHozLz+tNuQ69vRB/TyTGVxne
 RqeiwUxm3eUsjCIcTHIiimyHC+49M3Cd4vuFp8tyTBzWJlAhjBwcQrARJ5qMvxT/rB1u2b8krdr
 1zAoCjt8asnZt75JL2BiK+vNDK1dM4UTGRm2mCxzTEpWZhFk72x4PmF5a9C1V7MW7gr4YSwxfeK
 +E5xsAEHIR34=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three independent pNFS client fixes, all in paths that consume data the
server gets to choose. They touch different files and can be applied in
any order.

Patch 1 raises PNFS_LAYOUTSTATS_MAXSIZE. encode_layoutstats_maxsz
reserves 256 bytes for the layoutupdate4 body, but a flexfiles record
whose data server filehandle approaches NFS_MAXFHSIZE already exceeds
that before the netaddr4 is encoded at all. The encoder then walks past
the end of the send buffer while dss_info->mirror->lock is held, and
that lock is never released.

Patch 2 adds the NFS version to the per-net data server cache key.
nfs4_pnfs_ds_add() matches on the multipath address set alone, which is
enough for the files layout driver because it always connects with
version 4, but flexfiles takes its version tuple from GETDEVICEINFO per
device. One address serving both NFSv3 and NFSv4 - a legitimate
configuration - collapses into a single nfs4_pnfs_ds, and whichever
mirror connects first pins ds_clp to its own version; the other one then
selects rpc_call_ops for a version the connection does not speak.

Patch 3 restores the pnfs_free_lseg_list() call on the out_forget path
of pnfs_layout_process(). The drain was added by 814b84971388, dropped
by 08bd8dbe8882 when the destination became lo->plh_return_segs (which
is drained elsewhere), and not restored by fb700ef02676 when the
destination went back to the on-stack free_me.

Signed-off-by: Junrui Luo <moonafterrain@outlook.com>

---
Junrui Luo (3):
      NFSv4.2: fix LAYOUTSTATS send buffer exhaustion
      NFSv4/pnfs: key the data server cache on the NFS version
      NFSv4.1: fix layout segment leak on the pnfs_layout_process() forget path

 fs/nfs/filelayout/filelayoutdev.c         |  3 ++-
 fs/nfs/flexfilelayout/flexfilelayoutdev.c |  3 ++-
 fs/nfs/pnfs.c                             |  1 +
 fs/nfs/pnfs.h                             |  3 ++-
 fs/nfs/pnfs_nfs.c                         | 14 +++++++++-----
 include/linux/nfs_xdr.h                   |  2 +-
 6 files changed, 17 insertions(+), 9 deletions(-)
---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260816-nfs4-fixes-efa08b166591

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

