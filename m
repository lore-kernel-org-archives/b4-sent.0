From: Daan De Meyer <daan@amutable.com>
Subject: [PATCH 0/2] lsm: expose mount idmaps to inode hooks
Date: Mon, 24 Aug 2026 15:28:11 +0200
Message-Id: <20260824-lsm-mount-idmaps-v1-0-0414a9641c85@amutable.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMTQrCMBBGr1Jm7UATihivIi4m6dSOmLRkUhFK7
 26iy/f9vB2Us7DCtdsh81tUllTBnDoIM6UHo4yVwfb23F/sgC+NGJctlVpEWhXd6Lxzw8SGDNT
 bmnmSz095u/9ZN//kUJqnLTwpo8+UwtyiSFo4w3F8AdC/pU6NAAAA
X-Change-ID: 20260824-lsm-mount-idmaps-9d9b994fe1a1
To: brauner@kernel.org, jack@suse.cz, paul@paul-moore.com, 
 viro@zeniv.linux.org.uk
Cc: linux-security-module@vger.kernel.org, linux-fsdevel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787578101; l=1818;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=prDA2HVVe2wMa35Q1aFO3/S+aVUUWrB3TV9rg1BQDic=;
 b=yUjMxFE0LjiFTitSfdtCLTLoIEb9XI0bxeb4aHimp4xChKxivwZm18qcqoUxP8itXdh0R8hGs
 i/a82nK0eHLAnKOk9oyRyi1xtd/wlWUjvfGM1bERJy6EIDFsYjpMlhL
X-Developer-Key: i=daan@amutable.com; a=ed25519;
 pk=I1l+WwrtmzRgofA5SQ1wTuJi18fjh91w+f5uRkFeZEA=
X-Endpoint-Received: by B4 Relay for daan@amutable.com/20260712 with auth_id=868
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

OverlayFS performs upper-layer operations through inode-based security
hooks. Those hooks receive the upper inode and dentry, but not the mount
idmap used by the VFS operation.

The security layer cannot distinguish an identity-mapped upper from an
idmapped one or make the same ownership decision as the VFS. The VFS
layer already passes the idmap down into all relevant inode operations
so this just brings the security hooks to parity.

So pass the mount idmap through the create, link, symlink, mkdir, mknod,
and permission hooks. Update the in-tree security implementations and
non-VFS callers accordingly.

systemd has been shipping systemd-nsresourced for quite a while now. It
relies on inode and path hooks to perform ownership checks using a bpf lsm.
To make this actually secure we need to be able to calculate the on-disk
ownership from the idmap.

---
Daan De Meyer (2):
      lsm: expose mount idmaps to inode hooks
      selftests/bpf: verify mount idmaps reach inode hooks

 fs/cachefiles/security.c                          |   4 +-
 fs/namei.c                                        |  18 +-
 include/linux/lsm_hook_defs.h                     |  23 +--
 include/linux/security.h                          |  58 +++---
 security/security.c                               |  40 ++--
 security/selinux/hooks.c                          |  19 +-
 security/smack/smack_lsm.c                        |   9 +-
 tools/testing/selftests/bpf/prog_tests/test_lsm.c | 231 ++++++++++++++++++++++
 tools/testing/selftests/bpf/progs/lsm.c           |  79 ++++++++
 9 files changed, 410 insertions(+), 71 deletions(-)
---
base-commit: 0a0d1d55dad570724bf8c7ea83409639cfb4be9b
change-id: 20260824-lsm-mount-idmaps-9d9b994fe1a1

Best regards,
--  
Daan De Meyer <daan@amutable.com>

