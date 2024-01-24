From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 24 Jan 2024 16:20:06 +0000
Subject: [PATCH BlueZ v2 1/6] build: remove unused variable builtin_nodist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240124-autofoo-v2-1-a210f20aa2f7@gmail.com>
References: <20240124-autofoo-v2-0-a210f20aa2f7@gmail.com>
In-Reply-To: <20240124-autofoo-v2-0-a210f20aa2f7@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706113208; l=721;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=mRorcTTMdiR12GxUJR7RTE8pAyiDxz8fyZaYph6MM1Q=;
 b=zYqpeqpBTSvsRBWWKT221IWpEpNM0P32h51uAVI9lHUQ/oF01kAMS/Ek8I1BJbR7dUYmkNext
 cxrAAo1co8WCNEQCZpgzylVKkIf1lqit+gfpmomnaMPIQvohS9vswNk
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 Makefile.am | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index e738eb3a5..a470e40cf 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -288,7 +288,6 @@ gobex_sources = gobex/gobex.h gobex/gobex.c \
 builtin_modules =
 builtin_sources =
 builtin_cppflags =
-builtin_nodist =
 builtin_ldadd =
 
 include Makefile.plugins
@@ -350,7 +349,7 @@ src_bluetoothd_CPPFLAGS = $(AM_CPPFLAGS) -DBLUETOOTH_PLUGIN_BUILTIN \
 					$(BACKTRACE_CFLAGS) $(builtin_cppflags)
 src_bluetoothd_SHORTNAME = bluetoothd
 
-builtin_files = src/builtin.h $(builtin_nodist)
+builtin_files = src/builtin.h
 
 nodist_src_bluetoothd_SOURCES = $(builtin_files)
 

-- 
2.43.0

