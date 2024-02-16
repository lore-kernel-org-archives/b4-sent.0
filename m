From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 16 Feb 2024 23:11:12 +0000
Subject: [PATCH BlueZ v2 08/10] build: obexd: remove duplicate include
 -I$(builddir)/lib
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-hook-fixup-v2-8-a6b192d1a6ad@gmail.com>
References: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
In-Reply-To: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708125069; l=710;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=OZRKsu59444Zoitt96/ZqOD/W5o3DtQdHZSS7Mt3Auw=;
 b=QQ1PG6y7ObZvheXibgk3YuKIGNRxjiKJxTOdlax43C0JPqbilmVBEzBhk/wS1PnFr4cddze0S
 m4gKvTKmUIoDyMphPCHlDNCd+AhDGrK4AjlVe20OM+VPnd5iK/5pHUw
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The -I$(builddir)/lib include is already in the AM_CPPFLAGS. Drop the
duplicate instance in obexd.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 Makefile.obexd | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Makefile.obexd b/Makefile.obexd
index 01aa3a9c7..385e5618d 100644
--- a/Makefile.obexd
+++ b/Makefile.obexd
@@ -102,7 +102,7 @@ obexd_src_obexd_CPPFLAGS = $(AM_CPPFLAGS) $(GLIB_CFLAGS) $(DBUS_CFLAGS) \
 				$(ICAL_CFLAGS) -DOBEX_PLUGIN_BUILTIN \
 				-DPLUGINDIR=\""$(obex_plugindir)"\" \
 				-D_FILE_OFFSET_BITS=64 \
-				-I$(builddir)/lib -I$(builddir)/obexd/src
+				-I$(builddir)/obexd/src
 
 else
 obexd-add-service-symlink:

-- 
2.43.1

