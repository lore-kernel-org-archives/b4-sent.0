From: Daan De Meyer <daan@amutable.com>
Subject: [PATCH v3 0/2] lsm: expose mount idmaps to inode hooks
Date: Fri, 04 Sep 2026 16:48:54 +0200
Message-Id: <20260904-lsm-mount-idmaps-v3-0-920a1963675d@amutable.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32PwW4CMQxEfwXlXFdxNkWkJ/4DcXCyppuK7KI4u
 wKh/fcm9ICEqh7HY78Z35Vwjizqc3NXmZcocRqr6N42Kgw0fjHEvmpltNnqnbFwlgRpmsdSjUQ
 XAdc775w9MRKqenbJfIrXB/Jw/NUy+28OpXHahidh8JnGMLRRIimcmzFEKVO+Pcos2AD/5C4IG
 rRFS25rMew+9pTmQv7M72FKqkUv5slwGv9gGEDoOl0/6JF7Mi+MdV1/AAR5/AciAQAA
X-Change-ID: 20260824-lsm-mount-idmaps-9d9b994fe1a1
To: Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, Paul Moore <paul@paul-moore.com>
Cc: linux-fsdevel@vger.kernel.org, linux-security-module@vger.kernel.org, 
 Daan De Meyer <daan@amutable.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788533337; l=2257;
 i=daan@amutable.com; s=20260712; h=from:subject:message-id;
 bh=RPZk54L1rty0ICmm5Vw6nd84czl1ctT8mF95svoe+s8=;
 b=db8BeU4lBmswjj71tam6b0ZlFa10vg2dFktxgSM+aFee3/ldCqywM6PQAqYiBnQM3rvsm/Qak
 yP9wQ00Wh6oDrq5IInU6yk6X8pKX5VkKltBRcRZj244BJ8RLE2N4KxQ
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
Changes in v3:
- Restore the two-patch split from v1.
- Add the missing Signed-off-by trailers to both patches.
- Link to v2: https://patch.msgid.link/20260901-lsm-mount-idmaps-v2-1-3309b9d1eda2@amutable.com

Changes in v2:
- Squash the implementation and selftest into a single patch.
- Add the missing Signed-off-by trailer.
- Link to v1: https://patch.msgid.link/20260824-lsm-mount-idmaps-v1-0-0414a9641c85@amutable.com

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
base-commit: 786262be6048deab760f68c8acc2c85607165894
change-id: 20260824-lsm-mount-idmaps-9d9b994fe1a1

Best regards,
--  
Daan De Meyer <daan@amutable.com>

