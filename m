From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH v2 0/2] chipid: samsung: exynos-chipid: Add Exynos5515
 ChipID
Date: Tue, 18 Aug 2026 16:05:41 +0100
Message-Id: <20260818-for-next-lucky7-chipid-v2-0-28ae49f5c349@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMV0hGoC/3WNyw6CMBBFf4V07ZDSyMsV/2FY2GEKo0JJCwRC+
 HcB49LlSe49ZxWeHJMXt2AVjib2bLsd1CUQ2Dy6moCrnYWSKpFZFIOxDjqaB3iP+FpSwIZ7roA
 Q6ZonmCU6F/u5d2R4PsX38st+1E/C4bAdi4b9YN1ylqfo2P0i6b/IFIEE0iqXWSpjlFXRUqvJh
 cab0LpalNu2fQAyn4+L0wAAAA==
X-Change-ID: 20260815-for-next-lucky7-chipid-ecce496c86b9
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=966;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=WvhBurIy8A9u46LETLcI/MhJB6dhjgHJNOfnkpO39yM=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqhHUYUQuzBprixPTgcy8Al2eiWPDlLC/auEuGJ
 b7rFNdrS7mJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoR1GAAKCRBJJwGyxHrX
 68O5D/9JadzwC6VB9ScxAL+6S15RFJRmpF8VOn9qdwnh1WYZ/VKTrD9Muug4e+F9O/nVw36zojo
 6vo5AtQFlGMkvcJgMVQIPmjvdgq0YvbSkAwwDrmdJjW8U6GgGo04uFo/HbXBgCfqR+0F3srM3b8
 vlDvy9MKBTNkapfZqRINJj9oMp1fxL4Oi3YiFNC4s5Vv/Bjlek56JSmnreByfg+I3vZ2Sqw3L4k
 ioG6UdUdqxO1oAOiXZ++aLIsNdLot68PYvGwK8eYmvn5okRrqlJ7V/lalAqt9CuqgHgebX8+iwq
 yhWAjBsYFGklIxSZzNdY+83NKI7adh1eNTHLVXSSL6K3zfxzxCWAKb5IQM9PNcPEDwlFautb2p9
 EGJ4RY3tkQlR4lq89e0XzsXdKVqR/FYFR+Juy7wYc8iIr6EM3s2z78DS/3++RNkzRSSKYpTSbwX
 fKIS92m6rJrkvaKeUfQy4U2GyHpMzlFLJUlgBahOdlIULWtw71lgx2FZXdh60NV5Qil0Tx7aDP9
 dACgSMQ1ua0uVicja8Nn8t0S+2cqh8uB25btvPiKL7vaIhgiBHziDmnr6XiRSUqNJxTFlg0m92n
 8OonV5m3McfqvKK17kuRw18g0r3IVV52n0BY22TYPW6hZU/G3abqiC3J++y4pkSU1Ne9kJ6GjXI
 8qviN7VZfUqd1hQ==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi there,

This patchset adds support for the Exynos5515 SoC's ChipID to the
ChipID driver, and documents the samsung,exynos5515-chipid compatible.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
Changes in v2:
- Correct capitalisation of "Exynos5515" in commit messages
- Reword documentation commit message
- Link to v1: https://patch.msgid.link/20260817-for-next-lucky7-chipid-v1-0-eb2908705c0d@member.fsf.org

---
Aiden Isik (2):
      dt-bindings: hwinfo: samsung,exynos-chipid: Add Exynos5515 compatible
      soc: samsung: exynos-chipid: Add Exynos5515 SoC support

 Documentation/devicetree/bindings/hwinfo/samsung,exynos-chipid.yaml | 1 +
 drivers/soc/samsung/exynos-chipid.c                                 | 1 +
 2 files changed, 2 insertions(+)
---
base-commit: acde40ba506aae78633e080b5704d33cf4bc13c6
change-id: 20260815-for-next-lucky7-chipid-ecce496c86b9

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

