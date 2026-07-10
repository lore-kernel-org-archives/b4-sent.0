From: Dave Marquardt <davemarq@linux.ibm.com>
Subject: [PATCH v4 0/8] ibmvfc: make ibmvfc support FPIN messages
Date: Fri, 10 Jul 2026 14:16:40 -0500
Message-Id: <20260710-ibmvfc-fpin-support-v4-0-ef031ac19520@linux.ibm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNSwqDMBgE4KtI1o3EmPjoqvcoXZiY1L/UB4kGi
 3j3JpYiFLscmPlmQVYZUBadowUZ5cBC3/nAThGSTdXdFYbaZ0QJzQgjOQbROi2xHqDDdhqG3ox
 YlILnXNa0rhLkl4NRGuZNvd4+2U7ioeQYqNBowI69eW23Lgm970Nx+OASTDCngmSSZUyR9PKEb
 ppj341l36Lw4ujuZP8c6p2aJZozokXF5ZGT7k5O6LGTBqfkouQsl7oofp11Xd8PMhnyXAEAAA=
 =
X-Change-ID: 20260407-ibmvfc-fpin-support-b9b575cd2da1
To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Tyrel Datwyler <tyreld@linux.ibm.com>
Cc: linux-kernel@vger.kernel.org, linux-scsi@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, Brian King <brking@linux.ibm.com>, 
 Greg Joyce <gjoyce@linux.ibm.com>, Kyle Mahlkuch <kmahlkuc@linux.ibm.com>, 
 Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783711016; l=3671;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=sPh7BdSUxlwYiaPKY8X7BX64qk9W/BKsBqHoRGXPThw=;
 b=2pObWVgFpSMKaJcublk90c9spmETkIU0ECfwRyFpMIE+ZkEELB8RcPOMbG7JzfT3+133jt9zK
 BLQsjSe6QVwD9+cUD+jn6m1YPHsgjVAY45ALI/uAFsVxcjPGR5NMQ7V
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds FPIN (fabric performance impact notification)
support to the ibmvfc (IBM Virtual Fibre Channel) driver. This comes
in three flavors:

- basic, to recognize existing FPIN messages from the virtual I/O
  server (VIOS) (patch 1)
- full, supporting additional FPIN information and using its own
  asynchronous sub-queue and interrupt (patches 4-7)
- extended, supporting FC-LS-5 (patch 8)

Full and extended FPIN support requires a new asynchronous sub-queue
with its own interrupt. The asynchronous sub-queue support requires
ibmvfc to also support

- a new VFC_NOOP command, which the driver recognizes and
  ignores (patch 2)
- fabric login, to login separately to the fabric through messages
  exchanged with VIOS rather than doing fabric login through the
  existing NPIV login (patch 3)

All three modes convert an incoming FPIN message from VIOS to an FC
extended link service message, in some cases using default values for
information not provided by the VIOS FPIN message but expected in the
FC ELS message. This FC ELS message is passed to fc_host_rcv_fpin for
updating statistics and sending the information upstream by netlink
multicast, where it may be read by listeners including the DM
multipath daemon "multipathd."

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
Changes in v4:
- Refactored channel registration
- Check whether async work queue is allocated before using or freeing
- Fixed work queue allocation/destruction
- Skip basic KUnit test when there are no ibmvfc devices available
- Fix target not found condition in ibmvfc_process_async_work
- Link to v3: https://patch.msgid.link/20260702-ibmvfc-fpin-support-v3-0-d95b9547cf88@linux.ibm.com

Changes in v3:
- Fixed latent bug, exposed by VFC_NOOP, related to dataless CRQs and events
- Fixed FPIN TLV descriptor length calculations
- Use safe list walker to walk targets in ibmvfc_process_async_work
- Added write memory barriers after clearing CRQ valid field
- Use per-vhost work queue for FPIN work
- Link to v2: https://patch.msgid.link/20260608-ibmvfc-fpin-support-v2-0-d41f540fba5c@linux.ibm.com

Highlights of changes in v2:
- Refactored mostly common FPIN conversion routines and async event
  processing into single routines with wrappers for differences.
- Moved FPIN processing to a work queue to avoid conflicts with
  fc_host_fpin_rcv and memory allocation
- Set descriptor sizes correctly
- Use target WWPN for basic FPIN descriptor
- Split patch 4 into 3 patches, for definition, allocation, and use of
  the asynchronous sub-queue for events
- Link to v1: https://patch.msgid.link/20260408-ibmvfc-fpin-support-v1-0-52b06c464e03@linux.ibm.com

---
Dave Marquardt (8):
      ibmvfc: add basic FPIN support
      ibmvfc: Add NOOP command support
      ibmvfc: make ibmvfc login to fabric
      ibmvfc: define asynchronous sub-queue
      ibmvfc: allocate asynchronous sub-queue
      ibmvfc: extend async event handlers to handle async sub queue events
      ibmvfc: register and use asynchronous sub-queue for events
      ibmvfc: handle extended FPIN events

 drivers/scsi/Kconfig                 |  10 +
 drivers/scsi/ibmvscsi/Makefile       |   1 +
 drivers/scsi/ibmvscsi/ibmvfc.c       | 736 ++++++++++++++++++++++++++++++++---
 drivers/scsi/ibmvscsi/ibmvfc.h       | 115 +++++-
 drivers/scsi/ibmvscsi/ibmvfc_kunit.c | 240 ++++++++++++
 5 files changed, 1031 insertions(+), 71 deletions(-)
---
base-commit: 57a6ed0b41677ccc5e28cc0976e495c1dfa33747
change-id: 20260407-ibmvfc-fpin-support-b9b575cd2da1

Best regards,
--  
Dave Marquardt <davemarq@linux.ibm.com>

