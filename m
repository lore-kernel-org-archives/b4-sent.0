From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 25 Jun 2026 06:54:09 -0500
Subject: [PATCH] thunderbolt: bound the DROM dual link port number before
 indexing sw->ports
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-b4-disp-9f8d8a2d-v1-1-d767f256c54b@proton.me>
X-B4-Tracking: v=1; b=H4sIAOAWPWoC/x3MPQqAMAxA4auUzAZq8f8q4hCbqFm0tCBC8e4Wx
 294L0OSqJJgMhmi3Jr0OgvqyoA/6NwFlYvBWdfZzrW4NsiaAo7bwAM5RiKx4olrKz2ULETZ9Pm
 X8/K+H0oXMz9iAAAA
To: Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Andreas Noever <andreas.noever@gmail.com>
Cc: linux-usb@vger.kernel.org, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782388448; l=2331;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=oQprZsRa+Yn+IzGYZzrPZZv+52PjopLTeMKqCJsO2eE=;
 b=tb5cV0h3El2T+Z3H2HXyL03+rN77WdtqE5usadTPRyXY3vNNre07S38p0ApOTnboonPA588hp
 i1+LJTTiowJB1YSfBYcZHI5XZe6s9USsUMMf4HWVWE19eUS2bC1n6/o
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tb_drom_parse_entry_port() validates the device-supplied header->index
against sw->config.max_port_number before indexing sw->ports[], but the
sibling field entry->dual_link_port_nr -- a 6-bit value also read from
the DROM -- indexes the same array with no such check. A malicious or
malformed Thunderbolt device can set dual_link_port_nr beyond the
allocated sw->ports[] (max_port_number + 1 entries), producing an
out-of-bounds tb_port pointer that is stored and later dereferenced.

Reject a port entry whose dual_link_port_nr exceeds max_port_number,
the same bound already applied to header->index.

Fixes: cd22e73bdf5e ("thunderbolt: Read port configuration from eeprom.")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reachable only from the device side -- a malicious or malformed DROM, read at
enumeration -- so this hardens against an untrusted Thunderbolt device, not a
remote attacker.

I have no Thunderbolt hardware, so this is by source inspection plus an
out-of-tree KASAN module mirroring the &sw->ports[dual_link_port_nr] indexing:
with dual_link_port_nr = 63 on an 8-port switch the unpatched arithmetic
reports a slab-out-of-bounds read 1864 bytes past the kmalloc'd ports[]
object, while the bound and an in-range control run clean. Reproducer on
request.
---
 drivers/thunderbolt/eeprom.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/thunderbolt/eeprom.c b/drivers/thunderbolt/eeprom.c
index 5681c17f82ec..2a13fa6888ba 100644
--- a/drivers/thunderbolt/eeprom.c
+++ b/drivers/thunderbolt/eeprom.c
@@ -394,9 +394,16 @@ static int tb_drom_parse_entry_port(struct tb_switch *sw,
 			return -EIO;
 		}
 		port->link_nr = entry->link_nr;
-		if (entry->has_dual_link_port)
+		if (entry->has_dual_link_port) {
+			if (entry->dual_link_port_nr > sw->config.max_port_number) {
+				tb_sw_warn(sw,
+					"port entry has invalid dual link port number %u\n",
+					entry->dual_link_port_nr);
+				return -EIO;
+			}
 			port->dual_link_port =
 				&port->sw->ports[entry->dual_link_port_nr];
+		}
 	}
 	return 0;
 }

---
base-commit: 502d801f0ab03e4f32f9a33d203154ce84887921
change-id: 20260625-b4-disp-9f8d8a2d-aae0ecad10e7

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

