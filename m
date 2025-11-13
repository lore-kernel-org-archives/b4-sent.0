From: Louis Rannou <louis.rannou@non.se.com>
Date: Thu, 13 Nov 2025 15:46:14 +0100
Subject: [PATCH b4 2/2] send-receive: support for presubjects
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sub-v1-2-921bef0da4d2@non.se.com>
References: <20251113-sub-v1-0-921bef0da4d2@non.se.com>
In-Reply-To: <20251113-sub-v1-0-921bef0da4d2@non.se.com>
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Louis Rannou <louis.rannou@non.se.com>, pascal.eberhard@se.com, 
 antonin.godard@bootlin.com
X-Mailer: b4 0.15-dev-0f001
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763045178; l=1253;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=mUnQv8OfqDkhZlxsHVKldPSBZO9GmCSe2HoK1WeWp8Y=;
 b=EanBS+qahSy2R04XcjHF2K9PXm8pbh5IPa10cKtpMbERdYrrZA6EOp5UBX1PB3YwlOu0lYbGc
 lcUlPuE1cS9AB0LrLzwbuRLpwRGG4IU0ZwdsrxSwqA+ihdr3Hrkgrxi
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Accept subjects which start with bracketed prefixes.

eg. [anyproject][PATCH] title
    while 'anyproject[PATCH] title' won't pass

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
 misc/send-receive.py | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/misc/send-receive.py b/misc/send-receive.py
index bb65aaa..a3dd893 100644
--- a/misc/send-receive.py
+++ b/misc/send-receive.py
@@ -433,12 +433,12 @@ class SendReceiveListener(object):
             msg = email.message_from_bytes(bdata, policy=emlpolicy)
             logger.debug('Checking sanity on message: %s', msg.get('Subject'))
             # Some quick sanity checking:
-            # - Subject has to start with [PATCH
+            # - Subject must include [PATCH and have only bracketed prefixes before
             # - Content-type may ONLY be text/plain
             # - Has to include a diff or a diffstat
             passes = True
             subject = self.clean_header(msg.get('Subject', ''))
-            if not subject.startswith('[PATCH'):
+            if not re.match(r'(\[[^]]+\])*\[PATCH', subject):
                 passes = False
             if passes:
                 cte = msg.get_content_type()

-- 
2.43.0

