From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 16 Feb 2024 23:11:10 +0000
Subject: [PATCH BlueZ v2 06/10] build: drop explicit -fPIC from obexd
 CFLAGS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-hook-fixup-v2-6-a6b192d1a6ad@gmail.com>
References: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
In-Reply-To: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
To: linux-bluetooth@vger.kernel.org
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708125068; l=777;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=RWIlAJI/f0bffjXcuxiy9osevTreZ+4pUs/NPwBF2tA=;
 b=Q7XgNCkkxFOJ7c+3UFQmzJduYnXLnGLmxVvhtPRhndRPtTVw0GFrYBUJIBV302Tf+ZKJLdavi
 hGm3G6GV0YiCy4ViuvukEbJeTIc5BhQlxn7GmWgqdjgIGFRw47WCjWk
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The option is handled by the global --enable-pic. Drop the local
explicit argument.

With that we can drop the standalone CFLAGS.

Aside: the -D_FILE_OFFSET_BITS=64 also seems off - we should either be
setting it globally or not at all... Something for another rainy day.
---
 Makefile.obexd | 2 --
 1 file changed, 2 deletions(-)

diff --git a/Makefile.obexd b/Makefile.obexd
index e8e4a6144..01aa3a9c7 100644
--- a/Makefile.obexd
+++ b/Makefile.obexd
@@ -104,8 +104,6 @@ obexd_src_obexd_CPPFLAGS = $(AM_CPPFLAGS) $(GLIB_CFLAGS) $(DBUS_CFLAGS) \
 				-D_FILE_OFFSET_BITS=64 \
 				-I$(builddir)/lib -I$(builddir)/obexd/src
 
-obexd_src_obexd_CFLAGS = $(AM_CFLAGS) -fPIC
-
 else
 obexd-add-service-symlink:
 obexd-remove-service-symlink:

-- 
2.43.1

