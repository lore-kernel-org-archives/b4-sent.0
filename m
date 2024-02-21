From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:40 -0600
Subject: [PATCH v2 09/25] commoncap: use is_fscaps_xattr()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-9-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=972; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=4t7VYe2pfzhO0kZ+94iPfJDYCD1vDaacDt9TOtFcBjg=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1mogZOFLFrTJHOsqMGqEXCfScBiIf9AXwC8KoSVV
 frhhLcCJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqIAAKCRBTA5mu5fQxyQbxCA
 CB/noEJJlpI9g151/fViGjdeWOgiQrNeYPragty6p9bGZUks5yPjNApObB+aefC+H5tKHvGXzIrbEB
 n9MzhIumjZYNHrsibS1d5sAG1Bwqgggfi9Sx3VOvIsDip4pg6NtDhmVtW5+Yt20+5GnTd/jGezJryP
 a1EhXCIxhToqhCm8BjKwufrx88FED6FORWo9DmD92IwhJWEvf6SQrnn5DKY/aXw9kF7FzdceVCDrAw
 kxY/MZXXVqwEedLkAlP4Q3sx8JCqZPzpoVZj2Q7z9g1oNDJDGWXr/KWOlBYRxWFr5V1dFQ0WXy9iP4
 Ig0HUzkQv1L68QjY8iH4SVVE9ldej/
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 security/commoncap.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/security/commoncap.c b/security/commoncap.c
index 289530e58c37..19affcfa3126 100644
--- a/security/commoncap.c
+++ b/security/commoncap.c
@@ -1205,7 +1205,7 @@ int cap_inode_setxattr(struct dentry *dentry, const char *name,
 	 * For XATTR_NAME_CAPS the check will be done in
 	 * cap_convert_nscap(), called by setxattr()
 	 */
-	if (strcmp(name, XATTR_NAME_CAPS) == 0)
+	if (is_fscaps_xattr(name))
 		return 0;
 
 	if (!ns_capable(user_ns, CAP_SYS_ADMIN))
@@ -1242,7 +1242,7 @@ int cap_inode_removexattr(struct mnt_idmap *idmap,
 			XATTR_SECURITY_PREFIX_LEN) != 0)
 		return 0;
 
-	if (strcmp(name, XATTR_NAME_CAPS) == 0) {
+	if (is_fscaps_xattr(name)) {
 		/* security.capability gets namespaced */
 		struct inode *inode = d_backing_inode(dentry);
 		if (!inode)

-- 
2.43.0

