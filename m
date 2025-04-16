From: Yang Li <yang.li@amlogic.com>
Date: Wed, 16 Apr 2025 18:12:34 +0800
Subject: [PATCH BlueZ bluez] bass: remove the device of BIS source when
 modify operation.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250416-bass_modify-v1-1-6f4a85c2c7e4@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAJGC/2cC/x3MSQqAMAxA0atI1ha0jngVEemQasCJBsUB725x+
 Rb/P8DoCRma6AGPBzGtS0AaR2BGtQwoyAaDTGSR5GkptGLu59WSu0SljEGNdZXJDEKxeXR0/rc
 W9LTjDd37fvTbIHxkAAAA
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744798359; l=965;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=WtwMgRyLk6dasgHiKyiBAQVxi48ubSbCjVHnpYA4Ysw=;
 b=y1jhPzJX0sU5nAC0OXtPgsPRFfJF+rhOxGvyBOccQ4EHU/pM26ywg9JxbcHCxNtMAtJv7bYjB
 vXtLniQndXBDh4uDks4N2mMZ/UoXta9ivFmUWii3F6DkYqLGwjsETRQ
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the Client sends a modify operation and PA Sync is
"Do not synchronize to PA", the BIS source information
needs to be cleared.

Fixes: https://github.com/bluez/bluez/issues/1145
---
Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 profiles/audio/bass.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/profiles/audio/bass.c b/profiles/audio/bass.c
index c36f43277..4bbb1bf17 100644
--- a/profiles/audio/bass.c
+++ b/profiles/audio/bass.c
@@ -1427,6 +1427,9 @@ static int handle_mod_src_req(struct bt_bcast_src *bcast_src,
 
 			bt_bass_set_pa_sync(dg->src,
 				BT_BASS_NOT_SYNCHRONIZED_TO_PA);
+
+			/* Remove device of BIS source*/
+			btd_adapter_remove_device(device_get_adapter(dg->device), dg->device);
 		} else {
 			bass_update_bis_sync(dg, bcast_src);
 		}

---
base-commit: f8e7bcfdfb83a6a3becabdba1e4448bf04e32db5
change-id: 20250416-bass_modify-7accebe87323

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

