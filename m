From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Wed, 25 Nov 2026 23:50:29 +0300
Subject: [PATCH RFC net-next 1/7] dt-bindings: net: dsa: allow the QCA
 four-byte tag protocol
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-almondplus-offload-rfc-v1-1-703175c6340c@gmail.com>
References: <20261125-almondplus-offload-rfc-v1-0-703175c6340c@gmail.com>
In-Reply-To: <20261125-almondplus-offload-rfc-v1-0-703175c6340c@gmail.com>
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Simon Horman <horms@kernel.org>, Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Linus Walleij <linusw@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Russell King <linux@armlinux.org.uk>, 
 Christian Marangi <ansuelsmth@gmail.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netfilter-devel@vger.kernel.org, 
 coreteam@netfilter.org, linux-arm-kernel@lists.infradead.org, 
 linux-doc@vger.kernel.org, Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795639829; l=758;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=wkWk664vl65KKLXoTZskWR/R2hKT7/ZFZXG8a8vLUkk=;
 b=/eO4EXD1n36cNyH3ASrEAiKexWlKJjTPGD8kpZhI/7Ia3+/vWyKH6iBhrle27HletfgHHNBVX
 gpEUi5XwYYBDCMK0lIDc8Hybti2nuEAwSXdBZnU7RwLpRbJDx8PeB1N
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CS7542 parser needs an EtherType identifier ahead of the QCA
metadata. Allow CPU ports to select that format through the existing DSA
property.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 Documentation/devicetree/bindings/net/dsa/dsa-port.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/net/dsa/dsa-port.yaml b/Documentation/devicetree/bindings/net/dsa/dsa-port.yaml
index 480120469..30c6f70c9 100644
--- a/Documentation/devicetree/bindings/net/dsa/dsa-port.yaml
+++ b/Documentation/devicetree/bindings/net/dsa/dsa-port.yaml
@@ -53,6 +53,7 @@ properties:
     enum:
       - dsa
       - edsa
+      - qca4
       - ocelot
       - ocelot-8021q
       - rtl8_4

-- 
2.53.0

