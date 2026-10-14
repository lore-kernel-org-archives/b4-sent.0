From: Eric Davis <eric.davis@broadcom.com>
Subject: [PATCH rdma-next 00/13] RDMA/core: Ultra Ethernet transport verbs
Date: Wed, 14 Oct 2026 15:21:09 -0700
Message-Id: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQqDMBAFf0X23AVdamn6K6UHTZ7tFhrLJoog/
 ntTPQ7DzEoJpkh0q1YyzJp0jAWaU0X+1cUnWENhkloutRPHEzJrz340cLgK3LkZWrRCpfgaBl3
 2250sfDqOWDI9DpWm/g2f/zfath9o6aOHegAAAA==
X-Change-ID: 20260929-uet-ib-core-d82e941f5e52
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792016478; l=5120;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=pmO235+sOiP0U982ZnFLaKOB723M7EJvhoJ2eSf6MuU=;
 b=2j9T//Lxu1ZXKUViHBaBUNaBvHlbFtD1QtbApUyy+slaG1871meEFMzOJg0WNpE0jn5ub3jo8
 9dJPIy9CyNWAoU2Pdm3qTFsS6U8JKaqlT9vXVAioAGdWSysE6Z6mwah
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
 drivers/infiniband/core/uverbs.h                  |  16 +
 drivers/infiniband/core/uverbs_cmd.c              | 261 ++++----
 drivers/infiniband/core/uverbs_main.c             |   5 +
 drivers/infiniband/core/uverbs_std_types.c        |  73 ++-
 drivers/infiniband/core/uverbs_std_types_device.c |  73 ++-
 drivers/infiniband/core/uverbs_std_types_job.c    | 763 ++++++++++++++++++++++
 drivers/infiniband/core/uverbs_std_types_mr.c     | 222 ++++++-
 drivers/infiniband/core/uverbs_std_types_qp.c     | 340 +++++++++-
 drivers/infiniband/core/uverbs_uapi.c             |   2 +
 drivers/infiniband/core/verbs.c                   | 109 +++-
 include/rdma/ib_verbs.h                           | 242 ++++++-
 include/rdma/restrack.h                           |   8 +
 include/rdma/uverbs_ioctl.h                       |   4 +-
 include/uapi/rdma/ib_user_ioctl_cmds.h            | 120 ++++
 include/uapi/rdma/ib_user_ioctl_verbs.h           | 100 +++
 include/uapi/rdma/ib_user_verbs.h                 |  25 +
 25 files changed, 2270 insertions(+), 161 deletions(-)
---
base-commit: d37e98844afea39a9614cac0de837701263c90f7
change-id: 20260929-uet-ib-core-d82e941f5e52

Best regards,
--  
Eric Davis <eric.davis@broadcom.com>

