From: Sperrbert <sperrbert@proton.me>
Date: Wed, 02 Sep 2026 06:56:13 +0200
Subject: [PATCH] wifi: iwlwifi: mvm: fix VHT NSS reporting for legacy RX
 API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-master-v1-1-a2cc0a65ce12@proton.me>
X-B4-Tracking: v=1; b=H4sIAGysl2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSwMj3dzE4pLUIl2DxOQUgzRzk5Q0Y0sloOKCotS0zAqwQdGxEH5xaVJ
 WanIJSLdSbS0A+QIyhWoAAAA=
X-Change-ID: 20260902-master-0acd0f74df39
To: Miri Korenblit <miriam.rachel.korenblit@intel.com>, 
 Johannes Berg <johannes.berg@intel.com>
Cc: linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sperrbert <sperrbert@proton.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788324990; l=1903;
 i=sperrbert@proton.me; s=20260902; h=from:subject:message-id;
 bh=/4vIsjR1iXuI+GVen+yjkyDz9ZsAQbCF2/9KiJ5Y6q4=;
 b=ZGRpShq2jaDCmTRs/2rwAYCGEwyDQ+V0mYpd3peVBHM8zxMpbVdIrRzZoT7VpP7vJtiyIj5wR
 45Pnal/sF3HApAcor6gbCdTTd5dJsqsW4vuShHEBQp6/YWyrBxGWSxJ
X-Developer-Key: i=sperrbert@proton.me; a=ed25519;
 pk=I4XYiGGbh8WAF7fk5prqJ3RawLcpmMRrm1y+qO0YOf8=
X-Endpoint-Received: by B4 Relay for sperrbert@proton.me/20260902 with auth_id=996
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 774302d2d3ad ("wifi: iwlwifi: mvm: clean up duplicated defines")
replaced the explicit legacy VHT NSS decoding with
RATE_MCS_NSS_MSK, which was equivalent at the time.

Commit dabc88cb3b78 ("wifi: iwlwifi: handle v3 rates") later changed
RATE_MCS_NSS_MSK for the v3 rate format, where NSS is encoded at a
different bit position. The legacy RX path, however, still handles
VHT rate_n_flags using the v1 format.

As a result, two-stream VHT RX rates on older devices can be reported
as NSS 1. Use RATE_VHT_MCS_NSS_MSK when decoding VHT NSS in the
legacy RX path.

On an Intel Wireless-AC 7260, an unmodified kernel reports VHT NSS 1
while receiving about 460 Mbit/s. With this change the same connection
is correctly reported as VHT NSS 2, with unchanged throughput.

Fixes: dabc88cb3b78 ("wifi: iwlwifi: handle v3 rates")
Cc: stable@vger.kernel.org
Signed-off-by: Sperrbert <sperrbert@proton.me>
---
 drivers/net/wireless/intel/iwlwifi/mvm/rx.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/wireless/intel/iwlwifi/mvm/rx.c b/drivers/net/wireless/intel/iwlwifi/mvm/rx.c
index ab1eb2eb0c3cd..124a5f52c53d1 100644
--- a/drivers/net/wireless/intel/iwlwifi/mvm/rx.c
+++ b/drivers/net/wireless/intel/iwlwifi/mvm/rx.c
@@ -502,7 +502,7 @@ void iwl_mvm_rx_rx_mpdu(struct iwl_mvm *mvm, struct napi_struct *napi,
 		u8 stbc = (rate_n_flags & RATE_MCS_STBC_MSK) >>
 				RATE_MCS_STBC_POS;
 		rx_status->nss =
-			FIELD_GET(RATE_MCS_NSS_MSK, rate_n_flags) + 1;
+			FIELD_GET(RATE_VHT_MCS_NSS_MSK, rate_n_flags) + 1;
 		rx_status->rate_idx = rate_n_flags & RATE_VHT_MCS_RATE_CODE_MSK;
 		rx_status->encoding = RX_ENC_VHT;
 		rx_status->enc_flags |= stbc << RX_ENC_FLAG_STBC_SHIFT;

---
base-commit: 786262be6048deab760f68c8acc2c85607165894
change-id: 20260902-master-0acd0f74df39

Best regards,
--  
Sperrbert <sperrbert@proton.me>

