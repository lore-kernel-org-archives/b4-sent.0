From: Yang Li <yang.li@amlogic.com>
Subject: [PATCH BlueZ bluez v2 0/2] bap for big sync lost
Date: Mon, 30 Jun 2025 16:02:38 +0800
Message-Id: <20250630-bap_for_big_sync_lost-v2-0-1491b608cda5@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJ5EYmgC/4WNWwqDMBREtyL3uykx1Yj9ch9FQp56QY0kVmole
 29wA/08M8yZE6INaCM8ixOC3TGiXzKwWwF6lMtgCZrMwCirKWcVUXIVzgehcBDxWLSYfNwIf1Q
 N17xpjVKQt2uwDj+X9wVqetsv9DkeMW4+HNfbXl7lH/FekpJQ41oqqatrQzs5T35Afdd+hj6l9
 AMfd+6XwwAAAA==
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751270571; l=707;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=X2unKFiKul4A0ubbaCDf/GNKDuc8drVAb6uE9Rr7Jsk=;
 b=0LAxtze6T/2DlZKt8pESJfdlSgjmbaocRFZTJnakISWf8jrMoFt1lyeE/wQfL/dzo0SOOOar5
 Zba1HjeBs8BAohAsGMiFX6sZo7is/ftD3+w5NVqHsHgAuzPOuE0D0hz
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Signed-off-by: Yang Li <yang.li@amlogic.com>

Changes in v2:
- Add state check in stream_disable.
- Add type check in stream_io_disconnected.
- Link to v1: https://patch.msgid.link/20250624-bap_for_big_sync_lost-v1-1-0df90a0f55d0@amlogic.com

---
Yang Li (2):
      shared/bap: Set stream to idle when I/O is disconnected
      shared/bap: Add stream state check in stream_disable

 src/shared/bap.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)
---
base-commit: ae1b7f6ba805f82742bbc32ff275e268248ef9f8
change-id: 20250624-bap_for_big_sync_lost-63476c679dbb

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

