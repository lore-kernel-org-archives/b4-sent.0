From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:41 -0600
Subject: [PATCH v2 10/25] xattr: use is_fscaps_xattr()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-10-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=597; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=lEHQXdLzM8XZmLEljh/ycw/4aa43YTvfIWETR64S7L4=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1mohq2XZVoBy8FgqIjMltMFNuzAWaj/Pn1Cc2fiJ
 PO+HZrOJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqIQAKCRBTA5mu5fQxyQ77B/
 9KzJ+i0X5eDYLpwTJQmYMCRqYN6k0Iuk1pwbpwXjF9ph8I+iLw/R/XYDD3yf025kbMHTCQC+Z0TYiw
 Wh64DvoVlVS+FkNp+7sCJETr3Lmx3gEs2vJNh+zIRRm9awNuEhnAezPVeOC9vXAOEB4vxQMJwWjjNG
 apBxkgO4CvmpusSXAZOJhK6Uo5XqCiEgjcl0DXRtnMbTph6y2KmqFVanvM1qba2HEXNFpL87fAwpST
 UDykJ5pSN8a964iteXDvWw/PLqFS33BKI9sLHcykFsgV4nTYUWM+hpTJJV1rOFRiE2YRaSB35mPMvF
 52ifUub/2VOnPAqvb376YvVerDPSZW
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 fs/xattr.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/xattr.c b/fs/xattr.c
index 09d927603433..06290e4ebc03 100644
--- a/fs/xattr.c
+++ b/fs/xattr.c
@@ -310,7 +310,7 @@ vfs_setxattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	const void  *orig_value = value;
 	int error;
 
-	if (size && strcmp(name, XATTR_NAME_CAPS) == 0) {
+	if (size && is_fscaps_xattr(name)) {
 		error = cap_convert_nscap(idmap, dentry, &value, size);
 		if (error < 0)
 			return error;

-- 
2.43.0

