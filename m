From: Louis Rannou <louis.rannou@non.se.com>
Date: Wed, 16 Jul 2025 16:04:09 +0200
Subject: [PATCH RFC 1/2] Fix usage of PATCH in prefixes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250716-prefixes-v1-1-b8652d4de0a6@non.se.com>
References: <20250716-prefixes-v1-0-b8652d4de0a6@non.se.com>
In-Reply-To: <20250716-prefixes-v1-0-b8652d4de0a6@non.se.com>
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Louis Rannou <louis.rannou@non.se.com>, pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752674650; l=1639;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=CfLpz8qB6gnvrEky8wC9S3UK+CoOrRvn6rKhhoHGcko=;
 b=osH708Kjx5Egvr2aVJDIYzv3YTPn1h1t8UnONo2/zrvqrU6yXeHNPMEMyXAjqeyK7OXK9aA6a
 D4zs41SAqD0A5IgySjUtf/4/co6ZQJcXXFa0lvHa+MZio7qvQjS90cI
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several projects have a '[prefix]' before '[PATCH]'. While git-send-email
supports having prefixes before 'PATCH' using a 'prefix][PATCH' syntax, b4 still
prepends prefixes with '[PATCH '.

Including 'PATCH' in prefixes is not sufficient as it will keep an extra space
before the 'PATCH' keyword.

Before:
b4 prep --set-prefix 'prefix][PATCH' gave [PATCH prefix][PATCH]
b4 prep --set-prefixes prefix PATCH  gave [prefix][ PATCH]

After:
b4 prep --set-prefix 'prefix][PATCH' gives [prefix][PATCH]

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
 src/b4/__init__.py | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/src/b4/__init__.py b/src/b4/__init__.py
index ff6075e..72ef79b 100644
--- a/src/b4/__init__.py
+++ b/src/b4/__init__.py
@@ -2568,14 +2568,16 @@ class LoreSubject:
 
     def get_rebuilt_subject(self, eprefixes: Optional[List[str]] = None) -> str:
         exclude = None
-        if eprefixes and 'PATCH' in eprefixes:
+        rpatch = re.compile(r'.*\[PATCH', re.IGNORECASE)
+
+        if eprefixes and list(filter(rpatch.match, eprefixes)):
             exclude = ['patch']
         _pfx = self.get_extra_prefixes(exclude=exclude)
         if eprefixes:
             for _epfx in eprefixes:
                 if _epfx.lower() not in [x.lower() for x in _pfx]:
                     _pfx.append(_epfx)
-        if 'patch' not in [x.lower() for x in _pfx]:
+        if not list(filter(rpatch.match, [x for x in _pfx])):
             _pfx.insert(0, 'PATCH')
         if self.revision > 1:
             _pfx.append(f'v{self.revision}')

-- 
2.43.0

