From: Ahmet Zeren <niko3x@proton.me>
Date: Fri, 27 Nov 2026 21:53:25 +0300
Subject: [PATCH wireless-next] wifi: mac80211: don't mark NO_ACK frames as
 failed in TX status radiotap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-mac80211-noack-v1-1-c7e6f7c56d3c@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMSQ7CMAwAv1L5jKU6LaTwFcQhcQ2YJUVxgUpV/
 06A42g0M4NJVjHYVTNkeanpkArQqgI+h3QS1L4wuNptiJzH2OI9cFc7IkxD4Cs2fdfw1nO79hF
 K98hy1On33MNbs9zEDJNMIxz+2p7xIjx+v7AsH+LMv8eEAAAA
X-Change-ID: 20261127-b4-mac80211-noack-3d83c97c457b
To: Johannes Berg <johannes@sipsolutions.net>
Cc: linux-wireless@vger.kernel.org, Luka Gejak <luka.gejak@linux.dev>, 
 Ahmet Zeren <niko3x@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795805607; l=2102;
 i=niko3x@proton.me; s=20261119; h=from:subject:message-id;
 bh=M1kdcetf79sRn55NV0lLAtC+P4wolqACj8MViFJSKg0=;
 b=A4kx9IBIzRJ8nRev7m+QjAeLwq5A825LhA+TsgTAw4Gn5FUpfecrf4Aws2w9cDfNvgv4NzUYw
 kpceCAtOKpzDAJJZ/jc1WgPF41jExgtVhFgaGD/IdqVwi+4xLT9spZo
X-Developer-Key: i=niko3x@proton.me; a=ed25519;
 pk=J4zNm2pudzQ/wF+pQ8xO+wW6jpcNa9EJ2C1g4DUAjhM=
X-Endpoint-Received: by B4 Relay for niko3x@proton.me/20261119 with auth_id=1575
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ieee80211_add_tx_radiotap_header() sets IEEE80211_RADIOTAP_F_TX_FAIL for
every unicast frame without IEEE80211_TX_STAT_ACK. That includes NO_ACK
frames that the driver reported with IEEE80211_TX_STAT_NOACK_TRANSMITTED,
i.e. frames that were sent successfully, so monitor interfaces show them
as failed.

Don't set TX_FAIL when IEEE80211_TX_STAT_NOACK_TRANSMITTED is set.

Tested with rtl8xxxu on an RTL8192CU (0bda:8178), on Linux 7.3.4 where
this code is the same: injected unicast NO_ACK frames were shown as
failed on the monitor interface and no longer are, and acked and unacked
frames are shown as before.

Reported-by: Luka Gejak <luka.gejak@linux.dev>
Closes: https://lore.kernel.org/linux-wireless/20261127115929.40205-1-luka.gejak@linux.dev/
Signed-off-by: Ahmet Zeren <niko3x@proton.me>
---
Luka noticed this while reviewing rtw88 injection patches, which now
report sent NO_ACK frames with IEEE80211_TX_STAT_NOACK_TRANSMITTED;
rtl8xxxu and rtw89 do the same.

AI tool use (Documentation/process/generated-content.rst): the patch was
written with help from Claude Code (Claude Opus 5.5). It was asked to
make the change Luka suggested and to test it on the RTL8192CU with a
patched mac80211 module. I have reviewed and tested the change and take
responsibility for it.
---
 net/mac80211/status.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/net/mac80211/status.c b/net/mac80211/status.c
index 5d1807ab46e..48db461d8da 100644
--- a/net/mac80211/status.c
+++ b/net/mac80211/status.c
@@ -315,7 +315,8 @@ ieee80211_add_tx_radiotap_header(struct ieee80211_local *local,
 
 	/* IEEE80211_RADIOTAP_TX_FLAGS */
 	txflags = 0;
-	if (!(info->flags & IEEE80211_TX_STAT_ACK) &&
+	if (!(info->flags & (IEEE80211_TX_STAT_ACK |
+			     IEEE80211_TX_STAT_NOACK_TRANSMITTED)) &&
 	    !is_multicast_ether_addr(hdr->addr1))
 		txflags |= IEEE80211_RADIOTAP_F_TX_FAIL;
 

---
base-commit: 18d0bedbb5f0538396cb7f763ed9cd1dd69c5b23
change-id: 20261127-b4-mac80211-noack-3d83c97c457b

Best regards,
--  
Ahmet Zeren <niko3x@proton.me>

