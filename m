From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 24 Nov 2026 04:43:29 +0300
Subject: [PATCH net-next] net: dsa: qca8k: select two-byte headers during
 setup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-qca8k-two-byte-header-init-v1-1-c644025b69fa@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQrCMBBA4auUWTvQhJJWryIu8jO1ozDVZNRK6
 d2Nunw8+FYolJkKHJoVMj258Cw1zK6BOHk5E3KqDba1zhjbYejwHv1wRX3NGN5KOJFPlJGFFV2
 b+t7ZvRtGC9W4ZRp5+flHEFIUWhRO/1Me4UJRvzxs2wfs169JiwAAAA==
X-Change-ID: 20261124-b4-qca8k-two-byte-header-init-60d7762968f2
To: Christian Marangi <ansuelsmth@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795484608; l=4136;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=uSCResecR5e/9XubjnoA9vw/Z2JIzLhyVXQwnSf9+wk=;
 b=MIGsySmIWqUTbQBiZq7Cy2qlQ28b0IFD2bHaE52W0juDjOglWVzMm1BZFmZJFZwitGaI6YaMn
 NW+/p52dFYYBUK6n+/QCk7tNLxaeScM+moHH4JZK+DQkR2zwnh5BXR0
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QCA tagger handles two-byte switch headers, but setup only programs
per-port header enable modes. The global HEADER_CTRL length selector can
remain in four-byte mode when firmware configured it and no reset GPIO
is supplied. Software tagger selection then disagrees with the switch.

Clear the global four-byte selector before enabling CPU header ports or
registering the user MDIO bus. Preserve the identifier and all other
bits, and abort setup if the register update fails. The register access
uses the existing MDIO transport before an in-band management conduit
is available.

Both ISIS and ISISC document the length selector at bit 16 of register
0x98. This does not add support for the optional four-byte protocol.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
The QCA tagger always uses two-byte headers. Initialize the global switch
length selector to match before enabling CPU header ports, rather than
relying on firmware or an optional reset GPIO to have selected that mode.
The register layout is shared by the supported ISIS and ISISC families.

This is a standalone generic driver change and does not depend on the
Cortina platform, Ethernet, PCIe or board DTS series. It adds no new tagger
or hardware offload capability. The identifier and other register bits are
preserved.

The retained four-byte state mismatch was identified by source inspection;
no four-byte firmware failure has been observed on the Almond+ test unit.
ARM W=1 QCA driver/tagger builds pass on Linux 7.4 and Linux 6.18.64 with
the existing upstream MDIO error-handling prerequisites. Source-helper
fault-injection tests cover the early setup update and returned errors.
Full ARM kernel builds with QCA8K built in and as a module also pass.

An instrumented Linux RAM kernel on the Almond+ completed two QCA8337
initializations. The read-clear-read snapshots were 0x00000000 throughout,
with unrelated bits preserved. PHY reads, MDIO recovery and real MIB byte
counter progress passed, along with 600 byte-exact ordinary DSA UDP echoes
and 20 large ICMPv6 replies. The watchdog returned to the installed system.
This covers the existing two-byte path; retained-four-byte handover has
not been exercised. The source-helper fault tests remain software tests.

Target net-next for now: this is a source-identified initialization issue,
with no demonstrated regression or stable backport request. Maintainers
can reassess the target if further evidence warrants it.
---
 drivers/net/dsa/qca/qca8k-8xxx.c | 8 ++++++++
 drivers/net/dsa/qca/qca8k.h      | 2 ++
 2 files changed, 10 insertions(+)

diff --git a/drivers/net/dsa/qca/qca8k-8xxx.c b/drivers/net/dsa/qca/qca8k-8xxx.c
index 382753bcc..15b97dee3 100644
--- a/drivers/net/dsa/qca/qca8k-8xxx.c
+++ b/drivers/net/dsa/qca/qca8k-8xxx.c
@@ -1865,6 +1865,14 @@ qca8k_setup(struct dsa_switch *ds)
 		return cpu_port;
 	}
 
+	/* The QCA tagger uses two-byte headers, regardless of firmware setup. */
+	ret = regmap_clear_bits(priv->regmap, QCA8K_REG_GLOBAL_HDR_CTRL,
+				QCA8K_GLOBAL_HDR_CTRL_LEN_4B);
+	if (ret) {
+		dev_err(priv->dev, "failed selecting two-byte QCA headers\n");
+		return ret;
+	}
+
 	/* Parse CPU port config to be later used in phy_link mac_config */
 	ret = qca8k_parse_port_config(priv);
 	if (ret)
diff --git a/drivers/net/dsa/qca/qca8k.h b/drivers/net/dsa/qca/qca8k.h
index 956338893..4740fcf39 100644
--- a/drivers/net/dsa/qca/qca8k.h
+++ b/drivers/net/dsa/qca/qca8k.h
@@ -149,6 +149,8 @@
 #define   QCA8K_PORT_STATUS_LINK_AUTO			BIT(9)
 #define   QCA8K_PORT_STATUS_LINK_PAUSE			BIT(10)
 #define   QCA8K_PORT_STATUS_FLOW_AUTO			BIT(12)
+#define QCA8K_REG_GLOBAL_HDR_CTRL			0x098
+#define   QCA8K_GLOBAL_HDR_CTRL_LEN_4B		BIT(16)
 #define QCA8K_REG_PORT_HDR_CTRL(_i)			(0x9c + (_i * 4))
 #define   QCA8K_PORT_HDR_CTRL_RX_MASK			GENMASK(3, 2)
 #define   QCA8K_PORT_HDR_CTRL_TX_MASK			GENMASK(1, 0)

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261124-b4-qca8k-two-byte-header-init-60d7762968f2

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

