From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 25 Apr 2025 13:19:28 +0400
Subject: [PATCH v2] net: dsa: qca8k: fix led devicename when using external
 mdio bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250425-qca8k-leds-v2-1-b638fd3885ca@outlook.com>
X-B4-Tracking: v=1; b=H4sIAJ9TC2gC/22MQQ7CIBBFr9LMWkwHpLGuvIfpAmFqJ61FoRJNw
 93Frl38xfvJeytECkwRTtUKgRJH9nMBuavADma+kWBXGGQtdX2QWjytOY5iIheF0qTw2hqFbQ9
 FeATq+b3FLl3hgePiw2drJ/y9fzMJBYpGYWOcKpPy7F/L5P24t/4OXc75C4PqVLmmAAAA
X-Change-ID: 20250425-qca8k-leds-35e31b9a319f
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745572796; l=3435;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=ydGK36Kl5X3P/v+3CwPypXc8oDZyqDCNEcnQKXNutFA=;
 b=M4+pevfUAbWEi3MH1shAmBryPB6xZcVeewXJQthY8K/LnKGCjAm5MZD+k9aHotIPA/Rb6PEPN
 SGaAHTo0uWVBjuck36b1/Fa4nk6RbYnvbqZwaXZnuR45en4ILAEFpS3
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The qca8k dsa switch can use either an external or internal mdio bus.
This depends on whether the mdio node is defined under the switch node
itself and, as such, the internal_mdio_mask is populated with its
internal phys. Upon registering the internal mdio bus, the slave_mii_bus
of the dsa switch is assigned to this bus. When an external mdio bus is
used, it is left unassigned, though its id is used to create the device
names of the leds.
This leads to the leds being named '(efault):00:green:lan' and so on as
the slave_mii_bus is null. So let's fix this by adding a null check and
use the devicename of the external bus instead when an external bus is
configured.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Fix the led device names when an external mdio is configured.
The current codepath for registering led device names 'assumes' that the
internal mdio bus is used. Therefore, add a check and fallback to the
device name of the external mdio bus while creating the led device
names.

Wrong device names:
root@OpenWrt:~# ls -l /sys/class/leds                                           
lrwxrwxrwx    1 root     root             0 Jan  1  1970 (efault):00:green:lan -> ../../devices/platform/soc@0/90000.mdio/mdio_bus/90000.mdio-1/90000.n
lrwxrwxrwx    1 root     root             0 Jan  1  1970 (efault):01:green:lan -> ../../devices/platform/soc@0/90000.mdio/mdio_bus/90000.mdio-1/90000.n
lrwxrwxrwx    1 root     root             0 Jan  1  1970 (efault):02:green:lan -> ../../devices/platform/soc@0/90000.mdio/mdio_bus/90000.mdio-1/90000.n

Correct device names:
root@OpenWrt:~# ls -l /sys/class/leds                                                                                                                      
lrwxrwxrwx    1 root     root             0 Jan  1  1970 90000.mdio-1:00:green:lan -> ../../devices/platform/soc@0/90000.mdio/mdio_bus/90000.mdio-1/90000.n
lrwxrwxrwx    1 root     root             0 Jan  1  1970 90000.mdio-1:01:green:lan -> ../../devices/platform/soc@0/90000.mdio/mdio_bus/90000.mdio-1/90000.n
lrwxrwxrwx    1 root     root             0 Jan  1  1970 90000.mdio-1:02:green:lan -> ../../devices/platform/soc@0/90000.mdio/mdio_bus/90000.mdio-1/90000.n
---
Changes in v2:
- Fixed c/p error from older kernel version: slave_mii_bus was renamed
  to internal_mdio_bus
- Link to v1: https://lore.kernel.org/r/20250425-qca8k-leds-v1-1-6316ad36ad22@outlook.com
---
 drivers/net/dsa/qca/qca8k-leds.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/net/dsa/qca/qca8k-leds.c b/drivers/net/dsa/qca/qca8k-leds.c
index 43ac68052baf9f9926aaf4a9d8d09640f9022fcd..ef496e345a4e7dd5b9fb805b8e0ff3cce56e2986 100644
--- a/drivers/net/dsa/qca/qca8k-leds.c
+++ b/drivers/net/dsa/qca/qca8k-leds.c
@@ -429,7 +429,8 @@ qca8k_parse_port_leds(struct qca8k_priv *priv, struct fwnode_handle *port, int p
 		init_data.fwnode = led;
 		init_data.devname_mandatory = true;
 		init_data.devicename = kasprintf(GFP_KERNEL, "%s:0%d",
-						 priv->internal_mdio_bus->id,
+						 priv->internal_mdio_bus ?
+						 priv->internal_mdio_bus->id : priv->bus->id,
 						 port_num);
 		if (!init_data.devicename) {
 			fwnode_handle_put(led);

---
base-commit: 02ddfb981de88a2c15621115dd7be2431252c568
change-id: 20250425-qca8k-leds-35e31b9a319f

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

