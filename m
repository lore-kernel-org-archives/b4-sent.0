From: Eric Davis <eric.davis@broadcom.com>
Subject: [PATCH rdma-next v2 00/13] RDMA/core: Ultra Ethernet transport
 verbs
Date: Mon, 19 Oct 2026 20:03:27 -0700
Message-Id: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNTQ6CMBCFr0Jm7ZhOBRRX3sOwKO0gNYGSthAM4
 e4WXLl4i5f3860Q2FsOcM9W8DzbYN2QjDxloDs1vBitSR6kkKWoZIUTR7QNaucZzU1ylVNbcCE
 hLUbPrV2Otyd40ysceIlQ/6IwNW/WcX/by50N0fnPQZ7pmOwQEpT/QWZCgUpwmTK6El0ejXfKa
 Nefk6Detu0LOVBlLcYAAAA=
X-Change-ID: 20260929-uet-ib-core-d82e941f5e52
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792465414; l=6042;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=sFFlSa++fT5Z1uSmM7NvspZa9JtaPfiaBKSTJI52v7c=;
 b=cZLgx2bjV5ZmtMIG1FQdLri8EC/JgRUHb4Pn2iNONujZyaFOJ0wRbSejFLD4xpcBVmhpmPozD
 gYexouJsJtgC2XLFnEEdAzFgdqohdFYlYGzobUJ59yn7Dgyqm7ID4Ml
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ultra Ethernet defines a reliable unconnected transport. A queue pair
sends to any peer in its job without a connection, incoming traffic is
demultiplexed on a JobID rather than on a connection, and what a device
orders is far weaker than IB or RoCE and varies between devices. None of
that has a home in the current uverbs ABI.

This series adds the generic half. The objects, methods, and attributes
any UET device implements. No driver is part of it, though two already
exist against this ABI. A reference device model that implements all of
it, and HPE's Slingshot driver implementing a large subset. That is the
argument for ib_core carrying this. What is device specific should come
from private interfaces per vendor.

Patch 1 widens the uverbs object key. The two new core objects would
otherwise leave drivers no free object keys.

Patches 2-4 expose the transport. The two UET encapsulations as GID
types, the capabilities and limits a device advertises, and IB_QPT_RU
with its 32-bit queue pair number.

Patch 5 widens address handles, which an unconnected peer needs since
it is named by both a network address and a queue pair number.

Patch 6 adds a query for what a queue pair type actually orders.

Patch 7 adds jobs and job keys, the objects an unconnected transport
demultiplexes and authorizes on. A job can be exported to a file
descriptor, so an unprivileged process can join one set up for it.

Patches 8-10 let a queue pair be created ready to send, since a
transport with nothing to negotiate gains nothing from the modify
sequence. Patch 8 is a no-functional-change refactor pulling the
attribute copy out of modify_qp. Patch 9 lets create take those
attributes. Patch 10 adds the attributes a reliable unconnected
transport needs.

Patches 11-13 cover memory registration with a job binding, a chosen
key, derived regions, 64-bit keys for devices whose keys do not fit
in 32 bits, and attaching a region to one queue pair so the network
reaches it only over that QP.

New attributes are optional, so existing userspace is unaffected and a
device without a feature reports it absent rather than failing. The
attributes that restrict access are sent mandatory by userspace, so a
kernel that does not know one refuses the request rather than creating
an object with less protection than was asked for.

Tested against a reference device implementing the ABI, and against rxe
to confirm nothing already upstream regressed. The userspace half is a
matching rdma-core series.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
Changes in v2:
- Rebase on rdma for-next
- Refuse the write post_send and post_recv commands on an RU QP (4)
- Read the extended AH attribute with uverbs_copy_from_or_zero() (5, 7)
- Export a job as a uverbs FD object, import it through a raw fd, and
  drop the job revoke on device removal (7)
- Drop the job and job key flags attributes, none was defined (7)
- Require the address table size at job allocation and check each
  index against it (7)
- Use uverbs_finalize_uobj_create() in JKEY_CREATE and
  uverbs_copy_to_struct_or_zero() in JOB_ADDR_QUERY (7)
- Drop IS_ERR() checks on mandatory handles (5, 7)
- Simplify the REG_MR optional attribute handling (11, 12)
- Reword the commit messages of patches 1 and 6
- Link to v1: https://patch.msgid.link/20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com

To: Jason Gunthorpe <jgg@ziepe.ca>
To: Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Eric Davis (13):
      RDMA/core: widen the uverbs object key
      RDMA/core: add the UET GID types
      RDMA/core: report the reliable unconnected device capabilities
      RDMA/core: add the reliable unconnected queue pair type
      RDMA/core: extended address handle attributes
      RDMA/core: query the semantics a queue pair type guarantees
      RDMA/core: job and job key objects
      RDMA/uverbs: factor out the queue pair attribute copy
      RDMA/core: create a queue pair ready to send
      RDMA/core: queue pair attributes for unconnected transports
      RDMA/core: extended memory registration
      RDMA/core: 64-bit memory keys
      RDMA/core: attach a memory region to a queue pair

 drivers/infiniband/core/Makefile                  |   3 +-
 drivers/infiniband/core/cache.c                   |  12 +-
 drivers/infiniband/core/cma.c                     |   4 +
 drivers/infiniband/core/device.c                  |  16 +-
 drivers/infiniband/core/nldev.c                   |   4 +
 drivers/infiniband/core/rdma_core.h               |   2 +
 drivers/infiniband/core/restrack.c                |  17 +-
 drivers/infiniband/core/roce_gid_mgmt.c           |   6 +-
 drivers/infiniband/core/user_mad.c                |   4 +-
 drivers/infiniband/core/uverbs.h                  |  15 +
 drivers/infiniband/core/uverbs_cmd.c              | 275 ++++++----
 drivers/infiniband/core/uverbs_std_types.c        |  70 ++-
 drivers/infiniband/core/uverbs_std_types_device.c |  73 ++-
 drivers/infiniband/core/uverbs_std_types_job.c    | 628 ++++++++++++++++++++++
 drivers/infiniband/core/uverbs_std_types_mr.c     | 218 +++++++-
 drivers/infiniband/core/uverbs_std_types_qp.c     | 340 +++++++++++-
 drivers/infiniband/core/uverbs_uapi.c             |   2 +
 drivers/infiniband/core/verbs.c                   | 108 +++-
 include/rdma/ib_verbs.h                           | 239 +++++++-
 include/rdma/restrack.h                           |   8 +
 include/rdma/uverbs_ioctl.h                       |   4 +-
 include/uapi/rdma/ib_user_ioctl_cmds.h            | 115 ++++
 include/uapi/rdma/ib_user_ioctl_verbs.h           | 100 ++++
 include/uapi/rdma/ib_user_verbs.h                 |  25 +
 24 files changed, 2126 insertions(+), 162 deletions(-)
---
base-commit: 9dd8b9a337af844291edcd9139c927d0f7958dbe
change-id: 20260929-uet-ib-core-d82e941f5e52

Best regards,
--  
Eric Davis <eric.davis@broadcom.com>

