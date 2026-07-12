From: Johan Alvarado <contact@c127.dev>
Subject: [PATCH net-next v6 0/2] net: dsa: realtek: rtl8365mb: add
 SGMII/HSGMII support for RTL8367S
Date: Sat, 11 Jul 2026 23:31:57 -0500
Message-Id: <20260711-rtl8367s-sgmii-v6-0-88f7944ddca7@c127.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQ6CMBAFf4W8s5tQTAv6K4YDLQuu0Wq6lZAQ/
 t2qx8lkZoNyElacqw2JF1F5xgLuUCFchzgzyVgYTd24ujWGUr53R9cq6fwQIXvyk/EdD8FalOi
 VeJL1N7wgcqbIa0b/N/r2Nw75+8O+fwCqc0SFfAAAAA==
X-Change-ID: 20260711-rtl8367s-sgmii-59bf1b8eac55
To: Linus Walleij <linusw@kernel.org>, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <alsi@bang-olufsen.dk>, 
 Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: Mieczyslaw Nalewaj <namiltd@yahoo.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Luiz Angelo Daros de Luca <luizluca@gmail.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Alvarado <contact@c127.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783830718; l=11718;
 i=contact@c127.dev; s=20260711; h=from:subject:message-id;
 bh=P+6U9x8APFBzSRG71c5Zq7UgO8CTjuna1bsNOaL41Zo=;
 b=WRd9H+2PyC8tQOy0qudaE6weuB6AmmmkRyEpjMDxyuaEhRlgfFESme02Dvvx1035vyozzR3Q8
 qU4EZGDJWS/CJIRfFzQctDI7a4ozRdLpqhxN5SbdU9oaiR+N7sE5o+C
X-Developer-Key: i=contact@c127.dev; a=ed25519;
 pk=ZgvIq3VMEZWi50hs8D+jx3cP3dPdBRYrZZyKEosLfBQ=
X-Endpoint-Received: by B4 Relay for contact@c127.dev/20260711 with auth_id=864
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The RTL8367S is a 5+2 port switch from the same family as the
RTL8365MB-VC already supported by this driver. Its chip info table
entry declares SGMII and HSGMII on external interface 1, but the
driver so far only implements RGMII, leaving boards that wire the
switch to the CPU over the SerDes without a working CPU port.

This series implements both modes. The configuration sequence and the
SerDes tuning parameters are derived from the GPL-licensed Realtek
rtl8367c vendor driver, as distributed in the Mercusys MR80X GPL code
drop, and cross-checked against the real register sequence captured at
runtime by chainloading a custom U-Boot ahead of the stock firmware
and logging the live SerDes accesses on hardware.

The vendor driver brings up the SerDes by loading firmware into the
switch's embedded DW8051 microcontroller. Analysis of that firmware
(by Luiz Angelo Daros de Luca) showed it only performs a SerDes
data-path reset right after the SerDes reset is deasserted, and then
runs a link-polling loop that writes the external interface force
registers -- duplicating, and racing with, the link management phylink
already performs. This series therefore keeps the DW8051 disabled and
performs the one necessary action (the data-path reset via the SerDes
BMCR register) directly in the driver, avoiding both the race and a
dependency on a redistributable firmware blob.

The SerDes is modelled as a phylink PCS: mac_select_pcs() hands the
SerDes interfaces to a phylink_pcs whose pcs_config()/pcs_link_up()
ops own the SerDes register sequence, keeping it out of the MAC
operations. In-band autonegotiation is not implemented; the link is
forced (fixed-link or conventional PHY), as for RGMII, and the PCS
reports this to phylink through pcs_inband_caps().

Patch 1 adds the SerDes indirect access helpers, the PCS and SGMII
(1 Gbps) support. Patch 2 extends the PCS to HSGMII (2.5 Gbps), which
phylink represents as 2500base-x.

Tested on a Mercusys MR80X v2.20 (RTL8367S wired to the SoC over the
SerDes), in both SGMII and HSGMII modes with a fixed-link device tree
description: link bring-up verified across cold boots, warm reboots,
module reloads and link down/up cycles, with sustained traffic and no
CRC/symbol errors. The SerDes pause enables were verified by driving
congestion toward a 100M user port and observing pause frame emission
on the CPU port (dot3OutPauseFrames) toggle with the SDS_MISC
TXFC/RXFC bits. The port 6 rate limiters were verified to be live by
lowering them to 100 Mbps at runtime and observing iperf3 throughput
across the CPU port clamp accordingly in each direction, recovering
once the maximum was restored. The HSGMII link is confirmed running
at 2.5G at the register level (SoC uniphy mode and gmac clocks);
per-direction throughput could not be pushed past ~1 Gbps on this
board because the SoC side is driven by the IPQ5018 SSDK and the
user-facing PHY is 1G, so full 2.5G line-rate throughput remains
unverified on my hardware. Independently, >1 Gbps aggregate HSGMII
throughput (~2 Gbps with multiple clients) has been observed on an
RTL8367S-based Mercusys MR85X running an OpenWrt backport of this
series with the rate limiters raised (see patch 2).

The RTL8367SB also declares SGMII and HSGMII in its chip info entry
and therefore gains both modes as well. The vendor driver drives the
two chips through the same code path, keyed only on the chip option
register (both report chip id 0x6367), so this is expected to work
there too, but I have no RTL8367SB hardware to confirm it.

Changes across versions:

v6:
  - No code changes; resend of v5. The SMTP relay used for v5 rewrote
    the Message-IDs and dropped the References headers, so the patches
    did not thread under the cover letter on lore and could not be
    processed as a series. Reported by Mieczyslaw Nalewaj. This
    version is sent through the kernel.org b4 web endpoint instead.
v5: https://lore.kernel.org/netdev/0100019f488ec83f-cd82d418-999a-40de-b58b-135b4b2aee51-000000@email.amazonses.com/
  - Raise the port 6 ingress and egress rate limiters to their maximum
    at setup time, as the vendor switch init does. The chip resets them
    to 0x1FFFF (~1.048 Gbps in units of 8 Kbps), which caps the
    aggregate HSGMII throughput at roughly 1 Gbps; the cap was
    confirmed on an RTL8367S-based Mercusys MR85X, where raising the
    limiters took multi-client throughput across the HSGMII CPU port
    from ~1.02 Gbps combined to ~2 Gbps (link in patch 2). The related
    HSGMII scheduler line rate (LINE_RATE_HSG_H) is already set to its
    maximum by the common init jam table. Pointed out by Mieczyslaw
    Nalewaj.
  - Drop the PHYLINK_PCS_NEG_INBAND_ENABLED check from pcs_config().
    With pcs_inband_caps() returning LINK_INBAND_DISABLE, phylink can
    never select an in-band-enabled negotiation mode for this PCS, so
    the check was unreachable. Pointed out by Maxime Chevallier.
  - Document the SerDes SDS_MISC pause bits as the functional pause
    enables of the SerDes external interface, after testing flow
    control on hardware: pause frames are only emitted with the SerDes
    TXFC bit set, while the MAC force pause bits alone have no effect
    on this port. Comment-only change, prompted by a question from
    Maxime Chevallier.
v4: https://lore.kernel.org/netdev/20260702204648.276112-1-contact@c127.dev/
  - Drop the chip model name from the driver's NOTE comment; which
    interfaces a given chip exposes is described by its chip_info entry,
    not the file header. Pointed out by Luiz Angelo Daros de Luca.
  - Build the SerDes BMCR data-path-reset values from the standard
    BMCR_ANENABLE | BMCR_ISOLATE bits instead of a bare magic number, so
    the meaning is in the code rather than only in a comment. Pointed
    out by Luiz Angelo Daros de Luca.
  - Use a temporary for the DIGITAL_INTERFACE_SELECT value instead of
    wrapping the expression across the regmap_update_bits() arguments.
    Pointed out by Luiz Angelo Daros de Luca.
  - Reject the untested SerDes tuning variant. The vendor driver keeps
    two sets of SerDes tuning parameters and selects between them based
    on the chip option register (0x13C1); the tables in this series are
    the variant for a non-zero option, which is what the RTL8367S parts
    seen so far report. The option is probed once at setup and the
    SerDes interface modes are only advertised to phylink when the
    tuning parameters match, so an unsupported variant fails at phylink
    validation time instead of when configuring the link. Thanks to
    Luiz Angelo Daros de Luca for pointing out the conditional.
  - Express the external interface line rate bypass bit through a
    parametric macro keyed on the port number (with port 5 as the base),
    instead of an open-coded BIT(interface id) that only matched by
    coincidence; other RTL8367 families index this register differently.
    Suggested by Luiz Angelo Daros de Luca.
  - Drop the arbitrary usleep_range() after each SerDes indirect access.
    SerDes writes are now fire-and-forget and reads poll the self-clearing
    BUSY bit with regmap_read_poll_timeout(), matching the vendor driver,
    which never sleeps. On the MR80X the BUSY bit is never even observed
    set: the access completes within the register transaction. Pointed out
    by Luiz Angelo Daros de Luca; poll approach suggested by Mieczyslaw
    Nalewaj.
  - Drop the always-zero SerDes index argument from the SerDes indirect
    access helpers, along with the INDACS command index field whose
    width was questioned during review; this chip has a single SerDes
    block reachable through this window, so the index served no purpose.
    Raised by Luiz Angelo Daros de Luca.
  - Stop hardcoding external interface 1 with an early -EOPNOTSUPP in
    the SerDes configuration path. The SerDes interface modes are now
    advertised in phylink_get_caps() from the chip_info
    supported_interfaces, and mac_select_pcs() returns the PCS only for
    those modes. Pointed out by Luiz Angelo Daros de Luca.
  - Keep the new register definitions as raw hex masks, matching the
    prevailing style of the file. A file-wide GENMASK/BIT conversion,
    raised by Luiz Angelo Daros de Luca during review, is left for a
    separate cleanup patch so this series stays focused on the feature.
  - Convert the SerDes path to a phylink_pcs, as suggested by Maxime
    Chevallier. The SGMII/HSGMII SerDes handling now lives in
    pcs_config()/pcs_get_state()/pcs_link_up() selected via
    mac_select_pcs(), instead of being driven from the MAC
    mac_config()/mac_link_up()/mac_link_down() operations. This
    separates the MAC and SerDes layers and makes future in-band
    autonegotiation an additive change. No functional change intended
    for the forced-link path; retested on the MR80X v2.20. In-band
    autonegotiation remains unimplemented and is left for a follow-up,
    once hardware is available to validate it.
  - Implement pcs_inband_caps(), returning LINK_INBAND_DISABLE so that
    phylink knows this PCS cannot do in-band autonegotiation and never
    selects an in-band-enabled negotiation mode for it. pcs_config()
    rejects PHYLINK_PCS_NEG_INBAND_ENABLED with -EOPNOTSUPP instead of
    the previous warn-and-force.
  - Program the SerDes pause controls in SDS_MISC from the resolved
    pause modes when forcing the MAC external interface, as the vendor
    driver does, instead of leaving whatever state the boot firmware
    left there. Done in mac_link_up() because pcs_link_up() carries no
    pause information.
  - Set the PCS poll flag: the SerDes has no link interrupt wired up,
    so phylink must poll pcs_get_state() when it tracks the link
    through the PCS (in-band mode with autonegotiation disabled).
  - Report link down from pcs_get_state() if reading back the forced
    speed/duplex fails, rather than reporting link up with a stale
    state.
  - Reword the misleading "disable in-band aneg" comment.
v3: https://lore.kernel.org/netdev/20260613232136.24246-1-contact@c127.dev/
  - Drop the DW8051 firmware loading entirely. Analysis of the vendor
    firmware showed it only duplicates the link management phylink
    already does; the one needed action (SerDes data-path reset via
    the BMCR register) is now performed directly in the driver, with
    the DW8051 kept disabled. This removes the dependency on the
    rtl8367s-sgmii.bin firmware blob, which could not be redistributed
    via linux-firmware (the GPL vendor source ships it as a byte array
    without the corresponding microcode source). Thanks to Luiz Angelo
    Daros de Luca for the firmware analysis.
v2: https://lore.kernel.org/netdev/0100019eb0b1822e-ffc5626c-1b9f-4c8a-8a1a-759a9e665f4f-000000@email.amazonses.com/
  - No code changes; resend because the SMTP provider used for v1
    corrupted the mails and patch 1/2 never reached the list.
v1: https://lore.kernel.org/netdev/aebccaad-eca3-4ea4-99dd-ae7edbc8981b@smtp-relay.sendinblue.com/

Signed-off-by: Johan Alvarado <contact@c127.dev>
---
Johan Alvarado (2):
      net: dsa: realtek: rtl8365mb: add SGMII support for RTL8367S
      net: dsa: realtek: rtl8365mb: add HSGMII support for RTL8367S

 drivers/net/dsa/realtek/rtl8365mb_main.c | 619 ++++++++++++++++++++++++++++++-
 1 file changed, 614 insertions(+), 5 deletions(-)
---
base-commit: f6f3b36c15ed44de1fbb44e645e4fae8c4a4453e
change-id: 20260711-rtl8367s-sgmii-59bf1b8eac55

Best regards,
--  
Johan Alvarado <contact@c127.dev>

