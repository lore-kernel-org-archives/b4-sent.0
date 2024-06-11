From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 11 Jun 2024 15:34:56 +0100
Subject: [PATCH kmod] .mailmap: Forward to my personal email
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-mailmap-v1-1-69ce7f7ffbe6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJBgaGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDM0ND3dzEzJzcxALdFEtLQ9NkI3ODlFRLJaDqgqLUtMwKsEnRsbW1AHO
 HZBhZAAAA
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718116499; l=637;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=tP92u435afiqHpYb37PUHPdJHFdDZzRRYbNdk2K9+HI=;
 b=4k7eUFnEF+XuReppNLw5CVpDMuYJheEycH/rLQPeaJieCNf1Q9Ud0E6PTS6+EYirtNYTrhs8A
 78XVud30N8dCC72PJrjCXMeasAueyshMHe6GG43NXg4P1kIP6Bjb6/y
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

My Collabora email is bouncing, so forward to my personal Gmail.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
Hello everyone, just a trivial one-liner to reduce annoyance due to
bouncing emails.
---
 .mailmap | 1 +
 1 file changed, 1 insertion(+)

diff --git a/.mailmap b/.mailmap
new file mode 100644
index 0000000..7a9ca51
--- /dev/null
+++ b/.mailmap
@@ -0,0 +1 @@
+Emil Velikov <emil.l.velikov@gmail.com> <emil.velikov@collabora.com>

---
base-commit: 8837461494761d58be579641f20cc043274adddf
change-id: 20240611-mailmap-d9915c270de9

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

