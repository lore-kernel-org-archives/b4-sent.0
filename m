From: Louis Rannou <louis.rannou@non.se.com>
Subject: [PATCH RFC 0/2] RFC: bracket prefixes
Date: Fri, 11 Jul 2025 14:48:16 +0200
Message-Id: <20250711-prefixes-v1-0-c8d5715cc521@non.se.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABAIcWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDc0ND3YKi1LTMitRiXWNzo2Tj5DSDxDTLFCWgcpgEUHW0UpCbs1JsbS0
 Agrz8718AAAA=
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Louis Rannou <louis.rannou@non.se.com>, pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752238101; l=1336;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=fwHScP4CevQU44aZ824iYyYiSKY4ybSWzP82Z/1iJQQ=;
 b=AAEBZm9aTojfcEHgmSZjwg2mPaGCwECfIK28a5R73Kqpz/7IX85dOr1FBAZGCtwR5LVD1x80a
 fjupTRCcFXBDpp6wgcr9/7rsrBtLfxJ0fNBOwSe9qUTyRVpO8vYMkiw
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several projects such as meta-openembedded [1] or meta-security [2] require some
bracket-prefixes before '[PATCH]'. The issue is that prefixes are always
appended with spaces and the automatic '[PATCH]' prefix is excluded only if we
have a prefix 'PATCH'.

The first patch suggests to exclude the automatic prefix whenever we have a
prefix that ends with '[PATCH'.

However, it gets an error when sending:

  Reflecting via web endpoint https://lkml.kernel.org/_b4_submit
  Error from endpoint: This service only accepts patches

I suppose this comes from 'send-receive.py' ran by the server. Therefore comes
the second patch to make it accept any bracket-prefix. I was not able to test
that part.

[1]: https://git.openembedded.org/meta-openembedded/tree/meta-networking/MAINTAINERS#n3
[2]: https://git.yoctoproject.org/meta-security/tree/README.md#n77

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
Louis Rannou (2):
      Fix usage of PATCH in prefixes
      send-receive: accept bracket-prefix before '[PATCH'

 misc/send-receive.py | 5 +++--
 src/b4/__init__.py   | 6 ++++--
 2 files changed, 7 insertions(+), 4 deletions(-)
---
base-commit: a9b2aba54be85ea2933c43b8a6d71c1611230b59
change-id: 20250711-prefixes-372c3cf0af9d

Best regards,
-- 
Louis Rannou <louis.rannou@non.se.com>

