From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:36 +0000
Subject: [PATCH BlueZ 11/20] gobex: const annotate RO arrays, use
 G_N_ELEMENTS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-11-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=1328;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=fKEuOSVKg0zguPSlbGmjQMiLNTaWi6zZrrBTQ9MTicY=;
 b=0OUt50pFkhUCXUGGFl5FRDpNCvoyOOEqLLNQNxqu1qafyrRwAGipXGI30lQSczquLxIwZZGYu
 FL5ynJpKvwYDlAD42F5dtJcDo8NiyUJt2WB5MEa+s7VAwqXWknO3tCX
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 gobex/gobex.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/gobex/gobex.c b/gobex/gobex.c
index e9b89cead..8924e059f 100644
--- a/gobex/gobex.c
+++ b/gobex/gobex.c
@@ -122,7 +122,7 @@ struct setpath_data {
 	guint8 constants;
 } __attribute__ ((packed));
 
-static struct error_code {
+static const struct error_code {
 	guint8 code;
 	const char *name;
 } obex_errors[] = {
@@ -169,7 +169,7 @@ static struct error_code {
 
 const char *g_obex_strerror(guint8 err_code)
 {
-	struct error_code *error;
+	const struct error_code *error;
 
 	for (error = obex_errors; error->name != NULL; error++) {
 		if (error->code == err_code)
@@ -1423,7 +1423,7 @@ failed:
 	return FALSE;
 }
 
-static GDebugKey keys[] = {
+static const GDebugKey keys[] = {
 	{ "error",	G_OBEX_DEBUG_ERROR },
 	{ "command",	G_OBEX_DEBUG_COMMAND },
 	{ "transfer",	G_OBEX_DEBUG_TRANSFER },
@@ -1443,7 +1443,7 @@ GObex *g_obex_new(GIOChannel *io, GObexTransportType transport_type,
 		const char *env = g_getenv("GOBEX_DEBUG");
 
 		if (env) {
-			gobex_debug = g_parse_debug_string(env, keys, 7);
+			gobex_debug = g_parse_debug_string(env, keys, G_N_ELEMENTS(keys));
 			g_setenv("G_MESSAGES_DEBUG", "gobex", FALSE);
 		} else
 			gobex_debug = G_OBEX_DEBUG_NONE;

-- 
2.43.0

