From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH 0/5] NFSv4/flexfiles: harden LAYOUTGET and GETDEVICEINFO
 decode
Date: Tue, 04 Aug 2026 18:55:00 +0800
Message-Id: <20260804-nfs-fixes-v1-0-1544df970e7c@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAATFcWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCwMT3by0Yt20zIrUYt0ky0STFOM0k1RTA3MloPqColSwBFB5dGxtLQB
 CNjQkWwAAAA==
X-Change-ID: 20260804-nfs-fixes-b9a4d3f4e507
To: Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>
Cc: linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Curley <jcurley@purestorage.com>, 
 Michael Bommarito <michael.bommarito@gmail.com>, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2609;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=hhGrI/mzu3aPM7QOJT92Awih3YCME5wdzbeEt4sTwTE=;
 b=kA0DAAoWceg4UIuO8EAByyZiAGpxxRehjihg2fa9p7l612YNlk+omlLFaNcayWpISPql/qkaA
 Yh1BAAWCgAdFiEEx3DS9jhNtC20TLRjceg4UIuO8EAFAmpxxRcACgkQceg4UIuO8EA38wD+NFSS
 t2R5KI1Lq9icoRtW7TkkbE/EhQNa6bL+1BrI1igBALxCjQAGVXTYqLYtEphKxM+FZqnPzwaZUbP
 lA0REHCAA
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All five patches fix bugs the flexfiles layout driver hits while decoding
a reply body from the metadata server.

Patches 1-3 are on the GETDEVICEINFO side.

Patch 1 bounds the multipath address count. Once the xdr_stream is
exhausted, nfs4_decode_mp_ds_addr() returns NULL without consuming a
byte, so every remaining iteration re-fails at the same offset. A server
advertising 0xffffffff addresses in a body that holds none of them spins
the loop for roughly 2^32 iterations with no rescheduling point.

Patch 2 fixes a leak of the r_netid string. Both loops in
nfs4_ff_alloc_deviceid_node() that drain the local dsaddrs list free
da_remotestr and the da itself but not da_netid.

Patch 3 checks the sscanf return in nfs4_decode_mp_ds_addr(). Nothing
constrains the characters after the last two dots of r_addr, so an
address such as "192.168.1.1.x.y" leaves the uninitialised tmp[] array
unwritten. The stale stack contents become the data server port and are
rendered into da_remotestr, which can leak client stack memory back to
the metadata server.

Patches 4-5 are on the LAYOUTGET side.

Patch 4 bounds the filehandle version count, which sizes a kzalloc_objs()
of struct nfs_fh. sizeof(struct nfs_fh) is 130, so a count of 32264 or
more pushes get_order() past MAX_PAGE_ORDER and trips the page
allocator's WARN_ON_ONCE_GFP().

Patch 5 rejects a stripe_unit above U32_MAX. It is decoded and validated
as a u64, but ff_layout_pg_test() narrows it to u32 and
nfs4_ff_layout_calc_dss_id() passes it to do_div(), which narrows the
divisor itself. A non-zero multiple of 2^32 therefore passes the
existing zero check and reaches both dividers as a zero divisor.

The five are independent of each other and can be applied in any order.

Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Junrui Luo (5):
      NFSv4/flexfiles: bound the multipath address count
      NFSv4/flexfiles: fix da_netid leak in nfs4_ff_alloc_deviceid_node()
      NFSv4/pNFS: check the sscanf return in nfs4_decode_mp_ds_addr
      NFSv4/flexfiles: bound the filehandle version count
      NFSv4/flexfiles: bound stripe_unit to 32 bits

 fs/nfs/flexfilelayout/flexfilelayout.c    | 6 ++++--
 fs/nfs/flexfilelayout/flexfilelayout.h    | 9 +++++++++
 fs/nfs/flexfilelayout/flexfilelayoutdev.c | 7 +++++++
 fs/nfs/pnfs_nfs.c                         | 3 ++-
 4 files changed, 22 insertions(+), 3 deletions(-)
---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260804-nfs-fixes-b9a4d3f4e507

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

