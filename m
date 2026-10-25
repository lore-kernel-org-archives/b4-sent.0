From: Dhruva Gole <goledhruva@gmail.com>
Subject: [PATCH v2 0/3] btrfs: add NOCOMPRESS defrag regression coverage
Date: Sun, 25 Oct 2026 17:21:49 +0000
Message-Id: <20261025-b4-btrfs-nocomp-v2-v2-0-628c1986f9b9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK063moC/02OzY6DIBSFX6Vh3Wv40St01feYdAEISlOlAUqma
 Xz3qrOZ5Zec853zIdml4DK5nD4kuRpyiMsG/HwidtLL6CAMGxNOOTLKOzAtmJJ8hiXaOD+hcpD
 GS49CIBeabMVncj78HtKf2x/nl7k7W3bTnvApzlCm5PQhN0oh68wAyvQWWmkQtO0pDG1HNVIUU
 trrOOvwaLbNXTCFXGJ6H7cr24eIjdWlhvWKCdUh0mYMpRnjww1TelX9r39b1/ULkarSx/kAAAA
 =
X-Change-ID: 20261025-b4-btrfs-nocomp-v2-8bf8f633623a
To: fstests@vger.kernel.org
Cc: linux-btrfs@vger.kernel.org, Anand Jain <asj@kernel.org>, 
 Filipe Manana <fdmanana@suse.com>, Zorro Lang <zlang@kernel.org>, 
 Qu Wenruo <wqu@suse.com>, Dhruva Gole <goledhruva@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792948953; l=1705;
 i=goledhruva@gmail.com; s=remote-20261025; h=from:subject:message-id;
 bh=n/3vRrou5YbrZbVXlPGDJ5JH9mPmNCyJhEtjuKyblUY=;
 b=TF5Be2fLrDmjFsrgaGVtq+0CJ2TckeeXNSMK6gzl6vf8rXeZGO1SlA65WqLezGf9fI4sa+oHm
 KhbxzEKxqirDQo6OETxURIR1OAXtVIA4HQE7V0xfQ8kUtDWSs+/GqR+
X-Developer-Key: i=goledhruva@gmail.com; a=ed25519;
 pk=OBz78Vw5K+/+HyXjxg9mNOV2Bq087eJgHL749H+Xe/k=
X-Endpoint-Received: by B4 Relay for goledhruva@gmail.com/remote-20261025 with auth_id=1318
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add three tests for btrfs filesystem defragment --nocomp: range and EOF
handling, preservation of holes and preallocation, and inline eligibility
and short EOF tails. Check extent layouts and file contents after remount.

Changes in v2 (thanks to Qu Wenruo and Filipe Manana):
- Replace the private helper framework and C ioctl probe with direct
  btrfs-progs, xfs_io and md5sum calls checked against golden output.
- Move the capability probe to _require_btrfs_defrag_nocompress() in
  common/btrfs.
- Use a test-local FIEMAP filter preserving all flags, including INLINE,
  as suggested by Qu; leave the shared filter interface unchanged.
- Improve naming of variables/ filenames to be more descriptive

v1: https://lore.kernel.org/linux-btrfs/b99615bd-9b7c-48b6-ac70-d450a606388c@gmail.com/

Signed-off-by: Dhruva Gole <goledhruva@gmail.com>
---
Dhruva Gole (3):
      btrfs: exercise NOCOMPRESS range and EOF handling
      btrfs: check NOCOMPRESS preserves holes and preallocation
      btrfs: cover NOCOMPRESS inline eligibility and short tails

 common/btrfs        | 14 +++++++++
 tests/btrfs/355     | 76 +++++++++++++++++++++++++++++++++++++++++++++++++
 tests/btrfs/355.out | 45 +++++++++++++++++++++++++++++
 tests/btrfs/356     | 64 ++++++++++++++++++++++++++++++++++++++++++
 tests/btrfs/356.out | 28 ++++++++++++++++++
 tests/btrfs/357     | 81 +++++++++++++++++++++++++++++++++++++++++++++++++++++
 tests/btrfs/357.out | 39 ++++++++++++++++++++++++++
 7 files changed, 347 insertions(+)
---
base-commit: 3e1ee800e52a0f53d7d9a7809be1ffc80ec1788f
change-id: 20261025-b4-btrfs-nocomp-v2-8bf8f633623a

Best regards,
--  
Dhruva Gole <goledhruva@gmail.com>

