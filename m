From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 16 Feb 2024 23:11:09 +0000
Subject: [PATCH BlueZ v2 05/10] build: simplify coverage handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-hook-fixup-v2-5-a6b192d1a6ad@gmail.com>
References: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
In-Reply-To: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708125068; l=1002;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=F7HjqEFBfzVfrOcOwzbG4BM6hzjjRaT6Ip2Olxc4hyo=;
 b=c72IAGHa37cqH7M2VSCdaRImQqKk8qNj2JMssAafC7dD0yy5p5pbfHE0hKaaG9HwmDPlzfLgi
 WrV7URNzSNFB1HVZfnal/4EZdAl7JiLZ8iHfKzdtxrIKxvoQaYt0s9k
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 Makefile.am | 10 ++--------
 1 file changed, 2 insertions(+), 8 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index 2d43493aa..94df43869 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -787,8 +787,8 @@ ell/ell.h: Makefile
 maintainer-clean-local:
 	-rm -rf ell
 
-if COVERAGE
 clean-coverage:
+if COVERAGE
 	@lcov --directory $(top_builddir) --zerocounters
 	$(RM) -r coverage $(top_builddir)/coverage.info
 
@@ -797,15 +797,9 @@ coverage: check
 				--output-file $(top_builddir)/coverage.info
 	$(AM_V_at)$(MKDIR_P) coverage
 	@genhtml -o coverage/ $(top_builddir)/coverage.info
+endif
 
 clean-local: clean-coverage
 	-find $(top_builddir) -name "*.gcno" -delete
 	-find $(top_builddir) -name "*.gcda" -delete
 	$(RM) -r lib/bluetooth
-
-else
-clean-local:
-	-find $(top_builddir) -name "*.gcno" -delete
-	-find $(top_builddir) -name "*.gcda" -delete
-	$(RM) -r lib/bluetooth
-endif

-- 
2.43.1

