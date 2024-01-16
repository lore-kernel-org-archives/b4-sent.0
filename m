From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:39 +0000
Subject: [PATCH BlueZ 14/20] mesh: const annotate misc data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-14-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=736;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=6tOC6zO5jyNErTKsxfQ8UiUAUopjHEVML0310cw+Lzg=;
 b=JSjJXFSnWAE4MeQNJ4JzFZDEPQDGDb7ZoYs/5pg4Leodg964HThBOPwsTxYDcraVqr6GQ41w6
 GLijVFiDJeVD/eu0cYAe+C+K/ZZsOgzfY5PHdKxAvdNX/6qAuimDG0n
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 mesh/agent.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/mesh/agent.c b/mesh/agent.c
index 5058d0d8d..2f9697a33 100644
--- a/mesh/agent.c
+++ b/mesh/agent.c
@@ -61,7 +61,7 @@ struct oob_info {
 	uint16_t mask;
 };
 
-static struct prov_action cap_table[] = {
+static const struct prov_action cap_table[] = {
 	{"blink", 0x0001, 0x0000, 1},
 	{"beep", 0x0002, 0x0000, 1},
 	{"vibrate", 0x0004, 0x0000, 1},
@@ -73,7 +73,7 @@ static struct prov_action cap_table[] = {
 	{"in-alpha", 0x0000, 0x0008, 8}
 };
 
-static struct oob_info oob_table[] = {
+static const struct oob_info oob_table[] = {
 	{"other", 0x0001},
 	{"uri", 0x0002},
 	{"machine-code-2d", 0x0004},

-- 
2.43.0

