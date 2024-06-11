From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:10 +0100
Subject: [PATCH kmod 10/20] man: stop removing DISTCONFDIR lines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-10-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=1089;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=MRlljoUHYBNK6Z6N5RhRZTe/uBXRrwuRR7bbc0V2Tww=;
 b=jDYIVtlDROU2qm86wbM3x7+bMQdV8LcSZLozo7IibTiM6EI0bqgBydT9umRPZIfjkZiZnSjUf
 06rDjaipQJ5DztjhbfYZqKEAaMxSnObwvWEN3yiLG20oFRTm0bc1VP0
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
index 0285fdd..25135e9 100644
--- a/man/Makefile.am
+++ b/man/Makefile.am
@@ -14,11 +14,8 @@ EXTRA_DIST = $(MAN5:%.5=%.5.scd) $(MAN8:%.8=%.8.scd)
 CLEANFILES = $(dist_man_MANS)
 
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
2.45.0

