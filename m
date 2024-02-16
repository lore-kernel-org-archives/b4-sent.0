From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 16 Feb 2024 23:11:11 +0000
Subject: [PATCH BlueZ v2 07/10] gitignore: add org.bluez.obex.service
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-hook-fixup-v2-7-a6b192d1a6ad@gmail.com>
References: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
In-Reply-To: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
To: linux-bluetooth@vger.kernel.org
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708125069; l=400;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=g0lVHzuaBBARwiB2Yc0yacc+yEkZDozfWorUyKbfBdc=;
 b=47KhO18sgWeZ/I1/LFS6zTxvR6jhbRbsZD2WmhnX/STaOIEd0XIoOKTW3efxdw/eM2fp/VsP3
 cSlnrqFEzYmANSAhlSuZwdK+KFFLvNQMDWOnxxlAaBuDoU9/A75o6Wz
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 .gitignore | 1 +
 1 file changed, 1 insertion(+)

diff --git a/.gitignore b/.gitignore
index a5954658a..4da95f275 100644
--- a/.gitignore
+++ b/.gitignore
@@ -168,6 +168,7 @@ mesh/bluetooth-mesh.service
 obexd/src/builtin.h
 obexd/src/obexd
 obexd/src/obex.service
+obexd/src/org.bluez.obex.service
 tools/obex-client-tool
 tools/obex-server-tool
 unit/test-gobex

-- 
2.43.1

