From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 21 Apr 2025 23:27:33 -0500
Subject: [PATCH 1/2] dt-bindings: power: supply: bq24190: Add BQ24193
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250421-bq24193-v1-1-f125ef396d24@gmail.com>
References: <20250421-bq24193-v1-0-f125ef396d24@gmail.com>
In-Reply-To: <20250421-bq24193-v1-0-f125ef396d24@gmail.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745296054; l=840;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=qOjayHUiWoIVkR1SIJGiQLJodRWPSQpu8XYOp3kWbAY=;
 b=ybZ6PARFeANCIx8hbvatk6BWSS9tEWyKaPgfm7I/uNQljR6DONKB9OJtyZx6eFUbNpaO/U28r
 fsALrh2QtcAA1hPFAleWBrnaYJuQSsiImTNKviTBxRZ3z5mMzHVcAH6
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The BQ24193 is most similar to the BQ24192. This is used in many Nvidia
Tegra devices such as the SHIELD Portable.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/power/supply/bq24190.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/power/supply/bq24190.yaml b/Documentation/devicetree/bindings/power/supply/bq24190.yaml
index 07adf88997b4e3eaa4bd7c6245efdc31fddc9058..307c99c077217ab4b5fac30694a4a316dd51f8e4 100644
--- a/Documentation/devicetree/bindings/power/supply/bq24190.yaml
+++ b/Documentation/devicetree/bindings/power/supply/bq24190.yaml
@@ -19,6 +19,7 @@ properties:
       - ti,bq24190
       - ti,bq24192
       - ti,bq24192i
+      - ti,bq24193
       - ti,bq24196
       - ti,bq24296
       - ti,bq24297

-- 
2.48.1

