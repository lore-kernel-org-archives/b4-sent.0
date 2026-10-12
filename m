From: Bishwa Bhusan Saha <contact@bishwasaha.com>
Date: Tue, 13 Oct 2026 01:45:23 +0530
Subject: [PATCH 1/5] HID: add IDs for UNCTRL RAGE Mouse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-unctrl-m1-battery-v1-1-4a50203b7177@bishwasaha.com>
References: <20261013-b4-unctrl-m1-battery-v1-0-4a50203b7177@bishwasaha.com>
In-Reply-To: <20261013-b4-unctrl-m1-battery-v1-0-4a50203b7177@bishwasaha.com>
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bishwa Bhusan Saha <contact@bishwasaha.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791836132; l=749;
 i=contact@bishwasaha.com; s=20261012; h=from:subject:message-id;
 bh=fIXuct51biCVxZ2lNfnwp7ct6qZ/yUIRAhnNtUxASx0=;
 b=DR12+yzzMS+n+/FH7MxUmLaiIvcd8nM6TNe7wy7b8xFyaOMicVJCTEfM/NYUdR0rS6Jf/Ot0r
 dFVtf4egmN2A2ZEg1UBI12+stCwDrbbF6aiPj4zk58w4WDAV/ziGRDO
X-Developer-Key: i=contact@bishwasaha.com; a=ed25519;
 pk=bW8B6BzX1VU4IIcYagrb5nNRxBho+rTXaQZ8fLx8CoU=
X-Endpoint-Received: by B4 Relay for contact@bishwasaha.com/20261012 with auth_id=1168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the product IDs for both wired and wireless (dongle) mode of
UNCTRL RAGE mouse (also known as UNCTRL M1).

Signed-off-by: Bishwa Bhusan Saha <contact@bishwasaha.com>
---
 drivers/hid/hid-ids.h | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/hid/hid-ids.h b/drivers/hid/hid-ids.h
index a9537b7bb..fb4c25c71 100644
--- a/drivers/hid/hid-ids.h
+++ b/drivers/hid/hid-ids.h
@@ -1008,6 +1008,8 @@
 #define USB_DEVICE_ID_MADCATZ_RAT5	0x1705
 #define USB_DEVICE_ID_MADCATZ_RAT9	0x1709
 #define USB_DEVICE_ID_MADCATZ_MMO7  0x1713
+#define USB_DEVICE_ID_UNCTRL_M1_WIRED	0xA09F
+#define USB_DEVICE_ID_UNCTRL_M1_DONGLE	0xA0AF
 
 #define USB_VENDOR_ID_MCC		0x09db
 #define USB_DEVICE_ID_MCC_PMD1024LS	0x0076

-- 
2.56.0

