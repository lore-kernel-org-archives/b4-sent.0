From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:35 +0000
Subject: [PATCH BlueZ 10/20] emulator: const annotate rfcomm_crc_table[]
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-10-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=627;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=NZds5ZvHb3CFb81d/ppE/ipwe1m7zAUlnTKfMKDPIOM=;
 b=JxjwP7lKY5Pg7j09p3ZEbOT71Tw8Ib18YwZ4TDIjxFhOCQxGaNUXmL7K23zo0UhNa49UhZRkH
 svAikt0TR3nDE16//G9EPLt4XDSoelPdMjcM+sipvmLjGkU/btfzd4a
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 emulator/bthost.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/emulator/bthost.c b/emulator/bthost.c
index c7d59eefc..8c40fce90 100644
--- a/emulator/bthost.c
+++ b/emulator/bthost.c
@@ -59,7 +59,7 @@
 /* RFCOMM FCS calculation */
 #define CRC(data) (rfcomm_crc_table[rfcomm_crc_table[0xff ^ data[0]] ^ data[1]])
 
-static unsigned char rfcomm_crc_table[256] = {
+static const unsigned char rfcomm_crc_table[256] = {
 	0x00, 0x91, 0xe3, 0x72, 0x07, 0x96, 0xe4, 0x75,
 	0x0e, 0x9f, 0xed, 0x7c, 0x09, 0x98, 0xea, 0x7b,
 	0x1c, 0x8d, 0xff, 0x6e, 0x1b, 0x8a, 0xf8, 0x69,

-- 
2.43.0

