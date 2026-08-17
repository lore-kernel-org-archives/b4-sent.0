From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH 0/2] Hi there,
Date: Mon, 17 Aug 2026 11:11:44 +0100
Message-Id: <20260817-for-next-lucky7-chipid-v1-0-eb2908705c0d@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGDegmoC/yXMQQ6CMBBG4auQWTsJEK3gVQwLGH5k1BTSFlPTc
 HerLr/Fe4k8nMLTpUjk8FKvi82oDgXJ3NsbWMdsqsvalE114mlxbBEDPzd5vM8ss646MkRwbI0
 0Zmgpx6vDpPE3vnZ/+224Q8L3Rvv+AXE+4tJ6AAAA
X-Change-ID: 20260815-for-next-lucky7-chipid-ecce496c86b9
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik+git@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=760;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=HBymSy0e8V1Jdo3HydqtzVX4WJvfuiz0AeM/kPrBAho=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqgt5ikqtrRi9zC5WphlCcPFX8+LqrSpK0WCl/O
 YMXUIuPtquJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoLeYgAKCRBJJwGyxHrX
 6/cXEADNUPtRxwYaI87hahphr8JmnU/eihs96reJnyIwHeK4Q81v34q+MMmk3Ztxm29PDT57p0f
 SRqG8QJHZ5k3TOhhA3qTjbN/tvx6W093AAhA9TnvkZ57TdeP4VUlDCdi0Z/nKsg4sG4xdpwkIxe
 agUvqoyzLeBFcuym0EhQe75nRGvyRmVCxW7t0+HP6tZoVC9lbdKN6EOCGmBDYNeIS4au58yqU20
 UEK87Lk0sqWFFtsJmgUx2UFQKwNGu5R7xZaifr+T1k2JfjLOW43/4AP/Mgg6Ex2uaM/oFiRY09x
 tjxNsClfBB/FboFsvAa40jPyXuWZcUPiDPhEPU+ZRlfQIrqMkE8wMguJDaegIRFZjFZnXnHBNC5
 skKlydIu87+QXlTEsr7oHLuvQrjYWaxRtNIZyB1E1n5TJt9EcUZ6NeenUDRTHCSwsspkvwsduyg
 6bRfxNu3bsxynLUSkDYpB6xGorJo2equ16wofTWyB6fn/vYbdT859ou9nLfNoY8M7XdeB/0/6Ya
 kV86yXhrkf2/YnmWCMSL4l3FdjtqKIglXwhwg4Guf8GioKYi8s5TsKe+7UplE8RfBG1R62oqWw9
 a3GePb9GVkkzGSn6Q6Max+Iz8Xfy8Vp0l/QsQdnsrysUFf9PbU8X9cxOAYaGs6aBVzhf8UxH+nV
 gnuNHLUgrBN7H7Q==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds support for the Exynos5515 SoC's chipid to the
chipid driver, and documents the samsung,exynos5515-chipid compatible.

Kind regards,
- Aiden Isik

Signed-off-by: Aiden Isik <aidenisik+git@member.fsf.org>
---
Aiden Isik (2):
      dt-bindings: hwinfo: samsung,exynos-chipid: Add exynos5515 compatible
      soc: samsung: exynos-chipid: Add exynos5515 SoC support

 Documentation/devicetree/bindings/hwinfo/samsung,exynos-chipid.yaml | 1 +
 drivers/soc/samsung/exynos-chipid.c                                 | 1 +
 2 files changed, 2 insertions(+)
---
base-commit: acde40ba506aae78633e080b5704d33cf4bc13c6
change-id: 20260815-for-next-lucky7-chipid-ecce496c86b9

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

