From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH pynfs 0/3] Block layout tests for LAYOUTCOMMITs of ranges
 without blocks
Date: Wed, 14 Oct 2026 13:10:25 +0900
Message-Id: <20261014-pynfs-block-commit-v1-0-1723979f495f@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALEAz2oC/x2M0QpAMBRAf0X32a0NjfyKPDB33LBpk0j+3drjq
 XPOC4E8U4A2e8HTxYGdjSDzDPQy2JmQp8hQiEJJISs8HmsCjpvTK2q373yiroWhsqxH1VQQw8O
 T4TtNO0g+9N/3A2H/OH9rAAAA
To: Calum Mackay <calum.mackay@oracle.com>
Cc: linux-nfs@vger.kernel.org, Chuck Lever <cel@kernel.org>, 
 Jeff Layton <jlayton@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Dai Ngo <dai.ngo@oracle.com>, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791951025; l=1794;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=3Fp8P4HKTqbNbg3T2GfmaG47HIdB9kMIe1WJy9U0SW4=;
 b=pJwOE5elA4qDNMpNft7wX+SjhuUYZZG2TfK2shhALNt73Qz+ItwlrkZ85H8pJhYauI+XrUgnh
 0R2YaBlZ7csBPcF4Wsc3vrZFZ2GgKc2tamcdvz2rjgMa+Beb1abbTJn
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch 1 is "Add a test for contiguous writable extents in a block
layout", posted on October 6 [1] and unchanged. Patch 2 adds tests for
LAYOUTCOMMITs of ranges that no layout covered, which shut XFS down or
committed a block that nobody wrote before the XFS series in [2].
Patch 3 describes how the block layout tests are run against Linux
nfsd, as Christoph asked [3].

Tested with Linux nfsd on nfsd-testing d918c664efd5, XFS on an
NVMe/TCP namespace exported by nvmet, in QEMU guests with KASAN and
lockdep:

 - Without [2], BLOCK7 fails at the GETATTR after the LAYOUTCOMMIT, as
   XFS has shut down, and the tests after it fail for the same reason.
   With BLOCK7 and BLOCK8 left out, BLOCK9 fails because the server
   commits the hole. BLOCK10 passes; the server only logs a
   "non-standard errno" warning for it.
 - With [2], BLOCK6 to BLOCK10 pass in 5 runs, and also on an
   XFS_DEBUG kernel.
 - BLOCK3 fails with and without [2], on a bug in the test.

[1] https://lore.kernel.org/r/20261006002622epcms2p38e492aef17fdf79e48b05c9aada2918d@epcms2p3
[2] https://lore.kernel.org/r/20261014-xfs-pnfs-commit-hole-v2-0-d3a02a79ab6c@samsung.com
[3] https://lore.kernel.org/r/20261013120359.GB2944@lst.de

---
Daejun Park (3):
      Add a test for contiguous writable extents in a block layout
      Add tests for LAYOUTCOMMITs of ranges without blocks in a block layout
      Add README-blocklayout

 nfs4.1/README-blocklayout        |  41 +++++++
 nfs4.1/server41tests/st_block.py | 230 ++++++++++++++++++++++++++++++++++++++-
 2 files changed, 268 insertions(+), 3 deletions(-)
---
base-commit: cd4701827a8261fedbfb4c6e39029fb9671321a6
change-id: 20261014-pynfs-block-commit-c70fe337b684

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

