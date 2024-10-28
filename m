From: Aleksei Vetrov <vvvvvv@google.com>
Date: Mon, 28 Oct 2024 22:18:40 +0000
Subject: [PATCH] wifi: nl80211: fix bounds checker error in
 nl80211_parse_sched_scan
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241028-nl80211_parse_sched_scan-bounds-checker-fix-v1-1-bb640be0ebb7@google.com>
X-B4-Tracking: v=1; b=H4sIAL8NIGcC/x2N0QqDMAxFf0XyvEAbu1H2K2NIbeMsG1USHAPx3
 w17uXDOw7k7KEtlhXu3g/C3al2agb90kOfUXoy1GAM5Ct5RxPaJjrwf1iTKg+aZi21qOC5bK4o
 m8psFp/rDfI2BpuDHeOvBiquw6f/b43kcJzdtLVt9AAAA
X-Change-ID: 20241028-nl80211_parse_sched_scan-bounds-checker-fix-c5842f41b863
To: Johannes Berg <johannes@sipsolutions.net>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Aleksei Vetrov <vvvvvv@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730153971; l=1312;
 i=vvvvvv@google.com; s=20241028; h=from:subject:message-id;
 bh=iIxi2KLWI9wR0O0GYIDrc+V7xEplQHQGoi5qT4A15RA=;
 b=nTOEDZOton4avNlJ6GBQTWY3r29X14NRdFDJOLfoDH49KG2clQxQJmvJdqbubmFEyKHEVRiN4
 PyZlcBL9LotC8KqGQeQ4HeKzs+3geaLrffksSsD42ikKStOsGeu0SUB
X-Developer-Key: i=vvvvvv@google.com; a=ed25519;
 pk=b4c4Uc4EKDS3ie6P4xhkyobon88ZGFLMHyo8kw1IuM4=
X-Endpoint-Received: by B4 Relay for vvvvvv@google.com/20241028 with auth_id=257
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The channels array in the cfg80211_scan_request has a __counted_by
attribute attached to it, which points to the n_channels variable. This
attribute is used in bounds checking, and if it is not set before the
array is filled, then the bounds sanitizer will issue a warning or a
kernel panic if CONFIG_UBSAN_TRAP is set.

This patch sets the size of allocated memory as the initial value for
n_channels. It is updated with the actual number of added elements after
the array is filled.

Signed-off-by: Aleksei Vetrov <vvvvvv@google.com>
---
 net/wireless/nl80211.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/net/wireless/nl80211.c b/net/wireless/nl80211.c
index d7d099f7118ab5d5c745905abdea85d246c2b7b2..9b1b9dc5a7eb2a864da7b0212bc6a156b7757a9d 100644
--- a/net/wireless/nl80211.c
+++ b/net/wireless/nl80211.c
@@ -9776,6 +9776,7 @@ nl80211_parse_sched_scan(struct wiphy *wiphy, struct wireless_dev *wdev,
 	request = kzalloc(size, GFP_KERNEL);
 	if (!request)
 		return ERR_PTR(-ENOMEM);
+	request->n_channels = n_channels;
 
 	if (n_ssids)
 		request->ssids = (void *)request +

---
base-commit: 81983758430957d9a5cb3333fe324fd70cf63e7e
change-id: 20241028-nl80211_parse_sched_scan-bounds-checker-fix-c5842f41b863

Best regards,
-- 
Aleksei Vetrov <vvvvvv@google.com>

