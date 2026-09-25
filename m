From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 23:43:44 +1000
Subject: [PATCH 09/13] wifi: brcmfmac: Accept newer BSS information
 versions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-brcm4388-submit-v1-9-b5cbc2cde2fb@gmail.com>
References: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
In-Reply-To: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
To: Arend van Spriel <arend.vanspriel@broadcom.com>, 
 Pieter-Paul Giesberts <pieterpg@broadcom.com>, 
 "Franky Lin (Zhenhui)" <frankyl@broadcom.com>, 
 Mathy Vanhoef <vanhoefm@gmail.com>, Kalle Valo <kvalo@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-wireless@vger.kernel.org, brcm80211@lists.linux.dev, 
 brcm80211-dev-list.pdl@broadcom.com, asahi@lists.linux.dev, 
 Hector Martin <marcan@marcan.st>, Daniel Berlin <dberlin@dberlin.org>, 
 Janne Grunau <j@jannau.net>, linux-kernel@vger.kernel.org, 
 Hante Meuleman <meuleman@broadcom.com>, linux-hardening@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=2112;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=8kqW4IsiAZD50rAfacLlp9/XbfRe0/TGm5y0e1tN9dQ=;
 b=H8igOmyL5UUB1TH17yWYjV21xuzli872/7XgS5NYtw2Cor9W2YERquEW3/lrUHgwHjWclwz1O
 q6cgtn/WPstBz1zsjG6FHu4dZRFj6rgDjl9j8WqUMNHGyOjaMj+A74e
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

The driver accepts only BSS information version 109, rejecting scan
results with newer versions even though the common fields used for
reporting remain compatible.

Accept versions 109 through 112 when reporting scan results.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c   | 5 +++--
 drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h | 3 ++-
 2 files changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
index 5d99708007..4f1768c8bb 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
@@ -3484,8 +3484,9 @@ static s32 brcmf_inform_bss(struct brcmf_cfg80211_info *cfg)
 
 	bss_list = (struct brcmf_scan_results *)cfg->escan_info.escan_buf;
 	if (bss_list->count != 0 &&
-	    bss_list->version != BRCMF_BSS_INFO_VERSION) {
-		bphy_err(drvr, "Version %d != WL_BSS_INFO_VERSION\n",
+	    (bss_list->version < BRCMF_BSS_INFO_MIN_VERSION ||
+	     bss_list->version > BRCMF_BSS_INFO_MAX_VERSION)) {
+		bphy_err(drvr, "BSS info version %d unsupported\n",
 			 bss_list->version);
 		return -EOPNOTSUPP;
 	}
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
index d591f17960..c786da4336 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
@@ -18,7 +18,8 @@
 #define BRCMF_ARP_OL_HOST_AUTO_REPLY	0x00000004
 #define BRCMF_ARP_OL_PEER_AUTO_REPLY	0x00000008
 
-#define	BRCMF_BSS_INFO_VERSION	109 /* curr ver of brcmf_bss_info_le struct */
+#define BRCMF_BSS_INFO_MIN_VERSION	109
+#define BRCMF_BSS_INFO_MAX_VERSION	112
 #define BRCMF_BSS_RSSI_ON_CHANNEL	0x0004
 
 #define BRCMF_STA_BRCM			0x00000001	/* Running a Broadcom driver */

-- 
2.55.0

