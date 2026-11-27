From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH net-next 0/3] net: pcs: rzn1-miic: Deassert resets on RZ/N1
Date: Fri, 27 Nov 2026 10:14:24 -0800
Message-Id: <20261127-miic-reset-consumer-v1-0-3cab78b94e23@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02OTQ6CMBCFr9LM2iadAqXlKsZFGQbtgqItGCLx7
 jbqguXL+/t2yJwCZ+jEDomfIYc5FoEnAXTz8coyDEWDVtogaiOnEEgmzrxImmNeJ04Sx6F2znF
 Ng4LSvCcew/ZdPUMsycjbApefk/ixlpvlb/c+c1maprB0QhD1FoeGK2x75VkTGUMeyWhLirxTr
 dN2dDUc+TrxpVO6lekV8YCYpa2UbbDxXpPqnjVc3u8PwvRDBfQAAAA=
X-Change-ID: 20261126-miic-reset-consumer-1fd4999e4cd0
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@linux.dev>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Magnus Damm <magnus.damm@gmail.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795803312; l=1416;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=JO2AL8nQm/4CThDoEoEqZG8cMRX9Fw2AqtMC/yqXsaE=;
 b=9QNZSFuzxGcaVgPGdtuz7Jqdawua3j0FN29mZ/5bemR5zmJgDPve5gruqIZ9bapync18DkU6X
 hr4kXa/5ITVD66KdgVQuPNa+6l3o2l5Y/BaEWeV/Ok8TCyEra5TPdRZ
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two resets are held at boot and need to be cleared for the mii converted
to work. They are in the system controller managed by the clock driver and
are supported by this series:
https://lore.kernel.org/linux-renesas-soc/20261126-rzn1-miic-resets-v4-0-4f73af81d779@reliablecontrols.com

Add the reset information to the rzn1 info structure and device tree so
the miic driver can clear the resets the same way the rz/t2h does.

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
Kyle Hendry (3):
      dt-bindings: net: pcs: renesas,rzn1-miic: Document rzn1 resets
      net: pcs: rzn1-miic: Add resets to rzn1 info structure
      ARM: dts: renesas: r9a06g032: Add resets to mii converter

 .../bindings/net/pcs/renesas,rzn1-miic.yaml        | 36 +++++++++++++++-------
 arch/arm/boot/dts/renesas/r9a06g032.dtsi           |  3 ++
 drivers/net/pcs/pcs-rzn1-miic.c                    |  7 +++++
 3 files changed, 35 insertions(+), 11 deletions(-)
---
base-commit: ccb81d5e317b0ae2cc66ca1c628c0ca907928f94
change-id: 20261126-miic-reset-consumer-1fd4999e4cd0
prerequisite-change-id: 20261027-rzn1-miic-resets-8308515aa2c0:v4
prerequisite-patch-id: be35edd6b8532456aa90c8b32fb7e1d7adbde798
prerequisite-patch-id: 077c1ad53beb244026822f9591c1808527f852db
prerequisite-patch-id: b56a4d7c0efa9bb17aa898bdc619733f30f9097c

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

