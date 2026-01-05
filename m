From: Louis Rannou <louis.rannou@non.se.com>
Date: Mon, 05 Jan 2026 11:49:29 +0100
Subject: [PATCH 4/4] oeqa/utils: fitimage: rsa4096 signatures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-fitimage-v1-4-e319258c4c4f@non.se.com>
References: <20260105-fitimage-v1-0-e319258c4c4f@non.se.com>
In-Reply-To: <20260105-fitimage-v1-0-e319258c4c4f@non.se.com>
To: openembedded-core@lists.openembedded.org
Cc: Louis Rannou <louis.rannou@non.se.com>, adrian.freihofer@siemens.com, 
 pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767610172; l=762;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=mbO0Ur/XUEX74SWYk4SC5N44kMyTAjUd4Mp5Ss51pTs=;
 b=ej1A3jnH37E5Ur86nr/asv1hDm9CyXF4FNeajJg+OsWJ+pa4UjEKqToBtr7GuuWUuIlN4iKgp
 aekO0yP58UBAMXqbFbBxsY809uG6BxqsvYEv6oghqJkrPAsAvbf8j34
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Accept rsa4096 signatures whith length 1024.

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
 meta/lib/oeqa/utils/fitimage.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/meta/lib/oeqa/utils/fitimage.py b/meta/lib/oeqa/utils/fitimage.py
index bfe594c968..117206b39b 100644
--- a/meta/lib/oeqa/utils/fitimage.py
+++ b/meta/lib/oeqa/utils/fitimage.py
@@ -22,7 +22,7 @@ class FitImageUtils():
     """Kernel FIT image base library"""
 
     MKIMAGE_HASH_LENGTHS = { 'sha256': 64, 'sha384': 96, 'sha512': 128 }
-    MKIMAGE_SIGNATURE_LENGTHS = { 'rsa2048': 512 }
+    MKIMAGE_SIGNATURE_LENGTHS = { 'rsa2048': 512 , 'rsa4096': 1024}
 
     def __init__(self, logger):
         self.logger = logger

-- 
2.43.0

