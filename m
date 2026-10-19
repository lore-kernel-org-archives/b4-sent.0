From: Aiden Isik <aidenisik@member.fsf.org>
Date: Mon, 19 Oct 2026 11:23:49 +0100
Subject: [PATCH v2 3/5] dt-bindings: arm: samsung: Add lucky7 board binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-for-next-lucky7-v2-3-c4ecab4b1c4c@member.fsf.org>
References: <20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org>
In-Reply-To: <20261019-for-next-lucky7-v2-0-c4ecab4b1c4c@member.fsf.org>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1084;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=7JvUn6Gsqc0cxhWub/oalXTSGokInna58PtxHScXffE=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq1e+7u1fc6RiK79qTd3xcYvBPtWkFsc37Qiv6h
 VD3VsVE1uqJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCatXvuxsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+sy/w//ZekwG2PGvYhJbYmzUGgnKyuMJ70zcEn
 cD22liCLf0te67fVNfnhsbA1UcRmJW2zVGK06m+wW2BPs8jJAfya+AxGVeW18goOK8xz3SFGPyt
 QVLZjzcr36xWYhMIGcN40ptTMxO/6BRKVljGSTC/QuzbsmNwiGnMwWz/amIljM21fl2OOsWUnp0
 6SkFlafbMevjW556pAUE7n78H52qfHTSZCY39JaeZpoWzuOy57JSTy0g8QQOu5ugpDfLvRGWlbX
 Wu3pe8D4E8UA2piQkq1ppCeNOTsJyZMxD16Fy+adp3DoXBAjhnyyU4df8AhtLV7Ls1QLntb08nK
 RWwHywhL/SRPPuGB7vrqjB6YRmzSCMSL1kt6i5dshKvvYEV0oQ0qdTcQTi/0f0xgACv68gQaXm6
 qrBGSdqWNzKaGTsQeMOwniJoZrQ0kgNJhsVwEC7wmrvvYTiC8oLA31VrSwuFEBfJ2b9Tn3z0VOA
 Fs7XFOZb2dFFbWwD8+h0Pyyz3DH5ky5elpYQ7UwK8WK0C5nybCz94SAVo29m63nJDjV2mAyhO8Q
 0bbCW98XcDt1krkOZGWJVbOy2OLO53U2BSGHgiM/k1I/+8FAt0Ht+QX4y4V5lwTkIkmmcFIg9Dw
 eTOA2BTXC21Pt+Os/E0HIiKyR92TaoBh+eSuVX87hmD97VEltYLY=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree binding for the Samsung Galaxy Watch FE (SM-R861/SM-R866)
board, based on the Exynos5515 SoC.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml b/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml
index db19a686f490..c80fac4fad7a 100644
--- a/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml
+++ b/Documentation/devicetree/bindings/arm/samsung/samsung-boards.yaml
@@ -157,6 +157,12 @@ properties:
           - const: samsung,exynos5420
           - const: samsung,exynos5
 
+      - description: Exynos5515 based boards
+        items:
+          - enum:
+              - samsung,lucky7                  # Samsung Galaxy Watch FE (SM-R861/SM-R866)
+          - const: samsung,exynos5515
+
       - description: Google Peach Pit Boards (Rev 6+)
         items:
           - const: google,pit-rev16

-- 
2.54.0

