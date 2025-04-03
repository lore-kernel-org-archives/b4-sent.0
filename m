From: Yang Li <yang.li@amlogic.com>
Date: Thu, 03 Apr 2025 11:37:44 +0800
Subject: [PATCH BlueZ bluez v2] bass: Set the service connection flag when
 BASS connected
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250403-bass-v2-1-7925bb16468a@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAIcC7mcC/1WMyw7CIBBFf6WZtRigL+PK/zBdDDhtJ2lLA0rUh
 n+XsHN57j05BwTyTAGu1QGeIgd2WwZ9qsDOuE0k+JEZtNStbKQWBkMQXaelNKYngwqyunsa+V0
 ydzDLi74w5Hnm8HT+U+JRlfO/E5VQoqa+rS+NGhHbG66Lm9ierVthSCn9APRI3nChAAAA
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743651465; l=1169;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=/oUaFNQ9t8b1iPPgrFaYLuEADjVumJlRJxChQ0j/KrM=;
 b=c4YzSA5IL2+JAoCgrorUlXBUjLadnz99nJM5RGBTkkeEa+PXD575gTEGiTEvYsbgvFLzuhc3k
 EwylsoSekhEDLtHmQAk4Vf3t45EaFjAxQVH8yYCTQ37O9Har32bWGcS
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When BASS serice connected, set the service states to
BTD_SERVICE_STATE_CONNECTED. Otherwise, the device will
timeout and be removed, triggering the automatic termination
 of BIG.

issue: https://github.com/bluez/bluez/issues/1144

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v2:
- Set the BASS service connection success flag in the connect_cb function.
- Link to v1: https://patch.msgid.link/20250402-bass-v1-1-3e753841faa5@amlogic.com
---
 profiles/audio/bass.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/profiles/audio/bass.c b/profiles/audio/bass.c
index c36f43277..c28d9d1ad 100644
--- a/profiles/audio/bass.c
+++ b/profiles/audio/bass.c
@@ -321,6 +321,8 @@ static void connect_cb(GIOChannel *io, GError *err, void *user_data)
 	if (bt_bap_stream_set_io(stream, fd)) {
 		g_io_channel_set_close_on_unref(io, FALSE);
 	}
+
+	btd_service_connecting_complete(setup->dg->service, 0);
 }
 
 static bool link_enabled(const void *data, const void *match_data)

---
base-commit: 0efa20cbf3fb5693c7c2f14ba8cf67053ca029e5
change-id: 20250402-bass-66200bb7eba1

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

