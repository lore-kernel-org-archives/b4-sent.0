From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 13:51:59 +0000
Subject: [PATCH BlueZ 05/10] build: remove unused variable builtin_nodist
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-autofoo-v1-5-626f6b54bd06@gmail.com>
References: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
In-Reply-To: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413116; l=721;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=1rROEGp9NOWMlEicl4MnpoSQNRD9hD+pCI8aDd5Iw2Y=;
 b=6jtaeZ6PO/Q9YbEwDcmhoxjfYFo0I1NkXk0OaOcsnq4hzzT1mYAgRHMErs2ozaGoGUvadEUbF
 /OQSpMQba1kCv9RFKEWeiuhh3tfrzReStoPvq40JPvAWx+1Zl4sGwyf
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 Makefile.am | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index 16d6bf160..564f1b935 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -282,7 +282,6 @@ gobex_sources = gobex/gobex.h gobex/gobex.c \
 builtin_modules =
 builtin_sources =
 builtin_cppflags =
-builtin_nodist =
 builtin_ldadd =
 
 include Makefile.plugins
@@ -344,7 +343,7 @@ src_bluetoothd_CPPFLAGS = $(AM_CPPFLAGS) -DBLUETOOTH_PLUGIN_BUILTIN \
 					$(BACKTRACE_CFLAGS) $(builtin_cppflags)
 src_bluetoothd_SHORTNAME = bluetoothd
 
-builtin_files = src/builtin.h $(builtin_nodist)
+builtin_files = src/builtin.h
 
 nodist_src_bluetoothd_SOURCES = $(builtin_files)
 

-- 
2.43.0

