From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 15 Dec 2024 16:18:13 +0100
Subject: [PATCH 1/4] powerpc: mpc83xx: Fix timer value calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241215-mpc83xx-misc-v1-1-8cd6daae4f93@posteo.net>
References: <20241215-mpc83xx-misc-v1-0-8cd6daae4f93@posteo.net>
In-Reply-To: <20241215-mpc83xx-misc-v1-0-8cd6daae4f93@posteo.net>
To: Mario Six <mario.six@gdsys.cc>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734275902; l=837;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=X9I83qjkwkleJkwazR2W4ooKJgiVatQiN8xaQIBDfgo=;
 b=GKD8LbwRRMHwlkJsL9id0NJ6Z+lbW42sUKkiduEG3JgLuEBdCi4xHVW/bTTw0PTdOoVgn6HjW
 NQf7XVkoOS8A9eMAOiKk6Du8rJRkhXhkoEqtXoq2mhZluxIMhUkA6J7
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TBU and TBL are specified as two 32-bit registers that form a 64-bit
value, but the calculation only shifted TBU by 16 bits.

Fix this by actually shifting 32 bits.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/timer/mpc83xx_timer.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/timer/mpc83xx_timer.c b/drivers/timer/mpc83xx_timer.c
index 9da74479aaa678bfab861950a770b216b604c433..f92009e4ccc8256d4c5f4d11e414dfc141f5a043 100644
--- a/drivers/timer/mpc83xx_timer.c
+++ b/drivers/timer/mpc83xx_timer.c
@@ -206,7 +206,7 @@ static u64 mpc83xx_timer_get_count(struct udevice *dev)
 		tbl = mftb();
 	} while (tbu != mftbu());
 
-	return (tbu * 0x10000ULL) + tbl;
+	return (uint64_t)tbu << 32 | tbl;
 }
 
 static int mpc83xx_timer_probe(struct udevice *dev)

-- 
2.45.2

