From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 09:03:23 +0000
Subject: [PATCH wpan] mac802154: llsec: reject secured frames with security
 level 0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-llsec-seclevel-none-v1-1-06ef143e467f@gmail.com>
X-B4-Tracking: v=1; b=H4sIANrd8moC/x2MSwqEMBAFryK9tiEJOH6uIi5i5qkNoZUEVBDvP
 mEWtahF1UMZSZBpqB5KOCXLrkVsXVHYvK5g+RYnZ9zHWms4xozAhYgTkXVXcB+6pXFm9q1pqZR
 HwiL3/zrSdXil6X1/TSPEBmsAAAA=
To: alex.aring@gmail.com, stefan@datenfreihafen.org, 
 miquel.raynal@bootlin.com, joasantonio108@gmail.com
Cc: davem@davemloft.net, edumazet@kernel.org, kuba@kernel.org, 
 pabeni@redhat.com, horms@kernel.org, linux-wpan@vger.kernel.org, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794301402; l=2972;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=D5EaJBjC8M7RHA6vb/0t+xHzBpEctd0lgATfGQnGuqA=;
 b=AvenG5SdRGme9uWM1JQXBb23fS5x4xf0jrQTz85B6HBZqxGbSsPXPzg0f/YdjhL4nm/a7ahLI
 L0RJfiznDZlCixkBjbh0cLzFuYGNmpUKOiVuM9ZIZpIYKtlREw0yxhs
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mac802154_llsec_decrypt() handles every received frame that has the
Security Enabled bit set.  The security level is taken from the
auxiliary security header of the frame and is not required to be
non-zero.  The only check that looks at level 0 rejects the frame only
if level 0 is not allowed by the matching seclevel entry, the entry has
device_override set and the device is not seclevel_exempt:

	if (!(seclevel.sec_levels & BIT(hdr.sec.level)) &&
	    (hdr.sec.level == 0 && seclevel.device_override &&
	     !dev->dev.seclevel_exempt)) {

Otherwise the frame reaches llsec_do_decrypt(), which sends every level
other than IEEE802154_SCF_SECLEVEL_ENC to llsec_do_decrypt_auth().
There ieee802154_sechdr_authtag_len() returns 0 for level 0 and

	req = aead_request_alloc(llsec_tfm_by_len(key, authlen), GFP_ATOMIC);

looks for a transform with an authentication tag size of 0.  The key
only has transforms for tag sizes 4, 8 and 16, so llsec_tfm_by_len()
runs into its BUG().

The frame is not authenticated at that point.  A station in radio range
can crash a node that has llsec enabled if it sends a frame that matches
a configured key entry and a device table entry (source address, key id
mode and key id are sent in the clear and can be observed), uses a frame
type that has a seclevel entry and carries a frame counter that is not
lower than the stored one.  No key material is needed.  The frame
counter of that device is also updated before the BUG() is reached.

A frame with the Security Enabled bit set and security level 0 carries
no protection and cannot be processed by the incoming security
procedure.  Reject it before any key or device state is looked up.  The
transmit side already leaves such frames alone in
mac802154_llsec_encrypt().

Found by LLM-assisted source review.

Fixes: 4c14a2fb5d14 ("mac802154: add llsec decryption method")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
This issue was found with the help of an LLM-based code review tool
(Claude).  I checked the code paths by hand against v7.4-rc3 and
reviewed the fix myself.  It is build-tested only (W=1, arm64); I do
not have the hardware to test it at runtime.
---
 net/mac802154/llsec.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/net/mac802154/llsec.c b/net/mac802154/llsec.c
index 85452ef9a58c..32565f18897e 100644
--- a/net/mac802154/llsec.c
+++ b/net/mac802154/llsec.c
@@ -1019,6 +1019,8 @@ int mac802154_llsec_decrypt(struct mac802154_llsec *sec, struct sk_buff *skb)
 		return 0;
 	if (hdr.fc.version == 0)
 		return -EINVAL;
+	if (hdr.sec.level == IEEE802154_SCF_SECLEVEL_NONE)
+		return -EINVAL;
 
 	read_lock_bh(&sec->lock);
 	if (!sec->params.enabled) {

---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-llsec-seclevel-none-9c8f520ba707

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

