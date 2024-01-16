From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:18:54 +0000
Subject: [PATCH BlueZ 2/8] build: don't export internal obexd API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-rm-ext-plugins-v1-2-62990fb07369@gmail.com>
References: <20240116-rm-ext-plugins-v1-0-62990fb07369@gmail.com>
In-Reply-To: <20240116-rm-ext-plugins-v1-0-62990fb07369@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705414735; l=827;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=T0AIHHzKyS8F70Lq7NH7HmKSqGQUdU/5YvZARVJoz4Y=;
 b=cVZdkWcGGy4IlRdvrra7YNOAuxpwA6tftTtQ53iUl2NFvD9xVbg4GPVBnzgpy7ny/HzZq1It8
 KGGsoW9Ef5HCl8qdT6fqMp8Pbwdi+a0rD4VM/QrOeNF0WzLX/ZAQJZT
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

Unlike bluetoothd, obexd does not support external plugins. As such it
should not export any functions. If that ever change and plugins do
emerge, the symbols should be controlled via a version script.
---
 Makefile.obexd | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Makefile.obexd b/Makefile.obexd
index 2774f3aec..4e473d50b 100644
--- a/Makefile.obexd
+++ b/Makefile.obexd
@@ -84,7 +84,7 @@ obexd_src_obexd_LDADD = lib/libbluetooth-internal.la \
 			$(ICAL_LIBS) $(DBUS_LIBS) $(LIBEBOOK_LIBS) \
 			$(LIBEDATASERVER_LIBS) $(GLIB_LIBS) -ldl
 
-obexd_src_obexd_LDFLAGS = $(AM_LDFLAGS) -Wl,--export-dynamic
+obexd_src_obexd_LDFLAGS = $(AM_LDFLAGS)
 
 obexd_src_obexd_CPPFLAGS = $(AM_CPPFLAGS) $(GLIB_CFLAGS) $(DBUS_CFLAGS) \
 				$(ICAL_CFLAGS) -D_FILE_OFFSET_BITS=64 \

-- 
2.43.0

