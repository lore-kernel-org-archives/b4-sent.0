From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 21 Feb 2024 15:24:33 -0600
Subject: [PATCH v2 02/25] mnt_idmapping: include cred.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240221-idmap-fscap-refactor-v2-2-3039364623bd@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=615; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=s8BhiBRhiwiAP2lDz8YD4FeHbwY0FdRcy4khC2QXOeo=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBl1moZWJyTYqEQXXwQLJ5EhCO4IsZaODJ1GwzPRkjR
 O9Ooj0yJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZdZqGQAKCRBTA5mu5fQxycLAB/
 4gilqSDMXmqmW5ACdjlSaK8IVbKVXj692sOmAd52ZU7RyDpRMqErfeo+jKA9HZ4jpNMRinnIbv5ZJc
 IgyPm1VNoeYHtZ3uI+nzhAuZFC6/OM+l+muPeJwJFVYuiRHY0MnqLcJ402ZyYNVL5NCRfHg0HB09x+
 p8g4irxXYe4CvbNPE7Hj4Nl8+MePzf15MKpUJS1fMu5eW+uEkv0BRqLqbIkXGqoGLyP28E8xhjA0HY
 Il7EAF6BoAhxoG52+v9loCyzJZjiN4oMZ5A1QRkvhA9MEZRXmz386l+/K1dmGAwPxn6EbEOtRlfb55
 qnL3LrPDn/o6PZFFOlK7G26VetuwcU
X-Developer-Key: i=sforshee@kernel.org; a=openpgp;
 fpr=2ABCA7498D83E1D32D51D3B5AB4800A62DB9F73A
X-Endpoint-Received: by B4 Relay for sforshee@kernel.org/default with auth_id=103
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mnt_idmapping.h uses declarations from cred.h, so it should include that
file directly.

Signed-off-by: Seth Forshee (DigitalOcean) <sforshee@kernel.org>
---
 include/linux/mnt_idmapping.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/linux/mnt_idmapping.h b/include/linux/mnt_idmapping.h
index f463b9e1e258..6deba8d5481e 100644
--- a/include/linux/mnt_idmapping.h
+++ b/include/linux/mnt_idmapping.h
@@ -5,6 +5,7 @@
 #include <linux/types.h>
 #include <linux/uidgid.h>
 #include <linux/vfsid.h>
+#include <linux/cred.h>
 
 struct mnt_idmap;
 struct user_namespace;

-- 
2.43.0

