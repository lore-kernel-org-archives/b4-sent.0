From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:39 -0600
Subject: [PATCH v2 08/25] xattr: add is_fscaps_xattr() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-8-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=898; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=MjPDmuGYxTwVV3XD9s9x96VSdlRd13Fx8UY16afoWLI=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1mofpeDW0VRFpT+qzsFdS/fHWj5IKuhck4JZotJG
 3ni+RRWJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqHwAKCRBTA5mu5fQxyRAAB/
 9E0ZBYKot+MRKSR27p0Kv0vDG4b1T8VUYNXdxn7GTVrucCBGVtpVtqSyN8mJcxmFFj6dgjcjWE/8Fq
 5ZjeTdXL+YyPRBKcf0KBrbLryipvjsqSujzheGkbqC8maXAS3ScS4R+vuzpQuiMRBhwd432RWhFkRu
 ALGbz9FzAX6BGGK/+JaabY7XD/jynxRjg5i8POSN19q0OJlsOqUpYJrmjTusaT4lCzgC+6ixXcwFzw
 +z6fBZXxwGNAJ/G0yohMDqfv4/nS298M7iKZhieHyKr5Hz/dZ+rOFIiwoGWzyRw8ccnmGTkNSWT3Dq
 Yxtsflp7R+yVNxyPqIPgRpugwoXtdA
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a helper to determine if an xattr time is XATTR_NAME_CAPS instead of
open-coding a string comparision.

Suggested-by: Amir Goldstein <amir73il@gmail.com>
Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 include/linux/xattr.h | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/include/linux/xattr.h b/include/linux/xattr.h
index d20051865800..cbacfb4d74fa 100644
--- a/include/linux/xattr.h
+++ b/include/linux/xattr.h
@@ -28,6 +28,11 @@ static inline bool is_posix_acl_xattr(const char *name)
 	       (strcmp(name, XATTR_NAME_POSIX_ACL_DEFAULT) == 0);
 }
 
+static inline bool is_fscaps_xattr(const char *name)
+{
+	return strcmp(name, XATTR_NAME_CAPS) == 0;
+}
+
 /*
  * struct xattr_handler: When @name is set, match attributes with exactly that
  * name.  When @prefix is set instead, match attributes with that prefix and

-- 
2.43.0

