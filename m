From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 14 Feb 2024 22:01:27 +0000
Subject: [PATCH BlueZ 4/4] build: simplify coverage handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240214-hook-fixup-v1-4-0e158ffea140@gmail.com>
References: <20240214-hook-fixup-v1-0-0e158ffea140@gmail.com>
In-Reply-To: <20240214-hook-fixup-v1-0-0e158ffea140@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707948093; l=1002;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=ESy0gP0YuVBpkapzmcgkbeJQ/DjxQ37O4UDqJ+8xAZc=;
 b=dEsw1YM+JtmX/r12Xky6gnaUXB/m7NAH4937n9pxQnTOdfDoLV+C1KBKOVldEbbazABA5Y6kO
 oyz8+2Mm9MTDwlHe0WJ8743GiO+12pPDboqvHlkR2wtO0hpUl2c25lX
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 Makefile.am | 10 ++--------
 1 file changed, 2 insertions(+), 8 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index b0845e707..08eb32852 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -793,8 +793,8 @@ ell/ell.h: Makefile
 maintainer-clean-local:
 	-rm -rf ell
 
-if COVERAGE
 clean-coverage:
+if COVERAGE
 	@lcov --directory $(top_builddir) --zerocounters
 	$(RM) -r coverage $(top_builddir)/coverage.info
 
@@ -803,15 +803,9 @@ coverage: check
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

