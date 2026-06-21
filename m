From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 20 Jun 2026 21:45:18 -0500
Subject: [PATCH] wifi: mac80211_hwsim: clamp virtio RX length before
 skb_put
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260620-b4-disp-474bee37-v1-1-1a4d37f3e2d4@proton.me>
X-B4-Tracking: v=1; b=H4sIAD1QN2oC/x2MMQqAMAwAvyKZDdRYWvQr4mDbqFlUWhCh+HeDt
 91wV6FwFi4wNhUy31LkPFS6toG4L8fGKEkdyJAzjgwGi0nKhdbbwNx7DBwHhVyKBJpdmVd5/uU
 0v+8H6+K7ZGIAAAA=
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782009917; l=1634;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=HtfyUWDREuoINdT8NTkjOwRIxvQAbmpdni8YZu5OyaE=;
 b=l9uiKusTE+/qmCSun1xP8GV+9egR3wX99KQL2QurOzdFlurwTTL7BHRsCR0HgIJNaymx3dy3b
 rPxe23SiYBeAxa/cz5yjc6DjofDDvUX/FvjSBv39cJlZf4JRLl+ak5Q
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hwsim_virtio_rx_work() passes the virtqueue used-ring length reported by
the device straight to skb_put() on a fixed-size receive skb. A backend
reporting a length larger than the skb tailroom drives skb_put() past the
buffer end and hits skb_over_panic() -- a host-triggerable guest panic
(denial of service).

Clamp the length to the skb's available room before skb_put(). A
conforming device never reports more than the posted buffer size, so valid
frames are unaffected; a truncated over-report then fails the
length/header checks in hwsim_virtio_handle_cmd() and is dropped, so
truncating rather than dropping here cannot be turned into a parsing
problem.

Fixes: 5d44fe7c9808 ("mac80211_hwsim: add frame transmission support over virtio")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/net/wireless/virtual/mac80211_hwsim_main.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/wireless/virtual/mac80211_hwsim_main.c b/drivers/net/wireless/virtual/mac80211_hwsim_main.c
index 0dd8a6c85953..5c1718277599 100644
--- a/drivers/net/wireless/virtual/mac80211_hwsim_main.c
+++ b/drivers/net/wireless/virtual/mac80211_hwsim_main.c
@@ -7289,6 +7289,7 @@ static void hwsim_virtio_rx_work(struct work_struct *work)
 
 	skb->data = skb->head;
 	skb_reset_tail_pointer(skb);
+	len = min(len, skb_end_offset(skb));
 	skb_put(skb, len);
 	hwsim_virtio_handle_cmd(skb);
 

---
base-commit: 1a3746ccbb0a97bed3c06ccde6b880013b1dddc1
change-id: 20260620-b4-disp-474bee37-bec999926dc2

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

