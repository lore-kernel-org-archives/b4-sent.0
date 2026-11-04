From: orkunsari <sariorkunemin@gmail.com>
Subject: [PATCH 0/2] nfsd: fix two mount-crossing regressions from the v7.4
 merge window
Date: Wed, 04 Nov 2026 14:56:14 +0300
Message-Id: <20261104-nfsd-cross-mnt-v1-0-5ec5fca0a553@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqEMAxA4atI1gZsEf+uIi60TTWCVRodBop3t
 84sv8V7EYQCk0CXRQj0YeHdJ6g8A7OMfiZkmwy60JVSRYneiUUTdhHc/InKNaWt21o3VQspOgI
 5/v6G/fC3XNNK5nwvcN8P5yNQGXIAAAA=
X-Change-ID: 20261104-nfsd-cross-mnt-1f84d7972869
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 orkunsari <sariorkunemin@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793793374; l=1188;
 i=sariorkunemin@gmail.com; s=20261103; h=from:subject:message-id;
 bh=QUJUQXa5hExsDV/MhlbVSo+ywaTLPPSuOAFTqzJnnt0=;
 b=CgeTVhR+6frjNyCzeLzIPupeBtoQebyGkzSAuTI+npHVgN9XLA8+DUVJGp6yROp0bHdiXPQzL
 8zWm8qAndLUAxr9nmZMlkeEIuV6uflMXh7Xu7KbK4ukzxdDKv6d31zO
X-Developer-Key: i=sariorkunemin@gmail.com; a=ed25519;
 pk=MJ3Y3somkGDQVAXOSR189QAqWOcfzYCRkL1cSQgJXnE=
X-Endpoint-Received: by B4 Relay for sariorkunemin@gmail.com/20261103 with auth_id=1408
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for code merged for v7.4-rc1; released kernels are not
affected.

Patch 1 fixes the NFSv2/v3 CREATE paths, which pass the dentry returned
by nfsd_cross_mnt() to end_creating() and so unlock the wrong directory
when the target file has something mounted on it.

Patch 2 makes nfsd_cross_mnt() check access to the export being entered
rather than the one being left, and restores the check after ".." in
nfsd_lookup(). SECINFO keeps its previous behaviour and does not return
NFS4ERR_WRONGSEC.

Both were found by AI-assisted code review (Claude Code). The fixes are
build-tested with W=1 only; no reproducer was run.

---
orkunsari (2):
      nfsd: unlock the locked parent after crossing a mount in CREATE
      nfsd: check access to the export being entered when crossing mounts

 fs/nfsd/nfs3proc.c | 14 +++++++++++---
 fs/nfsd/nfsproc.c  | 14 +++++++++++---
 fs/nfsd/vfs.c      | 46 +++++++++++++++++++++++++++++++++++++++-------
 3 files changed, 61 insertions(+), 13 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-nfsd-cross-mnt-1f84d7972869

Best regards,
--  
orkunsari <sariorkunemin@gmail.com>

