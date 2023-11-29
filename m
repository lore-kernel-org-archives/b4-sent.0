From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 29 Nov 2023 15:50:25 -0600
Subject: [PATCH 07/16] fs: add inode operations to get/set/remove fscaps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231129-idmap-fscap-refactor-v1-7-da5a26058a5b@kernel.org>
References: <20231129-idmap-fscap-refactor-v1-0-da5a26058a5b@kernel.org>
In-Reply-To: <20231129-idmap-fscap-refactor-v1-0-da5a26058a5b@kernel.org>
To: Christian Brauner <brauner@kernel.org>, Serge Hallyn <serge@hallyn.com>, 
 Paul Moore <paul@paul-moore.com>, Eric Paris <eparis@redhat.com>, 
 James Morris <jmorris@namei.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Miklos Szeredi <miklos@szeredi.hu>, Amir Goldstein <amir73il@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-security-module@vger.kernel.org, audit@vger.kernel.org, 
 linux-unionfs@vger.kernel.org, 
 "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=1071; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=a3Y6lynq44wXodnU5zT/TB2mw/YUwehyzd+izLi+710=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBlZ7I3jkGX0ENxe+x6fg9biSGvzfaFH0+OzJVRhGL1
 4G7+T7mJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZWeyNwAKCRBTA5mu5fQxyeKuB/
 9fSGpP5pXSOyn3UkRq6j9l/2nr77wJO5nHSUPVLP5ZWjfcO8vezbperL5n23B6ppF7zSRWMWMK8nc5
 RyyQRhW+2y60KxF7sGRyYhAI434prSE8W5pSf7yj0IjuslabYuvpSVW+1aVPcpLrgHoOlZv0fINTDT
 aB0X2HDzovSJwmMjrbaV8xmVzw6wxyxc+ag8dHIAe+9FYPtEAJc6orS+tYRHGIVwsIgR682ZdjQ5TQ
 Rb5zjFwxxkGdTu/udnpVVQb4YujdB+Ds6VuSdPXJOtS8eiLFpJX9NWsGs5pUJ8RMEjmOBT9Ds0S0uR
 41HDfP0hKQ7rUTwY1jLx6IQL3V59Sf
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add inode operations for getting, setting and removing filesystem
capabilities rather than passing around raw xattr data. This provides
better type safety for ids contained within xattrs.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 include/linux/fs.h | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/include/linux/fs.h b/include/linux/fs.h
index 98b7a7a8c42e..a0a77f67b999 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -2002,6 +2002,11 @@ struct inode_operations {
 				     int);
 	int (*set_acl)(struct mnt_idmap *, struct dentry *,
 		       struct posix_acl *, int);
+	int (*get_fscaps)(struct mnt_idmap *, struct dentry *,
+			  struct vfs_caps *);
+	int (*set_fscaps)(struct mnt_idmap *, struct dentry *,
+			  const struct vfs_caps *, int flags);
+	int (*remove_fscaps)(struct mnt_idmap *, struct dentry *);
 	int (*fileattr_set)(struct mnt_idmap *idmap,
 			    struct dentry *dentry, struct fileattr *fa);
 	int (*fileattr_get)(struct dentry *dentry, struct fileattr *fa);

-- 
2.43.0

