From: Ye He <ye.he@amlogic.com>
Date: Tue, 19 Aug 2025 16:03:22 +0800
Subject: [PATCH bluez] bap: Fix setup double free with bis sink
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250819-bap-setup-double-free-v1-1-a7c64be0d807@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAMkvpGgC/x3MywqDMBBG4VeRWXcgiVgvr1K6cJpfHRANSVOK4
 rs3dPktzjkpISoSDdVJER9Num8F9lbRaxm3Gay+mJxxjelszzIGTnjnwH7PsoKnCHDd2XsvzrR
 eGiptiJj0+/8+SNaMg57X9QPAQIdqbgAAAA==
X-Change-ID: 20250819-bap-setup-double-free-38169b207db5
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755590604; l=1413;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=Z/qONVZw2n+fP9ohFfxGXed1U3JcKAzWJdnNk5Mfa/s=;
 b=qVFsKXMCmUVnLnkyIsZgNUeGnpKPsZlFnL+ntGnb2NJfserSvdeFq0rwMbCGrFOPYpd8cPAHx
 8sshX35mtt8A3jTUdVxFqdp9b7ZEOibk5WgIglpZxZgBdCyluuy+jAa
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If try to remove the bis sink device that big sync lost with
remote bis source, the following crash is observed:

0x00000a78 in ?? ()
0x004c8970 in setup_free ()
0x00551a78 in queue_remove_all ()
0x00551abc in queue_destroy ()
0x004cb590 in bap_data_remove ()
0x004cb9f0 in bap_bcast_remove ()
0x0051457c in service_remove ()
0x005272e4 in device_remove ()
0x0050e134 in adapter_remove_connection ()
0x0050e24c in dev_disconnected ()
0x00553478 in request_complete ()
0x00554670 in can_read_data ()
0x005850c4 in watch_callback ()
0xf7d5ab9c in g_main_context_dispatch () from /usr/lib/libglib-2.0.so.0
0xf7d5af28 in ?? () from /usr/lib/libglib-2.0.so.0

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 profiles/audio/bap.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/profiles/audio/bap.c b/profiles/audio/bap.c
index 2994881ccc1d7daa1d97210edc6ff67381e74cc1..c8c83cf94c57878f3bd8b805e926bd58ff648d9a 100644
--- a/profiles/audio/bap.c
+++ b/profiles/audio/bap.c
@@ -1010,6 +1010,8 @@ static void setup_free(void *data)
 
 	if (setup->ep)
 		queue_remove(setup->ep->setups, setup);
+	else if (setup->data->bcast_snks)
+		queue_remove(setup->data->bcast_snks, setup);
 
 	setup_io_close(setup, NULL);
 

---
base-commit: 0bb66d3d1abd7d25b840d535c03b1b9613727d5c
change-id: 20250819-bap-setup-double-free-38169b207db5

Best regards,
-- 
Ye He <ye.he@amlogic.com>

