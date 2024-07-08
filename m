From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 08 Jul 2024 14:43:14 +0100
Subject: [PATCH kmod v2 06/17] man: stop removing DISTCONFDIR lines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240708-man-v2-6-a23df6ef871e@gmail.com>
References: <20240708-man-v2-0-a23df6ef871e@gmail.com>
In-Reply-To: <20240708-man-v2-0-a23df6ef871e@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720446209; l=1116;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=D6xvHTo+v2kzK3NQz14BeM4H1z9+URlZ49VIK5g1yzg=;
 b=3YKV4A8Pb2O2BSmoRphpo1m2hilUytQEshPtJmlpzL+3aMlzvtHjtn3HpxKkOXQC7hJttiZQe
 8z4YOhiRq3MC5zkInTuzwD1AB2vH4GADIy05tC8NEHTUttzOVE6mTDQ
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Presently when DISTCONFDIR is identical to /lib we remove the whole
line, since the man pages already have an /lib instance.

At the same time, there are in-text DISTCONFDIR entries, and removing
the whole line outright breaks the documentation.

Drop the removal line - worst case scenario we get a duplicate entry in
the synopsis.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 man/Makefile.am | 7 ++-----
 1 file changed, 2 insertions(+), 5 deletions(-)

diff --git a/man/Makefile.am b/man/Makefile.am
index 77a0035..39a0015 100644
--- a/man/Makefile.am
+++ b/man/Makefile.am
@@ -14,11 +14,8 @@ EXTRA_DIST = $(MAN5:%.5=%.5.scd) $(MAN8:%.8=%.8.scd)
 CLEANFILES = $(filter-out $(MAN_STUB), $(dist_man_MANS))
 
 define generate_manpage
-	$(AM_V_SCDOC)if [ '$(distconfdir)' != '/lib' ] ; then \
-		sed -e 's|@DISTCONFDIR@|$(distconfdir)|g' $< ; \
-	else \
-		sed -e '/@DISTCONFDIR@/d' $< ; \
-	fi | \
+	$(AM_V_SCDOC)cat $< | \
+	sed -e 's|@DISTCONFDIR@|$(distconfdir)|g' | \
 	sed -e 's|@MODULE_DIRECTORY@|$(module_directory)|g' | \
 	$(SCDOC) > $@
 endef

-- 
2.45.2

