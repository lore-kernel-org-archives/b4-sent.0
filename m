From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 20:02:45 +0000
Subject: [PATCH BlueZ v2 09/10] obex: Use GLib helper function to
 manipulate paths
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-disto-patches-v2-9-8bab1bd08f4d@gmail.com>
References: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
In-Reply-To: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Bastien Nocera <hadess@hadess.net>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707768157; l=1584;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=GCUo/Nwzng2MpKTdvtQwQRt2p4nwTwzY0gaSQk+Xr7Y=;
 b=RRoKj0QjKCRqD8xfnN2FNs9AmfqfPFWy3NGEAPoYb6kR9t3DnLMdKUnhKvXrkYoKTz7Ee4YDh
 oCs3Rd8L+1SCgjpDZsqTWrUAYOxxG+cjQZVsJyJRhV9dvB9NwvH4wrK
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bastien Nocera <hadess@hadess.net>

Instead of trying to do it by hand. This also makes sure that
relative paths aren't used by the agent.

[Emil Velikov]
Originally this patch was posted in 2013, but deferred since bluez was
planning to move away from glib. Presently there's no obvious action
towards that goal, so I think we can safely land this.

As mentioned by the author, current code allows for relative paths and
considering that obexd service runs without meaningful sandboxing and on
some distributions it is ran as root, we should plug the whole before
anyone (ab)uses it.
---
 obexd/src/manager.c | 15 +++++----------
 1 file changed, 5 insertions(+), 10 deletions(-)

diff --git a/obexd/src/manager.c b/obexd/src/manager.c
index 73fd6b9af..cc1de7ae2 100644
--- a/obexd/src/manager.c
+++ b/obexd/src/manager.c
@@ -644,18 +644,13 @@ static void agent_reply(DBusPendingCall *call, void *user_data)
 				DBUS_TYPE_STRING, &name,
 				DBUS_TYPE_INVALID)) {
 		/* Splits folder and name */
-		const char *slash = strrchr(name, '/');
+		gboolean is_relative = !g_path_is_absolute(name);
 		DBG("Agent replied with %s", name);
-		if (!slash) {
-			agent->new_name = g_strdup(name);
+		agent->new_name = g_path_get_basename(name);
+		if (is_relative)
 			agent->new_folder = NULL;
-		} else {
-			if (strlen(slash) == 1)
-				agent->new_name = NULL;
-			else
-				agent->new_name = g_strdup(slash + 1);
-			agent->new_folder = g_strndup(name, slash - name);
-		}
+		else
+			agent->new_folder = g_path_get_dirname(name);
 	}
 
 	dbus_message_unref(reply);

-- 
2.43.0

