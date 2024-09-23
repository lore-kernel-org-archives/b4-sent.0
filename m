From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:32 +0100
Subject: [PATCH v2 04/16] check_whence.py: annotate replacement strings as
 raw
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-4-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=1469;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=QXGTsb532u1h7/x1Zbn/Qis/Q4r7t27FH56ktMBJAJI=;
 b=muT9UMuTDqxePyC+41xHUsietmHirEhPOilz50YlfoUk4wEO0NvdJFfW0TiNNn17gN2j/2vN3
 jpeVCB2O/QdAXkFBd5oGEfQh3YoA1zfCQZE2BNGXY4/2g65vrt+ulFq
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Otherwise python 3.12 throws warnings like below:

.../check_whence.py:40: SyntaxWarning: invalid escape sequence '\ '
  yield match.group(1).replace("\ ", " ").replace('"', "")

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 check_whence.py | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/check_whence.py b/check_whence.py
index dbbb68f7ab51b8db52c1d2334a6d4d20962bbef8..64dc133551a68aeb24dbf7f02f617ea3913477b2 100755
--- a/check_whence.py
+++ b/check_whence.py
@@ -37,7 +37,7 @@ def list_whence_files():
         for line in whence:
             match = re.match(r"(?:RawFile|File):\s*(.*)", line)
             if match:
-                yield match.group(1).replace("\ ", " ").replace('"', "")
+                yield match.group(1).replace(r"\ ", " ").replace('"', "")
                 continue
 
 
@@ -48,8 +48,8 @@ def list_links_list():
             if match:
                 linkname, target = match.group(1).split("->")
 
-                linkname = linkname.strip().replace("\ ", " ").replace('"', "")
-                target = target.strip().replace("\ ", " ").replace('"', "")
+                linkname = linkname.strip().replace(r"\ ", " ").replace('"', "")
+                target = target.strip().replace(r"\ ", " ").replace('"', "")
 
                 # Link target is relative to the link
                 target = os.path.join(os.path.dirname(linkname), target)

-- 
2.46.1

