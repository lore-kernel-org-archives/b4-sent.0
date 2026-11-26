From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 14:00:31 +0000
Subject: [PATCH 5.10.y] staging: rtl8723bs: rtw_mlme: add bounds checks
 before ie_length subtraction
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-so3-rtl-510-v1-1-4c22f41706db@certik.com>
X-B4-Tracking: v=1; b=H4sIAH47CGsC/02NwQ7CIBBEf6XZs1uBWqr+ivEAdLWYBgyLRtP03
 wW9eJyXmTcLMCVPDMdmgURPzz6GEuSmATeZcCX0Y8mghNJSKo0cO0x5xl4KNDQcdmavXTcIKIt
 7oot/fW0n6Fsp2jecf5wf9kYuV1VtWsOENpngpoqYwphjnLHy7d8FrOsHbw5u7aMAAAA=
X-Change-ID: 20261126-so3-rtl-510-ae794a86c370
To: stable@vger.kernel.org
Cc: Salman Alghamdi <me@cipherat.com>, Luka Gejak <luka.gejak@linux.dev>, 
 linux-staging@lists.linux.dev
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795701630; l=3127;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=V3GPftrUasuRGRSXywo9YOVzZnazbn9fCfCl0Gt8TVA=;
 b=hi6hubty2MowvZbbN+TZYZoR2veLkggcyuMBGp8Onqe/TpjgY7rPBHOcaeCVivjQeVCEVqE3m
 4u5jNH7IgNJCJy4FhqPyVkZd4y1atv8gxpXPip8y/27wq8f6/TV5+Ti
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Salman Alghamdi <me@cipherat.com>

commit 88e994c57a79f62d5338231d8d37ee8dd98baffe upstream.

Add guards to ensure ie_length is large enough before subtracting
fixed IE offsets to prevent unsigned integer underflow.

Fixes: 2038fe84b8bd ("staging: rtl8723bs: fix spacing around operators")
Fixes: d3fcee1b78a5 ("staging: rtl8723bs: fix camel case in struct wlan_bssid_ex")
Closes: https://lore.kernel.org/linux-staging/DI2H39EAAFBZ.3KI5NWN02AQ2S@linux.dev/
Cc: stable <stable@kernel.org>
Signed-off-by: Salman Alghamdi <me@cipherat.com>
Reviewed-by: Luka Gejak <luka.gejak@linux.dev>
Link: https://patch.msgid.link/20260513203455.31792-1-me@cipherat.com
Signed-off-by: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
[ adapted to 5.10.y: use IELength, IEs, and _RSN_IE_2_ ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.6.y and newer already have this fix. This branch still uses
the older IELength/IEs field names and _RSN_IE_2_; the added checks
are otherwise the same as upstream.

Tested on v5.10.275:
- x86_64 allmodconfig W=1 build of
  drivers/staging/rtl8723bs/core/rtw_mlme.o, base vs patched, no new
  warnings
- booted the patched kernel with the driver built as a module under
  QEMU/KVM. I don't have rtl8723bs hardware, so the scan path wasn't
  run.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/staging/rtl8723bs/core/rtw_mlme.c | 14 ++++++++++----
 1 file changed, 10 insertions(+), 4 deletions(-)

diff --git a/drivers/staging/rtl8723bs/core/rtw_mlme.c b/drivers/staging/rtl8723bs/core/rtw_mlme.c
index c7fab90550f0..a172121b8171 100644
--- a/drivers/staging/rtl8723bs/core/rtw_mlme.c
+++ b/drivers/staging/rtl8723bs/core/rtw_mlme.c
@@ -723,6 +723,8 @@ int rtw_is_desired_network(struct adapter *adapter, struct wlan_network *pnetwor
 	privacy = pnetwork->network.Privacy;
 
 	if (check_fwstate(pmlmepriv, WIFI_UNDER_WPS)) {
+		if (pnetwork->network.IELength < _FIXED_IE_LENGTH_)
+			return false;
 		if (rtw_get_wps_ie(pnetwork->network.IEs+_FIXED_IE_LENGTH_, pnetwork->network.IELength-_FIXED_IE_LENGTH_, NULL, &wps_ielen))
 			return true;
 		else
@@ -737,11 +739,15 @@ int rtw_is_desired_network(struct adapter *adapter, struct wlan_network *pnetwor
 	    bselected = false;
 
 		if (psecuritypriv->ndisauthtype == Ndis802_11AuthModeWPA2PSK) {
-			p = rtw_get_ie(pnetwork->network.IEs + _BEACON_IE_OFFSET_, _RSN_IE_2_, &ie_len, (pnetwork->network.IELength - _BEACON_IE_OFFSET_));
-			if (p && ie_len > 0)
-				bselected = true;
-			else
+			if (pnetwork->network.IELength < _BEACON_IE_OFFSET_) {
 				bselected = false;
+			} else {
+				p = rtw_get_ie(pnetwork->network.IEs + _BEACON_IE_OFFSET_, _RSN_IE_2_, &ie_len, (pnetwork->network.IELength - _BEACON_IE_OFFSET_));
+				if (p && ie_len > 0)
+					bselected = true;
+				else
+					bselected = false;
+			}
 		}
 	}
 

---
base-commit: 99112ea818e35b606397c84fbc05e6fadb6ea162
change-id: 20261126-so3-rtl-510-ae794a86c370

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

