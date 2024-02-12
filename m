From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 20:02:37 +0000
Subject: [PATCH BlueZ v2 01/10] Return at least the title attribute from
 player_list_metadata()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-disto-patches-v2-1-8bab1bd08f4d@gmail.com>
References: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
In-Reply-To: <20240212-disto-patches-v2-0-8bab1bd08f4d@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Sam Lantinga <slouken@libsdl.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707768157; l=669;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=bHLjtE0BG3PUYg6Jf5Zv16cafv879d0HdvZOTdHzrz4=;
 b=lPBdaDdiQpidYd3FrEXZfUvhbbag4qQnneh3NTvUU1h3AliGylEKB+1kEq0S7FyDiuzNgM6Rk
 P4sznH5RHq2AWWw/dc1KsyovnQo3mHWoaaKai7N4c+mXcd0ukyW6A1L
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sam Lantinga <slouken@libsdl.org>

This fixes Bluetooth AVRCP certification test AVRCP/TG/MDI/BV-04-C,
which requires a valid response from the get_element_attributes command.
---
 profiles/audio/avrcp.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/profiles/audio/avrcp.c b/profiles/audio/avrcp.c
index 439fa27a9..36ce01a14 100644
--- a/profiles/audio/avrcp.c
+++ b/profiles/audio/avrcp.c
@@ -1210,6 +1210,10 @@ static GList *player_list_metadata(struct avrcp_player *player)
 					GUINT_TO_POINTER(str_to_metadata(key)));
 	}
 
+	if (attrs == NULL)
+		return g_list_prepend(NULL,
+				GUINT_TO_POINTER(AVRCP_MEDIA_ATTRIBUTE_TITLE));
+
 	return attrs;
 }
 

-- 
2.43.0

