From: Chen Linxuan <chenlinxuan@uniontech.com>
Date: Fri, 09 May 2025 14:33:53 +0800
Subject: [PATCH v3 1/3] fs: fuse: add const qualifier to
 fuse_ctl_file_conn_get()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-fusectl-backing-files-v3-1-393761f9b683@uniontech.com>
References: <20250509-fusectl-backing-files-v3-0-393761f9b683@uniontech.com>
In-Reply-To: <20250509-fusectl-backing-files-v3-0-393761f9b683@uniontech.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Amir Goldstein <amir73il@gmail.com>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=867;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=5gsZgPpE9DdgJfjYJLZW01nMHgcjhblXor/5EfeOtfc=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoHaHiGBTYKTNPLygt65IWwju1YTcRzZlzExW2K
 7EfQHe2FhaJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaB2h4gAKCRB2HuYUOZmu
 i0T8D/0V2wpmoYFcyUr4RitSZ6jcZ1nvzzmOVRs7e/J1xspBATHnhbH+Apfu0vleG2vBc2FPHg9
 c3vJlViJKQhida9zgXtDfCDc8PjwaeRNiKmiVmvq6Yug3+AjJE2fdRL4cilxe3h0ms/MEzXgP+H
 170FDIGZ1Udm7BzdSVwK+t4XUmINkfKKkl7VJTmQh2JCBbQRa+6t4ZOapdJIir8hWPHUzfmcE9F
 Y3kF+heZJrTU5rJzO6vMeDj9NfEVMXKgTroMsjiZ3VjBL23Ig4NRch4TL50ef9KMH0j53L9EV/2
 +clnoh65gDkv4hT9EYrF9EZxgS467tuRvjjnQuWRLVKXTjDmudDKpA9hft5qERyO4TXNIU5EVJR
 AY9BxoLvWTtga8kF8pgpn1ewu99ItD1b65VRf/xZc8z9/nNhVNzxNLarcKTF8edcxoR66UDxiX7
 Smvw0XbG5U3y+70cvPNzOsnbi760+CkU3w+gB9hPrB08/73kFVUMB3veXj7bRaFx45TqvRTqLXp
 85EAbo2gAiI5nUJnCfa324u7tKxRsV3IvxTKCYFszvTxu+ORiLfz7jCg7VhziAk5A1omoDIE+mI
 tRoy+OYpJSQLeOoWDdXPE7bONi4O/wP7FjjdzZUjHrczQaZw0tJUpxx1JB5t24eFfqYihDn7QOP
 LWLrDnHL2HDKJ3w==
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add const qualifier to the file parameter in fuse_ctl_file_conn_get
function to indicate that this function does not modify the passed file
object. This improves code clarity and type safety by making the API
contract more explicit.

Signed-off-by: Chen Linxuan <chenlinxuan@uniontech.com>
---
 fs/fuse/control.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/fuse/control.c b/fs/fuse/control.c
index 2a730d88cc3bdb50ea1f8a3185faad5f05fc6e74..f0874403b1f7c91571f38e4ae9f8cebe259f7dd1 100644
--- a/fs/fuse/control.c
+++ b/fs/fuse/control.c
@@ -20,7 +20,7 @@
  */
 static struct super_block *fuse_control_sb;
 
-static struct fuse_conn *fuse_ctl_file_conn_get(struct file *file)
+static struct fuse_conn *fuse_ctl_file_conn_get(const struct file *file)
 {
 	struct fuse_conn *fc;
 	mutex_lock(&fuse_mutex);

-- 
2.43.0

