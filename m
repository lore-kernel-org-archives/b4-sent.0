From: Aiden Isik <aidenisik@member.fsf.org>
Date: Thu, 22 Oct 2026 17:46:36 +0100
Subject: [PATCH 1/2] dt-bindings: phy: samsung,usb3-drd-phy: Add Exynos5515
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-for-next-lucky7-usb-phy-v1-1-2e47f8484bf4@member.fsf.org>
References: <20261022-for-next-lucky7-usb-phy-v1-0-2e47f8484bf4@member.fsf.org>
In-Reply-To: <20261022-for-next-lucky7-usb-phy-v1-0-2e47f8484bf4@member.fsf.org>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1354;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=TSsA+fRx4RBo19oCHI+BqN+RycpJHWo/dLkXD94y3zQ=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq2j3ssieeYp5OpBBa7/6qfdEtFIdA4uG3F7T2S
 7t+nJe7sCeJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCato97BsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+sn+RAA5RsY9YeLzM9rKsLA3zt2qepMy9qla5K
 8Ym4GmxLjGv4RGD1b34/5GxOOjTG19kRdtsQQkK8Cai+N79QSEw3IcfiMIjplw/iIbdgGyLRdBo
 X4lyTKCnB6ElPcURLBg5hdUuw5nzs820738ld96WELDcelDiZFmzfSQgjWORZYlRdZXK35ODdBA
 0Eo3SDYoExdOsqjcQEb7yfRdwhU5q5D3/vaub0F/JjmbaHk7JWAn48PCTOf6SLr/kAO8tA6GU56
 Z+0G6oVqzGXSBI4TyXnXQwbWB0eMCgVYedtNByQhWs5w+GdwJKUhJVce/AloHaTBvKbj6154NeE
 ZLFcNZ6usUTnzGQtY6tLQcHkGGYC56oJdpinpvOpzpndeLrSmP3ySjjgJDGYb8vAIeSaus8Kbg+
 iKtSuTBqWviOXF0+IB03T6BAQ8bvaIH2LPuUrtzuGy9se5e6cx0SmJe6lRnf0mTVAoh5qDczFnJ
 56gC8Lvhqrq3VpqKl8oMLpREgn1qU9P810ITZjTW12Scj7tsXvojTZ/myNUzdGSRAzcrt121o1Y
 PcpwzYnU8uJFz6VCUFBYar3Y+mX3KwjVdUsBRK92wZkpoZX5pwDcnQcHmyG9f1YI0WSGVadHQ9h
 MJ53kzDKK+VyQmOdwT4B8ScpFh33mcRrmFTcA/flKQUU/9jCZYOs=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the compatible string for exynos5515-usbdrd-phy. This PHY is
compatible with the Exynos5420 PHY when running in High-Speed mode,
in that it uses two clocks, phy and ref, so document it as such.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 Documentation/devicetree/bindings/phy/samsung,usb3-drd-phy.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/samsung,usb3-drd-phy.yaml b/Documentation/devicetree/bindings/phy/samsung,usb3-drd-phy.yaml
index a1b3d9e6a094..a9af03066d8d 100644
--- a/Documentation/devicetree/bindings/phy/samsung,usb3-drd-phy.yaml
+++ b/Documentation/devicetree/bindings/phy/samsung,usb3-drd-phy.yaml
@@ -30,6 +30,7 @@ properties:
       - samsung,exynos5250-usbdrd-phy
       - samsung,exynos5420-usbdrd-phy
       - samsung,exynos5433-usbdrd-phy
+      - samsung,exynos5515-usbdrd-phy
       - samsung,exynos7-usbdrd-phy
       - samsung,exynos7870-usbdrd-phy
       - samsung,exynos850-usbdrd-phy
@@ -233,6 +234,7 @@ allOf:
             enum:
               - samsung,exynos5250-usbdrd-phy
               - samsung,exynos5420-usbdrd-phy
+              - samsung,exynos5515-usbdrd-phy
               - samsung,exynos7870-usbdrd-phy
               - samsung,exynos850-usbdrd-phy
               - samsung,exynos990-usbdrd-phy

-- 
2.54.0

