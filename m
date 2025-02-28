From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 28 Feb 2025 18:32:51 +0100
Subject: [PATCH v2 2/3] dt-bindings: net: fsl,gianfar-mdio: Update
 information about TBI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250228-gianfar-yaml-v2-2-6beeefbd4818@posteo.net>
References: <20250228-gianfar-yaml-v2-0-6beeefbd4818@posteo.net>
In-Reply-To: <20250228-gianfar-yaml-v2-0-6beeefbd4818@posteo.net>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Claudiu Manoil <claudiu.manoil@nxp.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740763971; l=2181;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=zMz5pAYjehVzrNabVSZ8qNmJKs7MqhCYd9lIZiB49GU=;
 b=AkdnvksPfyxakEhB3XwQ6sK5tZChmkcrUjnPSbZK3tJdJtEfx5VTc/uKkXTbqX/8SjPEjtPYR
 e1vbgPFysgPChsNmWKfIUmEBkmmxwHZfXvF3WTuGVhs/jkjKu56DVyi
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When this binding was originally written, all known TSEC Ethernet
controllers had a Ten-Bit Interface (TBI). However, some datasheets such
as for the MPC8315E suggest that this is not universally true:

  The eTSECs do not support TBI, GMII, and FIFO operating modes, so all
  references to these interfaces and features should be ignored for this
  device.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

V2:
- Add Rob's Acked-by tag
---
 Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml | 13 ++++++-------
 1 file changed, 6 insertions(+), 7 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml b/Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml
index 22369771c13614875845b6d6e6d6031b933cb152..03c819bc701be4e6bcae37891baccd4b01ec53c4 100644
--- a/Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml
+++ b/Documentation/devicetree/bindings/net/fsl,gianfar-mdio.yaml
@@ -11,13 +11,12 @@ description:
   connected. For each device that exists on this bus, a child node should be
   created.
 
-  As of this writing, every TSEC is associated with an internal Ten-Bit
-  Interface (TBI) PHY. This PHY is accessed through the local MDIO bus. These
-  buses are defined similarly to the mdio buses, except they are compatible
-  with "fsl,gianfar-tbi". The TBI PHYs underneath them are similar to normal
-  PHYs, but the reg property is considered instructive, rather than
-  descriptive. The reg property should be chosen so it doesn't interfere with
-  other PHYs on the bus.
+  Some TSECs are associated with an internal Ten-Bit Interface (TBI) PHY. This
+  PHY is accessed through the local MDIO bus. These buses are defined similarly
+  to the mdio buses, except they are compatible with "fsl,gianfar-tbi". The TBI
+  PHYs underneath them are similar to normal PHYs, but the reg property is
+  considered instructive, rather than descriptive. The reg property should be
+  chosen so it doesn't interfere with other PHYs on the bus.
 
 maintainers:
   - J. Neuschäfer <j.ne@posteo.net>

-- 
2.48.0.rc1.219.gb6b6757d772

