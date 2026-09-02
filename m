From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH v3 0/2] net: pcs: rzn1-miic: Fix config array
 initialization
Date: Wed, 02 Sep 2026 11:37:34 -0700
Message-Id: <20260902-rzn1-miic-fix-array-v3-0-3f7dccffaf5a@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO5smGoC/33NzQ6CMAzA8VchO1uzjY+BJ9/DeBizSBNgpiNEJ
 Ly7g4sX9fhv018XEZAJgzgli2CcKJAfYqSHRLjWDncEusUWWupClioFfg0KeiIHDT3BMtsZsLC
 YZbl2UhkRLx+Mcbmrl2vslsLoed6fTGqb/vcmBQrqvHS2ca5SBs+MHdm6Q+eHkX0Xjs73YqMn/
 eEqqb5zGiSkWEkjswqNkT+4dV3fiBw4QhABAAA=
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>, 
 linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>, 
 Geert Uytterhoeven <geert+renesas@glider.be>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788374255; l=940;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=JSkAMrttf03IeqGaTYIwicBjs4X9ewx5Yd4SI1TwCLQ=;
 b=A1G7LnBE/kxgqKFIDqWrNK+MumUa5OJsh/l2rSTsCYjZq2J6sqAgrjvF3kI6n2Fsq0Cee5QaI
 JeF+naspXStA6I8xIrM8me3qgci92j4elQ6yzXcqXzsmhmh5Wc3jawJ
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
Fix issues when populating dt_val array from device tree values

Changes in v3:
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

 drivers/net/pcs/pcs-rzn1-miic.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)
---
base-commit: 544d85de4dc22c01badfd8cefa59829ce35c4858
change-id: 20260813-rzn1-miic-fix-array-e6ae4452c017

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

