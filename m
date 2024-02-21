From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:34 -0600
Subject: [PATCH v2 03/25] capability: add static asserts for comapatibility
 of vfs_cap_data and vfs_ns_cap_data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-3-3039364623bd@kernel.org>
References: <20240221-idmap-fscap-refactor-v2-0-3039364623bd@kernel.org>
In-Reply-To: <20240221-idmap-fscap-refactor-v2-0-3039364623bd@kernel.org>
To: Christian Brauner <brauner@kernel.org>, 
 Seth Forshee <sforshee@kernel.org>, Serge Hallyn <serge@hallyn.com>, 
 Paul Moore <paul@paul-moore.com>, Eric Paris <eparis@redhat.com>, 
 James Morris <jmorris@namei.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Jan Kara <jack@suse.cz>, Stephen Smalley <stephen.smalley.work@gmail.com>, 
 Ondrej Mosnacek <omosnace@redhat.com>, 
 Casey Schaufler <casey@schaufler-ca.com>, Mimi Zohar <zohar@linux.ibm.com>, 
 Roberto Sassu <roberto.sassu@huawei.com>, 
 Dmitry Kasatkin <dmitry.kasatkin@gmail.com>, 
 Eric Snowberg <eric.snowberg@oracle.com>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Jonathan Corbet <corbet@lwn.net>, Miklos Szeredi <miklos@szeredi.hu>, 
 Amir Goldstein <amir73il@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-security-module@vger.kernel.org, audit@vger.kernel.org, 
 selinux@vger.kernel.org, linux-integrity@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-unionfs@vger.kernel.org
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=1385; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=bxTL27ZkILW3Z/PzdK+zkxv1J47CpCEVsrwmLCLu4uQ=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1moa/fJIxAg3DN6LOTcQsDvH+cZkYg8eiXdC9JTK
 9qLOZZKJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqGgAKCRBTA5mu5fQxyYwTB/
 0d04ClkP7dmDAlcfihBhhJW2R5p6fTL0P2eSnUHdh3EIvIuiO7fUd8A1x3SG34fs+5Dvuh9su7zIEW
 EIkSiAN6/ApACZYiaq8hA6USOPOYTJoprKB9gxYdSZnwtM0jBsTQJJBWeniB0tmsNqNK5IcG+4zjzf
 9T+E79htjMvGDgTfzhPO4Rz4RDUXIp4f743XGZig4ke+wGBits11N8mEtI93rEHrj2RYYHjsbFC5wB
 spyh4kqE0A8w5lxKuce5v4NGcHPr8rawPMXMe/3gbFJTGSB1biA/M9v2SalORt97iZEgk3CuwSNFuW
 mtlO95lKDpr28Q6/Y6GSGWAay4GQM9
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Capability code depends on vfs_ns_cap_data being an extension of
vfs_cap_data, so verify this at compile time.

Suggested-by: Christian Brauner <brauner@kernel.org>
Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 include/uapi/linux/capability.h | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/include/uapi/linux/capability.h b/include/uapi/linux/capability.h
index 5bb906098697..0fd75aab9754 100644
--- a/include/uapi/linux/capability.h
+++ b/include/uapi/linux/capability.h
@@ -16,6 +16,10 @@
 
 #include <linux/types.h>
 
+#ifdef __KERNEL__
+#include <linux/build_bug.h>
+#endif
+
 /* User-level do most of the mapping between kernel and user
    capabilities based on the version tag given by the kernel. The
    kernel might be somewhat backwards compatible, but don't bet on
@@ -100,6 +104,15 @@ struct vfs_ns_cap_data {
 #define _LINUX_CAPABILITY_VERSION  _LINUX_CAPABILITY_VERSION_1
 #define _LINUX_CAPABILITY_U32S     _LINUX_CAPABILITY_U32S_1
 
+#else
+
+static_assert(offsetof(struct vfs_cap_data, magic_etc) ==
+	      offsetof(struct vfs_ns_cap_data, magic_etc));
+static_assert(offsetof(struct vfs_cap_data, data) ==
+	      offsetof(struct vfs_ns_cap_data, data));
+static_assert(sizeof(struct vfs_cap_data) ==
+	      offsetof(struct vfs_ns_cap_data, rootid));
+
 #endif
 
 

-- 
2.43.0

