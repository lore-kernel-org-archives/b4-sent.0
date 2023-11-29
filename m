From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Subject: [PATCH 00/16] fs: use type-safe uid representation for filesystem
 capabilities
Date: Wed, 29 Nov 2023 15:50:18 -0600
Message-Id: <20231129-idmap-fscap-refactor-v1-0-da5a26058a5b@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABqyZ2UC/x2NSwrDMAxErxK0rsEf6kWvUrqQXbkRpE6Q2hAwu
 XtFNwNvmMcMUBImhds0QGhn5bUbhMsEdcb+IsdPY4g+Jn8N0fCNm2taLYUa1s8qLqeSQ0OPKTc
 wtaCSK4K9zib377JYudmcj//X/XGeP3LapMJ7AAAA
To: Christian Brauner <brauner@kernel.org>, Serge Hallyn <serge@hallyn.com>, 
 Paul Moore <paul@paul-moore.com>, Eric Paris <eparis@redhat.com>, 
 James Morris <jmorris@namei.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Miklos Szeredi <miklos@szeredi.hu>, Amir Goldstein <amir73il@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-security-module@vger.kernel.org, audit@vger.kernel.org, 
 linux-unionfs@vger.kernel.org, 
 "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=3944; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=e1bNk2Y02IUrvPq3JW/J0kW9YOkEkHQ2aztr89JaGE4=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBlZ7IvK9HzszM2i/QraAFHa/VADmqY0TX3S+lGLdmx
 3rXykB2JATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZWeyLwAKCRBTA5mu5fQxybUeB/
 9SuaWrirztZmjFyIZj0l9JjtT/BlFqVDMNEQ9u0K8av0oIJB6M4C+/RxW2HovO6Ze3et6gPlXNVVM+
 EyGFKVn7W875FYmmGCEKwdZ5VTyO8dFom9t8Upy/gl3rgVv3iFFG80ZtQ72B70/tsyKRSYzuyxsdDR
 ey1cN6W7S85ZBKF84pbR/CEiAhHNjFRYjh5iPJbyGtjvx32qKGcgDYtKJYP3csznkYGd+lEb9aF5T1
 dzpudoFlnW4B3oA67kMhTd5ptj+WVZwhfHNdslqbEBFad389VfZho7Y38Q05t8pxDSg+hFsHv9OvKa
 iAd8bRVxTYQ7QQByaZ4+SebYPCa48r
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series converts filesystem capabilities from passing around raw
xattr data to using a kernel-internal representation with type safe
uids, similar to the conversion done previously for posix ACLs.
Currently fscaps representations in the kernel have two different
instances of unclear or confused types:

 - fscaps are generally passed around in the raw xattr form, with the
   rootid sometimes containing the user uid value and at other times
   containing the filesystem value.

 - The existing kernel-internal representation of fscaps,
   cpu_vfs_cap_data, uses the kuid_t type, but the value stored is
   actually a vfsuid.

This series eliminates this confusion by converting the xattr data to
the kernel representation near the userspace and filesystem boundaries,
using the kernel representation within the vfs and commoncap code. The
internal representation is renamed to vfs_caps to reflect this broader
use, and the rootid is changed to a vfsuid_t to correctly identify the
type of uid which it contains.

New vfs interfaces are added to allow for getting and setting fscaps
using the kernel representation. This requires the addition of new inode
operations to allow overlayfs to handle fscaps properly; all other
filesystems fall back to a generic implementation. The top-level vfs
xattr interfaces will now reject fscaps xattrs, though the lower-level
interfaces continue to accept them for reading and writing the raw xattr
data.

The existing xattr security hooks can continue to be used for fscaps.
There is some awkwardness here, as EVM requires the on-disk fscaps data
to compare with any existing on-disk value. Security checks need to
happen before calling into filesystem inode operations, when the fscaps
are still in the kernel-internal format, so an extra conversion to the
on-disk format is necessary for EVM's setxattr checks.

The remainder of the changes are preparatory work and addition of
helpers for converting between the xattr and kernel fscaps
representation. 

I have tested this code with xfstests, ltp, libcap2, and libcap-ng with
no regressions found.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
Seth Forshee (DigitalOcean) (16):
      mnt_idmapping: split out core vfs[ug]id_t definitions into vfsid.h
      mnt_idmapping: include cred.h
      capability: rename cpu_vfs_cap_data to vfs_caps
      capability: use vfsuid_t for vfs_caps rootids
      capability: provide helpers for converting between xattrs and vfs_caps
      capability: provide a helper for converting vfs_caps to xattr for userspace
      fs: add inode operations to get/set/remove fscaps
      fs: add vfs_get_fscaps()
      fs: add vfs_set_fscaps()
      fs: add vfs_remove_fscaps()
      ovl: add fscaps handlers
      ovl: use vfs_{get,set}_fscaps() for copy-up
      fs: use vfs interfaces for capabilities xattrs
      commoncap: remove cap_inode_getsecurity()
      commoncap: use vfs fscaps interfaces for killpriv checks
      vfs: return -EOPNOTSUPP for fscaps from vfs_*xattr()

 MAINTAINERS                   |   1 +
 fs/overlayfs/copy_up.c        |  72 +++---
 fs/overlayfs/dir.c            |   3 +
 fs/overlayfs/inode.c          |  84 +++++++
 fs/overlayfs/overlayfs.h      |   6 +
 fs/xattr.c                    | 286 ++++++++++++++++++++++-
 include/linux/capability.h    |  23 +-
 include/linux/fs.h            |  13 ++
 include/linux/mnt_idmapping.h |  67 +-----
 include/linux/security.h      |   5 +-
 include/linux/vfsid.h         |  74 ++++++
 kernel/auditsc.c              |   9 +-
 security/commoncap.c          | 519 ++++++++++++++++++++++--------------------
 13 files changed, 802 insertions(+), 360 deletions(-)
---
base-commit: 2cc14f52aeb78ce3f29677c2de1f06c0e91471ab
change-id: 20230512-idmap-fscap-refactor-63b61fa0a36f

Best regards,
-- 
Seth Forshee (DigitalOcean) <sforshee@kernel.org>

