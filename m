From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/2] Minor typo fixes
Date: Fri, 29 Nov 2024 20:42:27 +0100
Message-Id: <20241129-typo-v1-0-1ac3fef74eee@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACMZSmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDQyNL3ZLKgnxdyxSTFJNEC/PEZLNUJaDSgqLUtMwKsDHRsbW1AFt66id
 WAAAA
X-Change-ID: 20241129-typo-9d4d4a87ac6e
To: Mario Six <mario.six@gdsys.cc>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732909355; l=519;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=5p1ZuMH4hjGy0QxNBSAhRF0kND0CdqEMCGSoiIiObDY=;
 b=a3E0EblwADltd9wOWEAmEirDDjTsCVKYSoLVvmqAL7uuP8Kz2LfHIrhHm1di94w79HSQtZfE/
 5+LeV3JfetJAFN1lAsprMqW++5VFc69wF5v7veQoiJhsI7/e9Mhh6xd
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset includes two small typo fixes.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (2):
      clk: mpc83xx: Fix typo in "Coherent System Bus"
      doc: sending_patches: Fix spelling of "its"

 doc/develop/sending_patches.rst | 2 +-
 drivers/clk/mpc83xx_clk.h       | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
---
base-commit: 62224280d9e89648ae90346c0aede76f9b7e7610
change-id: 20241129-typo-9d4d4a87ac6e

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

