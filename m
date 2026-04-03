From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 15:58:46 +0200
Subject: [PATCH v3 1/5] dt-bindings: nfc: nxp,nci: Document PN557
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-oneplus-nfc-v3-1-fbdce57d63c1@ixit.cz>
References: <20260403-oneplus-nfc-v3-0-fbdce57d63c1@ixit.cz>
In-Reply-To: <20260403-oneplus-nfc-v3-0-fbdce57d63c1@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alexander Martinz <amartinz@shift.eco>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Alexander Martinz <amartinz@shiftphones.com>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 biemster <l.j.beemster@gmail.com>, netdev@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=801; i=david@ixit.cz;
 h=from:subject:message-id; bh=XAr0YPSe88hbZiI1E3SbtdYUk0kg/OIc+A90H6b4IMY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz8ebxDmaJwjzyRUTYj1d8k6YnudHVAbaS8Z0z
 WZS8g3mTjuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/HmwAKCRBgAj/E00kg
 ctP8D/4tH7JBKTPHlQxYPJDFWKPPaCb8sX95ulLhQltIx4eKz3/rdyOWz0DVGxLHyOCCxXY+yh1
 vzOjvHlM1+uUlUT9fKALTgVHIdK/ekiYEWh9mvzTGp2+XYyC7nYZgu2872UpcAy+K2+4bErVOx1
 vnlPUbSMj6EdN2g65b9zQhWzRdqwZ7b3coCjU0mtV2h4ZcFCPSfxIvGnS9B7C0NwG7D6/RW9Ut2
 AQZoHQL0gu7+MWSV1yKGqtPsH2kqmcLEefupzPJLXArS88YX7uDL4Nev1ce3ypTeOXoEibVSTII
 QzQo+FMLr++ILDXmsHhdjN+Fr+Zke5f/5S+Y600rSwJRr6AV08BKSYl9KY43HU3/56xBpd8/Mav
 Z6wkL0vn1o/orT6cZ/Vqzc0Q6TWsbsLjZ/pdG7kMrgqbF2K8VBpc5OTACiWDYCu//khwO7wY1Db
 o38e2ilcAT8DfwBsuOLPvpfIZ7gxTrYLimWc0kA/ovvliXQ6qr2sEdI9CrPEJeLQh28vcbovgaI
 3XtUwbjF2FG9yL304R39Xj7ALJMBvegnY2xHZxOhKgHpA+wLIL0YpnFn/IpLpmIj2jm5Im0D44p
 BXy6Z2nBYxDge68OwsDc5MHwLJRJID7+wvxCiuPEsWOyb6KiTUVoOKZ10cTXO3aim+fnaANu56i
 yuA0YIIcTPCechA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PN557 uses the same hardware as the PN553 but ships with
firmware compliant with NCI 2.0.

Document PN557 as a compatible device.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/net/nfc/nxp,nci.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/net/nfc/nxp,nci.yaml b/Documentation/devicetree/bindings/net/nfc/nxp,nci.yaml
index 364b361511808..4f3847f64983b 100644
--- a/Documentation/devicetree/bindings/net/nfc/nxp,nci.yaml
+++ b/Documentation/devicetree/bindings/net/nfc/nxp,nci.yaml
@@ -18,6 +18,7 @@ properties:
               - nxp,nq310
               - nxp,pn547
               - nxp,pn553
+              - nxp,pn557
           - const: nxp,nxp-nci-i2c
 
   enable-gpios:

-- 
2.53.0

