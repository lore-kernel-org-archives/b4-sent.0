From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Mar 2025 20:56:46 +0100
Subject: [PATCH v3 3/5] dt-bindings: wireless: bcm4329-fmac: Use
 wireless-controller.yaml schema
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-dt-bindings-network-class-v3-3-4d8d04ddfb61@ixit.cz>
References: <20250318-dt-bindings-network-class-v3-0-4d8d04ddfb61@ixit.cz>
In-Reply-To: <20250318-dt-bindings-network-class-v3-0-4d8d04ddfb61@ixit.cz>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Mailing List <devicetree-spec-u79uwXL29TY76Z2rM5mHXA@public.gmane.org>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, van Spriel <arend@broadcom.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_Pouiller?= <jerome.pouiller@silabs.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Andy Gross <agross@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Janne Grunau <j@jannau.net>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1032; i=david@ixit.cz;
 h=from:subject:message-id; bh=F26gMFvM4q7wCneWHdYAidCttNYCdnepTJdhqq9kBJw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2c/+OJVW2gz+HIjuFQflSTYGI/7N6UB8moiin
 ztWD5x6yGCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9nP/gAKCRBgAj/E00kg
 cgFHD/0dU/17AixTsOgnPu4cKlfCEEd0CcnNB1Mg9Dle+Jsju0Fn6pATDufALx/RqVto5IR5apa
 yJlkm6EcEOXq6SwfySNCHAIypSfgoZp/Y5fMuaHLdq69tD96PXvPfbCRtd1gPGr1Bq51yvSngcV
 9NmwDF4gewdP+XFavYO5EhkfnpK6ejlQtVbiVXb2hRR1+nunPgCxwYQl+XlIYeE+yplOF5ko2ty
 EEq+DuxxiqIZ6qcOzmSQjjYXtbKjw1bAqXb0ZZK9iV9BuJ5REGQACGppWwuJ/l30DexB3dCUuN6
 Uv2E0zElwxNfHZQKxSzrNrIm0hzVRm0q8x7/0lQMugp2UnSdxqhVFcDxluyf0NzUeVqlY7z5Ayq
 Fzz63WAk1F9V7rzhG3XA1+d+PN+HH8l3xLnEcKpg6mMK3AKxedZ6uihtqVfM14NbY0Q91gL1xUc
 f551PAqOX1AJp42ADBauvsnjAN1GWoEApk0NG1ll6vqBL9AUA0PPJiDHe69jYVVOMYS9Yg1FNij
 aPdCX1iLsnEGt5YVGo2FrbC0L5ZxEmNeMod7m3uGZxsZFJGyFL6dHl0nlamFrp2bt+uYrNGYzPh
 Sl0O+pfTJVmP5NdC0N0ylZsbju7vVSxIy3Dtox5X7HSqnVIbfMispYBHP/shsBF2U391Xtbk7cB
 Zx6JPLVs4Ikwyvg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

The wireless-controller schema specifies local-mac-address as
used in the bcm4329-fmac device nodes of Apple silicon devices
(arch/arm64/boot/dts/apple).

Fixes `make dtbs_check` for those devices.

Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/net/wireless/brcm,bcm4329-fmac.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/net/wireless/brcm,bcm4329-fmac.yaml b/Documentation/devicetree/bindings/net/wireless/brcm,bcm4329-fmac.yaml
index a3607d55ef3671514cdf2c884cf5bd0ccaadb162..7c8100e59a6cd045837a2f602e367f3f79ced5ba 100644
--- a/Documentation/devicetree/bindings/net/wireless/brcm,bcm4329-fmac.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/brcm,bcm4329-fmac.yaml
@@ -16,7 +16,7 @@ description:
   binding.
 
 allOf:
-  - $ref: ieee80211.yaml#
+  - $ref: /schemas/net/wireless/wireless-controller.yaml#
 
 properties:
   compatible:

-- 
2.49.0

