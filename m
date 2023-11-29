From: "Seth Forshee (DigitalOcean)" <sforshee@kernel.org>
Date: Wed, 29 Nov 2023 15:50:20 -0600
Subject: [PATCH 02/16] mnt_idmapping: include cred.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231129-idmap-fscap-refactor-v1-2-da5a26058a5b@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=615; i=sforshee@kernel.org;
 h=from:subject:message-id; bh=kBYMx/ct1DJWmWZZrfAgu5rv/aqJOd49LOYKeJgW/mY=;
 b=owEBbQGS/pANAwAKAVMDma7l9DHJAcsmYgBlZ7IzazfoDYxcriweVPsbLfsCPXs/YDZSjasrRYGN
 eexJIWaJATMEAAEKAB0WIQSQnt+rKAvnETy4Hc9TA5mu5fQxyQUCZWeyMwAKCRBTA5mu5fQxySJiB/
 9HkMVbp8BLl9a8xkc+YIMjsDXeUD/DHctJIej9o90WQvjfYFOqnp97oRSL05awrVwXaUy4ay7+yCJS
 h+TxM3omvveG14tjLJ3wCyk3SZ5mQum5AyAut1Dx7GvAH+aKzPhZyyQZtT0nPq9vJ494NfMFXjQ5yJ
 3S4b0KcfPnTHEeSpenRnG/gVjMR15wLsSE07DAnXfndDrwZ25uR9RNVxxoQ2/oIyPGlW9O4KZj8s0y
 ApyXfbn7vle/qhUTdd10Mt0GITrja5wk0lSvSicVeS2eB1a7VlOSSCIz6PQhg2BEDCONPD+NTd0khr
 zlm1ANoVLdZpKoEkqw0ZUzJrM5jm8Z
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
index 8b5e00ee6472..65e5d0c32fde 100644
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

