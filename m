From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/2] net: tsec: Improve receive error path
Date: Sun, 16 Feb 2025 22:18:11 +0100
Message-Id: <20250216-tsec-v1-0-9a704bedd048@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABNWsmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDI0Mz3ZLi1GRdo8TkFDOjJMs0CxMTJaDSgqLUtMwKsDHRsbW1AD/iLYp
 WAAAA
X-Change-ID: 20250216-tsec-2acd62b9f844
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739740693; l=603;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=ocAAKkpNeD1R37ZlvXCW9INUlqN8UcuGOX/TcPPNr8k=;
 b=ll7CbA5opicZYcLkskJDYE/Th5a0ezXbI/xinvVGwPuYReZ5d95IR6G199JDmRWwSBjEty9oo
 x7Rya2I5U97DZgWSU/f+Bye64K5xJvnh+Wl59LGc2/oRHVDu30f6IHt
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, errors in the receive path of the TSEC Ethernet driver result
in an exhaustion of packet buffer descriptors. This series fixes it.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (2):
      net: tsec: Reorder tsec_recv and tsec_free_pkt
      net: tsec: Re-arm packet buffer in error case

 drivers/net/tsec.c | 39 +++++++++++++++++++++------------------
 1 file changed, 21 insertions(+), 18 deletions(-)
---
base-commit: 5919f48b1c751b85453adca96493ab16f9098be0
change-id: 20250216-tsec-2acd62b9f844

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

