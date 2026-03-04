From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 04 Mar 2026 01:42:57 +0100
Subject: [PATCH] io_uring/mock: Fix typo in help text
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260304-uring-typo-v1-1-152bd7474dde@posteo.net>
X-B4-Tracking: v=1; b=H4sIABCAp2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYwMT3dKizLx03ZLKgnxdk2RzYwtzE0NjA1NjJaCGgqLUtMwKsGHRsbW
 1ANKff55cAAAA
X-Change-ID: 20260304-uring-typo-4c7387413053
To: io-uring@vger.kernel.org
Cc: Jens Axboe <axboe@kernel.dk>, Pavel Begunkov <asml.silence@gmail.com>, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772584980; l=792;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=DxSaceN2mJMhpNCtrbbBcSl6awZbjwelglsQqQzCSS0=;
 b=ODptXtfvI+TT/uh0ahgieM6+lXSAuyspU2Opa6r04HnFeeZdDnjaFCotU2HBaLsac8aBwna16
 YwadOTwAa1uCJuw6uFMW+pCq9/oTIx5MiGE4K9Xi2buJJjji54m1axl
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the spelling of "subsystem".

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 init/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/init/Kconfig b/init/Kconfig
index b55deae9256c70..444ce811ea674a 100644
--- a/init/Kconfig
+++ b/init/Kconfig
@@ -1902,7 +1902,7 @@ config IO_URING_MOCK_FILE
 	default n
 	depends on IO_URING
 	help
-	  Enable mock files for io_uring subststem testing. The ABI might
+	  Enable mock files for io_uring subsystem testing. The ABI might
 	  still change, so it's still experimental and should only be enabled
 	  for specific test purposes.
 

---
base-commit: 11439c4635edd669ae435eec308f4ab8a0804808
change-id: 20260304-uring-typo-4c7387413053

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

