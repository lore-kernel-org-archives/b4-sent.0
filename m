From: Louis Rannou <louis.rannou@non.se.com>
Date: Wed, 16 Jul 2025 16:04:10 +0200
Subject: [PATCH RFC 2/2] send-receive: accept bracket-prefix before
 '[PATCH'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250716-prefixes-v1-2-b8652d4de0a6@non.se.com>
References: <20250716-prefixes-v1-0-b8652d4de0a6@non.se.com>
In-Reply-To: <20250716-prefixes-v1-0-b8652d4de0a6@non.se.com>
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Louis Rannou <louis.rannou@non.se.com>, pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752674650; l=1336;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=kAkV02g7Gz/O8wHv7cuyXl69EEnMYrXcM4k+aRHsAxI=;
 b=WAbopOdLb4pcZRpM+vLVrPXVp5jspBJfnRRj1/prtbwBIlNbsPrVpEnTJf0FotS8aS6aH+djR
 5HfwirhbAjJDBnqePz9N/aAa+MS601w8uLknpA5oZTv1dZvUioh+9z7
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Change how send-receive checks the subject is well-formatted by accepting
bracket prefixes before [PATCH.

All opened bracket must be closed and text is only accepted in brackets.

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
 misc/send-receive.py | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/misc/send-receive.py b/misc/send-receive.py
index bb65aaa..d574054 100644
--- a/misc/send-receive.py
+++ b/misc/send-receive.py
@@ -433,12 +433,13 @@ class SendReceiveListener(object):
             msg = email.message_from_bytes(bdata, policy=emlpolicy)
             logger.debug('Checking sanity on message: %s', msg.get('Subject'))
             # Some quick sanity checking:
-            # - Subject has to start with [PATCH
+            # - Subject has to start with [PATCH or has only bracket-prefixes
+            #   such as [prefix][PATCH
             # - Content-type may ONLY be text/plain
             # - Has to include a diff or a diffstat
             passes = True
             subject = self.clean_header(msg.get('Subject', ''))
-            if not subject.startswith('[PATCH'):
+            if not re.match(r'(\[.*\])*[PATCH.*', subject):
                 passes = False
             if passes:
                 cte = msg.get_content_type()

-- 
2.43.0

