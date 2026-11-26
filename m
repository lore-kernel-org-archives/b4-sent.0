From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 14:04:40 +0000
Subject: [PATCH 6.1.y] staging: rtl8723bs: rtw_mlme: add bounds checks
 before ie_length subtraction
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-so3-rtl-61-v1-1-96e1a9756c6d@certik.com>
X-B4-Tracking: v=1; b=H4sIAHc8CGsC/0WNwQrCMBBEf6Xs2a3dCCn4K+IhSTc2UhLJpqKU/
 ruJHjzOY+bNBsI5sMC52yDzM0hIsQY6dOBmE2+MYaoZ1KA0kdIo6YS5LKgJzUgDezUqTx7q4JH
 Zh9dXdgHdU/+G6w/Lau/sShO1ojXCaLOJbm5IOE4lpQUbP/4PYN8/IDVoAKAAAAA=
X-Change-ID: 20261126-so3-rtl-61-a710ef272f1f
To: stable@vger.kernel.org
Cc: Salman Alghamdi <me@cipherat.com>, Luka Gejak <luka.gejak@linux.dev>, 
 linux-staging@lists.linux.dev
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795701879; l=3160;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=Ys/Tq/5BzFedQ5FeXcg5z6hbVsf4FzrQ3pyU6hVxDVo=;
 b=Aod7ceNg2c2M1EeuPXDQYQ14tfANlBzgEBeYhzCujpJepWpDLYaqagFWS+09GdG9mlk7ovGuU
 Yd8FNfKNqv1AnDa+lBpn3yLHNqz6cmBLb9Rt5bi27WG2qvUGmOVdrS0
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
[ adapted to 6.1.y: preserve branch WPS helper-call spacing ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.6.y and newer already have this fix. The added lines are the
same as upstream. The WPS lookup next to them keeps this branch's
older spacing, which is why it doesn't cherry-pick cleanly.

Tested on v6.1.193:
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
index ac3a08e6727f..8a83d1fedeac 100644
--- a/drivers/staging/rtl8723bs/core/rtw_mlme.c
+++ b/drivers/staging/rtl8723bs/core/rtw_mlme.c
@@ -658,6 +658,8 @@ int rtw_is_desired_network(struct adapter *adapter, struct wlan_network *pnetwor
 	privacy = pnetwork->network.privacy;
 
 	if (check_fwstate(pmlmepriv, WIFI_UNDER_WPS)) {
+		if (pnetwork->network.ie_length < _FIXED_IE_LENGTH_)
+			return false;
 		if (rtw_get_wps_ie(pnetwork->network.ies+_FIXED_IE_LENGTH_, pnetwork->network.ie_length-_FIXED_IE_LENGTH_, NULL, &wps_ielen))
 			return true;
 		else
@@ -672,11 +674,15 @@ int rtw_is_desired_network(struct adapter *adapter, struct wlan_network *pnetwor
 			bselected = false;
 
 		if (psecuritypriv->ndisauthtype == Ndis802_11AuthModeWPA2PSK) {
-			p = rtw_get_ie(pnetwork->network.ies + _BEACON_IE_OFFSET_, WLAN_EID_RSN, &ie_len, (pnetwork->network.ie_length - _BEACON_IE_OFFSET_));
-			if (p && ie_len > 0)
-				bselected = true;
-			else
+			if (pnetwork->network.ie_length < _BEACON_IE_OFFSET_) {
 				bselected = false;
+			} else {
+				p = rtw_get_ie(pnetwork->network.ies + _BEACON_IE_OFFSET_, WLAN_EID_RSN, &ie_len, (pnetwork->network.ie_length - _BEACON_IE_OFFSET_));
+				if (p && ie_len > 0)
+					bselected = true;
+				else
+					bselected = false;
+			}
 		}
 	}
 

---
base-commit: 1ca1436ccc68275d0b43b6a730b3940fcc46b7c2
change-id: 20261126-so3-rtl-61-a710ef272f1f

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

