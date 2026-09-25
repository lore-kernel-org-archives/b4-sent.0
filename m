From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 23:43:38 +1000
Subject: [PATCH 03/13] wifi: brcmfmac: Fall back to RSSI-only default join
 preferences
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-brcm4388-submit-v1-3-b5cbc2cde2fb@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=1156;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=D6m7eaWnIp+UcQ2goCb0mybb908iS4h2gNzgalFLqPY=;
 b=DGEOlG/yM1NwWG2g1L6tHmSsi/MvzotCKiTqj88S5M3lfn0lx1NlJ8AoYMooqcoLzULwpaf3X
 BWOOZ5+l6SqCisJrlwJk8oeeNDQtDB2yBfMnj9dlMoQikmKyyRVsG33
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BCM4388 firmware rejects the default join preference containing a 5 GHz
RSSI boost with -EBADE, but accepts an RSSI-only preference.

Retry with RSSI-only selection only after -EBADE. Log other errors
without retrying.

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 drivers/net/wireless/broadcom/brcm80211/brcmfmac/common.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/common.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/common.c
index b6027d83e6..2a37b42ca9 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/common.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/common.c
@@ -95,6 +95,10 @@ void brcmf_c_set_joinpref_default(struct brcmf_if *ifp)
 	join_pref_params[1].band = 0;
 	err = brcmf_fil_iovar_data_set(ifp, "join_pref", join_pref_params,
 				       sizeof(join_pref_params));
+	if (err == -EBADE)
+		err = brcmf_fil_iovar_data_set(ifp, "join_pref",
+					       &join_pref_params[1],
+					       sizeof(join_pref_params[1]));
 	if (err)
 		bphy_err(drvr, "Set join_pref error (%d)\n", err);
 }

-- 
2.55.0

