From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:31 +0000
Subject: [PATCH BlueZ 06/20] monitor: const annotate type_table and related
 API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-6-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=783;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=xa4m8BsqTwPsc2SbBBo+2BlpNjfQfWB+tZ+SM4CKAmo=;
 b=wuusPUs7wV1y9nQqPDEeVU00HLz/4Zdq0v8wX4r6qgkspyKyLOFd0JQJvXwvE2XQz2fc6GGXH
 /502u705obvC8TgKotC2wO8DmTfKS/eL+ifhg35AFVy5pK+FGyjqQB5
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 monitor/sdp.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/monitor/sdp.c b/monitor/sdp.c
index 2c69dc83b..5fe4f2979 100644
--- a/monitor/sdp.c
+++ b/monitor/sdp.c
@@ -148,9 +148,9 @@ static void print_boolean(uint8_t indent, const uint8_t *data, uint32_t size)
 
 #define SIZES(args...) ((uint8_t[]) { args, 0xff } )
 
-static struct {
+static const struct {
 	uint8_t value;
-	uint8_t *sizes;
+	const uint8_t *sizes;
 	bool recurse;
 	const char *str;
 	void (*print) (uint8_t indent, const uint8_t *data, uint32_t size);
@@ -184,7 +184,7 @@ static const struct {
 	{ }
 };
 
-static bool valid_size(uint8_t size, uint8_t *sizes)
+static bool valid_size(uint8_t size, const uint8_t *sizes)
 {
 	int i;
 

-- 
2.43.0

