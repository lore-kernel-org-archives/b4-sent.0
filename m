From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 24 Jan 2024 23:43:56 +0000
Subject: [PATCH BlueZ 2/9] Return at least the title attribute from
 player_list_metadata()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240124-disto-patches-v1-2-97e0eb5625a3@gmail.com>
References: <20240124-disto-patches-v1-0-97e0eb5625a3@gmail.com>
In-Reply-To: <20240124-disto-patches-v1-0-97e0eb5625a3@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Sam Lantinga <slouken@libsdl.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706139864; l=669;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=bHLjtE0BG3PUYg6Jf5Zv16cafv879d0HdvZOTdHzrz4=;
 b=qEzrX0iEvgFW8dbFzlXNy1TkJfsjRtbIJ9hNER84Bn597DR7apDT71vdoiNQF50Hg7Dn44kND
 9e8w8jrrjsMDpMdcVXUnkImkznHH1x2ZmkhX9YrEg9mLnD6C74v1Kl4
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

