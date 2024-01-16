From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 13:51:58 +0000
Subject: [PATCH BlueZ 04/10] build: remove dummy {conf,state}{dir,_DATA}
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-autofoo-v1-4-626f6b54bd06@gmail.com>
References: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
In-Reply-To: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413116; l=1330;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=Q7TCSQ+lTvESiDlf6GOyquny1w/mZRux7BcOUrFyJvw=;
 b=zs56xedLr7+3P9GVPhMkEbqsSEm7QL/Q4Kpgf8Qzj3WFC+8RBHORpib/q5pJKGYtdK7PmuODy
 hBTjQ2t+zOzAIof2UuaVXZf+ViPYKlmDFtMhLMhoxpUb7wpjNUOEY80
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

The project does not install anything in the respective confdir and
statedir(s). Since no files are installed, the respective folders are
not created either - systemd will create them prior to starting the
service(s).

The *dir variables themselves are no longer used in *service.in, so
remove everything.
---
 Makefile.am | 10 +---------
 1 file changed, 1 insertion(+), 9 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index e738eb3a5..16d6bf160 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -28,15 +28,9 @@ AM_CFLAGS = $(MISC_CFLAGS) $(WARNING_CFLAGS) $(UDEV_CFLAGS) $(LIBEBOOK_CFLAGS) \
 				$(LIBEDATASERVER_CFLAGS) $(ell_cflags)
 AM_LDFLAGS = $(MISC_LDFLAGS)
 
-confdir = $(sysconfdir)/bluetooth
-statedir = $(localstatedir)/lib/bluetooth
-
 if DATAFILES
 dbusdir = $(DBUS_CONFDIR)/dbus-1/system.d
 dbus_DATA = src/bluetooth.conf
-
-conf_DATA =
-state_DATA =
 endif
 
 if SYSTEMD
@@ -747,9 +741,7 @@ MAINTAINERCLEANFILES = Makefile.in \
 
 SED_PROCESS = $(AM_V_GEN)$(MKDIR_P) $(dir $@) && \
 		$(SED) -e 's,@pkglibexecdir\@,$(pkglibexecdir),g' \
-		       -e 's,@libexecdir\@,$(libexecdir),g' \
-		       -e 's,@statedir\@,$(statedir),g' \
-		       -e 's,@confdir\@,$(confdir),g' \
+		       -e 's,@libexecdir\@,$(libexecdir),g'
 		< $< > $@
 
 if RUN_RST2MAN

-- 
2.43.0

