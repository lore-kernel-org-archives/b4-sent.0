From: Daan De Meyer <daan@amutable.com>
Subject: [PATCH 0/2] btrfs: allow reflinks into NODATASUM files
Date: Sun, 12 Jul 2026 16:25:12 +0200
Message-Id: <20260712-reflink-into-nodatasum-v1-0-9f27ef836073@amutable.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBBFr0JmbROoBoJXMS6mZSqjMjWdYkwId
 7fV5ft5/22glJgUzs0Gid6sHKVAd2jAzyg3MjwVBtvavh06axKFJ8vDsORoJE6YUdfFYAhjb8N
 xGE8E5fwqHn9+4cv1z7q6O/lca9VwqGRcQvFznRbUTAn2/QvP6psfkwAAAA==
X-Change-ID: 20260712-reflink-into-nodatasum-aff962f3794e
To: Chris Mason <clm@fb.com>, David Sterba <dsterba@suse.com>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daan De Meyer <daan@amutable.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783866322; l=1580;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=qaXEC32MfQGt8UOFvwvDkdREPyI2tYc6ieR1JjlanBY=;
 b=vNqE8SGJ6710yEKKP1HPWKT1TlfVE9R+k90beYLrBA2RExdy4fn/nIlYELTYqZaTyOBgESCOc
 IzHU400w4eXB8ifm3bSZ4kHuhWe8FcPtxX+w6JG5/4IOQX9GYI5m2OV
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The primary use case for this series is building a NOCOW VM image from
individual partition images that are COW and checksummed. Today those
partitions cannot be cloned into the NODATACOW and NODATASUM destination,
so tools fall back to a full copy. This makes provisioning slower and
duplicates all of the image data up front.

Allow cloning and deduplication from a checksummed file into a NODATASUM
file. The VM image can then share extents with the partition images.
Existing checksummed extents are COWed once when modified, protecting the
source checksums, while newly allocated extents use the destination's
normal NOCOW behavior.

The reverse direction remains rejected because the destination would
expect checksums that do not exist.

Patch 1 prevents swap activation from bypassing the COW protection when a
NODATASUM file references checksummed extents. Patch 2 relaxes the reflink
restriction in the safe direction.

The xfstests branch is available at:
https://github.com/kdave/xfstests/pull/6

Signed-off-by: Daan De Meyer <daan@amutable.com>
---
Daan De Meyer (2):
      btrfs: reject swapfile activation if any extent has checksums
      btrfs: allow reflinking from checksummed files into nodatasum files

 fs/btrfs/inode.c   | 29 +++++++++++++++++++++++++++++
 fs/btrfs/reflink.c | 18 ++++++++++++++----
 2 files changed, 43 insertions(+), 4 deletions(-)
---
base-commit: cab9e339cfbc1a4e075e53e281dfb00391e1a6bb
change-id: 20260712-reflink-into-nodatasum-aff962f3794e

Best regards,
--  
Daan De Meyer <daan@amutable.com>

