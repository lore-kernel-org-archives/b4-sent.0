From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Tue, 13 Feb 2024 10:29:05 +0300
Subject: [PATCH net-next v2] net: dsa: remove OF-based MDIO bus
 registration from DSA core
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240213-for-netnext-dsa-mdio-bus-v2-1-0ff6f4823a9e@arinc9.com>
X-B4-Tracking: v=1; b=H4sIAEAay2UC/yWNzQ6CMBCEX4Xs2SWl5ad48j0MhwqLbCKtaYFgC
 O9urbf5MvlmDgjkmQJcswM8bRzY2QjykkE/Gfsk5CEySCFLUSiBo/NoabG0LzgEg/PADh9rwFo
 2vSgbQVoriPrb08h7mr5DNPCnQBebicPi/Cd9bkXq//NSikqpUud1pVss0Hi2fb5a87ql2Oa9m
 6E7z/ML1dL4grgAAAA=
To: Andrew Lunn <andrew@lunn.ch>, Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: mithat.guner@xeront.com, erkin.bozoglu@xeront.com, 
 Luiz Angelo Daros de Luca <luizluca@gmail.com>, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <ALSI@bang-olufsen.dk>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707809354; l=4698;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=FQVu4SdlGCbVhlJyCOryP4ivDPy0SI6ZNNcbaFbu7M0=;
 b=FBdXqqaV0vEKXzhXwwhzwHIG9P6X2VZ1lJ3hEQcD0rAhBYuWM0nf8ZjiLytG+tTVXc8bbAHN7
 u1G4tKR/i4YCZNhxGmuqgAgGAJVxHmYM814pW+T6NThhfNzT6DzChrp
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The code block under the "!ds->user_mii_bus && ds->ops->phy_read" check
under dsa_switch_setup() populates ds->user_mii_bus. The use of
ds->user_mii_bus is inappropriate when the MDIO bus of the switch is
described on the device tree [1].

For this reason, use this code block only for switches [with MDIO bus]
probed on platform_data, and OF which the switch MDIO bus isn't described
on the device tree. Therefore, remove OF-based MDIO bus registration as
it's useless for these cases.

These subdrivers which control switches [with MDIO bus] probed on OF, will
lose the ability to register the MDIO bus OF-based:

drivers/net/dsa/b53/b53_common.c
drivers/net/dsa/lan9303-core.c
drivers/net/dsa/vitesse-vsc73xx-core.c

These subdrivers let the DSA core driver register the bus:
- ds->ops->phy_read() and ds->ops->phy_write() are present.
- ds->user_mii_bus is not populated.

The commit fe7324b93222 ("net: dsa: OF-ware slave_mii_bus") which brought
OF-based MDIO bus registration on the DSA core driver is reasonably recent
and, in this time frame, there have been no device trees in the Linux
repository that started describing the MDIO bus, or dt-bindings defining
the MDIO bus for the switches these subdrivers control. So I don't expect
any devices to be affected.

The logic we encourage is that all subdrivers should register the switch
MDIO bus on their own [2]. And, for subdrivers which control switches [with
MDIO bus] probed on OF, this logic must be followed to support all cases
properly:

No switch MDIO bus defined: Populate ds->user_mii_bus, register the MDIO
bus, set the interrupts for PHYs if "interrupt-controller" is defined at
the switch node. This case should only be covered for the switches which
their dt-bindings documentation didn't document the MDIO bus from the
start. This is to keep supporting the device trees that do not describe the
MDIO bus on the device tree but the MDIO bus is being used nonetheless.

Switch MDIO bus defined: Don't populate ds->user_mii_bus, register the MDIO
bus, set the interrupts for PHYs if ["interrupt-controller" is defined at
the switch node and "interrupts" is defined at the PHY nodes under the
switch MDIO bus node].

Switch MDIO bus defined but explicitly disabled: If the device tree says
status = "disabled" for the MDIO bus, we shouldn't need an MDIO bus at all.
Instead, just exit as early as possible and do not call any MDIO API.

After all subdrivers that control switches with MDIO buses are made to
register the MDIO buses on their own, we will be able to get rid of
dsa_switch_ops :: phy_read() and :: phy_write(), and the code block for
registering the MDIO bus on the DSA core driver.

Link: https://lore.kernel.org/netdev/20231213120656.x46fyad6ls7sqyzv@skbuf/ [1]
Link: https://lore.kernel.org/netdev/20240103184459.dcbh57wdnlox6w7d@skbuf/ [2]
Suggested-by: Luiz Angelo Daros de Luca <luizluca@gmail.com>
Acked-by: Luiz Angelo Daros de Luca <luizluca@gmail.com>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Changes in v2:
- Remove mention to drivers/net/dsa/realtek/realtek-mdio.c as it now
  registers the MDIO bus OF-based on its own, and now under
  drivers/net/dsa/realtek/rtl83xx.c. I've waited until this happened
  because if this patch was applied beforehand, there would be no way to
  set IRQs on PHYs as the subdriver doesn't do that for the MDIO bus
  registered non-OF-based.
- Link to v1: https://lore.kernel.org/r/20240122053348.6589-1-arinc.unal@arinc9.com
---
 net/dsa/dsa.c | 7 +------
 1 file changed, 1 insertion(+), 6 deletions(-)

diff --git a/net/dsa/dsa.c b/net/dsa/dsa.c
index ac7be864e80d..09d2f5d4b3dd 100644
--- a/net/dsa/dsa.c
+++ b/net/dsa/dsa.c
@@ -15,7 +15,6 @@
 #include <linux/slab.h>
 #include <linux/rtnetlink.h>
 #include <linux/of.h>
-#include <linux/of_mdio.h>
 #include <linux/of_net.h>
 #include <net/dsa_stubs.h>
 #include <net/sch_generic.h>
@@ -626,7 +625,6 @@ static void dsa_switch_teardown_tag_protocol(struct dsa_switch *ds)
 
 static int dsa_switch_setup(struct dsa_switch *ds)
 {
-	struct device_node *dn;
 	int err;
 
 	if (ds->setup)
@@ -666,10 +664,7 @@ static int dsa_switch_setup(struct dsa_switch *ds)
 
 		dsa_user_mii_bus_init(ds);
 
-		dn = of_get_child_by_name(ds->dev->of_node, "mdio");
-
-		err = of_mdiobus_register(ds->user_mii_bus, dn);
-		of_node_put(dn);
+		err = mdiobus_register(ds->user_mii_bus);
 		if (err < 0)
 			goto free_user_mii_bus;
 	}

---
base-commit: 4acf4e62cd572b0c806035046b3698f5585ab821
change-id: 20240130-for-netnext-dsa-mdio-bus-627c0470e883

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

