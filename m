From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH v2 0/3] usb: dwc2: Add Siflower SF19A2890 support
Date: Wed, 11 Nov 2026 03:26:00 -0500
Message-Id: <20261111-sf19a2890-dwc2-v2-0-cba9dd4a4256@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJgm9GoC/12NQQ6CMBREr0L+2hr6EUpZeQ/DorQfqRowLVYN6
 d0tGDfu5iUzbxbw5Cx5aLIFHAXr7TQmwF0GelDjmZg1iQFzrDjPkfmeS4W1zJl5amS1KEXRC00
 dGUiju6Pevjbhqf2yf3QX0vNqWRuD9fPk3ttj4GvvJz/8ywNnKclSFqIkrFR3nOmm1HVvKEAbY
 /wA7CPc1L8AAAA=
X-Change-ID: 20261102-sf19a2890-dwc2-87573f7cebed
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Minas Harutyunyan <hminas@synopsys.com>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Conor Dooley <conor.dooley@microchip.com>, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794385586; l=2104;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=XpPZzJla59jRYnxtlUKPMCiQISBZDVhJWWG2U+hp7e0=;
 b=J824Y9+0Y+s7NKowLk6iAhTt8go1JljRvGQix4EpsIYwsFK8W/HwbxOfj27EhbVNndGCw6EsK
 2E7fN9Jo2u/Dox2ww2xjSChX4zVogKXarTKweKXzTd/mwUViFzidLQJ
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Siflower SF19A2890, a MIPS SoC for home routers, has a DWC OTG 3.30a.
This series adds its compatible and parameters, and handles an
interrupt it raises without flagging it: with battery charger support
enabled, the core sets MultValIpChng in GOTGINT but not OTGINT in GINTSTS,
so the interrupt is never cleared. Chuanhong saw the line disabled with
"nobody cares"; on the GL-SFT1200 the system stalls instead (below).

The two driver patches are Chuanhong Guo's, from OpenWrt and his
SF19A2890 branch. The OTG one handled GOTGINT on every interrupt for
every core; here it does so only for cores that set the new
otg_int_unflagged parameter, which only the SF19A2890 does.

Tested on a GL.iNet GL-SFT1200 with the USB PHY driver: a USB stick
enumerates at 480 Mb/s, reads at 5.6 MB/s and comes back cleanly after
two replugs. Without patch 3, a couple of replugs leave the system
stuck, the console repeating its last message with the same timestamp
until a power cycle; no "nobody cares" message appears first.

---
Changes in v2:
- Write my notes on Chuanhong's patches as lists, with Co-developed-by
  on the OTG interrupt patch.
- Sort the new compatible in the binding and in the match table.
- Describe the OTG interrupt fix as it is now in its commit message.
- Patch 1: add Conor's Ack.
- Link to v1: https://patch.msgid.link/20261104-sf19a2890-dwc2-v1-0-d959375e26ab@telaak.dev

---
Chuanhong Guo (2):
      usb: dwc2: Add Siflower SF19A2890 support
      usb: dwc2: Handle OTG interrupts that GINTSTS does not flag

Joseph Telaak (1):
      dt-bindings: usb: dwc2: Add Siflower SF19A2890

 Documentation/devicetree/bindings/usb/dwc2.yaml |  1 +
 drivers/usb/dwc2/core.h                         |  6 ++++++
 drivers/usb/dwc2/core_intr.c                    |  5 ++++-
 drivers/usb/dwc2/params.c                       | 11 +++++++++++
 4 files changed, 22 insertions(+), 1 deletion(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261102-sf19a2890-dwc2-87573f7cebed

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

