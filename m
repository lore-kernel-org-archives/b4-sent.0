From: Janne Grunau <j@jannau.net>
Date: Sat, 03 Aug 2024 21:52:55 +0200
Subject: [PATCH] wifi: brcmfmac: cfg80211: Handle SSID based pmksa deletion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240803-brcmfmac_pmksa_del_ssid-v1-1-4e85f19135e1@jannau.net>
X-B4-Tracking: v=1; b=H4sIAJaKrmYC/x3MQQqAIBBA0avErBOsKYiuEiGmYw1lhQMRRHdPW
 r7F/w8IJSaBvngg0cXCx55RlQW4xe4zKfbZUOu60Z1GNSUXQ7TOnHEVazxtRoS9QoctBcIWUUO
 uz0SB7/88jO/7AZiy8PppAAAA
To: Arend van Spriel <arend.vanspriel@broadcom.com>, 
 Kalle Valo <kvalo@kernel.org>, Hector Martin <marcan@marcan.st>, 
 Linus Walleij <linus.walleij@linaro.org>
Cc: linux-wireless@vger.kernel.org, brcm80211@lists.linux.dev, 
 brcm80211-dev-list.pdl@broadcom.com, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, stable@vger.kernel.org, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1950; i=j@jannau.net;
 h=from:subject:message-id; bh=kwa63Uu8k2lWu1jh8mzzIZRococdlt5kl/m4MUAUTEw=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhrR1XfMEpu1b+fuSsfFsHu0AC7n/HqLvPkyYsUf8qoPE2
 WVB35WOd5SyMIhxMciKKbIkab/sYFhdoxhT+yAMZg4rE8gQBi5OAZjI3HmMDPcyXdbdTkgSbX8v
 +P1v2493CbJP93htlxD64/Ku96rAllBGhnYeTsmJeakhXxj4GP6WHDzR8etU5P9NPK1xZpKlydc
 6mQE=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wpa_supplicant 2.11 sends since 1efdba5fdc2c ("Handle PMKSA flush in the
driver for SAE/OWE offload cases") SSID based PMKSA del commands.
brcmfmac is not prepared and tries to dereference the NULL bssid and
pmkid pointers in cfg80211_pmksa. PMKID_V3 operations support SSID based
updates so copy the SSID.

Fixes: a96202acaea4 ("wifi: brcmfmac: cfg80211: Add support for PMKID_V3 operations")
Cc: stable@vger.kernel.org
Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
index 5fe0e671ecb3..826b768196e2 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
@@ -4320,9 +4320,16 @@ brcmf_pmksa_v3_op(struct brcmf_if *ifp, struct cfg80211_pmksa *pmksa,
 		/* Single PMK operation */
 		pmk_op->count = cpu_to_le16(1);
 		length += sizeof(struct brcmf_pmksa_v3);
-		memcpy(pmk_op->pmk[0].bssid, pmksa->bssid, ETH_ALEN);
-		memcpy(pmk_op->pmk[0].pmkid, pmksa->pmkid, WLAN_PMKID_LEN);
-		pmk_op->pmk[0].pmkid_len = WLAN_PMKID_LEN;
+		if (pmksa->bssid)
+			memcpy(pmk_op->pmk[0].bssid, pmksa->bssid, ETH_ALEN);
+		if (pmksa->pmkid) {
+			memcpy(pmk_op->pmk[0].pmkid, pmksa->pmkid, WLAN_PMKID_LEN);
+			pmk_op->pmk[0].pmkid_len = WLAN_PMKID_LEN;
+		}
+		if (pmksa->ssid && pmksa->ssid_len) {
+			memcpy(pmk_op->pmk[0].ssid.SSID, pmksa->ssid, pmksa->ssid_len);
+			pmk_op->pmk[0].ssid.SSID_len = pmksa->ssid_len;
+		}
 		pmk_op->pmk[0].time_left = cpu_to_le32(alive ? BRCMF_PMKSA_NO_EXPIRY : 0);
 	}
 

---
base-commit: 0c3836482481200ead7b416ca80c68a29cfdaabd
change-id: 20240803-brcmfmac_pmksa_del_ssid-3c35efe35330

Best regards,
-- 
Janne Grunau <j@jannau.net>

