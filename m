From: Rajan Yadav <rajanyadav0307@gmail.com>
Subject: [PATCH 0/2] usb: musb: sunxi: Fix unbinding and rebinding
Date: Tue, 10 Nov 2026 01:08:51 -0600
Message-Id: <20261110-musb-sunxi-unbind-v1-0-d821584fc4a4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAPD8moC/yXMwQqDMAyA4VeRnBdoi1TYq8gOps1mBmajWUUQ3
 91uO36H/9/BuAgbXLsdCq9i8tIGf+kgzZM+GCU3Q3Aheu8dLtUIreomWJVEM4aJ+uxypDREaN2
 78F2233O8/W2Vnpw+3xEcxwmkW2RHdQAAAA==
X-Change-ID: 20261110-musb-sunxi-unbind-2ab4d0d6bc76
To: Bin Liu <b-liu@ti.com>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: regressions@lists.linux.dev, Zijun Hu <zijun.hu@oss.qualcomm.com>, 
 linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Rajan Yadav <rajanyadav0307@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794294532; l=1975;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=ldGUp6lz3WZtjMz69tdwqzZtvWjZqidFlVH8uvgeKIc=;
 b=MCB2MXQIdsbIGlvQgYsC0+8HOab+meeL5xETwA9UXFgrRetKIiqDkp3ZBmxw5ibeaoItFqvdY
 SxhZe4UzrdbBNjvD868U2pKK9n2EYB1vzSaSz86Lk+g/UQm2F+QdMzd
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unbinding musb-sunxi crashes on current mainline: KASAN reports a
use-after-free in devm_usb_phy_release(), followed by a NULL pointer
dereference. This came back in v6.12 with commit 498dbd9aea20 ("usb:
musb: sunxi: Fix accessing an released usb phy"), which removed the 2017
fix for the same oops. Patch 1 lets devres unregister the generic PHY
after the PHY reference has been dropped.

While testing it, binding the musb-hdrc child again, the case that
498dbd9aea20 was about, turned out to fail with -EEXIST: since 2017 the
extcon notifier is registered with devm on the glue device, so it is
never unregistered when the child goes away. Patch 2 pairs the
registration with sunxi_musb_init() and sunxi_musb_exit() again.

The two patches are independent. Both were tested on a KickPi K5C
(Allwinner A133) with v7.4-rc1 and KASAN, without out-of-tree modules,
using the board's device tree, which is not in mainline yet. The
details, and what was not tested, are in each patch.

From reading the code only, drivers/usb/musb/mediatek.c seems to have
the same problem as patch 1: mtk_musb_remove() unregisters the generic
PHY while devm_usb_get_phy() still holds a reference to it. I have no
hardware to test it.

As in the patches, I used Claude Code (Anthropic) to find the causes,
write the fixes and the commit messages, and help with the tests; I
reviewed everything and ran the tests on the board.

Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
Rajan Yadav (2):
      usb: musb: sunxi: Unregister the generic PHY after dropping its reference
      usb: musb: sunxi: Unregister the extcon notifier in sunxi_musb_exit()

 drivers/usb/musb/sunxi.c | 43 +++++++++++++++++++++++++++++++------------
 1 file changed, 31 insertions(+), 12 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261110-musb-sunxi-unbind-2ab4d0d6bc76

Best regards,
--  
Rajan Yadav <rajanyadav0307@gmail.com>

