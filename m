From: Louis Rannou <louis.rannou@non.se.com>
Subject: [PATCH b4 0/2] Add support for presubject
Date: Thu, 13 Nov 2025 15:46:12 +0100
Message-Id: <20251113-sub-v1-0-921bef0da4d2@non.se.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADTvFWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQ0Nj3eLSJF1jQ0OLFDODJAMDszQloMqCotS0zAqwKdFKSSZKsbW1ABf
 FcupZAAAA
X-Change-ID: 20251113-sub-3118d60b006f
To: "Kernel.org Tools" <tools@kernel.org>
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Louis Rannou <louis.rannou@non.se.com>, pascal.eberhard@se.com, 
 antonin.godard@bootlin.com
X-Mailer: b4 0.15-dev-0f001
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763045178; l=834;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=jGqCt8dKKnj64w8PDOKsSID6wACElSGtrQuf6/YKRqc=;
 b=7lIlvlZMoBedSni2GPwd9jLauK4Sa5w4EOVzRuoCfeU5O24k4QB2PqSQYsTDoNUbsV2Q7rYzx
 Z31Dc6a69ztAguztLFIHg6u2Heu0YiiN9dxCRQl0g9ImN/avx5cBu0Z
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This takes the unmerged work from Antonin Godard <antonin.godard@bootlin.com> and adds
the send-receive patch to accept presubjects.

Link: https://lore.kernel.org/tools/20250627-send-presubject-v1-1-f8e11fda1543@bootlin.com/

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
Antonin Godard (1):
      Add support for setting a presubject

Louis Rannou (1):
      send-receive: support for presubjects

 misc/send-receive.py |  4 ++--
 src/b4/__init__.py   | 27 +++++++++++++++------
 src/b4/command.py    |  2 ++
 src/b4/ez.py         | 68 ++++++++++++++++++++++++++++++++++++++++++++--------
 4 files changed, 82 insertions(+), 19 deletions(-)
---
base-commit: a6db3f06ce9836a7fc8921f588452804fc62bed1
change-id: 20251113-sub-3118d60b006f

Best regards,
--  
Louis Rannou <louis.rannou@non.se.com>

