From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 10 Aug 2026 23:16:19 +0300
Subject: [PATCH] dt-bindings: gpu: arm,mali-utgard: add mt6572
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-6572-dt-mali-v1-1-fb908627bf23@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0MDXTNTcyPdlBLd3MScTF2LJEvjJENTy0SD5FQloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loA1qQsdXAAAAA=
X-Change-ID: 20260810-6572-dt-mali-8b93b159a0ce
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786393594; l=1015;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=w9n8g0GvmLHdo4ZTDe8Qbd8jCW9LIeOjEpTJ03K8T3A=;
 b=Wl4b7fBK2XQcGb9Kc4Pqrn9gaLffzHfZKwfl+k10TPwS5Q3Y5WE+9SGFjVRrpTZpsY/d731yr
 uFMh1XUT+M7Bp5ULqe8NWew9WYkdx+wB/eRSn4u3ghdHyY5Eun7sMYb
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the mt6572 Mali-400 MP1 GPU.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/gpu/arm,mali-utgard.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/gpu/arm,mali-utgard.yaml b/Documentation/devicetree/bindings/gpu/arm,mali-utgard.yaml
index c8d0d9192d92..6bdbab82126c 100644
--- a/Documentation/devicetree/bindings/gpu/arm,mali-utgard.yaml
+++ b/Documentation/devicetree/bindings/gpu/arm,mali-utgard.yaml
@@ -27,6 +27,7 @@ properties:
               - allwinner,sun8i-h3-mali
               - allwinner,sun8i-r40-mali
               - allwinner,sun50i-a64-mali
+              - mediatek,mt6572-mali
               - rockchip,rk3036-mali
               - rockchip,rk3066-mali
               - rockchip,rk3128-mali

---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260810-6572-dt-mali-8b93b159a0ce

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

