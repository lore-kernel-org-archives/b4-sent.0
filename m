From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 11:32:05 +0000
Message-Id: <20261127-kvt1-virtio-d-v1-0-bfa9ce1cece5@certik.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADVqCWsC/yWMSw7CMAwFr1J5jaWkhZZyFcQiH0MNKEFxiJCq3
 p0EljN6b1YQSkwCp26FRIWFY6igdx24xYQbIfvK0Kt+1Lqf8FGyxsIpc0SPx1lNo1OHYd4PUD+
 vRFf+/Hrny5/lbe/kcou0hTVCaJMJbmlKKPgc4xObh237AvLQLY6RAAAA
X-Change-ID: 20261127-kvt1-virtio-d-89076c053943
Subject: [PATCH kvmtool 0/3] virtio: Bound descriptor chains and validate
 9p requests
To: will@kernel.org, kvm@vger.kernel.org
Cc: julien.thierry.kdev@gmail.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795779125; l=2290;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=5j1JHFdkrf5uc9J1afcnODHnb2r+3e6F5MbaYBCSiKs=;
 b=rVZWSDgTtBXF/rSF0G1omd09zxQ+yVdLz0tYYDCjtX1SZ1fsXpYGwtxttW9wGUdxgftRs3EhK
 jp+p7YqfWEyBv6ftc9GUHEVLrzJLKlWPrRKgK4PKN5vBHOwCEVPf5ey
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Will, Julien,

As Will asked after my private report, here are the fixes on the list.
A guest that controls its virtqueues can make descriptor chains exceed
fixed host iovec arrays, place descriptor tables or buffers partly
outside mapped RAM, supply malformed 9p strings or I/O layouts, or
notify queues a device does not have. Reaching these paths requires
kernel-level control of the guest.

Tested:
  - On kvmtool master 2f3abe56dcd2658dc6dae3eeeb4996dc4b518bcf,
    the default -Werror build and 9p, net, RNG and balloon guest
    reproducers ran on real lkvm.
  - With the three patches on that master (tree
    51a74622257779e94627f721b2e51bc51d23d627), the default
    -Werror build, net valid and split RX, balloon valid, split and
    oversized statistics, and net/9p guest smoke passed. Smoke moved
    network traffic and created, read, wrote, renamed and deleted
    files over 9p.
  - A paired MMIO selection probe on master and the patched tree
    showed invalid selection on master and safe rejection on patched,
    with x86 MMIO enabled only in test copies.
  - checkpatch --no-tree --strict is clean on all three patches.

The reproducers are available if they help.

The bugs were found, and the fixes and test runs were
prepared with AI coding tools (OpenAI Codex agents, with review by
Claude). I went over the result before signing off.

---
Dickson Wu (3):
      virtio: Bound descriptor chains and guest ranges
      virtio: 9p: Validate unsigned string lengths
      virtio: Reject invalid 9p buffers and queue indices

 include/kvm/virtio.h |   9 +-
 virtio/9p-pdu.c      |  61 +++++++--
 virtio/9p.c          | 345 +++++++++++++++++++++++++++++++++++----------------
 virtio/balloon.c     |  59 +++++++--
 virtio/blk.c         |  18 ++-
 virtio/console.c     |   9 +-
 virtio/core.c        | 290 +++++++++++++++++++++++++++++++++++++------
 virtio/mmio-modern.c |   9 +-
 virtio/mmio.c        |   5 +-
 virtio/net.c         |  57 +++++++--
 virtio/pci-modern.c  |   3 +
 virtio/pci.c         |   9 +-
 virtio/rng.c         |   5 +-
 virtio/scsi.c        |   3 +-
 virtio/vsock.c       |   3 +-
 15 files changed, 679 insertions(+), 206 deletions(-)

base-commit: 2f3abe56dcd2658dc6dae3eeeb4996dc4b518bcf
