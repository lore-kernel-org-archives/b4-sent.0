From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH v4 0/2] net: pcs: rzn1-miic: Fix config array
 initialization
Date: Mon, 14 Sep 2026 09:40:59 -0700
Message-Id: <20260914-rzn1-miic-fix-array-v4-0-069112feec86@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJsjqGoC/33NOw7CMAyA4augzBglaUsoE/dADMF1wFJpkFNVP
 NS7k3aBARh/W/78VImEKant4qmEBk4cuxzlcqHw7LsTATe5ldV2rTemAHl0Bi7MCIFv4EX8HWj
 tqSwri9o4lS+vQnk5q/tD7jOnPsp9fjKYafrfGwwYOFYb9AGxNo52Qi37Y0sYu15im1YYL2qiB
 /vmam2+cxY0FFRrp8uanNN/uOKTs9+5YuKCaxBD8KHyP7hxHF8HYSO9XwEAAA==
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>, 
 linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789404061; l=1130;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=wGE2smqVz2Oj4oJkTsgmVmHvoGq7SVA/xQuf5aNBnOI=;
 b=qJaoEOxzsjms0JGj6ZgEwK3qM6Icu3nQnyDcWPwQXrlA9n1GXfAqCd+7YX8BbriCKUNw1717J
 ud8Ah2jEB1HDBlylMu9MtFqmgaXGVKxSnmlNOIZ8cpFO2TU1HGks1j3
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
Fix issues when populating dt_val array from device tree values

Changes in v4:
 * Fix lines longer than 80 char
 * Add of_node_put() before returning

Changes in v3: https://lore.kernel.org/r/20260902-rzn1-miic-fix-array-v3-0-3f7dccffaf5a@reliablecontrols.com
 * Make invalid port number return error
 * Update commit tags

Changes in v2: https://lore.kernel.org/r/20260901-rzn1-miic-fix-array-v2-0-3e907049e770@reliablecontrols.com
 * Use a more correct array size in memset
 * Ensure that write to dt_val is in range

Link to v1: https://lore.kernel.org/r/20260813-rzn1-miic-fix-array-v1-1-b58cafcc917e@reliablecontrols.com

---
Kyle Hendry (2):
      net: pcs: rzn1-miic: Fix config array initialization
      net: pcs: rzn1-miic: Verify port number from dtb

 drivers/net/pcs/pcs-rzn1-miic.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)
---
base-commit: e6b6078ea1731b05b3b552497b3bce4bf8b014ae
change-id: 20260813-rzn1-miic-fix-array-e6ae4452c017

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

