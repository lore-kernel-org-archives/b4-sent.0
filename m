From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 16:05:03 +0100
Subject: [PATCH kmod 03/20] man: build the scdoc based man pages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-man-v1-3-bd6864d49639@gmail.com>
References: <20240611-man-v1-0-bd6864d49639@gmail.com>
In-Reply-To: <20240611-man-v1-0-bd6864d49639@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718118301; l=2553;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=dl1+/dNbs/jvTy3ZNqBX6ojBIXb0bXg0KM+9qRR65Go=;
 b=4ZqlwLgzt57gf07nKUiCplQWZHXc+cXWwHxTbFJA7pTmO9EmXRWt+R7SW+UwUP1IVVhhQs30s
 LNzhaz0xKykB8+g2ZwgnsVpAeQ7+kHr+wZE7+kTvpF+DL+jDBOJRLGp
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Note that scdoc does not handle natively handle the dummy
modules.dep.bin.5 entry, so we need to create one manually.

Not a big deal, since it's single static line anyway.

Also: pkg-config --variable=scdoc scdoc, produces the full executable
and path, although for now we stick with the AC_PATH_PROG approach.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 configure.ac          |  2 +-
 man/Makefile.am       | 24 ++++++++----------------
 man/modules.dep.bin.5 |  1 +
 3 files changed, 10 insertions(+), 17 deletions(-)

diff --git a/configure.ac b/configure.ac
index 9527aa2..dcf7479 100644
--- a/configure.ac
+++ b/configure.ac
@@ -32,7 +32,7 @@ AC_PROG_SED
 AC_PROG_MKDIR_P
 AC_PROG_LN_S
 PKG_PROG_PKG_CONFIG
-AC_PATH_PROG([XSLTPROC], [xsltproc])
+AC_PATH_PROG([SCDOC], [scdoc])
 
 AC_PROG_CC_C99
 
diff --git a/man/Makefile.am b/man/Makefile.am
index d62ff21..0285fdd 100644
--- a/man/Makefile.am
+++ b/man/Makefile.am
@@ -2,37 +2,29 @@ MAN5 = depmod.d.5 modprobe.d.5 modules.dep.5
 MAN8 = kmod.8 depmod.8 insmod.8 lsmod.8 rmmod.8 modprobe.8 modinfo.8
 MAN_STUB = modules.dep.bin.5
 
-AM_V_XSLT = $(AM_V_XSLT_$(V))
-AM_V_XSLT_ = $(AM_V_XSLT_$(AM_DEFAULT_VERBOSITY))
-AM_V_XSLT_0 = @echo "  XSLT    " $@;
-
-XSLT = $(if $(XSLTPROC), $(XSLTPROC), xsltproc)
+AM_V_SCDOC = $(AM_V_SCDOC_$(V))
+AM_V_SCDOC_ = $(AM_V_SCDOR_$(AM_DEFAULT_VERBOSITY))
+AM_V_SCDOC_0 = @echo "  SCDOC    " $@;
 
 if BUILD_TOOLS
 dist_man_MANS = $(MAN5) $(MAN8) $(MAN_STUB)
-modules.dep.bin.5: modules.dep.5
 endif
 
-EXTRA_DIST = $(MAN5:%.5=%.5.xml) $(MAN8:%.8=%.8.xml)
+EXTRA_DIST = $(MAN5:%.5=%.5.scd) $(MAN8:%.8=%.8.scd)
 CLEANFILES = $(dist_man_MANS)
 
 define generate_manpage
-	$(AM_V_XSLT)if [ '$(distconfdir)' != '/lib' ] ; then \
+	$(AM_V_SCDOC)if [ '$(distconfdir)' != '/lib' ] ; then \
 		sed -e 's|@DISTCONFDIR@|$(distconfdir)|g' $< ; \
 	else \
 		sed -e '/@DISTCONFDIR@/d' $< ; \
 	fi | \
 	sed -e 's|@MODULE_DIRECTORY@|$(module_directory)|g' | \
-	$(XSLT) \
-		-o $@ \
-		--nonet \
-		--stringparam man.output.quietly 1 \
-		--param funcsynopsis.style "'ansi'" \
-		http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl -
+	$(SCDOC) > $@
 endef
 
-%.5: %.5.xml
+%.5: %.5.scd
 	$(generate_manpage)
 
-%.8: %.8.xml
+%.8: %.8.scd
 	$(generate_manpage)
diff --git a/man/modules.dep.bin.5 b/man/modules.dep.bin.5
new file mode 100644
index 0000000..795636b
--- /dev/null
+++ b/man/modules.dep.bin.5
@@ -0,0 +1 @@
+.so modules.dep.5

-- 
2.45.0

