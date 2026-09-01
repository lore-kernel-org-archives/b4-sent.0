From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH v2 0/2] net: pcs: rzn1-miic: Fix config array
 initialization
Date: Tue, 01 Sep 2026 08:25:12 -0700
Message-Id: <20260901-rzn1-miic-fix-array-v2-0-3e907049e770@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFjulmoC/32NSw6CQBBEr2JmbRt65Kcr72FYDG0jncCM6SFEJ
 NzdkQO4fFWpV6uJrMLRXA+rUZ4lSvAJ7PFgqHf+ySCPxMZmtsxqPIN+PMIoQtDJG5yqW4BLx3l
 eWMqwMmn5Uk7lbr03iXuJU9BlP5nxl/73zQgIbVGT64guWPFNeRDXDkzBTxqGeKIwmmbbti/U8
 GtVwQAAAA==
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788276361; l=762;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=EPJ8RSWJB5URu3++h0cPK6xaFqxgLUn6Sbl44l6V/sQ=;
 b=GRVjUws+n7JiTBA1xv1VApzL+tvpJYMGPHb01yIf4+srgprXaovjBiDvePLVijKaXwhp5lkif
 1kV4edyqKvZANoRBQ3mE+xAk1egjvwsFIyMLuH9wgG0sYjL6RhgIHUf
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
Fix issues when populating dt_val array from device tree values

Changes in v2:
 * Use a more correct array size in memset
 * Ensure that write to dt_val is in range

Link to v1: https://lore.kernel.org/r/20260813-rzn1-miic-fix-array-v1-1-b58cafcc917e@reliablecontrols.com

---
Kyle Hendry (2):
      net: pcs: rzn1-miic: Fix config array initialization
      net: pcs: rzn1-miic: Verify port number from dtb

 drivers/net/pcs/pcs-rzn1-miic.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)
---
base-commit: 1376afc7660bad2a1a5ee0876898312a486cf8bd
change-id: 20260813-rzn1-miic-fix-array-e6ae4452c017

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

