From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 23:43:47 +1000
Subject: [PATCH 12/13] wifi: brcmfmac: Handle extended PMK command payloads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-brcm4388-submit-v1-12-b5cbc2cde2fb@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=3793;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=21CTJ1cSuNsOBHHOhHZPHR3ABfniMlmWG0c7gN9QAGE=;
 b=e+uuYW//sDzL0yIRy08EQa9gPMjdoNz7dUKwMR4kGX7ylSI9mFDzOeqN/J8V7vLaxDU43LSVo
 zkrYgYZ09qtBBqS5B7r4QegIL4Niv8x3FySnZ2f3GlR1LO6B2H7Jq34
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some firmware rejects the legacy BRCMF_C_SET_WSEC_PMK payload despite
advertising firmware supplicant support.

Add the extended PMK layout. Try the legacy payload first when the key
fits, and retry with the extended layout only after -EBADE. Use the
extended layout directly for larger keys and reject keys that exceed its
capacity.

Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../broadcom/brcm80211/brcmfmac/cfg80211.c         | 39 ++++++++++++++++------
 .../broadcom/brcm80211/brcmfmac/fwil_types.h       | 18 ++++++++++
 2 files changed, 46 insertions(+), 11 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
index 2a742ae8cc..c9cc6e0ccd 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/cfg80211.c
@@ -1584,28 +1584,45 @@ int brcmf_set_wsec(struct brcmf_if *ifp, const u8 *key, u16 key_len, u16 flags)
 {
 	struct brcmf_pub *drvr = ifp->drvr;
 	struct brcmf_wsec_pmk_le pmk;
+	struct brcmf_wsec_pmk_ext_le pmk_ext;
 	int err;
 
-	if (key_len > sizeof(pmk.key)) {
+	if (key_len > sizeof(pmk_ext.key)) {
 		bphy_err(drvr, "key must be less than %zu bytes\n",
-			 sizeof(pmk.key));
+			 sizeof(pmk_ext.key));
 		return -EINVAL;
 	}
 
-	memset(&pmk, 0, sizeof(pmk));
+	if (key_len <= sizeof(pmk.key)) {
+		memset(&pmk, 0, sizeof(pmk));
 
-	/* pass key material directly */
-	pmk.key_len = cpu_to_le16(key_len);
-	pmk.flags = cpu_to_le16(flags);
-	memcpy(pmk.key, key, key_len);
+		pmk.key_len = cpu_to_le16(key_len);
+		pmk.flags = cpu_to_le16(flags);
+		memcpy(pmk.key, key, key_len);
+
+		err = brcmf_fil_cmd_data_set(ifp, BRCMF_C_SET_WSEC_PMK,
+					     &pmk, sizeof(pmk));
+		if (!err)
+			return 0;
+		if (err != -EBADE)
+			goto fail;
+	}
+
+	memset(&pmk_ext, 0, sizeof(pmk_ext));
+	pmk_ext.key_len = cpu_to_le16(key_len);
+	pmk_ext.flags = cpu_to_le16(flags);
+	memcpy(pmk_ext.key, key, key_len);
 
-	/* store key material in firmware */
 	err = brcmf_fil_cmd_data_set(ifp, BRCMF_C_SET_WSEC_PMK,
-				     &pmk, sizeof(pmk));
+				     &pmk_ext, sizeof(pmk_ext));
 	if (err < 0)
-		bphy_err(drvr, "failed to change PSK in firmware (len=%u)\n",
-			 key_len);
+		goto fail;
+
+	return 0;
 
+fail:
+	bphy_err(drvr, "failed to change PSK in firmware (len=%u, err=%d)\n",
+		 key_len, err);
 	return err;
 }
 BRCMF_EXPORT_SYMBOL_GPL(brcmf_set_wsec);
diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
index 917966ad70..37d9414546 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/fwil_types.h
@@ -75,6 +75,7 @@
 #define BRCMF_WSEC_MAX_PSK_LEN		32
 #define	BRCMF_WSEC_PASSPHRASE		BIT(0)
 
+#define BRCMF_WSEC_MAX_PMK_LEN		256
 #define BRCMF_WSEC_MAX_SAE_PASSWORD_LEN 128
 
 /* primary (ie tx) key */
@@ -667,6 +668,23 @@ struct brcmf_wsec_pmk_le {
 	u8 key[BRCMF_WSEC_MAX_SAE_PASSWORD_LEN];
 };
 
+/**
+ * struct brcmf_wsec_pmk_ext_le - extended firmware pmk material.
+ *
+ * @key_len: number of octets in key material.
+ * @flags: key handling qualifiers.
+ * @key: PMK key material.
+ * @opt_len: optional field length.
+ * @opt_tlvs: optional fields in TLV format.
+ */
+struct brcmf_wsec_pmk_ext_le {
+	__le16  key_len;
+	__le16  flags;
+	u8 key[BRCMF_WSEC_MAX_PMK_LEN];
+	__le16  opt_len;
+	u8 opt_tlvs[];
+};
+
 /**
  * struct brcmf_wsec_sae_pwd_le - firmware SAE password material.
  *

-- 
2.55.0

