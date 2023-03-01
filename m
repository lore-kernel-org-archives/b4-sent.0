From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 01 Mar 2023 18:51:32 +0000
Subject: [PATCH v2 07/16] check_whence: error on directory listed as File
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230301-fixes-and-compression-v2-7-6061ab1a0483@gmail.com>
References: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
In-Reply-To: <20230301-fixes-and-compression-v2-0-6061ab1a0483@gmail.com>
To: Josh Boyer <jwboyer@kernel.org>, Adam Sampson <ats@offog.org>, 
 David Woodhouse <dwmw2@infradead.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1677696718; l=859;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=F3j5Qldgen7pQ7rPea6JFL3+27lQd6Q2y34UCLnJp7k=;
 b=uIyH00cjYeloh83fZEScmbeJ96qo8Xrpl0KWYkUhdqEeEIxK5voKtuaEIt/hWtHEvubxvYZq5
 lpFnSTfzBRWA1pdBVU+wQ7xWdOPx9fcsoyCAwJT+j/VkRAzCd8lZd4S
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No occurrences in-tree, but it makes sense to sanity check that.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 check_whence.py | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/check_whence.py b/check_whence.py
index 7ff21f6..130966e 100755
--- a/check_whence.py
+++ b/check_whence.py
@@ -47,6 +47,11 @@ def main():
     known_prefixes = set(name for name in whence_list if name.endswith('/'))
     git_files = set(list_git())
 
+    for name in set(name for name in whence_files if name.endswith('/')):
+        sys.stderr.write('E: %s listed in WHENCE as File, but is directory\n' %
+                         name)
+        ret = 1
+
     for name in set(fw for fw in whence_files if whence_files.count(fw) > 1):
         sys.stderr.write('E: %s listed in WHENCE twice\n' % name)
         ret = 1

-- 
2.39.2

